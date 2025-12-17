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
# 40-clients.tf
#
# This file defines all the input client variables for the root module of the
# Terraform-GCP project.
# -----------------------------------------------------------------------------

# Client specific variables (prefixed with clients_)

variable "clients_instance_count" {
  description = "Number of client instances"
  type        = number
  default     = 1
}

variable "clients_image" {
  description = "Image name for client instances"
  type        = string
  default     = "ubuntu-2204-jammy-v20240126"
}

variable "clients_machine_type" {
  description = "Machine type for client instances"
  type        = string
  default     = "n2-standard-4"
}

variable "clients_boot_disk_size" {
  description = "Boot disk size in GB for client instances"
  type        = number
  default     = 50
}

variable "clients_boot_disk_type" {
  description = "Boot disk type for client instances (pd-standard, pd-ssd, pd-balanced)"
  type        = string
  default     = "pd-balanced"
  validation {
    condition     = contains(["pd-standard", "pd-ssd", "pd-balanced", "pd-extreme"], var.clients_boot_disk_type)
    error_message = "Boot disk type must be one of: pd-standard, pd-ssd, pd-balanced, pd-extreme."
  }
}

variable "clients_disk_count" {
  description = "Number of additional disks per client instance"
  type        = number
  default     = 0
}

variable "clients_disk_size" {
  description = "Size of additional disks in GB"
  type        = number
  default     = 100
}

variable "clients_disk_type" {
  description = "Type of additional disks (pd-standard, pd-ssd, pd-balanced, pd-extreme)"
  type        = string
  default     = "pd-balanced"
  validation {
    condition     = contains(["pd-standard", "pd-ssd", "pd-balanced", "pd-extreme"], var.clients_disk_type)
    error_message = "Disk type must be one of: pd-standard, pd-ssd, pd-balanced, pd-extreme."
  }
}

variable "clients_tier0" {
  description = "Enable Tier 0 (local SSD) storage for clients"
  type        = bool
  default     = false
}

variable "clients_tier0_type" {
  description = "Interface type for local SSDs (SCSI or NVME)"
  type        = string
  default     = "NVME"
  validation {
    condition     = contains(["SCSI", "NVME"], var.clients_tier0_type)
    error_message = "Tier 0 type must be either SCSI or NVME."
  }
}

variable "clients_target_user" {
  description = "Target user for client operations"
  type        = string
  default     = "ubuntu"
}

variable "clients_network_tags" {
  description = "Network tags for client instances"
  type        = list(string)
  default     = ["client", "nfs-client"]
}

variable "clients_preemptible" {
  description = "Use preemptible instances for clients"
  type        = bool
  default     = false
}

variable "clients_automatic_restart" {
  description = "Automatically restart client instances if terminated"
  type        = bool
  default     = true
}

variable "clients_on_host_maintenance" {
  description = "Behavior when a maintenance event occurs (MIGRATE or TERMINATE)"
  type        = string
  default     = "MIGRATE"
  validation {
    condition     = contains(["MIGRATE", "TERMINATE"], var.clients_on_host_maintenance)
    error_message = "on_host_maintenance must be either MIGRATE or TERMINATE."
  }
}

variable "clients_enable_nested_virtualization" {
  description = "Enable nested virtualization on client instances"
  type        = bool
  default     = false
}

variable "clients_threads_per_core" {
  description = "Number of threads per core (1 to disable SMT, 2 to enable)"
  type        = number
  default     = 2
  validation {
    condition     = contains([1, 2], var.clients_threads_per_core)
    error_message = "threads_per_core must be either 1 or 2."
  }
}