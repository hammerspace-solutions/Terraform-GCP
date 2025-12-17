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
# modules/clients/clients_variables.tf
#
# Input variables for the Clients module
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
  description = "Number of client instances"
  type        = number
}

variable "image" {
  description = "Image name for client instances"
  type        = string
}

variable "image_project" {
  description = "Project ID where the image is stored"
  type        = string
  default     = ""
}

variable "machine_type" {
  description = "Machine type for client instances"
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

variable "disk_count" {
  description = "Number of additional data disks"
  type        = number
  default     = 0
}

variable "disk_size" {
  description = "Size of each data disk in GB"
  type        = number
  default     = 100
}

variable "disk_type" {
  description = "Type of data disks"
  type        = string
  default     = "pd-balanced"
}

variable "tier0" {
  description = "Enable local SSDs (Tier 0 storage)"
  type        = bool
  default     = false
}

variable "tier0_type" {
  description = "Interface type for local SSDs (NVME or SCSI)"
  type        = string
  default     = "NVME"
}

variable "target_user" {
  description = "Target user for client operations"
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

variable "enable_nested_virtualization" {
  description = "Enable nested virtualization"
  type        = bool
  default     = false
}

variable "threads_per_core" {
  description = "Number of threads per core"
  type        = number
  default     = 2
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