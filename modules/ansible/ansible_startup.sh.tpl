#!/bin/bash
# Copyright (c) 2025 Hammerspace, Inc
# Ansible Controller Startup Script with Daemon Support

set -e

# Update system
apt-get update

# Install Ansible and dependencies
apt-get install -y software-properties-common python3-pip git jq curl

# Install Ansible via pip for latest version
pip3 install ansible ansible-core

# Create ansible user if it doesn't exist
if ! id "${target_user}" &>/dev/null; then
    useradd -m -s /bin/bash ${target_user}
fi

# Setup SSH keys for ansible user
mkdir -p /home/${target_user}/.ssh
chmod 700 /home/${target_user}/.ssh

# Add public key
cat > /home/${target_user}/.ssh/authorized_keys <<EOF
${admin_pub_key}
EOF
chmod 600 /home/${target_user}/.ssh/authorized_keys

# Add private key
cat > /home/${target_user}/.ssh/id_rsa <<EOF
${admin_priv_key}
EOF
chmod 600 /home/${target_user}/.ssh/id_rsa

# Generate public key from private
ssh-keygen -y -f /home/${target_user}/.ssh/id_rsa > /home/${target_user}/.ssh/id_rsa.pub
chmod 644 /home/${target_user}/.ssh/id_rsa.pub

# Set ownership
chown -R ${target_user}:${target_user} /home/${target_user}/.ssh

# Configure SSH client
cat > /home/${target_user}/.ssh/config <<EOF
Host *
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    IdentityFile ~/.ssh/id_rsa
EOF
chmod 600 /home/${target_user}/.ssh/config
chown ${target_user}:${target_user} /home/${target_user}/.ssh/config

# Allow passwordless sudo for ansible user
echo "${target_user} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${target_user}
chmod 440 /etc/sudoers.d/${target_user}

# Setup root access if allowed
%{ if allow_root ~}
mkdir -p /root/.ssh
cp /home/${target_user}/.ssh/authorized_keys /root/.ssh/
chmod 600 /root/.ssh/authorized_keys
sed -i 's/^PermitRootLogin.*/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config
systemctl restart sshd
%{ endif ~}

# Create Ansible directory structure
mkdir -p /etc/ansible
mkdir -p /home/${target_user}/playbooks
mkdir -p /home/${target_user}/inventories
mkdir -p /home/${target_user}/roles

# Create default ansible.cfg
cat > /etc/ansible/ansible.cfg <<EOF
[defaults]
host_key_checking = False
inventory = /home/${target_user}/inventories
roles_path = /home/${target_user}/roles
remote_user = ${target_user}
private_key_file = /home/${target_user}/.ssh/id_rsa
EOF

# Set ownership for ansible directories
chown -R ${target_user}:${target_user} /home/${target_user}/playbooks
chown -R ${target_user}:${target_user} /home/${target_user}/inventories
chown -R ${target_user}:${target_user} /home/${target_user}/roles

# -----------------------------------------------------------------------------
# Ansible Controller Daemon Setup
# -----------------------------------------------------------------------------
%{ if enable_daemon ~}

JOBS_DIR="/usr/local/ansible/jobs"
TRIGGER_DIR="/var/ansible/trigger"
STATUS_DIR="/var/run/ansible_jobs_status"
PLAYBOOKS_DIR="/usr/local/ansible/playbooks"
VARS_DIR="/usr/local/ansible/vars"
ANSIBLE_LIB="/usr/local/lib/ansible_functions.sh"
ANSIBLE_DAEMON="/usr/local/bin/ansible_controller_daemon.sh"
UNIT_PATH="/etc/systemd/system/ansible-controller.service"

# Create directories
mkdir -p /usr/local/lib /usr/local/bin "$JOBS_DIR" "$TRIGGER_DIR" "$STATUS_DIR" "$PLAYBOOKS_DIR" "$VARS_DIR"

# --- Install function library ---
cat > "$ANSIBLE_LIB" <<'FUNCEOF'
${functions_script}
FUNCEOF

# --- Install daemon script ---
cat > "$ANSIBLE_DAEMON" <<'DAEMONEOF'
${daemon_script}
DAEMONEOF

chmod 0644 "$ANSIBLE_LIB"
chmod 0755 "$ANSIBLE_DAEMON"

# --- Install Hammerspace playbook ---
cat > "$PLAYBOOKS_DIR/hs-ansible.yml" <<'PLAYBOOKEOF'
${playbook_script}
PLAYBOOKEOF

chmod 0644 "$PLAYBOOKS_DIR/hs-ansible.yml"

# --- Install job script ---
cat > "$JOBS_DIR/10-hammerspace-integration.sh" <<'JOBEOF'
${job_script}
JOBEOF

chmod 0755 "$JOBS_DIR/10-hammerspace-integration.sh"

# --- Install Hammerspace variables file ---
cat > "$VARS_DIR/hammerspace_vars.json" <<'VARSEOF'
${vars_json}
VARSEOF

chmod 0644 "$VARS_DIR/hammerspace_vars.json"

# --- Create systemd unit ---
cat > "$UNIT_PATH" <<'UNITEOF'
[Unit]
Description=Ansible Controller Daemon (inventory-triggered job runner)
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
ExecStart=/usr/local/bin/ansible_controller_daemon.sh
Restart=always
RestartSec=5s
User=root
Group=root
NoNewPrivileges=yes

[Install]
WantedBy=multi-user.target
UNITEOF

# --- Reload, enable & start ---
systemctl daemon-reload
systemctl enable --now ansible-controller.service

echo "ansible-controller.service is now: $(systemctl is-active ansible-controller.service)"
echo "Logs: journalctl -u ansible-controller.service -f"

%{ endif ~}

echo "Ansible controller setup complete"
