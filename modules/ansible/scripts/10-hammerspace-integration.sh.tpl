#!/bin/bash
# Copyright (c) 2025 Hammerspace, Inc
# Job Script: Add ECGroup/Storage nodes to Hammerspace Anvil cluster
# This script runs the hs-ansible.yml playbook to integrate nodes with Anvil

set -euo pipefail

# --- Source the Function Library ---
source /usr/local/lib/ansible_functions.sh

echo "--- Starting Hammerspace integration job ---"

# --- Variables passed from Terraform ---
ANVIL_CLUSTER_IP="${anvil_cluster_ip}"
HS_USERNAME="${hs_username}"
HS_PASSWORD="${hs_password}"
VOLUME_GROUP_NAME="${volume_group_name}"
SHARE_NAME="${share_name}"
PLAYBOOK_PATH="/usr/local/ansible/playbooks/hs-ansible.yml"
VARS_FILE="/usr/local/ansible/vars/hammerspace_vars.json"

# --- Check if playbook exists ---
if [ ! -f "$PLAYBOOK_PATH" ]; then
  echo "ERROR: Playbook not found at $PLAYBOOK_PATH"
  exit 1
fi

# --- Check if variables file exists ---
if [ ! -f "$VARS_FILE" ]; then
  echo "ERROR: Variables file not found at $VARS_FILE"
  exit 1
fi

# --- Run the Ansible playbook ---
echo "Running Hammerspace integration playbook..."
ansible-playbook "$PLAYBOOK_PATH" \
  -e "data_cluster_mgmt_ip=$ANVIL_CLUSTER_IP" \
  -e "hsuser=$HS_USERNAME" \
  -e "password=$HS_PASSWORD" \
  -e "volume_group_name=$VOLUME_GROUP_NAME" \
  -e "share_name=$SHARE_NAME" \
  -e "@$VARS_FILE" \
  -v

echo "--- Hammerspace integration job completed successfully ---"
