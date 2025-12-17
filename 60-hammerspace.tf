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
# 60-hammerspace.tf
#
# This file defines all the input Hammerspace variables for the root module of the
# Terraform-GCP project.
# -----------------------------------------------------------------------------

# Hammerspace specific variables (prefixed with hammerspace_)

variable "hammerspace_image" {
  description = "Image name for Hammerspace Anvil and DSX instances"
  type        = string
  default     = "hammerspace-5-1-0"
}

# Deployment naming (from guide)
variable "goog_cm_deployment_name" {
  description = "Google deployment name for Hammerspace instances"
  type        = string
  default     = ""
}

variable "admin_user_password" {
  description = "Admin user password for Hammerspace"
  type        = string
  sensitive   = true
}

variable "hammerspace_anvil_firewall_rule_name" {
  description = "Name of the firewall rule for Anvil instances. If blank, a new rule will be created."
  type        = string
  default     = ""
}

variable "hammerspace_dsx_firewall_rule_name" {
  description = "Name of the firewall rule for DSX instances. If blank, a new rule will be created."
  type        = string
  default     = ""
}

# Anvil Configuration

variable "hammerspace_anvil_count" {
  description = "Number of Anvil instances to deploy"
  type        = number
  default     = 1
}

# Compatibility with guide naming
variable "anvil_instance_count" {
  description = "Number of Anvil instances (alias for guide compatibility)"
  type        = number
  default     = 2
}

variable "hammerspace_sa_anvil_destruction" {
  description = "Allow stand-alone Anvil destruction (for non-production environments)"
  type        = bool
  default     = false
}

variable "hammerspace_anvil_machine_type" {
  description = "Machine type for Anvil instances"
  type        = string
  default     = "n2-highmem-8"
}

variable "hammerspace_anvil_meta_disk_size" {
  description = "Size of metadata disk in GB for Anvil instances"
  type        = number
  default     = 100
}

variable "hammerspace_anvil_meta_disk_type" {
  description = "Type of metadata disk for Anvil (pd-standard, pd-ssd, pd-balanced, pd-extreme)"
  type        = string
  default     = "pd-ssd"
  validation {
    condition     = contains(["pd-standard", "pd-ssd", "pd-balanced", "pd-extreme"], var.hammerspace_anvil_meta_disk_type)
    error_message = "Metadata disk type must be one of: pd-standard, pd-ssd, pd-balanced, pd-extreme."
  }
}

variable "hammerspace_anvil_network_tags" {
  description = "Network tags for Anvil instances"
  type        = list(string)
  default     = ["anvil", "hammerspace", "nfs-server"]
}

# DSX Configuration

variable "hammerspace_dsx_count" {
  description = "Number of DSX instances to deploy"
  type        = number
  default     = 1
}

variable "hammerspace_dsx_machine_type" {
  description = "Machine type for DSX instances"
  type        = string
  default     = "n2-standard-16"
}

variable "hammerspace_dsx_disk_size" {
  description = "Size of each data disk in GB for DSX instances"
  type        = number
  default     = 500
}

variable "hammerspace_dsx_disk_type" {
  description = "Type of data disks for DSX (pd-standard, pd-ssd, pd-balanced)"
  type        = string
  default     = "pd-standard"
  validation {
    condition     = contains(["pd-standard", "pd-ssd", "pd-balanced"], var.hammerspace_dsx_disk_type)
    error_message = "DSX disk type must be one of: pd-standard, pd-ssd, pd-balanced."
  }
}

variable "hammerspace_dsx_disk_count" {
  description = "Number of data disks per DSX instance"
  type        = number
  default     = 4
}

variable "hammerspace_dsx_add_vols" {
  description = "Additional volume configuration for DSX instances"
  type        = list(object({
    size = number
    type = string
  }))
  default = []
}

variable "hammerspace_dsx_network_tags" {
  description = "Network tags for DSX instances"
  type        = list(string)
  default     = ["dsx", "hammerspace", "storage-node"]
}

# Common Hammerspace settings

variable "hammerspace_preemptible" {
  description = "Use preemptible instances for Hammerspace (not recommended for production)"
  type        = bool
  default     = false
}

variable "hammerspace_automatic_restart" {
  description = "Automatically restart Hammerspace instances if terminated"
  type        = bool
  default     = true
}

variable "hammerspace_on_host_maintenance" {
  description = "Behavior when a maintenance event occurs (MIGRATE or TERMINATE)"
  type        = string
  default     = "MIGRATE"
  validation {
    condition     = contains(["MIGRATE", "TERMINATE"], var.hammerspace_on_host_maintenance)
    error_message = "on_host_maintenance must be either MIGRATE or TERMINATE."
  }
}

variable "hammerspace_deletion_protection" {
  description = "Enable deletion protection for Hammerspace instances"
  type        = bool
  default     = false
}

variable "hammerspace_enable_display" {
  description = "Enable virtual display for Hammerspace instances"
  type        = bool
  default     = false
}

# Additional variables from deployment guide
variable "kms_key" {
  description = "KMS key for encryption (e.g., projects/hammerspace-public/locations/global/keyRings/...)"
  type        = string
  default     = ""
}

variable "networks" {
  description = "List of networks for Hammerspace deployment"
  type        = list(string)
  default     = []
}

variable "sub_networks" {
  description = "List of subnetworks for Hammerspace deployment"
  type        = list(string)
  default     = []
}

variable "enable_logging" {
  description = "Enable Cloud Logging"
  type        = bool
  default     = true
}

variable "enable_monitoring" {
  description = "Enable Cloud Monitoring"
  type        = bool
  default     = true
}

variable "enable_https" {
  description = "Enable HTTPS"
  type        = bool
  default     = false
}

variable "add_nodes_to_existing_solution" {
  description = "Whether adding nodes to existing Hammerspace deployment"
  type        = bool
  default     = false
}

variable "internal_ip" {
  description = "Internal IP of existing Hammerspace deployment (for node add)"
  type        = string
  default     = ""
}