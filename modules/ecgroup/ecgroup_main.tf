# Copyright (c) 2025 Hammerspace, Inc
# -----------------------------------------------------------------------------
# modules/ecgroup/ecgroup_main.tf
# -----------------------------------------------------------------------------

locals {
  ecgroup_name_prefix = "${var.common_config.project_name}-ecgroup"
  image_project       = var.image_project != "" ? var.image_project : var.common_config.project_id
  all_network_tags    = distinct(concat(var.network_tags, ["ecgroup", "storage-node"]))
}

# Metadata disks for ECGroup nodes
resource "google_compute_disk" "ecgroup_metadata" {
  count = var.node_count

  name = "${local.ecgroup_name_prefix}-node${count.index + 1}-metadata"
  type = var.metadata_disk_type
  size = var.metadata_disk_size
  zone = var.common_config.zone

  labels = merge(var.common_config.labels, {
    component = "ecgroup"
    disk_type = "metadata"
    node      = count.index + 1
  })
}

# Storage disks for ECGroup nodes
resource "google_compute_disk" "ecgroup_storage" {
  for_each = {
    for pair in setproduct(range(var.node_count), range(var.storage_disk_count)) :
    "${pair[0]}-${pair[1]}" => {
      node_index = pair[0]
      disk_index = pair[1]
    }
  }

  name = "${local.ecgroup_name_prefix}-node${each.value.node_index + 1}-storage${each.value.disk_index + 1}"
  type = var.storage_disk_type
  size = var.storage_disk_size
  zone = var.common_config.zone

  labels = merge(var.common_config.labels, {
    component = "ecgroup"
    disk_type = "storage"
    node      = each.value.node_index + 1
    disk      = each.value.disk_index + 1
  })
}

# ECGroup node instances
resource "google_compute_instance" "ecgroup_node" {
  count = var.node_count

  name                = "${local.ecgroup_name_prefix}-node${count.index + 1}"
  machine_type        = var.machine_type
  zone                = var.common_config.zone
  deletion_protection = var.deletion_protection
  can_ip_forward      = var.enable_ip_forwarding

  labels = merge(var.common_config.labels, {
    component = "ecgroup"
    node      = count.index + 1
  })

  tags = local.all_network_tags

  boot_disk {
    initialize_params {
      image = "projects/${local.image_project}/global/images/${var.image}"
      size  = var.boot_disk_size
      type  = var.boot_disk_type
    }
  }

  # Attach metadata disk
  attached_disk {
    source      = google_compute_disk.ecgroup_metadata[count.index].self_link
    device_name = "ecgroup-metadata"
    mode        = "READ_WRITE"
  }

  # Attach storage disks
  dynamic "attached_disk" {
    for_each = range(var.storage_disk_count)
    content {
      source      = google_compute_disk.ecgroup_storage["${count.index}-${attached_disk.value}"].self_link
      device_name = "ecgroup-storage-${attached_disk.value + 1}"
      mode        = "READ_WRITE"
    }
  }

  network_interface {
    subnetwork = var.common_config.subnet_self_link
  }

  service_account {
    email  = var.service_account_email
    scopes = ["cloud-platform"]
  }

  metadata = {
    enable-oslogin = "FALSE"
    ecgroup-node   = count.index + 1
    ecgroup-total  = var.node_count
  }

  scheduling {
    preemptible         = var.preemptible
    automatic_restart   = var.preemptible ? false : var.automatic_restart
    on_host_maintenance = var.preemptible ? "TERMINATE" : var.on_host_maintenance
  }

  shielded_instance_config {
    enable_secure_boot          = false
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }

  # Resource policy for placement
  resource_policies = var.placement_policy_name != "" ? ["projects/${var.common_config.project_id}/regions/${var.common_config.region}/resourcePolicies/${var.placement_policy_name}"] : []

  depends_on = [
    google_compute_disk.ecgroup_metadata,
    google_compute_disk.ecgroup_storage
  ]
}