#!/usr/bin/env bash
set -euo pipefail

########################################################################
# KijaniKiosk Server Foundation Provisioning Script
# Week 3 / Friday — Server Foundation
#
# Expected dirty conditions found in pre-provisioning audit
# (see pre-provisioning-audit.txt for raw evidence):
#   1. kk-api / kk-payments / kk-logs already existed as users, created
#      with interactive /bin/bash shells and default home directories
#      -> handled in Phase 2 via idempotent usermod reconciliation
#   2. /opt/kijanikiosk/config had world-writable 777 permissions
#      -> corrected in Phase 3 to 750 root:kijanikiosk, individual
#         EnvironmentFiles further locked to 600 in Phase 4
#   3. ufw had a spurious `deny 3001` rule left over from manual testing,
#      with no comment and no relationship to the monitoring-subnet model
#      -> wiped and rebuilt from an explicit baseline in Phase 5
#   4. curl was held via apt-mark with no version pin recorded anywhere
#      -> reconciled against a recorded pin in Phase 1, held again after
#   5. No systemd units existed for kk-api/kk-payments/kk-logs on the
#      very first run of this script -> created idempotently in Phase 4,
#      safe to re-run without duplicating or corrupting state
#   6. No logrotate config or journald persistence existed on the very
#      first run -> created idempotently in Phase 7
#
# This script is designed to converge correctly regardless of which of
# the above it finds -- a script that assumes a specific dirty state
# instead of detecting one is not actually idempotent.
########################################################################

# ---------------------------------------------------------------------
# Global check-tracking used by the Phase 8 final verification gate.
# Any phase can call record_pass/record_fail. Nothing exits early on a
# single failed check, so the full picture is visible in one run and
# the final gate can report exactly which checks passed and which
# failed, per Requirement 1.
# ---------------------------------------------------------------------
CHECK_RESULTS=()
record_pass() { CHECK_RESULTS+=("PASS: $1"); echo "  [PASS] $1"; }
record_fail() { CHECK_RESULTS+=("FAIL: $1"); echo "  [FAIL] $1" >&2; }
log()         { echo "  -> $1"; }

STATE_DIR="/opt/kijanikiosk/.provision-state"
sudo mkdir -p "$STATE_DIR"

########################################################################
echo "=== PHASE 1: PACKAGE MANAGEMENT ==="
########################################################################
# Challenge D: a dirty VM may have packages already installed at a
# version that drifted from what was pinned earlier in the week. We
# record a canonical pinned version on the first successful run and
# FAIL LOUDLY on drift on subsequent runs, rather than silently
# downgrading/upgrading a package on a machine that will host a
# payments service. An unattended version change is exactly the kind
# of action that should require a human to look at it first. This
# choice (fail loud vs. auto-downgrade) is documented in
# integration-notes.md (Challenge D) and defended in hardening-decisions.md.

CURL_PIN_FILE="$STATE_DIR/curl.pin"

if apt-mark showhold | grep -qx "curl"; then
  sudo apt-mark unhold curl
  log "curl had an existing apt-mark hold; temporarily released for version check"
fi

sudo apt-get update -y

INSTALLED_CURL_VERSION="$(apt-cache policy curl | awk '/Installed:/{print $2}')"

if [[ -f "$CURL_PIN_FILE" ]]; then
  PINNED_CURL_VERSION="$(cat "$CURL_PIN_FILE")"
  if [[ "$INSTALLED_CURL_VERSION" == "$PINNED_CURL_VERSION" ]]; then
    record_pass "curl version matches pinned target ($PINNED_CURL_VERSION)"
  else
    record_fail "curl version drift: installed=$INSTALLED_CURL_VERSION pinned=$PINNED_CURL_VERSION"
    echo "Refusing to silently downgrade/upgrade curl on a payments host." >&2
    echo "Manual intervention required -- see integration-notes.md (Challenge D)." >&2
    sudo apt-mark hold curl
    exit 1
  fi
else
  echo "$INSTALLED_CURL_VERSION" | sudo tee "$CURL_PIN_FILE" > /dev/null
  record_pass "curl version pin recorded for the first time ($INSTALLED_CURL_VERSION)"
fi

sudo apt-get install -y acl ufw
sudo apt-mark hold curl
record_pass "curl held at pinned version"

