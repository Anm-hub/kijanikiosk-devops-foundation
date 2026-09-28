# KijaniKiosk Access Model — Final (Week 3 / Friday)

This document consolidates the access model developed across the week
(service accounts on Tuesday, ACL corrections through Wednesday/Thursday)
and finalizes it as of Friday's provisioning run. No standalone
`access-model.md` was kept as a separate file earlier in the week — the
model existed as applied state on the VM and in `provision.sh` — so this
document is the authoritative, verified record going forward. All values
below are taken directly from `post-remediation-verification.txt`, not
reconstructed from memory.

## 1. Service Accounts

| Account | UID | Primary Group | Shell | Home |
|---|---|---|---|---|
| `kk-api` | 997 | `kijanikiosk` (1001) | `/sbin/nologin` | `/opt/kijanikiosk` |
| `kk-payments` | 994 | `kijanikiosk` (1001) | `/sbin/nologin` | `/opt/kijanikiosk` |
| `kk-logs` | 993 | `kijanikiosk` (1001) | `/sbin/nologin` | `/opt/kijanikiosk` |

All three accounts are system accounts with no interactive login shell.
Earlier in the week these existed with `/bin/bash` shells (a dirty
condition documented in `pre-provisioning-audit.txt`); the provisioning
script reconciles this idempotently via `usermod` rather than requiring
manual correction.

All three share the `kijanikiosk` primary group, which is what allows
default ACLs on shared resources (Section 3) to apply uniformly, and is
also why per-service secrets are locked to `600` rather than relying on
group permissions (Section 4) — group membership alone is not
fine-grained enough to separate the three services from each other.

## 2. Directory Structure & Base Ownership

| Path | Owner:Group | Mode | Purpose |
|---|---|---|---|
| `/opt/kijanikiosk` | `root:kijanikiosk` | `0755` | Base directory |
| `/opt/kijanikiosk/config` | `root:kijanikiosk` | `0750` | Per-service EnvironmentFiles |
| `/opt/kijanikiosk/shared/logs` | `root:kijanikiosk` | `0775` | Shared application logs |
| `/opt/kijanikiosk/health` | `kk-logs:kijanikiosk` | `0750` | Structured health check output |

`config` was `0777` (world-writable) at the start of the week — this was
one of the six dirty conditions in the pre-provisioning audit and is
corrected on every run of the provisioning script, not just once.

## 3. POSIX ACLs on `shared/logs`

Base permissions (`0775 root:kijanikiosk`) are not sufficient on their
own: `kk-payments` needs read-only access for audit correlation while
`kk-api` and `kk-logs` need read/write, and this distinction cannot be
expressed by group ownership alone since all three share one group.
ACLs provide the per-user granularity that group ownership can't:

**Active ACL (applies to the directory itself):**
```
user::rwx
user:kk-logs:rwx
user:kk-payments:r-x
user:kk-api:rwx
group::rwx
group:kijanikiosk:r-x
mask::rwx
other::r-x
```

**Default ACL (inherited by every new file/subdirectory created inside):**
```
default:user::rwx
default:user:kk-logs:rw-
default:user:kk-payments:r--
default:user:kk-api:rw-
default:group::rwx
default:group:kijanikiosk:r-x
default:mask::rwx
default:other::r-x
```

The default ACL entries are what make this model survive log rotation
— see Section 5.

## 4. EnvironmentFile Access (Challenge A)

Each service has a dedicated EnvironmentFile under `/opt/kijanikiosk/config/`,
never under `/etc/`:

| File | Owner:Group | Mode |
|---|---|---|
| `config/api.env` | `kk-api:kijanikiosk` | `0600` |
| `config/payments-api.env` | `kk-payments:kijanikiosk` | `0600` |
| `config/logs.env` | `kk-logs:kijanikiosk` | `0600` |

Mode `0600` (owner-only) is deliberately tighter than the shared-group
model used elsewhere: because all three services share the `kijanikiosk`
group, a group-readable env file would let any of the three services read
another's configuration/secrets. `600` closes that gap. Readability is
verified per-service before any unit is started (`sudo -u <user> test -r
<path>`), confirmed passing for all three in
`post-remediation-verification.txt` Section 4.

Keeping these files under `/opt/kijanikiosk/config` rather than `/etc` is
also what allows `kk-payments.service` to run with `ProtectSystem=strict`
(which makes `/etc` read-only to the process) without needing to punch a
hole in that protection just to read its own config.

## 5. Logrotate Interaction (Requirement 3)

Logrotate's `create` directive only sets standard owner/mode on a new log
file after rotation (`0640 kk-logs kijanikiosk`, per
`/etc/logrotate.d/kijanikiosk`) — it does **not** apply ACLs. Without the
default ACL in Section 3, `kk-api` would silently lose write access to
every log file created after the first rotation, `kk-payments` would lose
read access for audit correlation, and monitoring would go blind.

The default ACL on `/opt/kijanikiosk/shared/logs` closes this gap because
default ACLs are applied by the kernel to any new file created in that
directory, regardless of which process or user created it — so a file
created by `logrotate` running as root still inherits the `kk-api`/`kk-payments`/`kk-logs`
entries automatically.

This was verified with a real forced rotation, not just a syntax check:
```
$ sudo logrotate --force /etc/logrotate.d/kijanikiosk
$ sudo -u kk-api touch /opt/kijanikiosk/shared/logs/test-write.tmp
PASS: kk-api can write after logrotate
$ sudo -u kk-payments cat /opt/kijanikiosk/shared/logs/*.log
PASS: kk-payments can read logs after rotation
```
(Full output in `post-remediation-verification.txt`, Section 8.)

## 6. Health Directory (Challenge B)

`/opt/kijanikiosk/health` did not exist in the access model prior to
Friday. It is owned `kk-logs:kijanikiosk` at `0750`: `kk-logs` (as the
service that writes structured health/logging data) owns and can write
to it directly; any member of the `kijanikiosk` group can read it without
sudo.

This has one operational consequence worth stating plainly: **group
ownership alone does not give a human operator access.** During
verification, reading `last-provision.json` as the human operator
(`anamwangi`, standing in for Amina) initially failed with `Permission
denied`, because that account was not yet a member of `kijanikiosk`. The
fix was a one-line, auditable step:
```
sudo usermod -aG kijanikiosk anamwangi
```
This is **not** something the provisioning script does automatically —
the script has no way to know which human accounts should be treated as
operators, so onboarding a new team member to read health output remains
a deliberate manual action, not an automated one. This boundary is
intentional and is called out again in `integration-notes.md`.

## 7. Summary of Changes Since Tuesday

- Health directory (`/opt/kijanikiosk/health`) added, per Challenge B
- Per-service EnvironmentFiles added at `600`, per Challenge A
- Default ACL model verified to survive real log rotation, not just
  assumed correct from a syntax check, per Requirement 3
- `config` corrected from `0777` to `0750` and kept that way idempotently
  on every provisioning run
