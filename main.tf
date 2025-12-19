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
# main.tf
#
# This is the root module for the Terraform-GCP project. It defines the
# providers, pre-flight validations, and calls the component modules.
# -----------------------------------------------------------------------------

# Setup the provider

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# -----------------------------------------------------------------------------
# Pre-flight Validation for Networking
# -----------------------------------------------------------------------------

data "google_compute_network" "validation" {
  count   = var.create_network ? 0 : 1
  name    = var.network_name
  project = var.project_id
}

data "google_compute_subnetwork" "private_subnet" {
  count   = var.create_network ? 0 : 1
  name    = var.subnet_name
  project = var.project_id
  region  = var.region
}

# Use either created or existing network/subnet
locals {
  network_self_link = var.create_network ? google_compute_network.vpc_network[0].self_link : data.google_compute_network.validation[0].self_link
  network_name      = var.create_network ? google_compute_network.vpc_network[0].name : data.google_compute_network.validation[0].name
  subnet_self_link  = var.create_network ? google_compute_subnetwork.private_subnet[0].self_link : data.google_compute_subnetwork.private_subnet[0].self_link
  subnet_cidr_range = var.create_network ? google_compute_subnetwork.private_subnet[0].ip_cidr_range : data.google_compute_subnetwork.private_subnet[0].ip_cidr_range
}

# Define the public subnet data source. It will only be instantiated (count = 1)
# if var.public_subnet_name is not null. Otherwise, it will be an empty list (count = 0).

data "google_compute_subnetwork" "public_subnet_data" {
  count   = var.public_subnet_name != "" ? 1 : 0
  name    = var.public_subnet_name
  project = var.project_id
  region  = var.region
}

# These group of checks make sure that the images exist in the project
# where you are trying to start them up. This only gets the data,
# it does not trigger the check and error message. That comes later.

# Ansible Image Exists?

data "google_compute_image" "ansible_image_check" {
  count = local.deploy_ansible ? 1 : 0

  project = var.ubuntu_image_project
  name    = var.ansible_image
}

# Client Image Exists?

data "google_compute_image" "client_image_check" {
  count = local.deploy_clients ? 1 : 0

  project = var.ubuntu_image_project
  name    = var.clients_image
}

# ECGroup Image Exists?

data "google_compute_image" "ecgroup_node_image_check" {
  count = local.deploy_ecgroup ? 1 : 0

  project = var.ubuntu_image_project
  name    = local.select_ecgroup_image_for_region
}

# Hammerspace Anvil and DSX share an image

data "google_compute_image" "hammerspace_image_check" {
  count = local.deploy_hammerspace ? 1 : 0

  project = var.image_project != "" ? var.image_project : var.project_id
  name    = var.hammerspace_image
}

# Storage Server Image Exists?

data "google_compute_image" "storage_image_check" {
  count = local.deploy_storage ? 1 : 0

  project = var.ubuntu_image_project
  name    = var.storage_image
}

# -----------------------------------------------------------------------------
# Pre-flight check that the subnet is in the network
# -----------------------------------------------------------------------------

check "network_and_subnet_validation" {
  assert {
    condition     = !var.create_network ? data.google_compute_subnetwork.private_subnet[0].network == data.google_compute_network.validation[0].self_link : true
    error_message = "Validation Error: The provided subnet (Name: ${var.subnet_name}) does not belong to the provided network (Name: ${var.network_name})."
  }
}

check "public_subnet_validation" {
  assert {
    condition = var.public_subnet_name == "" || (
      length(data.google_compute_subnetwork.public_subnet_data) > 0 &&
      data.google_compute_subnetwork.public_subnet_data[0].network == local.network_self_link
    )
    error_message = "Validation Error: The provided public_subnet_name (Name: ${var.public_subnet_name}) does not belong to the provided network (Name: ${var.network_name})."
  }
}

# -----------------------------------------------------------------------------
# Pre-flight checks for machine type availability.
# -----------------------------------------------------------------------------

check "anvil_machine_type_is_available" {
  data "google_compute_machine_types" "anvil_check" {
    filter = "name = \"${var.hammerspace_anvil_machine_type}\""
    zone   = var.zone
  }
  assert {
    condition     = length(data.google_compute_machine_types.anvil_check.machine_types) > 0
    error_message = "The specified Anvil machine type (${var.hammerspace_anvil_machine_type}) is not available in the selected zone (${var.zone})."
  }
}

