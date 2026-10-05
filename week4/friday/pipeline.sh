#!/usr/bin/env bash
set -euo pipefail

# pipeline.sh -- Requirement 3: run the full Terraform + Ansible pipeline
# in sequence. Terraform provisions, this script extracts the outputs,
# writes inventory.ini, then Ansible configures. Exits non-zero if
# either stage fails (set -e handles this: any failing command aborts
# the script immediately with its own non-zero exit code).
#
# Usage: ./pipeline.sh
# Primary path only (Multipass) -- this project did not build the
# optional cloud path, so no [multipass|cloud] mode switch is needed.

TERRAFORM_DIR="$HOME/kijanikiosk-infra"
ANSIBLE_DIR="$HOME/kijanikiosk-ansible"

echo "=== PIPELINE STEP 1: terraform apply ==="
cd "$TERRAFORM_DIR"
terraform apply -auto-approve

echo ""
echo "=== PIPELINE STEP 2: extract IPs from Terraform outputs ==="
API_IP=$(terraform output -raw api_server_ip)
PAYMENTS_IP=$(terraform output -raw payments_server_ip)
LOGS_IP=$(terraform output -raw logs_server_ip)

if [[ -z "$API_IP" || -z "$PAYMENTS_IP" || -z "$LOGS_IP" ]]; then
  echo "ERROR: one or more Terraform outputs were empty. Aborting before touching Ansible." >&2
  exit 1
fi

echo "api_server_ip:      $API_IP"
echo "payments_server_ip: $PAYMENTS_IP"
echo "logs_server_ip:     $LOGS_IP"

echo ""
echo "=== PIPELINE STEP 3: write inventory.ini ==="
# Written fresh every run -- never hand-edited, never stale. This is
# Challenge A's core requirement: the inventory must always reflect
# the current Terraform state, not a snapshot from a previous run.
cat > "$ANSIBLE_DIR/inventory.ini" << INV
[kijanikiosk_api]
api-staging ansible_host=${API_IP}

[kijanikiosk_payments]
payments-staging ansible_host=${PAYMENTS_IP}

[kijanikiosk_logs]
logs-staging ansible_host=${LOGS_IP}

[kijanikiosk:children]
kijanikiosk_api
kijanikiosk_payments
kijanikiosk_logs

[kijanikiosk:vars]
ansible_python_interpreter=/usr/bin/python3
INV

echo "inventory.ini written to $ANSIBLE_DIR/inventory.ini"
cat "$ANSIBLE_DIR/inventory.ini"

echo ""
echo "=== PIPELINE STEP 4: ansible-playbook ==="
cd "$ANSIBLE_DIR"
ansible-playbook -i inventory.ini kijanikiosk.yml

echo ""
echo "=== PIPELINE COMPLETE: Terraform + Ansible ran successfully ==="
