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
# 20-ansible.tf
#
# This file defines all the input ansible variables for the root module of the
# Terraform-GCP project.
# -----------------------------------------------------------------------------

# Ansible specific variables

variable "use_os_login" {
  description = "Use OS Login for SSH access management"
  type        = bool
  default     = false
}

variable "ansible_ssh_keys" {
  description = "SSH public keys to add to Ansible instances. Format: 'username:ssh-rsa AAAAB3N...'"
  type        = list(string)
  default     = []
}

variable "ansible_instance_count" {
  description = "Number of ansible instances"
  type        = number
  default     = 1
}

variable "ansible_image" {
  description = "Image name for Ansible instances"
  type        = string
  default     = "ubuntu-2204-jammy-v20240126"
}

variable "ansible_machine_type" {
  description = "Machine type for Ansible instances"
  type        = string
  default     = "e2-medium"
}

variable "ansible_boot_disk_size" {
  description = "Boot disk size in GB for Ansible instances"
  type        = number
  default     = 20
}

variable "ansible_boot_disk_type" {
  description = "Boot disk type for Ansible instances (pd-standard, pd-ssd, pd-balanced)"
  type        = string
  default     = "pd-standard"
  validation {
    condition     = contains(["pd-standard", "pd-ssd", "pd-balanced"], var.ansible_boot_disk_type)
    error_message = "Boot disk type must be one of: pd-standard, pd-ssd, pd-balanced."
  }
}

variable "ansible_target_user" {
  description = "Target user for Ansible operations"
  type        = string
  default     = "ansible"
}

variable "ansible_network_tags" {
  description = "Network tags for Ansible instances"
  type        = list(string)
  default     = ["ansible", "ssh-server"]
}

variable "ansible_preemptible" {
  description = "Use preemptible instances for Ansible"
  type        = bool
  default     = false
}

variable "ansible_automatic_restart" {
  description = "Automatically restart Ansible instances if terminated"
  type        = bool
  default     = true
}

variable "ansible_on_host_maintenance" {
  description = "Behavior when a maintenance event occurs (MIGRATE or TERMINATE)"
  type        = string
  default     = "MIGRATE"
  validation {
    condition     = contains(["MIGRATE", "TERMINATE"], var.ansible_on_host_maintenance)
    error_message = "on_host_maintenance must be either MIGRATE or TERMINATE."
  }
}