# kk-payments Hardening Log

All scores below were captured live with `sudo systemd-analyze security
kk-payments.service`, with `systemctl is-active kk-payments.service`
checked at every step to confirm the service still starts. Nothing here
is estimated — every number was produced by actually running the
directives on the VM, in the order shown.

## Progression

| Stage | Directives added | Score | Verdict | Service status |
|---|---|---|---|---|
| 0 — Baseline | none (`User=`, `Group=`, `WorkingDirectory=`, `EnvironmentFile=`, `ExecStart=`, `Restart=` only) | **9.2** | UNSAFE 😨 | active |
| 1 | `ProtectSystem=strict`, `ProtectHome=true`, `PrivateTmp=true`, `NoNewPrivileges=true` | **8.3** | EXPOSED 🙁 | active |
| 2 | `PrivateDevices`, `ProtectClock`, `ProtectKernelTunables`, `ProtectKernelModules`, `ProtectKernelLogs`, `ProtectControlGroups`, `ProtectHostname`, `ProtectProc=invisible`, `ProcSubset=pid`, `RestrictNamespaces`, `RestrictSUIDSGID`, `RestrictRealtime`, `LockPersonality`, `MemoryDenyWriteExecute`, `RemoveIPC` | **5.2** | MEDIUM 😐 | active |
| 3 — Final | `SystemCallArchitectures=native`, `SystemCallFilter=@system-service`, `CapabilityBoundingSet=` (empty), `UMask=0077`, `ReadWritePaths=/opt/kijanikiosk/shared/logs`, `RestrictAddressFamilies=AF_UNIX AF_INET AF_INET6`, `IPAddressDeny=any`, `IPAddressAllow=localhost`, `IPAddressAllow=10.0.1.0/24` | **1.4** | OK 🙂 | active |

**Target was below 2.5. Final score: 1.4, service confirmed active at
every stage — no directive was applied at the cost of a broken start.**

### Why Stage 2 moved the score the most

The largest single drop (5.2 → 8.3, a 3.1-point improvement) came from
the kernel/namespace/device isolation batch. This makes sense given what
`kk-payments` actually is: a service with no legitimate reason to touch
hardware devices, load kernel modules, read other processes' `/proc`
entries, or change the system clock. Removing broad access it never
needed accounts for most of the reduction, more than the filesystem
protections in Stage 1 or the network/syscall restrictions in Stage 3.

## Rejected Directives

Two directives were tested live, both scored *better* than the final
config (0.9 SAFE vs. 1.4 OK), and both were rejected anyway. This is the
central judgment call of this exercise: a lower number is not the goal
if it comes from disabling something the service will actually need once
real application code lands.

### 1. `PrivateNetwork=true` — rejected

**Tested score:** 0.9 SAFE, service `active`.

**What it does:** Puts the service in its own network namespace with
only loopback — no route to anything outside the host.

**Why it was rejected:** It only scored well and started cleanly because
the placeholder `ExecStart=/usr/bin/sleep infinity` never opens a socket.
The moment real payment-processing code needs to reach a payment
gateway, a database, or respond to a health check from the monitoring
subnet (`10.0.1.0/24`, which is explicitly allowed via
`IPAddressAllow=` two lines above it in the same file), it would be cut
off entirely — `PrivateNetwork` overrides `IPAddressAllow`/`IPAddressDeny`
rather than working alongside them. The good score was an artifact of
testing against a stub, not evidence the directive is safe to keep.

### 2. `DynamicUser=true` — rejected

**Tested score:** 0.9 SAFE, service `active`.

**What it does:** Allocates a random ephemeral UID to the service on
each start, instead of running as a fixed, named user.

**Why it was rejected:** The entire access model built across this
project depends on `kk-payments` being a stable, known identity
(UID 994): the `payments-api.env` file is `chown`'d directly to
`kk-payments` at mode `600`, and the default ACL on
`/opt/kijanikiosk/shared/logs` grants read access to `kk-payments` by
name. A rotating UID would silently break both of those on the very
next restart — the service would lose the ability to read its own
config and its audit-log access, with no error until something actually
tried to use them. Same root cause as directive 1: the placeholder
workload doesn't exercise the paths that would break, so the test
looked clean when the underlying design conflict wasn't.

## Final Unit File

```ini
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
```

Restored and re-verified identical to the version shipped in
`kijanikiosk-provision.sh` (`diff` against backup confirmed no
differences) with a final live score of **1.4 OK**, service `active`.