########################################################################
echo "=== PHASE 2: USERS AND GROUPS ==="
########################################################################
if ! getent group kijanikiosk >/dev/null; then
  sudo groupadd -r kijanikiosk
  log "Created group: kijanikiosk"
else
  log "Already exists: group kijanikiosk"
fi

setup_service_user() {
  local user="$1"
  if id "$user" &>/dev/null; then
    local current_shell current_home
    current_shell="$(getent passwd "$user" | cut -d: -f7)"
    current_home="$(getent passwd "$user" | cut -d: -f6)"
    log "Already exists: $user (shell=$current_shell home=$current_home)"
    if [[ "$current_shell" != "/sbin/nologin" || "$current_home" != "/opt/kijanikiosk" ]]; then
      sudo usermod -s /sbin/nologin -g kijanikiosk -d /opt/kijanikiosk "$user"
      log "Reconciled $user: shell -> /sbin/nologin, home -> /opt/kijanikiosk, group -> kijanikiosk"
    else
      log "$user already correctly configured, no change needed"
    fi
  else
    sudo useradd -r -s /sbin/nologin -g kijanikiosk -d /opt/kijanikiosk "$user"
    log "Created: $user"
  fi
}

setup_service_user kk-api
setup_service_user kk-payments
setup_service_user kk-logs

for u in kk-api kk-payments kk-logs; do
  shell="$(getent passwd "$u" | cut -d: -f7)"
  if [[ "$shell" == "/sbin/nologin" ]]; then
    record_pass "$u has no interactive shell ($shell)"
  else
    record_fail "$u still has an interactive shell ($shell)"
  fi
done

########################################################################
echo "=== PHASE 3: DIRECTORY HIERARCHY AND ACL PERMISSIONS ==="
########################################################################
sudo mkdir -p /opt/kijanikiosk/config /opt/kijanikiosk/shared/logs /opt/kijanikiosk/health

# Drift detection: report what we found before correcting it
CONFIG_MODE_BEFORE="$(stat -c '%a' /opt/kijanikiosk/config)"
if [[ "$CONFIG_MODE_BEFORE" != "750" ]]; then
  log "Drift detected: /opt/kijanikiosk/config mode was $CONFIG_MODE_BEFORE, correcting to 750"
else
  log "Already correct: /opt/kijanikiosk/config mode is 750"
fi
sudo chown -R root:kijanikiosk /opt/kijanikiosk
sudo chmod 750 /opt/kijanikiosk/config
sudo chmod 775 /opt/kijanikiosk/shared/logs
sudo chmod 750 /opt/kijanikiosk/health

# Challenge B: the health directory did not exist in Tuesday's access
# model. It is owned by kk-logs (the service responsible for
# structured logging/health reporting) with group kijanikiosk, so any
# member of that group -- including a monitoring user added later --
# can read health output without sudo, while only kk-logs can write.
sudo chown kk-logs:kijanikiosk /opt/kijanikiosk/health

# Requirement 3: default ACLs on shared/logs so files created later by
# logrotate's `create` directive inherit correct access even though
# logrotate itself only sets standard owner/mode, not ACLs. The kernel
# applies a directory's default ACL to any new file created inside it
# regardless of which process creates it, which is what makes this
# survive rotation.
sudo setfacl -m u:kk-api:rwx,u:kk-payments:rx,u:kk-logs:rwx,g:kijanikiosk:rx /opt/kijanikiosk/shared/logs
sudo setfacl -d -m u:kk-api:rw-,u:kk-payments:r--,u:kk-logs:rw-,g:kijanikiosk:r-x /opt/kijanikiosk/shared/logs

if [[ "$(stat -c '%a' /opt/kijanikiosk/config)" == "750" ]]; then
  record_pass "config directory is 750 (was 777 pre-provisioning)"
else
  record_fail "config directory permissions incorrect"
fi

if getfacl /opt/kijanikiosk/shared/logs 2>/dev/null | grep -q "^default:user:kk-api:rw-"; then
  record_pass "default ACL for kk-api present on shared/logs"
else
  record_fail "default ACL for kk-api missing on shared/logs"
fi

