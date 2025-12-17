# Copyright (c) 2025 Hammerspace, Inc
# -----------------------------------------------------------------------------
# example_terraform.tfvars.rename
#
# Example variables file for the Terraform-GCP project.
# Rename this file to terraform.tfvars and customize the values for your deployment.
# -----------------------------------------------------------------------------

# Required Variables - You MUST set these

project_id   = "hs-mktg-general"
project_name = "hs-product-general"
subnet_name  = "bu-test-01-sb"

# Optional Variables - Customize as needed

# Region and Zone
region = "us-west1"
zone   = "us-west1-a"

# Network Configuration
network_name               = "bu-test-01-nt"
create_network             = true  # Set to true to create the VPC network
create_firewall_rules      = true  # Set to false to skip firewall rule creation
subnet_cidr                = "10.0.0.0/24"  # CIDR for the new subnet
allowed_source_cidr_blocks = ["10.0.0.0/8", "192.168.0.0/16", "0.0.0.0/0"]
assign_public_ip           = false
public_subnet_name         = ""  # Leave empty when using the same subnet for public IPs

# SSH Configuration
ssh_keys = [
  "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC07v6lqSClHrUmP10bVCrTpEg3NUjjm5TEuievmpVaLKNjDKST0juDU0TaSrhLAf/5RTFvCYeL8dWxn6w4CcFBMzblHJ3EFR13+M+0dLeZWv+RV/1Ag/X/jNIJLQ9ozQYQyTqKJaVQJimV/BKuGRmsjYljUrTqIqFAFEy1CzeT6Of0Cb5YnK5BM9i00MbK6FNb+QMl0r+62uI/cJj5jQSnpvKCJtlix1yIH2itzf3KcuDazDe5XHsu4i78zNjhs6U8qb4b84uMF0wzJ/iPsBbyiSBQoJBVQf4PDqDU15UPxjZ/lipblq0igXoLYFv/XaqeQxfbafHGS6UCLMFqETZ4HBuCeYIx8MG5KDtQCEyK9kMSyG65VK8Fj7eWUWAISHP4bA0nRIez+40wIfoiTv4yoTRt49zRuQgIZ3CPnnl2NzuvMTo6pnp8spR+mLNfrp5sB46gE58AmsihXt6hrR/Al9ooK3xbsO0UAW5kYLQhURUH8XJCrBmB3ep7/NpYmEHvydFIzKBDQjvOG4PZKJtNkgYjO0Uw3R/M2SeNhkL+3l8iOZU1HqRfxmR8YT7XbiV6v1j+OVS9OnO8ABtq3/VLY4/uIJKQF0tJDKiei0+z7dL3hX/lJmKtMHuxAWzLR36HDII0i58jIDAazJ029i2WoQPEDjgmnFzKH4gfleT9iQ== "
]

# Admin user password (from Hammerspace engineering team config)
admin_user_password = "Hammer.123!!"

# Component Deployment
deploy_components = ["hammerspace"]  # Options: "all", "clients", "storage", "hammerspace", "ecgroup"

# Labels for all resources
labels = {
  environment = "dev"
  team        = "infrastructure"
  project     = "hammerspace-demo"
}

# Network tags for firewall rules
# These tags should match the target tags in your existing firewall rules
tags = ["hammerspace", "demo"]

# Service Account (leave null to create new)
service_account_email = null
iam_admin_group_name  = null
iam_additional_roles  = []

# Placement Policy (for instance collocation)
placement_policy_name                      = ""  # Set to enable placement policy
placement_policy_vm_count                  = 2
placement_policy_availability_domain_count = 1
placement_policy_collocation               = "COLLOCATED"

# Image Configuration
image_project = "hammerspace-dev"  # Leave empty for Hammerspace images, will be set per-image type

# -----------------------------------------------------------------------------
# Ansible Configuration
# -----------------------------------------------------------------------------

