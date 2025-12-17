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
# 50-ecgroup.tf
#
# This file defines all the input EC Group variables for the root module of the
# Terraform-GCP project.
# -----------------------------------------------------------------------------

# ECGroup specific variables (prefixed with ecgroup_)

variable "ecgroup_node_count" {
  description = "Number of ECGroup nodes to deploy (minimum 4 for redundancy)"
  type        = number
  default     = 4
  validation {
    condition     = var.ecgroup_node_count >= 4
    error_message = "ECGroup requires at least 4 nodes for proper redundancy."
  }
}

variable "ecgroup_image" {
  description = "Image name for ECGroup instances (auto-selected based on region if not specified)"
  type        = string
  default     = ""
}

variable "ecgroup_machine_type" {
  description = "Machine type for ECGroup nodes"
  type        = string
  default     = "n2-standard-8"
}

variable "ecgroup_boot_disk_size" {
  description = "Boot disk size in GB for ECGroup nodes"
  type        = number
  default     = 50
}

variable "ecgroup_boot_disk_type" {
  description = "Boot disk type for ECGroup nodes (pd-standard, pd-ssd, pd-balanced)"
  type        = string
  default     = "pd-balanced"
  validation {
    condition     = contains(["pd-standard", "pd-ssd", "pd-balanced"], var.ecgroup_boot_disk_type)
    error_message = "Boot disk type must be one of: pd-standard, pd-ssd, pd-balanced."
  }
}

variable "ecgroup_metadata_disk_size" {
  description = "Size of metadata disk in GB for ECGroup nodes"
  type        = number
  default     = 100
}

variable "ecgroup_metadata_disk_type" {
  description = "Type of metadata disk (pd-standard, pd-ssd, pd-balanced, pd-extreme)"
  type        = string
  default     = "pd-ssd"
  validation {
    condition     = contains(["pd-standard", "pd-ssd", "pd-balanced", "pd-extreme"], var.ecgroup_metadata_disk_type)
    error_message = "Metadata disk type must be one of: pd-standard, pd-ssd, pd-balanced, pd-extreme."
  }
}

variable "ecgroup_storage_disk_count" {
  description = "Number of storage disks per ECGroup node"
  type        = number
  default     = 4
}

variable "ecgroup_storage_disk_size" {
  description = "Size of each storage disk in GB"
  type        = number
  default     = 500
}

variable "ecgroup_storage_disk_type" {
  description = "Type of storage disks (pd-standard, pd-ssd, pd-balanced)"
  type        = string
  default     = "pd-standard"
  validation {
    condition     = contains(["pd-standard", "pd-ssd", "pd-balanced"], var.ecgroup_storage_disk_type)
    error_message = "Storage disk type must be one of: pd-standard, pd-ssd, pd-balanced."
  }
}

variable "ecgroup_network_tags" {
  description = "Network tags for ECGroup instances"
  type        = list(string)
  default     = ["ecgroup", "storage-node"]
}

variable "ecgroup_preemptible" {
  description = "Use preemptible instances for ECGroup (not recommended for production)"
  type        = bool
  default     = false
}

variable "ecgroup_automatic_restart" {
  description = "Automatically restart ECGroup instances if terminated"
  type        = bool
  default     = true
}

variable "ecgroup_on_host_maintenance" {
  description = "Behavior when a maintenance event occurs (MIGRATE or TERMINATE)"
  type        = string
  default     = "MIGRATE"
  validation {
    condition     = contains(["MIGRATE", "TERMINATE"], var.ecgroup_on_host_maintenance)
    error_message = "on_host_maintenance must be either MIGRATE or TERMINATE."
  }
}

variable "ecgroup_enable_ip_forwarding" {
  description = "Enable IP forwarding for ECGroup nodes"
  type        = bool
  default     = false
}

variable "ecgroup_deletion_protection" {
  description = "Enable deletion protection for ECGroup instances"
  type        = bool
  default     = false
}