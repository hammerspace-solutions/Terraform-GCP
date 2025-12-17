# Copyright (c) 2025 Hammerspace, Inc
# -----------------------------------------------------------------------------
# modules/hammerspace/hammerspace_variables.tf
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

variable "assign_public_ip" {
  type    = bool
  default = false
}

variable "public_subnet_name" {
  type    = string
  default = ""
}

variable "image" {
  type = string
}

variable "image_project" {
  type    = string
  default = ""
}

variable "goog_cm_deployment_name" {
  description = "Google deployment name (from guide)"
  type        = string
  default     = ""
}

variable "admin_user_password" {
  description = "Admin user password for Hammerspace"
  type        = string
  default     = ""
  sensitive   = true
}

variable "anvil_firewall_rule_name" {
  type    = string
  default = ""
}

variable "dsx_firewall_rule_name" {
  type    = string
  default = ""
}

variable "anvil_count" {
  type = number
}

variable "sa_anvil_destruction" {
  type    = bool
  default = false
}

variable "anvil_machine_type" {
  type = string
}

variable "anvil_meta_disk_size" {
  type = number
}

variable "anvil_meta_disk_type" {
  type = string
}

variable "anvil_network_tags" {
  type = list(string)
}

variable "dsx_count" {
  type = number
}

variable "dsx_machine_type" {
  type = string
}

variable "dsx_disk_size" {
  type = number
}

variable "dsx_disk_type" {
  type = string
}

variable "dsx_disk_count" {
  type = number
}

variable "dsx_add_vols" {
  type    = list(object({ size = number, type = string }))
  default = []
}

variable "dsx_network_tags" {
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

variable "deletion_protection" {
  type    = bool
  default = false
}

variable "enable_display" {
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

variable "kms_key" {
  description = "KMS key for disk encryption"
  type        = string
  default     = ""
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

variable "add_nodes_to_existing_solution" {
  description = "Whether adding nodes to existing deployment"
  type        = bool
  default     = false
}

variable "internal_ip" {
  description = "Internal IP of existing primary Anvil (for node add)"
  type        = string
  default     = ""
}

variable "enable_https" {
  description = "Enable HTTPS for Hammerspace management"
  type        = bool
  default     = false
}