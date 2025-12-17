# Copyright (c) 2025 Hammerspace, Inc
# -----------------------------------------------------------------------------
# modules/hammerspace/hammerspace_main.tf
# -----------------------------------------------------------------------------

locals {
  # Use goog_cm_deployment_name if provided, otherwise fall back to project_name
  deployment_name = var.goog_cm_deployment_name != "" ? var.goog_cm_deployment_name : var.common_config.project_name

  # Naming convention from guide: <deployment-name>-mds<number> for Anvil
  anvil_name_prefix = "${local.deployment_name}-mds"
  # DSX naming: <deployment-name>-dsx<number>
  dsx_name_prefix   = "${local.deployment_name}-dsx"

  image_project     = var.image_project != "" ? var.image_project : var.common_config.project_id

  subnet_self_link = (var.assign_public_ip && var.public_subnet_name != "") ? "projects/${var.common_config.project_id}/regions/${var.common_config.region}/subnetworks/${var.public_subnet_name}" : var.common_config.subnet_self_link

  # Cluster IP for HA - use pre-allocated if HA, otherwise use anvil1's IP
  cluster_ip = var.anvil_count > 1 ? google_compute_address.anvil_cluster_ip[0].address : (var.anvil_count == 1 ? google_compute_instance.anvil1[0].network_interface[0].network_ip : "")

  # Get subnet mask (assuming /24 for now, should ideally be calculated)
  subnet_mask = "24"
}

# Pre-allocate IP addresses for HA deployment
resource "google_compute_address" "anvil1_ip" {
  count = var.anvil_count > 1 ? 1 : 0

  name         = "${local.anvil_name_prefix}-1-ip"
  address_type = "INTERNAL"
  subnetwork   = var.common_config.subnet_self_link
  region       = var.common_config.region
}

resource "google_compute_address" "anvil2_ip" {
  count = var.anvil_count > 1 ? 1 : 0

  name         = "${local.anvil_name_prefix}-2-ip"
  address_type = "INTERNAL"
  subnetwork   = var.common_config.subnet_self_link
  region       = var.common_config.region
}

# Cluster alias IP for HA deployment
resource "google_compute_address" "anvil_cluster_ip" {
  count = var.anvil_count > 1 ? 1 : 0

  name         = "${local.deployment_name}-cluster-ip"
  address_type = "INTERNAL"
  subnetwork   = var.common_config.subnet_self_link
  region       = var.common_config.region
}

# Anvil metadata disks
resource "google_compute_disk" "anvil1_meta" {
  count = var.anvil_count >= 1 ? 1 : 0

  name = "${local.anvil_name_prefix}-1-meta"
  type = var.anvil_meta_disk_type
  size = var.anvil_meta_disk_size
  zone = var.common_config.zone

  labels = merge(var.common_config.labels, {
    component = "anvil"
    disk_type = "metadata"
  })

  dynamic "disk_encryption_key" {
    for_each = var.kms_key != "" ? [1] : []
    content {
      kms_key_self_link = var.kms_key
    }
  }
}

resource "google_compute_disk" "anvil2_meta" {
  count = var.anvil_count > 1 ? 1 : 0

  name = "${local.anvil_name_prefix}-2-meta"
  type = var.anvil_meta_disk_type
  size = var.anvil_meta_disk_size
  zone = var.common_config.zone

  labels = merge(var.common_config.labels, {
    component = "anvil"
    disk_type = "metadata"
  })

  dynamic "disk_encryption_key" {
    for_each = var.kms_key != "" ? [1] : []
    content {
      kms_key_self_link = var.kms_key
    }
  }
}