check "dsx_machine_type_is_available" {
  data "google_compute_machine_types" "dsx_check" {
    filter = "name = \"${var.hammerspace_dsx_machine_type}\""
    zone   = var.zone
  }
  assert {
    condition     = length(data.google_compute_machine_types.dsx_check.machine_types) > 0
    error_message = "The specified DSX machine type (${var.hammerspace_dsx_machine_type}) is not available in the selected zone (${var.zone})."
  }
}

check "client_machine_type_is_available" {
  data "google_compute_machine_types" "client_check" {
    filter = "name = \"${var.clients_machine_type}\""
    zone   = var.zone
  }
  assert {
    condition     = length(data.google_compute_machine_types.client_check.machine_types) > 0
    error_message = "The specified Client machine type (${var.clients_machine_type}) is not available in the selected zone (${var.zone})."
  }
}

check "storage_server_machine_type_is_available" {
  data "google_compute_machine_types" "storage_check" {
    filter = "name = \"${var.storage_machine_type}\""
    zone   = var.zone
  }
  assert {
    condition     = length(data.google_compute_machine_types.storage_check.machine_types) > 0
    error_message = "The specified Storage Server machine type (${var.storage_machine_type}) is not available in the selected zone (${var.zone})."
  }
}

# ECGroup

check "ecgroup_node_machine_type_is_available" {
  data "google_compute_machine_types" "ecgroup_node_check" {
    filter = "name = \"${var.ecgroup_machine_type}\""
    zone   = var.zone
  }

  assert {
    condition     = length(data.google_compute_machine_types.ecgroup_node_check.machine_types) > 0
    error_message = "The specified ECGroup Node machine type (${var.ecgroup_machine_type}) is not available in the selected zone (${var.zone})."
  }
}

# -----------------------------------------------------------------------------
# Pre-flight checks for image existence.
# -----------------------------------------------------------------------------

check "ansible_image_exists" {
  assert {
    condition = !local.deploy_ansible || (
      length(data.google_compute_image.ansible_image_check) > 0 &&
      data.google_compute_image.ansible_image_check[0].id != ""
    )
    error_message = "Validation Error: The specified ansible_image (Name: ${var.ansible_image}) was not found in the project ${var.ubuntu_image_project}."
  }
}

check "client_image_exists" {
  assert {
    condition = !local.deploy_clients || (
      length(data.google_compute_image.client_image_check) > 0 &&
      data.google_compute_image.client_image_check[0].id != ""
    )
    error_message = "Validation Error: The specified clients_image (Name: ${var.clients_image}) was not found in the project ${var.ubuntu_image_project}."
  }
}

check "ecgroup_node_image_exists" {
  assert {
    condition = !local.deploy_ecgroup || (
      local.select_ecgroup_image_for_region != null &&
      length(data.google_compute_image.ecgroup_node_image_check) > 0 &&
      data.google_compute_image.ecgroup_node_image_check[0].id != ""
    )
    error_message = "EC-Group not available for the specified region (${var.region})."
  }
}

check "hammerspace_image_exists" {
  assert {
    condition = !local.deploy_hammerspace || (
      length(data.google_compute_image.hammerspace_image_check) > 0 &&
      data.google_compute_image.hammerspace_image_check[0].id != ""
    )
    error_message = "Validation Error: The specified hammerspace_image (Name: ${var.hammerspace_image}) was not found in the project ${var.image_project != "" ? var.image_project : var.project_id}."
  }
}

check "storage_image_exists" {
  assert {
    condition = !local.deploy_storage || (
      length(data.google_compute_image.storage_image_check) > 0 &&
      data.google_compute_image.storage_image_check[0].id != ""
    )
    error_message = "Validation Error: The specified storage_image (Name: ${var.storage_image}) was not found in the project ${var.ubuntu_image_project}."
  }
}

# Determine which components to deploy and create a common configuration object