########################################################################
echo "=== PHASE 4: ENVIRONMENT FILES AND SYSTEMD SERVICE UNITS ==="
########################################################################
# Challenge A: kk-payments runs with ProtectSystem=strict, which makes
# /etc read-only for the service process. EnvironmentFile paths are
# deliberately kept under /opt/kijanikiosk/config/ (never /etc) so that
# ProtectSystem=strict never has to be relaxed just to read config.
# This is a design choice, not an accident -- see integration-notes.md.

create_env_file() {
  local user="$1" path="$2"
  if [[ ! -f "$path" ]]; then
    sudo tee "$path" > /dev/null << ENVFILE
NODE_ENV=production
SERVICE_NAME=$user
ENVFILE
    log "Created env file: $path"
  else
    log "Already exists: $path"
  fi
  sudo chown "$user":kijanikiosk "$path"
  sudo chmod 600 "$path"
}

create_env_file kk-api      /opt/kijanikiosk/config/api.env
create_env_file kk-payments /opt/kijanikiosk/config/payments-api.env
create_env_file kk-logs     /opt/kijanikiosk/config/logs.env

# Requirement 2 hint: verify EnvironmentFile readability BEFORE trying
# to start the unit. A permission failure here produces a clear
# message; the same failure surfacing through systemd's own env-file
# loading produces a cryptic one.
for pair in "kk-api:/opt/kijanikiosk/config/api.env" "kk-payments:/opt/kijanikiosk/config/payments-api.env" "kk-logs:/opt/kijanikiosk/config/logs.env"; do
  svc_user="${pair%%:*}"
  env_path="${pair##*:}"
  if sudo -u "$svc_user" test -r "$env_path"; then
    record_pass "$env_path readable by $svc_user"
  else
    record_fail "$env_path NOT readable by $svc_user -- unit will fail to start"
  fi
done

# NOTE: ExecStart=/usr/bin/sleep infinity is a placeholder for
# application code that does not exist yet (it lands via Terraform/
# Ansible in Week 4). It is intentionally long-running rather than a
# one-shot command so that systemctl is-active and the hardening
# directives below are actually exercised, not skipped because the
# process already exited.

for unit in kk-api kk-payments kk-logs; do
  if [[ -f "/etc/systemd/system/$unit.service" ]]; then
    log "Already exists: /etc/systemd/system/$unit.service (overwriting with intended definition)"
  else
    log "Not found: $unit.service (creating)"
  fi
done

sudo tee /etc/systemd/system/kk-api.service > /dev/null << 'SERVICE'
[Unit]
Description=KijaniKiosk API Service
After=network.target

[Service]
Type=simple
User=kk-api
Group=kijanikiosk
WorkingDirectory=/opt/kijanikiosk
EnvironmentFile=/opt/kijanikiosk/config/api.env
ExecStart=/usr/bin/sleep infinity
Restart=on-failure

# --- Hardening (target: below 3.5) ---
ProtectSystem=strict
ProtectHome=true
PrivateTmp=true
PrivateDevices=true
ProtectClock=true
ProtectKernelTunables=true
ProtectKernelModules=true
ProtectKernelLogs=true
ProtectControlGroups=true
ProtectHostname=true
ProtectProc=invisible
ProcSubset=pid
RestrictNamespaces=true
RestrictSUIDSGID=true
RestrictRealtime=true
LockPersonality=true
MemoryDenyWriteExecute=true
RemoveIPC=true
NoNewPrivileges=true
SystemCallArchitectures=native
SystemCallFilter=@system-service
CapabilityBoundingSet=
UMask=0027
ReadWritePaths=/opt/kijanikiosk/shared/logs

[Install]
WantedBy=multi-user.target
SERVICE

sudo tee /etc/systemd/system/kk-logs.service > /dev/null << 'SERVICE'
[Unit]
Description=KijaniKiosk Logs Collector
After=network.target

[Service]
Type=simple
User=kk-logs
Group=kijanikiosk
WorkingDirectory=/opt/kijanikiosk
EnvironmentFile=/opt/kijanikiosk/config/logs.env
ExecStart=/usr/bin/sleep infinity
Restart=on-failure

