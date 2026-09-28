# Integration Notes & Technical Decisions

Each section below states what the conflict was, what options were
considered, what was chosen, and why — per the assignment's required
format. This replaces the earlier partial draft, which covered account
shells, ACL defaults, package holds, and firewall drift, but predated
the EnvironmentFile work, the health directory, and the logrotate
reload decision that came later in the project.

## Challenge A: ProtectSystem=strict and the EnvironmentFile

**The conflict:** `kk-payments.service` needs `ProtectSystem=strict` to
hit its hardening target — this directive makes `/etc` (and most of the
filesystem outside a small allow-list) read-only to the process. But the
service also needs to read its own configuration via `EnvironmentFile=`,
and a naive setup would have put that file under `/etc/kijanikiosk/`,
which `ProtectSystem=strict` would have blocked from being read at all.

**Options considered:**
1. Add `ReadWritePaths=/etc/kijanikiosk` (or a narrower `ReadOnlyPaths=`)
   to carve out an exception in `/etc` specifically for the config file.
2. Move the config file out of `/etc` entirely, to a path that
   `ProtectSystem=strict` was never going to touch in the first place.

**What was chosen:** Option 2. All three services' `EnvironmentFile=`
paths live under `/opt/kijanikiosk/config/`, which is unaffected by
`ProtectSystem=strict` regardless of how strict that directive gets in
future systemd versions.

**Why:** Punching a hole back into `/etc` for one file defeats part of
the point of enabling `ProtectSystem=strict` in the first place — it
turns a blanket protection into a protection-with-an-exception that has
to be remembered and maintained. Keeping config entirely outside the
path `ProtectSystem=strict` governs means the directive can be left at
its strictest setting with zero exceptions, and there's nothing to
misconfigure later. Verified working: `sudo -u kk-payments cat
/opt/kijanikiosk/config/payments-api.env` succeeds, and the unit starts
cleanly with `ProtectSystem=strict` in place (see
`kk-payments-hardening.md`, Stage 1 onward).

## Challenge B: The Monitoring User and ACL Defaults

**The conflict:** The health check (Phase 8) writes
`/opt/kijanikiosk/health/last-provision.json`, but that directory did
not exist in the access model established earlier in the week.
Tuesday's model defined access for `config` and `shared/logs` only.
Someone needed to decide who owns the health directory, who can write to
it, and who can read it without `sudo` — including a human operator, not
just the service accounts.

**Options considered:**
1. Leave the file owned by `root` (the user the provisioning script runs
   as), and require `sudo` for anyone who needs to read it.
2. Own it by `kk-logs` (the service responsible for structured
   logging/health data) with group `kijanikiosk`, so any member of that
   group can read it without `sudo`.

**What was chosen:** Option 2 — `kk-logs:kijanikiosk`, mode `750`.

**Why:** Requiring `sudo` just to check a health status file would make
routine monitoring more friction than it needs to be, and `root`
ownership by default (option 1) was really just an accident of which
account happens to run the script, not a deliberate choice. Group
ownership means any future monitoring tooling, or a human operator added
to the `kijanikiosk` group, can read the file directly.

**What this surfaced during testing:** This is the one place the
provisioning script's correctness and an operator's actual access
diverged in practice. The directory and file permissions were correct
from the first run, but the human operator account (`anamwangi`,
standing in for Amina) was not yet a member of the `kijanikiosk` group,
so `cat /opt/kijanikiosk/health/last-provision.json` returned
`Permission denied` even though every automated check in the script's
own Phase 8 passed. The fix was one command:
`sudo usermod -aG kijanikiosk anamwangi`. This is deliberately **not**
something the provisioning script does on its own — the script has no
way to know which human accounts should be treated as operators, so
onboarding a person to read health output remains a manual, auditable
step rather than an automated one. Full before/after evidence is in
`post-remediation-verification.txt`, Section 9.

## Challenge C: logrotate postrotate and PrivateTmp

**The conflict:** The logrotate config needs a `postrotate` step to tell
`kk-logs.service` to re-open its log file handles after rotation. The
standard pattern for this is `systemctl reload kk-logs.service`. But
`kk-logs.service` runs as a placeholder (`ExecStart=/usr/bin/sleep
infinity`, standing in for real application code that lands in Week 4)
and implements no `ExecReload=` directive — so `systemctl reload` would
simply fail, since there's nothing telling systemd how to perform a
reload for this unit.

**Options considered:**
1. Add a no-op `ExecReload=/bin/true` to the unit so `systemctl reload`
   technically succeeds.
2. Use `systemctl restart` instead of `reload` in the `postrotate`
   script, accepting a brief interruption during rotation.
3. Leave `postrotate` empty and rely on the application re-opening file
   handles some other way once it exists.

**What was chosen:** Option 2.

**Why:** Option 1 was rejected because it would be actively misleading —
adding `ExecReload=/bin/true` makes `systemctl reload` "succeed" while
doing nothing at all, which would look correct in a status check while
silently never actually reloading the log handles. That is worse than
an honest failure, because it hides the problem instead of surfacing it.
Option 3 was rejected because it defers a decision that needs to be made
now, on the assumption that whoever writes the real application code
later will remember to handle this — an assumption not worth relying on.
Option 2 is the only one of the three that is both true to what
currently happens and doesn't require every future engineer to
rediscover this constraint. The trade-off (a brief restart-driven gap
during rotation) is accepted and documented rather than hidden, and
`logrotate --debug` and a forced rotation both confirm the config is
otherwise valid (see `post-remediation-verification.txt`, Sections 7-8).

## Challenge D: The Dirty VM and Package Holds

**The conflict:** By Friday, `curl` was already installed on the VM, and
had been held via `apt-mark hold` earlier in the week with no version
pin recorded anywhere. Re-running the provisioning script needed to
either trust whatever version happened to already be installed, or
verify it against something concrete — and if a mismatch were ever
found, the script needed a policy for what to do about it.

**Options considered:**
1. Silently reinstall/downgrade to a hardcoded target version whenever a
   mismatch is detected, with no human involved.
2. Record the currently-installed version the first time the script
   runs successfully, treat that as the canonical pin going forward, and
   fail loudly (exit non-zero, refuse to proceed) if a later run finds
   the installed version has drifted from that recorded pin.

**What was chosen:** Option 2.

**Why:** This server will host a payments service. An unattended
version change — even one intended to "fix" drift — is exactly the kind
of automatic action that should require a human to look at it first on
a system handling financial transactions. Option 1 optimizes for the
script always completing; option 2 optimizes for a human being told
something changed before anything else happens. Given the stakes of
this particular server, option 2's extra friction is the correct
trade-off. The recorded pin is stored at
`/opt/kijanikiosk/.provision-state/curl.pin` and is checked on every
run (see `kijanikiosk-provision.sh`, Phase 1).
