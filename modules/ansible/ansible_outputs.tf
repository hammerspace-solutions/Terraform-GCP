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
# modules/ansible/ansible_outputs.tf
#
# Output values for the Ansible module
# -----------------------------------------------------------------------------

output "ansible_instances" {
  description = "Details of Ansible controller instances"
  value = {
    for inst in google_compute_instance.ansible : inst.name => {
      id          = inst.id
      name        = inst.name
      zone        = inst.zone
      machine_type = inst.machine_type
      private_ip  = inst.network_interface[0].network_ip
      public_ip   = var.assign_public_ip ? inst.network_interface[0].access_config[0].nat_ip : null
      self_link   = inst.self_link
    }
  }
}

output "ansible_private_ips" {
  description = "Private IP addresses of Ansible instances"
  value       = [for inst in google_compute_instance.ansible : inst.network_interface[0].network_ip]
}

output "ansible_public_ips" {
  description = "Public IP addresses of Ansible instances"
  value       = var.assign_public_ip ? [for inst in google_compute_instance.ansible : inst.network_interface[0].access_config[0].nat_ip] : []
}

output "ansible_ssh_private_key_path" {
  description = "Path to the SSH private key for Ansible"
  value       = var.admin_private_key_path != "" ? var.admin_private_key_path : "${path.module}/id_rsa"
  sensitive   = true
}

output "ansible_ssh_public_key" {
  description = "SSH public key for Ansible"
  value       = var.admin_private_key_path == "" ? tls_private_key.ansible_ssh[0].public_key_openssh : (var.admin_public_key_path != "" ? file(var.admin_public_key_path) : "")
}

output "ansible_inventory_path" {
  description = "Path to the Ansible inventory file"
  value       = "${path.module}/inventory.ini"
}

output "ansible_config_path" {
  description = "Path to the ansible.cfg file"
  value       = "${path.module}/ansible.cfg"
}