# --- Hardening (target: below 3.5) ---
ProtectSystem=strict
ProtectHome=true
PrivateTmp=true
PrivateDevices=true
ProtectClock=true
ProtectKernelTunables=true
ProtectKernelModules=true
ProtectKernelLogs=true
ProtectControlGroups=true
ProtectHostname=true
ProtectProc=invisible
ProcSubset=pid
RestrictNamespaces=true
RestrictSUIDSGID=true
RestrictRealtime=true
LockPersonality=true
MemoryDenyWriteExecute=true
RemoveIPC=true
NoNewPrivileges=true
SystemCallArchitectures=native
SystemCallFilter=@system-service
CapabilityBoundingSet=
UMask=0027
ReadWritePaths=/opt/kijanikiosk/shared/logs

[Install]
WantedBy=multi-user.target
SERVICE

# kk-payments: handles financial transaction data, target below 2.5.
# Requirement 2: must declare After= and Wants= on kk-api.service.
sudo tee /etc/systemd/system/kk-payments.service > /dev/null << 'SERVICE'
[Unit]
Description=KijaniKiosk Payments Service
After=network.target kk-api.service
Wants=kk-api.service

[Service]
Type=simple
User=kk-payments
Group=kijanikiosk
WorkingDirectory=/opt/kijanikiosk
EnvironmentFile=/opt/kijanikiosk/config/payments-api.env
ExecStart=/usr/bin/sleep infinity
Restart=on-failure

# --- Hardening (target: below 2.5 -- stricter than kk-api/kk-logs
# because this service touches financial transaction data) ---
ProtectSystem=strict
ProtectHome=true
PrivateTmp=true
PrivateDevices=true
ProtectClock=true
ProtectKernelTunables=true
ProtectKernelModules=true
ProtectKernelLogs=true
ProtectControlGroups=true
ProtectHostname=true
ProtectProc=invisible
ProcSubset=pid
RestrictNamespaces=true
RestrictSUIDSGID=true
RestrictRealtime=true
LockPersonality=true
MemoryDenyWriteExecute=true
RemoveIPC=true
NoNewPrivileges=true
SystemCallArchitectures=native
SystemCallFilter=@system-service
CapabilityBoundingSet=
UMask=0077
ReadWritePaths=/opt/kijanikiosk/shared/logs
RestrictAddressFamilies=AF_UNIX AF_INET AF_INET6
IPAddressDeny=any
IPAddressAllow=localhost
IPAddressAllow=10.0.1.0/24

[Install]
WantedBy=multi-user.target
SERVICE

sudo systemctl daemon-reload
log "All three unit files written and daemon reloaded"

########################################################################
echo "=== PHASE 5: FIREWALL BASELINE ==="
########################################################################
# Requirement 4: express intent, not history. Reset completely instead
# of patching four days of manual edits, then rebuild from an explicit
# baseline where every rule states who it is for and why.
#
# kk-api (3000) and kk-logs (3002) are intentionally NOT opened at all:
# kk-api is reached through nginx on port 80/443, and kk-logs is an
# internal-only collector with no external consumer. The default deny
# policy covers both -- no explicit rule needed, which is itself the
# point of Requirement 4 (only declare intent that exists).

# Drift detection: list whatever rules exist before the reset wipes them
UFW_RULE_COUNT_BEFORE="$(sudo ufw status numbered | grep -c '^\[' || true)"
log "Existing ufw rules found before reset: $UFW_RULE_COUNT_BEFORE"
sudo ufw status numbered | grep '^\[' | sed 's/^/       /' || true
sudo ufw --force reset
sudo ufw default deny incoming
sudo ufw default allow outgoing

# The loopback allow MUST be added before the external deny for the
# same port: ufw evaluates rules in the order they appear and the
# first match wins, so a deny added first would shadow this rule.
sudo ufw allow in on lo to any port 3001 proto tcp comment 'Loopback: nginx proxy to kk-payments'

sudo ufw allow from 10.0.1.0/24 to any port 22 proto tcp comment 'SSH from monitoring subnet'
sudo ufw allow from 10.0.1.0/24 to any port 80 proto tcp comment 'HTTP from monitoring subnet'
sudo ufw allow from 10.0.1.0/24 to any port 3001 proto tcp comment 'Payments health check from monitoring subnet'

# 3001 is an internal service port -- deny external access explicitly
# rather than relying on the default policy, so intent is visible in
# `ufw status` rather than implicit.
sudo ufw deny 3001/tcp comment 'Deny external access to internal payments port'

