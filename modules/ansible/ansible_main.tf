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
# modules/ansible/ansible_main.tf
#
# Main configuration for Ansible controller instances
# -----------------------------------------------------------------------------

locals {
  ansible_name_prefix = "${var.common_config.project_name}-ansible"

  # Determine which subnet to use based on public IP requirements
  subnet_self_link = (var.assign_public_ip && var.public_subnet_name != "") ? "projects/${var.common_config.project_id}/regions/${var.common_config.region}/subnetworks/${var.public_subnet_name}" : var.common_config.subnet_self_link

  # Combine network tags
  all_network_tags = distinct(concat(var.network_tags, ["ansible", "ssh-server"]))

  # Image project
  image_project = var.image_project != "" ? var.image_project : var.common_config.project_id
}

# Generate SSH key pair if not provided
resource "tls_private_key" "ansible_ssh" {
  count = var.admin_private_key_path == "" ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Save private key locally if generated
resource "local_file" "ansible_private_key" {
  count = var.admin_private_key_path == "" ? 1 : 0
  content  = tls_private_key.ansible_ssh[0].private_key_pem
  filename = "${path.module}/id_rsa"
  file_permission = "0600"
}

# Save public key locally if generated
resource "local_file" "ansible_public_key" {
  count = var.admin_private_key_path == "" ? 1 : 0
  content  = tls_private_key.ansible_ssh[0].public_key_openssh
  filename = "${path.module}/id_rsa.pub"
  file_permission = "0644"
}

# Read script templates for daemon mode
locals {
  functions_script = file("${path.module}/scripts/ansible_functions.sh.tpl")
  daemon_script    = file("${path.module}/scripts/ansible_controller_daemon.sh.tpl")
  playbook_script  = file("${path.module}/scripts/hs-ansible.yml")

  # Generate job script with variables
  job_script = templatefile("${path.module}/scripts/10-hammerspace-integration.sh.tpl", {
    anvil_cluster_ip  = var.anvil_cluster_ip
    hs_username       = var.hs_username
    hs_password       = var.hs_password
    volume_group_name = var.volume_group_name
    share_name        = var.share_name
  })

  # Generate variables JSON for playbook
  vars_json = jsonencode({
    storages = var.storages
    share = {
      "_type"       = "SHARE"
      "name"        = var.share_config.name
      "path"        = var.share_config.path
      "exportPath"  = var.share_config.exportPath
      "description" = var.share_config.description
      "exportOptions" = [
        {
          "_type"                  = "EXPORT_OPTION"
          "name"                   = "*"
          "accessType"             = "READ_WRITE"
          "squash"                 = "NO_ROOT_SQUASH"
          "securityModes"          = ["SYS"]
          "networkAddressAllowed"  = "*"
        }
      ]
    }
  })
}

# Startup script for Ansible controller
locals {
  startup_script = var.use_startup_script ? templatefile("${path.module}/ansible_startup.sh.tpl", {
    target_user      = var.target_user
    admin_pub_key    = var.admin_private_key_path == "" ? tls_private_key.ansible_ssh[0].public_key_openssh : file(var.admin_public_key_path)
    admin_priv_key   = var.admin_private_key_path == "" ? tls_private_key.ansible_ssh[0].private_key_pem : file(var.admin_private_key_path)
    allow_root       = var.common_config.allow_root
    enable_daemon    = var.enable_daemon
    functions_script = local.functions_script
    daemon_script    = local.daemon_script
    playbook_script  = local.playbook_script
    job_script       = local.job_script
    vars_json        = local.vars_json
  }) : ""
}

# Create Ansible controller instances
resource "google_compute_instance" "ansible" {
  count = var.instance_count

  name         = "${local.ansible_name_prefix}-${count.index + 1}"
  machine_type = var.machine_type
  zone         = var.common_config.zone

  labels = merge(
    var.common_config.labels,
    {
      component = "ansible"
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

  network_interface {
    subnetwork = local.subnet_self_link

    dynamic "access_config" {
      for_each = var.assign_public_ip ? [1] : []
      content {
        network_tier = "PREMIUM"
      }
    }
  }

  service_account {
    email  = var.service_account_email
    scopes = ["cloud-platform"]
  }

  metadata = {
    ssh-keys = join("\n", concat(
      var.ssh_keys,
      var.admin_public_key_path != "" ? ["${var.target_user}:${file(var.admin_public_key_path)}"] :
      var.admin_private_key_path == "" ? ["${var.target_user}:${tls_private_key.ansible_ssh[0].public_key_openssh}"] : []
    ))
    enable-oslogin = "FALSE"
    startup-script = local.startup_script
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

  allow_stopping_for_update = true
}

# Create inventory file for all managed instances
resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/inventory.ini.tpl", {
    ansible_hosts = google_compute_instance.ansible
    target_user   = var.target_user
  })
  filename = "${path.module}/inventory.ini"
  file_permission = "0644"
}

# Create ansible.cfg
resource "local_file" "ansible_config" {
  content = templatefile("${path.module}/ansible.cfg.tpl", {
    inventory_file = "${path.module}/inventory.ini"
    private_key    = var.admin_private_key_path != "" ? var.admin_private_key_path : "${path.module}/id_rsa"
    target_user    = var.target_user
  })
  filename = "${path.module}/ansible.cfg"
  file_permission = "0644"
}