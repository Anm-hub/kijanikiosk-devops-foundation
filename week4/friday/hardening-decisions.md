# KijaniKiosk Staging Environment — Security Posture Summary

**Prepared for:** Nia
**Scope:** The automated provisioning and configuration pipeline for the staging environment (three servers: the customer-facing API, the payments processor, and the logging system)

## Overview

This document explains the security decisions built into how our staging environment is managed and configured now that the process is automated rather than run by hand. Terraform manages the infrastructure handoff and connectivity, while Ansible configures what runs on each server. Consistency is itself a security property: a server configured correctly once but never checked again can become a risk. A server repeatedly checked against the same specification is less likely to drift.

Every control below was tested twice: once to confirm it works, and again to confirm the automation makes no unexpected changes on a repeat run. Two decisions carry real trade-offs, which are included honestly.

## What I Did

| Control | What it does | Risk mitigated |
|---|---|---|
| Infrastructure defined as a specification | The configuration of each server — software, accounts, firewall rules, and network access policy — is written in a form Terraform and Ansible can apply automatically instead of living in an engineer's memory or a one-off checklist | Reduces inconsistent server configurations caused by missed or manually altered steps |
| Automatic verification of drift | Each repeat run compares the servers against the written specification and reports what, if anything, needs changing | Detects undocumented manual changes before they become larger operational problems |
| Isolated service identities | Each server runs its own named service account with no interactive login, limiting that account to its required resources | Limits the damage if one service is compromised and prevents unnecessary access to other services |
| Locked-down configuration files | Each service's configuration and credentials are stored where only that service account can read them | Prevents one compromised process from reading another service's credentials |
| Strict payments isolation | The payments service can write only to its required log location while system-level access is restricted. The measured systemd security exposure score is **1.4** | Reduces the ability of a compromised payments process to modify the host or use it to attack other systems |
| SSH key-pair management | Servers accept access through the matching private key rather than passwords. The private key remains outside the repository and is shared by the Terraform connection and Ansible inventory configuration | Reduces password-based compromise risk and prevents credentials from being committed to source control |
| Firewall and security-group controls | On the local Multipass path, UFW provides host-level network restriction. A cloud deployment would additionally use security groups to restrict inbound traffic to required ports and trusted sources | Prevents unnecessary network exposure and reduces the attack surface |
| Terraform remote state | Terraform state is stored in persistent shared object storage rather than only on one engineer's machine | Reduces the risk of losing state or making infrastructure decisions from an outdated local copy |

## Why These Choices Matter

The selected primary path is the local Multipass environment with persistent
MinIO remote state. This keeps the staging exercise reproducible without
requiring a cloud account, while still demonstrating the separation between
infrastructure management, configuration management, and shared state.
The same security principles transfer to a cloud deployment: restricted
network access, controlled credentials, isolated service identities, and
protected state remain necessary even though the specific infrastructure
controls change.

The strongest control in this setup is the combination of automation and
least privilege. Automation reduces configuration inconsistency, while
service-specific accounts, restricted filesystem access, firewall rules,
and systemd hardening limit what a service can do after compromise. No
single control is treated as sufficient on its own; the controls are
layered so that failure of one does not automatically result in unrestricted
access to the whole server.

## Two Things Worth Being Direct About

**First:** Terraform remote state is stored in our persistent local MinIO S3-compatible backend. MinIO provides shared state storage for this lab but does **not** provide native Terraform state locking, so simultaneous state changes are not protected by a locking mechanism. In production, I would use native locking through DynamoDB with AWS, built-in locking with GCS on GCP, or Consul as a vendor-neutral option. For this local lab, we accepted and documented the limitation rather than claim protection that is not present.

**Second:** the local Multipass path does not provide cloud security groups. UFW therefore provides the equivalent host-level network restriction locally. Dedicated servers also remove a previous convenience: the payments service could no longer read API logs directly from shared disk. That access was sacrificed deliberately for stronger service isolation. If cross-service investigation is needed, it should be rebuilt as a controlled logging or monitoring process rather than restored through shared filesystem access.

## What the Current Posture Does Not Protect Against

This document covers how the servers are built and configured. It does not cover application-code security because the application does not yet exist. It does not provide proactive alerts when verification detects a problem; someone must currently review the results. It also does not address encryption of stored data, a formal breach-response process, or protection against a compromised engineer's laptop or credentials. These are reasonable next steps once the foundation is stable under real use, but they are not implemented yet.
