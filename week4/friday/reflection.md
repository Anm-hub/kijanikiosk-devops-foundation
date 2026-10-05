# Reflection

## 1. Where two requirements turned out to be in conflict

Challenge D names this conflict explicitly, and it is real: `kk-payments`
needs `ProtectSystem=strict` to hit its hardening score, but that
directive makes `/etc` read-only to the running process. The service
also needs `EnvironmentFile=` to read its own configuration. If that
file had been placed under `/etc/kijanikiosk/`, the two requirements
would have been impossible to satisfy simultaneously: harden the
service, or let it read its own config, pick one.

The resolution was the same one used in Week 3: keep every service's
`EnvironmentFile=` under `/opt/kijanikiosk/config/`, a path
`ProtectSystem=strict` never touches at all, rather than carving a
`ReadWritePaths=` exception back into `/etc`. What I learned repeating
this decision in a second context is that it generalizes: the fix
wasn't "relax the hardening for this one file," it was "design the
file's location so the hardening never has to be relaxed." A directive
that needs an exception the moment it's applied for real is a sign the
layout around it is wrong, not that the directive is too strict.

## 2. One sentence, rewritten for Tendo instead of Nia

**For Nia (from hardening-decisions.md):**
> "Access to each server restricted by SSH key: only a specific
> cryptographic key, held by the engineer running this process, can
> connect to any of the three servers at all."

**For Tendo:**
> "Each Multipass VM's `authorized_keys` was seeded with the public half
> of a passphrase-less 4096-bit RSA key before any Terraform or Ansible
> command ran; `group_vars/kijanikiosk.yml` points
> `ansible_ssh_private_key_file` at the matching private key, and
> `modules/app_server`'s `connection` block does the same, so both tools
> authenticate with the identical credential rather than two
> independently-managed ones."

**What's lost:** none of this is wrong for Nia's version, but it also
gives her nothing she could act on — she cannot verify a key length or
a file path, and she shouldn't need to.

**What's gained:** Tendo's version is checkable. He can confirm the key
length matches the project's own key-management policy, confirm both
tools reference the *same* key rather than two that happen to produce
the same result today, and know exactly which file to look in if SSH
ever stops working. The translation trades a sentence anyone can read
for a sentence only an engineer can verify — and a reviewer needs the
second kind.

## 3. The single most fragile handoff

The IP lookup. `modules/app_server/main.tf`'s `data "external"` block
runs `multipass info <name> --format json`, pipes it into an inline
Python one-liner, and expects a specific JSON shape:
`d["info"][vm_name]["ipv4"][0]`. Every other part of this pipeline fails
loudly when something is wrong — Terraform refuses to apply an invalid
plan, Ansible reports a task as `failed`. This one does not have that
property. If Multipass changes its `--format json` output structure in
a future version, or a VM is renamed, or `ipv4` is ever an empty list
instead of missing entirely (a VM that's running but hasn't finished
acquiring a DHCP lease yet), the Python script raises a `KeyError` or
an `IndexError` with no context about *which* assumption broke, and
Terraform surfaces that as an opaque data source failure rather than a
clear, specific error.

This is also the one part of the pipeline built entirely for the local
path with no cloud equivalent to fall back on — the optional path's
`data "aws_ami"` or similar is a first-class, maintained Terraform data
source; this one is a shell command wrapped in a string, held together
by an assumption about a third-party tool's undocumented JSON shape. To
make this robust for a real target environment, I would need to know
Multipass's actual guarantees about that JSON structure across
versions (not just what it happens to output today), and I would
rewrite the script to fail with a specific, readable error — "VM
`kijanikiosk-api` has no IPv4 address yet, is it still booting?" —
rather than let a raw Python traceback surface as the first signal
something is wrong.
