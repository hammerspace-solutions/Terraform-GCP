# Copyright (c) 2025 Hammerspace, Inc
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
# -----------------------------------------------------------------------------
# modules/clients/clients_main.tf
#
# Main configuration for client instances
# -----------------------------------------------------------------------------

locals {
  client_name_prefix = "${var.common_config.project_name}-client"

  # Combine network tags
  all_network_tags = distinct(concat(var.network_tags, ["client", "nfs-client"]))

  # Image project
  image_project = var.image_project != "" ? var.image_project : var.common_config.project_id

  # Calculate number of local SSDs if tier0 is enabled
  local_ssd_count = var.tier0 ? 1 : 0
}

# Create persistent disks for each client
resource "google_compute_disk" "client_data" {
  for_each = {
    for pair in setproduct(range(var.instance_count), range(var.disk_count)) :
    "${pair[0]}-${pair[1]}" => {
      instance_index = pair[0]
      disk_index     = pair[1]
    }
    if var.disk_count > 0
  }

  name = "${local.client_name_prefix}-${each.value.instance_index + 1}-disk-${each.value.disk_index + 1}"
  type = var.disk_type
  size = var.disk_size
  zone = var.common_config.zone

  labels = merge(
    var.common_config.labels,
    {
      component = "client"
      instance  = each.value.instance_index + 1
      disk      = each.value.disk_index + 1
    }
  )
}

# Create client instances
resource "google_compute_instance" "client" {
  count = var.instance_count

  name         = "${local.client_name_prefix}-${count.index + 1}"
  machine_type = var.machine_type
  zone         = var.common_config.zone

  labels = merge(
    var.common_config.labels,
    {
      component = "client"
      index     = count.index + 1
    }
  )

  tags = local.all_network_tags

  boot_disk {
    initialize_params {
      image = "projects/${local.image_project}/global/images/${var.image}"
      size  = var.boot_disk_size
      type  = var.boot_disk_type
    }
  }

  # Attach persistent data disks
  dynamic "attached_disk" {
    for_each = var.disk_count > 0 ? range(var.disk_count) : []
    content {
      source      = google_compute_disk.client_data["${count.index}-${attached_disk.value}"].self_link
      device_name = "data-disk-${attached_disk.value + 1}"
      mode        = "READ_WRITE"
    }
  }

  # Add local SSDs if tier0 is enabled
  dynamic "scratch_disk" {
    for_each = range(local.local_ssd_count)
    content {
      interface = var.tier0_type
    }
  }

  network_interface {
    subnetwork = var.common_config.subnet_self_link

    # Clients typically don't need public IPs
    # Add access_config block if needed
  }

  service_account {
    email  = var.service_account_email
    scopes = ["cloud-platform"]
  }

  metadata = {
    enable-oslogin = "FALSE"
    startup-script = templatefile("${path.module}/client_startup.sh.tpl", {
      target_user = var.target_user
      disk_count  = var.disk_count
      raid_level  = "0"  # Clients typically don't use RAID
      mount_point = "/data"
    })
  }

  scheduling {
    preemptible         = var.preemptible
    automatic_restart   = var.preemptible ? false : var.automatic_restart
    on_host_maintenance = (var.preemptible || var.tier0) ? "TERMINATE" : var.on_host_maintenance
  }

  # Advanced configuration
  advanced_machine_features {
    enable_nested_virtualization = var.enable_nested_virtualization
    threads_per_core            = var.threads_per_core
  }

  shielded_instance_config {
    enable_secure_boot          = false
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }

  # Resource policy for placement
  resource_policies = var.placement_policy_name != "" ? ["projects/${var.common_config.project_id}/regions/${var.common_config.region}/resourcePolicies/${var.placement_policy_name}"] : []

  allow_stopping_for_update = true

  depends_on = [google_compute_disk.client_data]
}