ansible_instance_count      = 1
ansible_image               = "ubuntu-2204-jammy-v20250924"
ansible_machine_type        = "e2-medium"
ansible_boot_disk_size      = 20
ansible_boot_disk_type      = "pd-standard"
ansible_target_user         = "ansible"
ansible_preemptible         = false
ansible_automatic_restart   = true
ansible_on_host_maintenance = "MIGRATE"

# -----------------------------------------------------------------------------
# Client Configuration
# -----------------------------------------------------------------------------

clients_instance_count              = 2
clients_image                       = "ubuntu-2204-jammy-v20250924"
clients_machine_type                = "n2-standard-4"
clients_boot_disk_size              = 50
clients_boot_disk_type              = "pd-balanced"
clients_disk_count                  = 0
clients_disk_size                   = 100
clients_disk_type                   = "pd-balanced"
clients_tier0                       = false
clients_tier0_type                  = "NVME"
clients_target_user                 = "ubuntu"
clients_preemptible                 = false
clients_automatic_restart           = true
clients_on_host_maintenance         = "MIGRATE"
clients_enable_nested_virtualization = false
clients_threads_per_core             = 2

# -----------------------------------------------------------------------------
# Storage Server Configuration
# -----------------------------------------------------------------------------

storage_instance_count      = 2
storage_image               = "ubuntu-2204-jammy-v20250924"
storage_machine_type        = "n2-standard-8"
storage_boot_disk_size      = 50
storage_boot_disk_type      = "pd-balanced"
storage_raid_level          = "0"
storage_disk_count          = 4
storage_disk_size           = 1000
storage_disk_type           = "pd-standard"
storage_target_user         = "ubuntu"
storage_preemptible         = false
storage_automatic_restart   = true
storage_on_host_maintenance = "MIGRATE"
storage_enable_ip_forwarding = false
storage_deletion_protection  = false
storage_min_cpu_platform     = ""

# -----------------------------------------------------------------------------
# Hammerspace Configuration
# -----------------------------------------------------------------------------

hammerspace_image = "hammerspace-5-1-41-452" # "hammerspace-5-3-0-86324"  # Update with your Hammerspace image

# Anvil Configuration
hammerspace_anvil_count         = 2
hammerspace_sa_anvil_destruction = false
hammerspace_anvil_machine_type  = "n2-standard-16"
hammerspace_anvil_meta_disk_size = 500
hammerspace_anvil_meta_disk_type = "pd-extreme"

# DSX Configuration
hammerspace_dsx_count      = 2
hammerspace_dsx_machine_type = "n2-standard-8"
hammerspace_dsx_disk_size   = 500
hammerspace_dsx_disk_type   = "pd-ssd"
hammerspace_dsx_disk_count  = 1
hammerspace_dsx_add_vols    = []

# Common Hammerspace Settings
hammerspace_preemptible         = false
hammerspace_automatic_restart   = true
hammerspace_on_host_maintenance = "MIGRATE"
hammerspace_deletion_protection = false
hammerspace_enable_display      = false

# Hammerspace Security and Configuration Settings
enable_logging                  = true
enable_monitoring               = true
enable_https                    = false
add_nodes_to_existing_solution  = false
internal_ip                     = ""

# -----------------------------------------------------------------------------
# ECGroup Configuration
# -----------------------------------------------------------------------------

ecgroup_node_count         = 4
ecgroup_image              = "ubuntu-2204-jammy-v20250924"  # Ubuntu image for ECGroup
ecgroup_machine_type       = "n2-standard-8"
ecgroup_boot_disk_size     = 50
ecgroup_boot_disk_type     = "pd-balanced"
ecgroup_metadata_disk_size = 100
ecgroup_metadata_disk_type = "pd-ssd"
ecgroup_storage_disk_count = 4
ecgroup_storage_disk_size  = 500
ecgroup_storage_disk_type  = "pd-standard"
ecgroup_preemptible         = false
ecgroup_automatic_restart   = true
ecgroup_on_host_maintenance = "MIGRATE"
ecgroup_enable_ip_forwarding = false
ecgroup_deletion_protection  = false