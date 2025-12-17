# Copyright (c) 2025 Hammerspace, Inc
# -----------------------------------------------------------------------------
# modules/hammerspace/hammerspace_outputs.tf
# -----------------------------------------------------------------------------

locals {
  # Combine anvil1 and anvil2 into a single list for outputs
  all_anvil_instances = concat(
    google_compute_instance.anvil1,
    google_compute_instance.anvil2
  )
}

output "anvil_instances" {
  value = {
    for inst in local.all_anvil_instances : inst.name => {
      id         = inst.id
      name       = inst.name
      private_ip = inst.network_interface[0].network_ip
      public_ip  = var.assign_public_ip ? inst.network_interface[0].access_config[0].nat_ip : null
    }
  }
}

output "anvil_private_ips" {
  value = [for inst in local.all_anvil_instances : inst.network_interface[0].network_ip]
}

output "anvil_public_ips" {
  value = var.assign_public_ip ? [for inst in local.all_anvil_instances : inst.network_interface[0].access_config[0].nat_ip] : []
}

output "anvil_ansible_info" {
  value = [
    for inst in local.all_anvil_instances : {
      hostname   = inst.name
      private_ip = inst.network_interface[0].network_ip
      user       = "hammerspace"
      component  = "anvil"
    }
  ]
}

output "cluster_ip" {
  description = "The cluster IP for HA deployments"
  value       = var.anvil_count > 1 ? google_compute_address.anvil_cluster_ip[0].address : null
}

output "dsx_instances" {
  value = {
    for inst in google_compute_instance.dsx : inst.name => {
      id         = inst.id
      name       = inst.name
      private_ip = inst.network_interface[0].network_ip
    }
  }
}

output "dsx_private_ips" {
  value = [for inst in google_compute_instance.dsx : inst.network_interface[0].network_ip]
}

output "dsx_ansible_info" {
  value = [
    for inst in google_compute_instance.dsx : {
      hostname   = inst.name
      private_ip = inst.network_interface[0].network_ip
      user       = "hammerspace"
      component  = "dsx"
    }
  ]
}
