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
# modules/storage_servers/storage_outputs.tf
#
# Output values for the Storage Servers module
# -----------------------------------------------------------------------------

output "storage_instances" {
  description = "Details of storage server instances"
  value = {
    for inst in google_compute_instance.storage : inst.name => {
      id           = inst.id
      name         = inst.name
      zone         = inst.zone
      machine_type = inst.machine_type
      private_ip   = inst.network_interface[0].network_ip
      self_link    = inst.self_link
      disks        = [for disk in inst.attached_disk : disk.device_name]
    }
  }
}

output "storage_private_ips" {
  description = "Private IP addresses of storage server instances"
  value       = [for inst in google_compute_instance.storage : inst.network_interface[0].network_ip]
}

output "storage_names" {
  description = "Names of storage server instances"
  value       = [for inst in google_compute_instance.storage : inst.name]
}

output "storage_ansible_info" {
  description = "Ansible inventory information for storage server instances"
  value = [
    for inst in google_compute_instance.storage : {
      hostname   = inst.name
      private_ip = inst.network_interface[0].network_ip
      user       = var.target_user
      component  = "storage"
    }
  ]
}

output "storage_data_disks" {
  description = "Information about attached data disks"
  value = {
    for k, disk in google_compute_disk.storage_data : k => {
      name      = disk.name
      size      = disk.size
      type      = disk.type
      self_link = disk.self_link
    }
  }
}

output "storage_export_paths" {
  description = "NFS export paths on storage servers"
  value = {
    for inst in google_compute_instance.storage :
    inst.name => "${inst.network_interface[0].network_ip}:/storage"
  }
}