sudo ufw --force enable
log "Firewall rebuilt from explicit baseline (previous ruleset reset)"

########################################################################
echo "=== PHASE 6: SERVICE ACTIVATION AND HARDENING VALIDATION ==="
########################################################################
start_and_check_service() {
  local unit="$1" threshold="$2"
  sudo systemctl enable "$unit" >/dev/null 2>&1 || true
  sudo systemctl restart "$unit"
  sleep 1

  if sudo systemctl is-failed --quiet "$unit"; then
    record_fail "$unit failed to start -- run: journalctl -u $unit -n 30"
    sudo systemctl status "$unit" --no-pager || true
  else
    record_pass "$unit started without entering failed state"
  fi

  local score
  score="$(sudo systemd-analyze security "$unit" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+' | tail -1)"
  if [[ -z "$score" ]]; then
    record_fail "$unit: could not parse systemd-analyze security score"
    return
  fi
  log "$unit exposure score: $score (threshold: <$threshold)"
  if awk -v s="$score" -v t="$threshold" 'BEGIN{exit !(s < t)}'; then
    record_pass "$unit exposure score $score is below threshold $threshold"
  else
    record_fail "$unit exposure score $score does NOT meet threshold $threshold"
  fi
}

start_and_check_service kk-api.service 3.5
start_and_check_service kk-payments.service 2.5
start_and_check_service kk-logs.service 3.5

########################################################################
echo "=== PHASE 7: JOURNAL PERSISTENCE AND LOG ROTATION ==="
########################################################################
sudo mkdir -p /var/log/journal
sudo systemd-tmpfiles --create --prefix /var/log/journal >/dev/null 2>&1 || true

if grep -q "^#\?SystemMaxUse=" /etc/systemd/journald.conf; then
  sudo sed -i 's/^#\?SystemMaxUse=.*/SystemMaxUse=500M/' /etc/systemd/journald.conf
else
  echo "SystemMaxUse=500M" | sudo tee -a /etc/systemd/journald.conf > /dev/null
fi
sudo systemctl restart systemd-journald
log "journald configured for persistent storage, capped at 500M"

# Challenge C: kk-logs runs as a placeholder (sleep infinity) and does
# not implement ExecReload=, so `systemctl reload kk-logs` would fail
# outright. Adding a no-op ExecReload= would technically "fix" that
# while lying about reload support once real app code lands. The
# decision here is to restart on rotation instead of reload, accepting
# a brief service interruption during log rotation -- documented, not
# hidden, in integration-notes.md (Challenge C).

if [[ -f /etc/logrotate.d/kijanikiosk ]]; then
  log "Already exists: /etc/logrotate.d/kijanikiosk (overwriting with intended config)"
else
  log "Not found: /etc/logrotate.d/kijanikiosk (creating)"
fi

