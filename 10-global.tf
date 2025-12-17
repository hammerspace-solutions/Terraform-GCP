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
# 10-global.tf
#
# This file defines all the global input variables for the root module of the
# Terraform-GCP project.
# -----------------------------------------------------------------------------

# Global variables (NO prefix)

variable "project_id" {
  description = "GCP project ID for all resources"
  type        = string
}

variable "region" {
  description = "GCP region for all resources"
  type        = string
  default     = "us-west2"
}

variable "zone" {
  description = "GCP zone for all resources"
  type        = string
  default     = "us-west2-a"
}

variable "allowed_source_cidr_blocks" {
  description = "A list of additional IPv4 CIDR ranges to allow SSH and all other ingress traffic from (e.g., your corporate VPN range)."
  type        = list(string)
  default     = []
}

variable "network_name" {
  description = "The name of the VPC network to use for instances"
  type        = string
  default     = "default"
}

variable "subnet_name" {
  description = "The name of the subnet to use for instances"
  type        = string
}

variable "public_subnet_name" {
  description = "The name of the public subnet to use for instances requiring a public IP. Optional, but required if assign_public_ip is true."
  type        = string
  default     = ""
}

variable "assign_public_ip" {
  description = "If true, assigns a public IP address to all created compute instances. If false, only a private IP will be assigned."
  type        = bool
  default     = false
}

variable "create_network" {
  description = "Whether to create a new VPC network and subnet (set to true if network doesn't exist)"
  type        = bool
  default     = false
}

variable "subnet_cidr" {
  description = "CIDR range for the subnet if creating a new one"
  type        = string
  default     = "10.0.0.0/24"
}

variable "image_project" {
  description = "The GCP project ID where custom images are stored. If empty, uses the current project."
  type        = string
  default     = ""
}

variable "ubuntu_image_project" {
  description = "The GCP project ID for Ubuntu images (typically ubuntu-os-cloud)"
  type        = string
  default     = "ubuntu-os-cloud"
}

variable "create_firewall_rules" {
  description = "Whether to create firewall rules (set to false if using existing rules)"
  type        = bool
  default     = true
}

variable "ssh_keys" {
  description = "SSH public keys to add to instances. Format: 'username:ssh-rsa AAAAB3N...'"
  type        = list(string)
  default     = []
}

variable "labels" {
  description = "Common labels for all resources"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Network tags for firewall rules"
  type        = list(string)
  default     = []
}

variable "project_name" {
  description = "Project name for resource naming and labels"
  type        = string
  validation {
    condition     = var.project_name != ""
    error_message = "Project must have a name"
  }
}

variable "ssh_keys_dir" {
  description = "Directory containing SSH public keys"
  type        = string
  default     = "./ssh_keys"
}

variable "allow_root" {
  description = "Allow root access via SSH"
  type        = bool
  default     = false
}

variable "deploy_components" {
  description = "Components to deploy. Valid values in the list are: \"all\", \"ansible\", \"clients\", \"storage\", \"hammerspace\", \"ecgroup\"."
  type        = list(string)
  default     = ["all"]
  validation {
    condition = alltrue([
      for c in var.deploy_components : contains(["all", "ansible", "clients", "storage", "hammerspace", "ecgroup"], c)
    ])
    error_message = "Each item in deploy_components must be one of: \"all\", \"ansible\", \"clients\", \"storage\", \"ecgroup\" or \"hammerspace\"."
  }
}

variable "placement_policy_name" {
  description = "Optional: The name of the placement policy to create for instance collocation. If left blank, no placement policy is used."
  type        = string
  default     = ""
}

variable "placement_policy_vm_count" {
  description = "The number of VMs to include in the placement policy"
  type        = number
  default     = 2
}

variable "placement_policy_availability_domain_count" {
  description = "The number of availability domains to spread VMs across"
  type        = number
  default     = 1
}

variable "placement_policy_collocation" {
  description = "The collocation type for the placement policy. Valid values: COLLOCATED"
  type        = string
  default     = "COLLOCATED"
  validation {
    condition     = contains(["COLLOCATED"], var.placement_policy_collocation)
    error_message = "Allowed values for placement_policy_collocation are: COLLOCATED."
  }
}

variable "service_account_email" {
  description = "The email of an existing service account to attach to instances. If left blank, a new one will be created with the necessary roles."
  type        = string
  default     = null
}

variable "iam_admin_group_name" {
  description = "Cloud Identity/Workspace group name for admin access (can be existing group name or blank to create new)"
  type        = string
  default     = null
}

variable "iam_additional_roles" {
  description = "A list of additional IAM roles to grant to the service account"
  type        = list(string)
  default     = []
}

variable "use_startup_script" {
  description = "Use metadata startup scripts for initial configuration"
  type        = bool
  default     = true
}