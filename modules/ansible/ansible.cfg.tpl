[defaults]
inventory = ${inventory_file}
host_key_checking = False
remote_user = ${target_user}
private_key_file = ${private_key}
timeout = 30
gather_facts = True
fact_caching = jsonfile
fact_caching_connection = /tmp/ansible_facts_cache
fact_caching_timeout = 3600

[ssh_connection]
ssh_args = -o ControlMaster=auto -o ControlPersist=60s -o StrictHostKeyChecking=no
pipelining = True