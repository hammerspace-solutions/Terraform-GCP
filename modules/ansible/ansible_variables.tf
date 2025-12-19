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
# modules/ansible/ansible_variables.tf
#
# Input variables for the Ansible module
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

variable "instance_count" {
  description = "Number of Ansible controller instances"
  type        = number
  default     = 1
}

variable "image" {
  description = "Image name for Ansible instances"
  type        = string
}

variable "image_project" {
  description = "Project ID where the image is stored"
  type        = string
  default     = ""
}

variable "machine_type" {
  description = "Machine type for Ansible instances"
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

variable "target_user" {
  description = "Target user for Ansible operations"
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

variable "service_account_email" {
  description = "Service account email"
  type        = string
}

variable "iam_admin_group_name" {
  description = "Admin group name"
  type        = string
  default     = null
}

variable "assign_public_ip" {
  description = "Assign public IP addresses"
  type        = bool
  default     = false
}

variable "public_subnet_name" {
  description = "Public subnet name for instances with public IPs"
  type        = string
  default     = ""
}

variable "use_startup_script" {
  description = "Use startup script for configuration"
  type        = bool
  default     = true
}

variable "ssh_keys" {
  description = "SSH public keys"
  type        = list(string)
  default     = []
}

variable "admin_private_key_path" {
  description = "Path to admin private key"
  type        = string
  default     = ""
}

variable "admin_public_key_path" {
  description = "Path to admin public key"
  type        = string
  default     = ""
}

# -----------------------------------------------------------------------------
# Ansible Controller Daemon Variables
# -----------------------------------------------------------------------------

variable "enable_daemon" {
  description = "Enable the Ansible controller daemon for automated playbook execution"
  type        = bool
  default     = false
}

variable "anvil_cluster_ip" {
  description = "Hammerspace Anvil cluster IP address for API access"
  type        = string
  default     = ""
}

variable "hs_username" {
  description = "Hammerspace admin username"
  type        = string
  default     = "admin"
}

variable "hs_password" {
  description = "Hammerspace admin password"
  type        = string
  default     = ""
  sensitive   = true
}

variable "volume_group_name" {
  description = "Name for the Hammerspace volume group"
  type        = string
  default     = "ecgroup-volumes"
}

variable "share_name" {
  description = "Name for the Hammerspace share"
  type        = string
  default     = "ecgroup-share"
}

variable "storages" {
  description = "List of storage nodes to add to Hammerspace cluster"
  type = list(object({
    name       = string
    nodeType   = string
    ipAddress  = string
  }))
  default = []
}

variable "share_config" {
  description = "Share configuration for Hammerspace"
  type = object({
    name        = string
    path        = string
    exportPath  = string
    description = string
  })
  default = {
    name        = "default-share"
    path        = "/default"
    exportPath  = "/default"
    description = "Default Hammerspace share"
  }
}