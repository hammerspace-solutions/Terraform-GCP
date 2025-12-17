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
# modules/storage_servers/storage_variables.tf
#
# Input variables for the Storage Servers module
# -----------------------------------------------------------------------------

variable "common_config" {
  description = "Common configuration from root module"
  type = object({
    project_id            = string
    region                = string
    zone                  = string
    network_name          = string
    subnet_name           = string
    subnet_self_link      = string
    tags                  = list(string)
    labels                = map(string)
    project_name          = string
    ssh_keys_dir          = string
    allow_root            = bool
    placement_policy_name = string
    allowed_source_cidr_blocks = list(string)
  })
}

variable "placement_policy_name" {
  description = "Name of the placement policy for instance collocation"
  type        = string
  default     = ""
}

variable "instance_count" {
  description = "Number of storage server instances"
  type        = number
}

variable "image" {
  description = "Image name for storage server instances"
  type        = string
}

variable "image_project" {
  description = "Project ID where the image is stored"
  type        = string
  default     = ""
}

variable "machine_type" {
  description = "Machine type for storage server instances"
  type        = string
}

variable "boot_disk_size" {
  description = "Boot disk size in GB"
  type        = number
}

variable "boot_disk_type" {
  description = "Boot disk type"
  type        = string
}

variable "raid_level" {
  description = "RAID level for storage disks"
  type        = string
  default     = "0"
}

variable "disk_count" {
  description = "Number of data disks per instance"
  type        = number
}

variable "disk_size" {
  description = "Size of each data disk in GB"
  type        = number
}

variable "disk_type" {
  description = "Type of data disks"
  type        = string
}

variable "target_user" {
  description = "Target user for storage server operations"
  type        = string
}

variable "network_tags" {
  description = "Network tags for firewall rules"
  type        = list(string)
}

variable "preemptible" {
  description = "Use preemptible instances"
  type        = bool
  default     = false
}

variable "automatic_restart" {
  description = "Automatically restart instances"
  type        = bool
  default     = true
}

variable "on_host_maintenance" {
  description = "Maintenance behavior"
  type        = string
  default     = "MIGRATE"
}

variable "enable_ip_forwarding" {
  description = "Enable IP forwarding"
  type        = bool
  default     = false
}

variable "deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = false
}

variable "min_cpu_platform" {
  description = "Minimum CPU platform"
  type        = string
  default     = ""
}

variable "service_account_email" {
  description = "Service account email"
  type        = string
}

variable "iam_admin_group_name" {
  description = "Admin group name"
  type        = string
  default     = null
}