locals {

  all_allowed_cidr_blocks = distinct(concat([local.subnet_cidr_range], var.allowed_source_cidr_blocks))

  common_config = {
    project_id        = var.project_id
    region            = var.region
    zone              = var.zone
    network_name      = var.network_name
    subnet_name       = var.subnet_name
    subnet_self_link  = local.subnet_self_link
    tags              = var.tags
    labels            = var.labels
    project_name      = var.project_name
    ssh_keys_dir      = var.ssh_keys_dir
    allow_root        = var.allow_root
    placement_policy_name = var.placement_policy_name != "" ? one(google_compute_resource_policy.placement_policy[*].name) : ""
    allowed_source_cidr_blocks = local.all_allowed_cidr_blocks
  }

  deploy_clients     = contains(var.deploy_components, "all") || contains(var.deploy_components, "clients")
  deploy_storage     = contains(var.deploy_components, "all") || contains(var.deploy_components, "storage")
  deploy_hammerspace = contains(var.deploy_components, "all") || contains(var.deploy_components, "hammerspace")
  deploy_ecgroup     = contains(var.deploy_components, "all") || contains(var.deploy_components, "ecgroup")
  deploy_ansible     = (contains(var.deploy_components, "all") || contains(var.deploy_components, "ansible")) && var.ansible_instance_count > 0

  all_ssh_nodes = concat(
    local.deploy_clients ? module.clients[0].client_ansible_info : [],
    local.deploy_storage ? module.storage_servers[0].storage_ansible_info : [],
    local.deploy_hammerspace ? module.hammerspace[0].anvil_ansible_info : [],
    local.deploy_hammerspace ? module.hammerspace[0].dsx_ansible_info : []
  )

  ecgroup_image_mapping = {
    "europe-west3"           = "ecgroup-europe-west3-image"
    "us-west2"               = "ecgroup-us-west2-image"
    "us-east1"               = "ecgroup-us-east1-image"
    "us-central1"            = "ecgroup-us-central1-image"
    "northamerica-northeast1" = "ecgroup-canada-image"
  }

  # Use var.ecgroup_image directly since region-specific images don't exist
  select_ecgroup_image_for_region = var.ecgroup_image

  # Service account... Should we create one or use an existing one?

  service_account_email = var.service_account_email != null ? var.service_account_email : module.iam_core.service_account_email
}

# -----------------------------------------------------------------------------
# Placement Policy (GCP equivalent of AWS placement groups)
# -----------------------------------------------------------------------------

resource "google_compute_resource_policy" "placement_policy" {
  count = var.placement_policy_name != "" ? 1 : 0

  name        = var.placement_policy_name
  region      = var.region
  description = "Placement policy for ${var.project_name} instances"

  group_placement_policy {
    vm_count                  = var.placement_policy_vm_count
    availability_domain_count = var.placement_policy_availability_domain_count
    collocation               = var.placement_policy_collocation
  }
}

# -----------------------------------------------------------------------------
# Firewall Rules
# -----------------------------------------------------------------------------

# SSH access rule
resource "google_compute_firewall" "ssh" {
  count   = var.create_firewall_rules ? 1 : 0
  name    = "${var.project_name}-allow-ssh"
  network = local.network_name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = local.all_allowed_cidr_blocks
  target_tags   = ["ssh-server"]
}

# NFS access rule
resource "google_compute_firewall" "nfs" {
  count   = var.create_firewall_rules ? 1 : 0
  name    = "${var.project_name}-allow-nfs"
  network = local.network_name

  allow {
    protocol = "tcp"
    ports    = ["111", "2049", "20048"]
  }

  allow {
    protocol = "udp"
    ports    = ["111", "2049", "20048"]
  }

  source_ranges = local.all_allowed_cidr_blocks
  target_tags   = ["nfs-server"]
}

# SMB access rule
resource "google_compute_firewall" "smb" {
  count   = var.create_firewall_rules ? 1 : 0
  name    = "${var.project_name}-allow-smb"
  network = local.network_name

  allow {
    protocol = "tcp"
    ports    = ["139", "445"]
  }

  source_ranges = local.all_allowed_cidr_blocks
  target_tags   = ["smb-server"]
}

# Hammerspace management access
resource "google_compute_firewall" "hammerspace_mgmt" {
  count   = var.create_firewall_rules ? 1 : 0
  name    = "${var.project_name}-allow-hammerspace-mgmt"
  network = local.network_name

  allow {
    protocol = "tcp"
    ports    = ["443", "8443", "4501", "4502", "4503", "4504", "4505", "4506"]
  }

  source_ranges = local.all_allowed_cidr_blocks
  target_tags   = ["hammerspace"]
}

# Internal communication between instances
resource "google_compute_firewall" "internal" {
  count   = var.create_firewall_rules ? 1 : 0
  name    = "${var.project_name}-allow-internal"
  network = local.network_name

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "icmp"
  }

  source_tags = ["hammerspace", "anvil", "dsx", "client", "storage", "ecgroup", "ansible"]
  target_tags = ["hammerspace", "anvil", "dsx", "client", "storage", "ecgroup", "ansible"]
}

# -----------------------------------------------------------------------------
# Resource and Module Definitions
# -----------------------------------------------------------------------------