# =============================================================================
# Anvil 1 (Primary for HA, or Standalone)
# =============================================================================
resource "google_compute_instance" "anvil1" {
  count = var.anvil_count >= 1 ? 1 : 0

  name                      = "${local.anvil_name_prefix}-1"
  machine_type              = var.anvil_machine_type
  zone                      = var.common_config.zone
  deletion_protection       = var.deletion_protection && !(var.anvil_count == 1 && var.sa_anvil_destruction)
  allow_stopping_for_update = true

  labels = merge(var.common_config.labels, {
    component = "anvil"
    role      = var.anvil_count > 1 ? "primary" : "standalone"
  })

  tags = distinct(concat(var.anvil_network_tags, ["anvil", "hammerspace"]))

  boot_disk {
    initialize_params {
      image = "projects/${local.image_project}/global/images/${var.image}"
      size  = 100
      type  = "pd-ssd"
    }
  }

  attached_disk {
    source      = google_compute_disk.anvil1_meta[0].self_link
    device_name = "anvil-metadata"
  }

  network_interface {
    subnetwork = local.subnet_self_link
    network_ip = var.anvil_count > 1 ? google_compute_address.anvil1_ip[0].address : null

    # Note: Cluster alias IP is on Secondary node (anvil2) per original GCP pattern

    dynamic "access_config" {
      for_each = var.assign_public_ip ? [1] : []
      content {
        network_tier = "PREMIUM"
      }
    }
  }

  service_account {
    email  = var.service_account_email
    scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
      "https://www.googleapis.com/auth/cloudkms",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring.write",
      "https://www.googleapis.com/auth/service.management.readonly",
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/trace.append"
    ]
  }

  metadata = {
    enable-oslogin = "FALSE"
    hammerspace-role = "anvil"
    serial-port-enable = "TRUE"
    goog-cm-deployment-name = local.deployment_name
    admin_user_password = var.admin_user_password
    enable-https = tostring(var.enable_https)
    add-nodes-to-existing-solution = tostring(var.add_nodes_to_existing_solution)
    internal-ip = var.internal_ip
    ATTACHED_DISKS = jsonencode([{
      deviceName = "anvil-metadata"
      mode       = "READ_WRITE"
      source     = google_compute_disk.anvil1_meta[0].self_link
      type       = "PERSISTENT"
    }])
    provision = var.anvil_count == 1 ? jsonencode({
      node = {
        ha_mode = "Standalone"
        features = ["metadata"]
        hostname = "${local.deployment_name}-mds"
        networks = {
          eth0 = {
            roles = ["data", "mgmt"]
          }
        }
      }
    }) : jsonencode({
      cluster = {
        password = var.admin_user_password
      }
      node_index = "0"
      nodes = {
        "0" = {
          features = ["metadata"]
          hostname = "${local.deployment_name}-mds-1"
          ha_mode = "Primary"
          networks = {
            eth0 = {
              roles = ["data", "mgmt", "ha"]
              cluster_ips = ["${google_compute_address.anvil_cluster_ip[0].address}/${local.subnet_mask}"]
              ips = ["${google_compute_address.anvil1_ip[0].address}/${local.subnet_mask}"]
            }
          }
        }
        "1" = {
          features = ["metadata"]
          hostname = "${local.deployment_name}-mds-2"
          ha_mode = "Secondary"
          networks = {
            eth0 = {
              roles = ["data", "mgmt", "ha"]
              cluster_ips = ["${google_compute_address.anvil_cluster_ip[0].address}/${local.subnet_mask}"]
              ips = ["${google_compute_address.anvil2_ip[0].address}/${local.subnet_mask}"]
            }
          }
        }
      }
    })
    google-monitoring-enable = tostring(var.enable_monitoring)
    google-logging-enable    = tostring(var.enable_logging)
  }

  scheduling {
    preemptible         = var.preemptible
    automatic_restart   = var.preemptible ? false : var.automatic_restart
    on_host_maintenance = var.preemptible ? "TERMINATE" : var.on_host_maintenance
  }

  enable_display = var.enable_display

  depends_on = [
    google_compute_disk.anvil1_meta,
    google_compute_address.anvil1_ip,
    google_compute_address.anvil_cluster_ip
  ]
}

