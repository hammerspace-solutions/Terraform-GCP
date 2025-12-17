# Copyright (c) 2025 Hammerspace, Inc
# -----------------------------------------------------------------------------
# modules/ecgroup/ecgroup_outputs.tf
# -----------------------------------------------------------------------------

output "ecgroup_instances" {
  value = {
    for inst in google_compute_instance.ecgroup_node : inst.name => {
      id         = inst.id
      name       = inst.name
      private_ip = inst.network_interface[0].network_ip
      zone       = inst.zone
    }
  }
}

output "ecgroup_private_ips" {
  value = [for inst in google_compute_instance.ecgroup_node : inst.network_interface[0].network_ip]
}

output "ecgroup_ansible_info" {
  value = [
    for inst in google_compute_instance.ecgroup_node : {
      hostname   = inst.name
      private_ip = inst.network_interface[0].network_ip
      user       = "ecgroup"
      component  = "ecgroup"
    }
  ]
}