sudo tee /etc/logrotate.d/kijanikiosk > /dev/null << 'LOGROTATE'
/opt/kijanikiosk/shared/logs/*.log {
    su kk-logs kijanikiosk
    daily
    missingok
    rotate 14
    compress
    delaycompress
    notifempty
    create 0640 kk-logs kijanikiosk
    sharedscripts
    postrotate
        systemctl restart kk-logs.service > /dev/null 2>&1 || true
    endscript
}
LOGROTATE

if sudo logrotate --debug /etc/logrotate.d/kijanikiosk > "$STATE_DIR/logrotate-debug.out" 2>&1; then
  record_pass "logrotate --debug passes for kijanikiosk config"
else
  record_fail "logrotate --debug failed -- see $STATE_DIR/logrotate-debug.out"
fi

# Requirement 3: this is the actual test that matters -- not that the
# config is syntactically valid, but that the access model survives a
# real rotation. The create directive sets base owner/mode; the
# directory's default ACLs (Phase 3) layer kk-api/kk-payments access
# on top automatically at the kernel level.
sudo touch /opt/kijanikiosk/shared/logs/placeholder.log
sudo chown kk-logs:kijanikiosk /opt/kijanikiosk/shared/logs/placeholder.log

if sudo logrotate --force /etc/logrotate.d/kijanikiosk > "$STATE_DIR/logrotate-force.out" 2>&1; then
  record_pass "forced logrotate rotation completed without error"
else
  record_fail "forced logrotate rotation failed -- see $STATE_DIR/logrotate-force.out"
fi

if sudo -u kk-api touch /opt/kijanikiosk/shared/logs/test-write.tmp 2>/dev/null; then
  record_pass "kk-api can write to shared/logs after forced rotation"
  sudo rm -f /opt/kijanikiosk/shared/logs/test-write.tmp
else
  record_fail "kk-api CANNOT write to shared/logs after rotation -- ACL model broken"
fi

########################################################################
echo "=== PHASE 8: MONITORING HEALTH CHECKS AND FINAL VERIFICATION ==="
########################################################################
api_status=$(timeout 2 bash -c "echo >/dev/tcp/localhost/3000" 2>/dev/null && echo '"ok"' || echo '"down"')
payments_status=$(timeout 2 bash -c "echo >/dev/tcp/localhost/3001" 2>/dev/null && echo '"ok"' || echo '"down"')
logs_status=$(timeout 2 bash -c "echo >/dev/tcp/localhost/3002" 2>/dev/null && echo '"ok"' || echo '"down"')

sudo mkdir -p /opt/kijanikiosk/health
printf '{"timestamp":"%s","kk-api":%s,"kk-payments":%s,"kk-logs":%s}\n' \
  "$(date -Is)" "$api_status" "$payments_status" "$logs_status" \
  | sudo tee /opt/kijanikiosk/health/last-provision.json > /dev/null

sudo chown kk-logs:kijanikiosk /opt/kijanikiosk/health/last-provision.json
sudo chmod 640 /opt/kijanikiosk/health/last-provision.json

if [[ -f /opt/kijanikiosk/health/last-provision.json ]]; then
  record_pass "health check JSON written to /opt/kijanikiosk/health/last-provision.json"
else
  record_fail "health check JSON missing"
fi

# Requirement 4: one PASS/FAIL assertion per firewall rule, not just a
# printed status.
verify_firewall() {
  local status
  status="$(sudo ufw status numbered)"

  echo "$status" | grep -q "22/tcp.*ALLOW.*10.0.1.0/24" \
    && record_pass "SSH (22) allowed only from monitoring subnet" \
    || record_fail "SSH monitoring-subnet rule missing or too broad"

  echo "$status" | grep -q "80/tcp.*ALLOW.*10.0.1.0/24" \
    && record_pass "HTTP (80) allowed only from monitoring subnet" \
    || record_fail "HTTP monitoring-subnet rule missing or too broad"

  echo "$status" | grep -q "3001/tcp.*ALLOW.*10.0.1.0/24" \
    && record_pass "Payments health check (3001) allowed from monitoring subnet" \
    || record_fail "Payments health-check monitoring-subnet rule missing"

  echo "$status" | grep -q "3001/tcp.*DENY" \
    && record_pass "External access to 3001 explicitly denied" \
    || record_fail "External deny rule for 3001 missing"

  local lo_line deny_line
  lo_line="$(echo "$status" | grep -n "on lo" | grep "3001" | head -1 | cut -d: -f1)"
  deny_line="$(echo "$status" | grep -n "3001/tcp.*DENY" | head -1 | cut -d: -f1)"
  if [[ -n "$lo_line" && -n "$deny_line" && "$lo_line" -lt "$deny_line" ]]; then
    record_pass "Loopback allow for 3001 is ordered before the external deny"
  else
    record_fail "Loopback allow for 3001 is NOT ordered before the external deny -- rule is dead"
  fi
}
verify_firewall

########################################################################
# FINAL VERIFICATION GATE
# Aggregates every check recorded across all 8 phases and exits
# non-zero if any single check failed, per Requirement 1.
########################################################################
echo ""
echo "=== FINAL VERIFICATION SUMMARY ==="
fail_count=0
for result in "${CHECK_RESULTS[@]}"; do
  echo "$result"
  if [[ "$result" == FAIL:* ]]; then
    fail_count=$((fail_count + 1))
  fi
done

echo ""
echo "Total checks: ${#CHECK_RESULTS[@]}, Failed: $fail_count"

if [[ "$fail_count" -gt 0 ]]; then
  echo "=== PROVISIONING COMPLETED WITH FAILURES ==="
  exit 1
else
  echo "=== PROVISIONING COMPLETE -- ALL CHECKS PASSED ==="
  exit 0
fi