# =============================================================================
# Anvil 2 (Secondary for HA) - depends on Anvil 1
# =============================================================================
resource "google_compute_instance" "anvil2" {
  count = var.anvil_count > 1 ? 1 : 0

  name                      = "${local.anvil_name_prefix}-2"
  machine_type              = var.anvil_machine_type
  zone                      = var.common_config.zone
  deletion_protection       = var.deletion_protection
  allow_stopping_for_update = true

  labels = merge(var.common_config.labels, {
    component = "anvil"
    role      = "secondary"
  })

  tags = distinct(concat(var.anvil_network_tags, ["anvil", "hammerspace"]))

  boot_disk {
    initialize_params {
      image = "projects/${local.image_project}/global/images/${var.image}"
      size  = 100
      type  = "pd-ssd"
    }
  }

  attached_disk {
    source      = google_compute_disk.anvil2_meta[0].self_link
    device_name = "anvil-metadata"
  }

  network_interface {
    subnetwork = local.subnet_self_link
    network_ip = google_compute_address.anvil2_ip[0].address

    # Cluster alias IP is assigned to Secondary node per original GCP pattern
    alias_ip_range {
      ip_cidr_range = "${google_compute_address.anvil_cluster_ip[0].address}/32"
    }

    dynamic "access_config" {
      for_each = var.assign_public_ip ? [1] : []
      content {
        network_tier = "PREMIUM"
      }
    }
  }

  service_account {
    email  = var.service_account_email
    scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
      "https://www.googleapis.com/auth/cloudkms",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring.write",
      "https://www.googleapis.com/auth/service.management.readonly",
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/trace.append"
    ]
  }

  metadata = {
    enable-oslogin = "FALSE"
    hammerspace-role = "anvil"
    serial-port-enable = "TRUE"
    goog-cm-deployment-name = local.deployment_name
    admin_user_password = var.admin_user_password
    enable-https = tostring(var.enable_https)
    add-nodes-to-existing-solution = tostring(var.add_nodes_to_existing_solution)
    internal-ip = var.internal_ip
    ATTACHED_DISKS = jsonencode([{
      deviceName = "anvil-metadata"
      mode       = "READ_WRITE"
      source     = google_compute_disk.anvil2_meta[0].self_link
      type       = "PERSISTENT"
    }])
    provision = jsonencode({
      cluster = {
        password = var.admin_user_password
      }
      node_index = "1"
      nodes = {
        "0" = {
          features = ["metadata"]
          hostname = "${local.deployment_name}-mds-1"
          ha_mode = "Primary"
          networks = {
            eth0 = {
              roles = ["data", "mgmt", "ha"]
              cluster_ips = ["${google_compute_address.anvil_cluster_ip[0].address}/${local.subnet_mask}"]
              ips = ["${google_compute_address.anvil1_ip[0].address}/${local.subnet_mask}"]
            }
          }
        }
        "1" = {
          features = ["metadata"]
          hostname = "${local.deployment_name}-mds-2"
          ha_mode = "Secondary"
          networks = {
            eth0 = {
              roles = ["data", "mgmt", "ha"]
              cluster_ips = ["${google_compute_address.anvil_cluster_ip[0].address}/${local.subnet_mask}"]
              ips = ["${google_compute_address.anvil2_ip[0].address}/${local.subnet_mask}"]
            }
          }
        }
      }
    })
    google-monitoring-enable = tostring(var.enable_monitoring)
    google-logging-enable    = tostring(var.enable_logging)
  }

  scheduling {
    preemptible         = var.preemptible
    automatic_restart   = var.preemptible ? false : var.automatic_restart
    on_host_maintenance = var.preemptible ? "TERMINATE" : var.on_host_maintenance
  }

  enable_display = var.enable_display

  # CRITICAL: Anvil2 must wait for Anvil1 to be created first
  depends_on = [
    google_compute_disk.anvil2_meta,
    google_compute_address.anvil2_ip,
    google_compute_instance.anvil1
  ]
}