# Build the IAM roles and permissions...
# I put all of the logic into one module that can be referenced
# by all the others. This makes auditing much simpler...

module "iam_core" {
  source = "./modules/iam-core"

  service_account_email = var.service_account_email
  common_config         = local.common_config
  extra_roles           = var.iam_additional_roles
}

# Deploy the Ansible module if requested

module "ansible" {
  count  = local.deploy_ansible ? 1 : 0
  source = "./modules/ansible"

  common_config      = local.common_config
  assign_public_ip   = var.assign_public_ip
  public_subnet_name = var.public_subnet_name

  # Pass the path to the key, not the content of the key.

  admin_private_key_path = fileexists("./modules/ansible/id_rsa") ? "./modules/ansible/id_rsa" : ""
  admin_public_key_path  = fileexists("./modules/ansible/id_rsa.pub") ? "./modules/ansible/id_rsa.pub" : ""

  instance_count      = var.ansible_instance_count
  image               = var.ansible_image
  image_project       = var.ubuntu_image_project
  machine_type        = var.ansible_machine_type
  boot_disk_size      = var.ansible_boot_disk_size
  boot_disk_type      = var.ansible_boot_disk_type
  target_user         = var.ansible_target_user
  network_tags        = var.ansible_network_tags
  preemptible         = var.ansible_preemptible
  automatic_restart   = var.ansible_automatic_restart
  on_host_maintenance = var.ansible_on_host_maintenance

  # Service Account

  service_account_email = local.service_account_email
  iam_admin_group_name  = var.iam_admin_group_name

  # Pass in whether to use metadata startup scripts and ssh keys

  use_startup_script = var.use_startup_script
  ssh_keys           = var.ansible_ssh_keys

  # Ansible Controller Daemon Configuration
  # Note: anvil_cluster_ip and storages are configured via terraform.tfvars
  # after initial deployment when the Anvil cluster IP and ECGroup node IPs are known.

  enable_daemon     = var.ansible_enable_daemon
  anvil_cluster_ip  = var.ansible_anvil_cluster_ip
  hs_username       = "admin"
  hs_password       = var.admin_user_password
  volume_group_name = var.ansible_volume_group_name
  share_name        = var.ansible_share_name
  storages          = var.ansible_storages

  # Share configuration
  share_config = {
    name        = var.ansible_share_name
    path        = var.ansible_share_path
    exportPath  = var.ansible_share_export_path
    description = var.ansible_share_description
  }

  depends_on = [
    module.iam_core
  ]
}

# Deploy the clients module if requested

module "clients" {
  count  = local.deploy_clients ? 1 : 0
  source = "./modules/clients"

  common_config                   = local.common_config
  placement_policy_name           = var.placement_policy_name != "" ? one(google_compute_resource_policy.placement_policy[*].name) : ""

  instance_count                  = var.clients_instance_count
  image                           = var.clients_image
  image_project                   = var.ubuntu_image_project
  machine_type                    = var.clients_machine_type
  boot_disk_size                  = var.clients_boot_disk_size
  boot_disk_type                  = var.clients_boot_disk_type
  disk_count                      = var.clients_disk_count
  disk_size                       = var.clients_disk_size
  disk_type                       = var.clients_disk_type
  tier0                           = var.clients_tier0
  tier0_type                      = var.clients_tier0_type
  target_user                     = var.clients_target_user
  network_tags                    = var.clients_network_tags
  preemptible                     = var.clients_preemptible
  automatic_restart               = var.clients_automatic_restart
  on_host_maintenance             = var.clients_on_host_maintenance
  enable_nested_virtualization    = var.clients_enable_nested_virtualization
  threads_per_core                = var.clients_threads_per_core

  # Service Account

  service_account_email = local.service_account_email
  iam_admin_group_name  = var.iam_admin_group_name

  depends_on = [
    module.ansible,
    module.hammerspace
  ]
}

module "storage_servers" {
  count  = local.deploy_storage ? 1 : 0
  source = "./modules/storage_servers"

  common_config         = local.common_config
  placement_policy_name = var.placement_policy_name != "" ? one(google_compute_resource_policy.placement_policy[*].name) : ""

