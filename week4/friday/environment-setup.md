# Environment Setup

What this environment actually consisted of, including two substitutions
made for reasons documented below. Every version number was captured
directly from the tools on the machine this pipeline was built and run
on, not assumed.

## Host

| Component | Version |
|---|---|
| OS | Ubuntu 26.04.1 LTS (codename: resolute) |
| Terraform | v1.16.4 |
| Multipass | 1.16.4 (client and daemon) |
| Docker | 29.1.3 |
| Ansible | core 2.20.1 |
| Python (Ansible control node) | 3.14.4 |
| ansible.posix collection | 2.1.0 |
| community.general collection | (already present on this machine) |

## Path Used: Primary (Multipass + Local MinIO)

No cloud account was used. All three servers are local Ubuntu 22.04 VMs
managed by Multipass; Terraform's state is stored in a locally-run MinIO
instance via the S3-compatible backend. The backend points to the local
MinIO S3 endpoint at `http://localhost:9000`.

## Substitution 1: MinIO Container Image

The course material's exact command (`minio/minio:latest` from Docker
Hub) failed with `pull access denied`. Investigation confirmed MinIO
deleted the `minio/minio` repository from Docker Hub in September 2026
as part of discontinuing their open-source Community Edition
distribution on that registry. `quay.io/minio/minio`, their documented
fallback, also returned `401 Unauthorized` at the time of this project.

Two alternatives were tried in order:

1. `bitnamilegacy/minio:latest` — pulled and started, but never printed
   a `Console:` line in its logs and never bound port 9001 internally.
   The API (port 9000) worked; the web console did not, for reasons not
   fully diagnosed. Abandoned after confirming the console port was
   genuinely unbound (`docker port` showed Docker's mapping existed,
   but nothing inside the container was listening).
2. `alpine/minio:RELEASE.2025-10-15T17-29-55Z` — this is the image
   actually used. It required the host-mounted data directory
   (`minio-data/`) to be world-writable (`chmod 777`), because this
   image runs MinIO as a non-root container user that could not write
   to a directory owned by the host user with standard permissions.
   This is acceptable here specifically because the directory holds
   only local, disposable lab state with no sensitive data and no
   network exposure beyond localhost — not a pattern to repeat for
   anything handling real data.

## Substitution 2: Backend Parameter Names

The course material's S3 backend example uses `endpoint` and
`force_path_style`. Both are deprecated in the Terraform AWS provider
version resolved by `terraform init` at the time of this project;
`terraform init` emitted deprecation warnings for both. The
configuration actually used `endpoints = { s3 = "..." }` and
`use_path_style` instead, their current replacements. Functionally
identical; this is a naming change in a provider release, not a
behavior change.

## SSH Key

A new 4096-bit RSA key pair was generated specifically for this project
(`~/.ssh/id_rsa`), with no passphrase, since both Terraform's
provisioner and Ansible need to authenticate non-interactively. The
public key was pushed to all three VMs via `multipass exec ... >>
~/.ssh/authorized_keys` before any Terraform or Ansible command was run
against them, and connectivity was verified manually (plain `ssh`) and
via `ansible -m ping` before either tool's real work began.

## Note on Security Groups

Cloud providers attach a security group (a virtual firewall) to each
VM Terraform creates. Multipass has no equivalent construct -- there is
no cloud API for Terraform to create one against. On this path, the
equivalent control is the firewall configuration applied directly
inside each VM by Ansible (kijanikiosk.yml, Phase 5: ufw default-deny,
SSH allowed, service port restricted to loopback), not a
Terraform-managed resource. This is a deliberate consequence of the
local/no-cloud-account path, not an omission.
