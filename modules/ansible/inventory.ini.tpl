[ansible_controllers]
%{ for host in ansible_hosts ~}
${host.name} ansible_host=${host.network_interface[0].network_ip} ansible_user=${target_user}
%{ endfor ~}

[all:vars]
ansible_python_interpreter=/usr/bin/python3
ansible_ssh_common_args='-o StrictHostKeyChecking=no'