  instance_count        = var.storage_instance_count
  image                 = var.storage_image
  image_project         = var.ubuntu_image_project
  machine_type          = var.storage_machine_type
  boot_disk_size        = var.storage_boot_disk_size
  boot_disk_type        = var.storage_boot_disk_type
  raid_level            = var.storage_raid_level
  disk_count            = var.storage_disk_count
  disk_size             = var.storage_disk_size
  disk_type             = var.storage_disk_type
  target_user           = var.storage_target_user
  network_tags          = var.storage_network_tags
  preemptible           = var.storage_preemptible
  automatic_restart     = var.storage_automatic_restart
  on_host_maintenance   = var.storage_on_host_maintenance
  enable_ip_forwarding  = var.storage_enable_ip_forwarding
  deletion_protection   = var.storage_deletion_protection
  min_cpu_platform      = var.storage_min_cpu_platform

  # Service Account

  service_account_email = local.service_account_email
  iam_admin_group_name  = var.iam_admin_group_name

  depends_on = [
    module.ansible,
    module.hammerspace
  ]
}

module "hammerspace" {
  count  = local.deploy_hammerspace ? 1 : 0
  source = "./modules/hammerspace"

  common_config      = local.common_config
  assign_public_ip   = var.assign_public_ip
  public_subnet_name = var.public_subnet_name

  image                       = var.hammerspace_image
  image_project               = var.image_project
  goog_cm_deployment_name     = var.goog_cm_deployment_name
  admin_user_password         = var.admin_user_password
  anvil_firewall_rule_name    = var.hammerspace_anvil_firewall_rule_name
  dsx_firewall_rule_name      = var.hammerspace_dsx_firewall_rule_name
  anvil_count                 = var.hammerspace_anvil_count
  sa_anvil_destruction        = var.hammerspace_sa_anvil_destruction
  anvil_machine_type          = var.hammerspace_anvil_machine_type
  anvil_meta_disk_size        = var.hammerspace_anvil_meta_disk_size
  anvil_meta_disk_type        = var.hammerspace_anvil_meta_disk_type
  anvil_network_tags          = var.hammerspace_anvil_network_tags
  dsx_count                   = var.hammerspace_dsx_count
  dsx_machine_type            = var.hammerspace_dsx_machine_type
  dsx_disk_size               = var.hammerspace_dsx_disk_size
  dsx_disk_type               = var.hammerspace_dsx_disk_type
  dsx_disk_count              = var.hammerspace_dsx_disk_count
  dsx_add_vols                = var.hammerspace_dsx_add_vols
  dsx_network_tags            = var.hammerspace_dsx_network_tags
  preemptible                 = var.hammerspace_preemptible
  automatic_restart           = var.hammerspace_automatic_restart
  on_host_maintenance         = var.hammerspace_on_host_maintenance
  deletion_protection         = var.hammerspace_deletion_protection
  enable_display              = var.hammerspace_enable_display

  # Additional configurations from guide
  kms_key                         = var.kms_key
  enable_logging                  = var.enable_logging
  enable_monitoring               = var.enable_monitoring
  enable_https                    = var.enable_https
  add_nodes_to_existing_solution  = var.add_nodes_to_existing_solution
  internal_ip                     = var.internal_ip

  # Service Account

  service_account_email = local.service_account_email
  iam_admin_group_name  = var.iam_admin_group_name

  depends_on = [
    module.ansible
  ]
}

# Deploy the ECGroup module if requested

module "ecgroup" {
  count  = local.deploy_ecgroup ? 1 : 0
  source = "./modules/ecgroup"

  common_config         = local.common_config
  placement_policy_name = var.placement_policy_name != "" ? one(google_compute_resource_policy.placement_policy[*].name) : ""

  node_count            = var.ecgroup_node_count
  image                 = local.select_ecgroup_image_for_region
  image_project         = var.ubuntu_image_project
  machine_type          = var.ecgroup_machine_type
  boot_disk_size        = var.ecgroup_boot_disk_size
  boot_disk_type        = var.ecgroup_boot_disk_type
  metadata_disk_type    = var.ecgroup_metadata_disk_type
  metadata_disk_size    = var.ecgroup_metadata_disk_size
  storage_disk_count    = var.ecgroup_storage_disk_count
  storage_disk_type     = var.ecgroup_storage_disk_type
  storage_disk_size     = var.ecgroup_storage_disk_size
  network_tags          = var.ecgroup_network_tags
  preemptible           = var.ecgroup_preemptible
  automatic_restart     = var.ecgroup_automatic_restart
  on_host_maintenance   = var.ecgroup_on_host_maintenance
  enable_ip_forwarding  = var.ecgroup_enable_ip_forwarding
  deletion_protection   = var.ecgroup_deletion_protection

  # Service Account

  service_account_email = local.service_account_email
  iam_admin_group_name  = var.iam_admin_group_name

  depends_on = [
    module.ansible,
    module.hammerspace
  ]
}