# =============================================================================
# DSX Resources
# =============================================================================

# DSX data disks
resource "google_compute_disk" "dsx_data" {
  for_each = {
    for pair in setproduct(range(var.dsx_count), range(var.dsx_disk_count)) :
    "${pair[0]}-${pair[1]}" => {
      instance_index = pair[0]
      disk_index     = pair[1]
    }
  }

  name = "${local.dsx_name_prefix}-${each.value.instance_index + 1}-disk-${each.value.disk_index + 1}"
  type = var.dsx_disk_type
  size = var.dsx_disk_size
  zone = var.common_config.zone

  labels = merge(var.common_config.labels, {
    component = "dsx"
    disk_type = "data"
  })

  dynamic "disk_encryption_key" {
    for_each = var.kms_key != "" ? [1] : []
    content {
      kms_key_self_link = var.kms_key
    }
  }
}

# DSX instances
resource "google_compute_instance" "dsx" {
  count = var.dsx_count

  name                = "${local.dsx_name_prefix}-${count.index + 1}"
  machine_type        = var.dsx_machine_type
  zone                = var.common_config.zone
  deletion_protection = var.deletion_protection

  labels = merge(var.common_config.labels, {
    component = "dsx"
  })

  tags = distinct(concat(var.dsx_network_tags, ["dsx", "hammerspace"]))

  boot_disk {
    initialize_params {
      image = "projects/${local.image_project}/global/images/${var.image}"
      size  = 100
      type  = "pd-ssd"
    }
  }

  dynamic "attached_disk" {
    for_each = range(var.dsx_disk_count)
    content {
      source      = google_compute_disk.dsx_data["${count.index}-${attached_disk.value}"].self_link
      device_name = "dsx-data-${attached_disk.value + 1}"
    }
  }

  network_interface {
    subnetwork = var.common_config.subnet_self_link
  }

  service_account {
    email  = var.service_account_email
    scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
      "https://www.googleapis.com/auth/cloudkms",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring.write",
      "https://www.googleapis.com/auth/service.management.readonly",
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/trace.append"
    ]
  }

  metadata = {
    enable-oslogin = "FALSE"
    hammerspace-role = "dsx"
    serial-port-enable = "TRUE"
    goog-cm-deployment-name = local.deployment_name
    admin_user_password = var.admin_user_password
    enable-https = tostring(var.enable_https)
    add-nodes-to-existing-solution = "true"
    internal-ip = local.cluster_ip
    ATTACHED_DISKS = jsonencode([
      for disk in range(var.dsx_disk_count) : {
        deviceName = "dsx-data-${disk + 1}"
        mode       = "READ_WRITE"
        source     = google_compute_disk.dsx_data["${count.index}-${disk}"].self_link
        type       = "PERSISTENT"
      }
    ])
    provision = jsonencode({
      cluster = {
        metadata = {
          ips = [local.cluster_ip]
        }
        password = var.admin_user_password
      }
      node = {
        features = ["portal", "storage"]
        add_volumes = true
        hostname = "${local.dsx_name_prefix}-${count.index + 1}"
        networks = {
          eth0 = {
            roles = ["data", "mgmt"]
          }
        }
      }
    })
    google-monitoring-enable = tostring(var.enable_monitoring)
    google-logging-enable    = tostring(var.enable_logging)
  }

  scheduling {
    preemptible         = var.preemptible
    automatic_restart   = var.preemptible ? false : var.automatic_restart
    on_host_maintenance = var.preemptible ? "TERMINATE" : var.on_host_maintenance
  }

  enable_display = var.enable_display

  # DSX must wait for all Anvil instances to be ready
  depends_on = [
    google_compute_disk.dsx_data,
    google_compute_instance.anvil1,
    google_compute_instance.anvil2
  ]
}
