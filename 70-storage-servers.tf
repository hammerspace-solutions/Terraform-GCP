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
# 70-storage-servers.tf
#
# This file defines all the input storage server variables for the root module of the
# Terraform-GCP project.
# -----------------------------------------------------------------------------

# Storage Server specific variables (prefixed with storage_)

variable "storage_instance_count" {
  description = "Number of storage server instances"
  type        = number
  default     = 2
}

variable "storage_image" {
  description = "Image name for storage server instances"
  type        = string
  default     = "ubuntu-2204-jammy-v20240126"
}

variable "storage_machine_type" {
  description = "Machine type for storage server instances"
  type        = string
  default     = "n2-standard-8"
}

variable "storage_boot_disk_size" {
  description = "Boot disk size in GB for storage server instances"
  type        = number
  default     = 50
}

variable "storage_boot_disk_type" {
  description = "Boot disk type for storage servers (pd-standard, pd-ssd, pd-balanced)"
  type        = string
  default     = "pd-balanced"
  validation {
    condition     = contains(["pd-standard", "pd-ssd", "pd-balanced"], var.storage_boot_disk_type)
    error_message = "Boot disk type must be one of: pd-standard, pd-ssd, pd-balanced."
  }
}

variable "storage_raid_level" {
  description = "RAID level for storage disks (0, 1, 5, 6, 10)"
  type        = string
  default     = "0"
  validation {
    condition     = contains(["0", "1", "5", "6", "10"], var.storage_raid_level)
    error_message = "RAID level must be one of: 0, 1, 5, 6, 10."
  }
}

variable "storage_disk_count" {
  description = "Number of data disks per storage server instance"
  type        = number
  default     = 4
}

variable "storage_disk_size" {
  description = "Size of each data disk in GB"
  type        = number
  default     = 1000
}

variable "storage_disk_type" {
  description = "Type of data disks (pd-standard, pd-ssd, pd-balanced)"
  type        = string
  default     = "pd-standard"
  validation {
    condition     = contains(["pd-standard", "pd-ssd", "pd-balanced"], var.storage_disk_type)
    error_message = "Disk type must be one of: pd-standard, pd-ssd, pd-balanced."
  }
}

variable "storage_target_user" {
  description = "Target user for storage server operations"
  type        = string
  default     = "ubuntu"
}

variable "storage_network_tags" {
  description = "Network tags for storage server instances"
  type        = list(string)
  default     = ["storage", "nfs-server", "smb-server"]
}

variable "storage_preemptible" {
  description = "Use preemptible instances for storage servers (not recommended for production)"
  type        = bool
  default     = false
}

variable "storage_automatic_restart" {
  description = "Automatically restart storage server instances if terminated"
  type        = bool
  default     = true
}

variable "storage_on_host_maintenance" {
  description = "Behavior when a maintenance event occurs (MIGRATE or TERMINATE)"
  type        = string
  default     = "MIGRATE"
  validation {
    condition     = contains(["MIGRATE", "TERMINATE"], var.storage_on_host_maintenance)
    error_message = "on_host_maintenance must be either MIGRATE or TERMINATE."
  }
}

variable "storage_enable_ip_forwarding" {
  description = "Enable IP forwarding for storage server instances"
  type        = bool
  default     = false
}

variable "storage_deletion_protection" {
  description = "Enable deletion protection for storage server instances"
  type        = bool
  default     = false
}

variable "storage_min_cpu_platform" {
  description = "Minimum CPU platform for storage servers (e.g., 'Intel Cascade Lake')"
  type        = string
  default     = ""
}