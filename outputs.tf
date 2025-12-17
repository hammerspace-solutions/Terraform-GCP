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
# outputs.tf
#
# This file defines all the output values for the root module of the
# Terraform-GCP project.
# -----------------------------------------------------------------------------

# Network Information

output "network_name" {
  description = "The name of the VPC network"
  value       = local.network_name
}

output "subnet_name" {
  description = "The name of the subnet"
  value       = var.subnet_name
}

output "subnet_cidr_range" {
  description = "The IP CIDR range of the subnet"
  value       = local.subnet_cidr_range
}

# Ansible Outputs

output "ansible_instances" {
  description = "Information about Ansible instances"
  value       = local.deploy_ansible ? module.ansible[0].ansible_instances : {}
}

output "ansible_private_ips" {
  description = "Private IP addresses of Ansible instances"
  value       = local.deploy_ansible ? module.ansible[0].ansible_private_ips : []
}

output "ansible_public_ips" {
  description = "Public IP addresses of Ansible instances (if assigned)"
  value       = local.deploy_ansible ? module.ansible[0].ansible_public_ips : []
}

# Client Outputs

output "client_instances" {
  description = "Information about client instances"
  value       = local.deploy_clients ? module.clients[0].client_instances : {}
}

output "client_private_ips" {
  description = "Private IP addresses of client instances"
  value       = local.deploy_clients ? module.clients[0].client_private_ips : []
}

output "client_ansible_info" {
  description = "Ansible inventory information for client instances"
  value       = local.deploy_clients ? module.clients[0].client_ansible_info : []
}

# Storage Server Outputs

output "storage_instances" {
  description = "Information about storage server instances"
  value       = local.deploy_storage ? module.storage_servers[0].storage_instances : {}
}

output "storage_private_ips" {
  description = "Private IP addresses of storage server instances"
  value       = local.deploy_storage ? module.storage_servers[0].storage_private_ips : []
}

output "storage_ansible_info" {
  description = "Ansible inventory information for storage server instances"
  value       = local.deploy_storage ? module.storage_servers[0].storage_ansible_info : []
}

# Hammerspace Outputs

output "anvil_instances" {
  description = "Information about Anvil instances"
  value       = local.deploy_hammerspace ? module.hammerspace[0].anvil_instances : {}
}

output "anvil_private_ips" {
  description = "Private IP addresses of Anvil instances"
  value       = local.deploy_hammerspace ? module.hammerspace[0].anvil_private_ips : []
}

output "anvil_public_ips" {
  description = "Public IP addresses of Anvil instances (if assigned)"
  value       = local.deploy_hammerspace ? module.hammerspace[0].anvil_public_ips : []
}

output "anvil_ansible_info" {
  description = "Ansible inventory information for Anvil instances"
  value       = local.deploy_hammerspace ? module.hammerspace[0].anvil_ansible_info : []
}

output "dsx_instances" {
  description = "Information about DSX instances"
  value       = local.deploy_hammerspace ? module.hammerspace[0].dsx_instances : {}
}

output "dsx_private_ips" {
  description = "Private IP addresses of DSX instances"
  value       = local.deploy_hammerspace ? module.hammerspace[0].dsx_private_ips : []
}

output "dsx_ansible_info" {
  description = "Ansible inventory information for DSX instances"
  value       = local.deploy_hammerspace ? module.hammerspace[0].dsx_ansible_info : []
}

# ECGroup Outputs

output "ecgroup_instances" {
  description = "Information about ECGroup node instances"
  value       = local.deploy_ecgroup ? module.ecgroup[0].ecgroup_instances : {}
}

output "ecgroup_private_ips" {
  description = "Private IP addresses of ECGroup node instances"
  value       = local.deploy_ecgroup ? module.ecgroup[0].ecgroup_private_ips : []
}

output "ecgroup_ansible_info" {
  description = "Ansible inventory information for ECGroup nodes"
  value       = local.deploy_ecgroup ? module.ecgroup[0].ecgroup_ansible_info : []
}

# All SSH Nodes for Ansible

output "all_ssh_nodes" {
  description = "Combined list of all SSH-accessible nodes for Ansible inventory"
  value       = local.all_ssh_nodes
}

# Service Account

output "service_account_email" {
  description = "Email address of the service account used by instances"
  value       = local.service_account_email
}

# Firewall Rules

output "firewall_rules" {
  description = "List of firewall rules created"
  value = var.create_firewall_rules ? [
    google_compute_firewall.ssh[0].name,
    google_compute_firewall.nfs[0].name,
    google_compute_firewall.smb[0].name,
    google_compute_firewall.hammerspace_mgmt[0].name,
    google_compute_firewall.internal[0].name
  ] : []
}

# Placement Policy

output "placement_policy_name" {
  description = "Name of the placement policy (if created)"
  value       = var.placement_policy_name != "" ? one(google_compute_resource_policy.placement_policy[*].name) : ""
}

# Summary

output "deployment_summary" {
  description = "Summary of deployed components"
  value = {
    project_id         = var.project_id
    region             = var.region
    zone               = var.zone
    network            = var.network_name
    subnet             = var.subnet_name
    project_name       = var.project_name
    deployed_components = {
      ansible      = local.deploy_ansible
      clients      = local.deploy_clients
      storage      = local.deploy_storage
      hammerspace  = local.deploy_hammerspace
      ecgroup      = local.deploy_ecgroup
    }
    instance_counts = {
      ansible = local.deploy_ansible ? var.ansible_instance_count : 0
      clients = local.deploy_clients ? var.clients_instance_count : 0
      storage = local.deploy_storage ? var.storage_instance_count : 0
      anvil   = local.deploy_hammerspace ? var.hammerspace_anvil_count : 0
      dsx     = local.deploy_hammerspace ? var.hammerspace_dsx_count : 0
      ecgroup = local.deploy_ecgroup ? var.ecgroup_node_count : 0
    }
  }
}