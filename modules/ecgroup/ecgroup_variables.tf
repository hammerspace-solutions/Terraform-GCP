# Copyright (c) 2025 Hammerspace, Inc
# -----------------------------------------------------------------------------
# modules/ecgroup/ecgroup_variables.tf
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
  type    = string
  default = ""
}

variable "node_count" {
  type = number
}

variable "image" {
  type = string
}

variable "image_project" {
  type    = string
  default = ""
}

variable "machine_type" {
  type = string
}

variable "boot_disk_size" {
  type = number
}

variable "boot_disk_type" {
  type = string
}

variable "metadata_disk_type" {
  type = string
}

variable "metadata_disk_size" {
  type = number
}

variable "storage_disk_count" {
  type = number
}

variable "storage_disk_type" {
  type = string
}

variable "storage_disk_size" {
  type = number
}

variable "network_tags" {
  type = list(string)
}

variable "preemptible" {
  type    = bool
  default = false
}

variable "automatic_restart" {
  type    = bool
  default = true
}

variable "on_host_maintenance" {
  type    = string
  default = "MIGRATE"
}

variable "enable_ip_forwarding" {
  type    = bool
  default = false
}

variable "deletion_protection" {
  type    = bool
  default = false
}

variable "service_account_email" {
  type = string
}

variable "iam_admin_group_name" {
  type    = string
  default = null
}