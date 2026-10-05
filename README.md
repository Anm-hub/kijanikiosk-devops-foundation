# KijaniKiosk DevOps Foundation

This repository contains the DevOps foundation work for the KijaniKiosk platform. The project is developed using a Git branch workflow to demonstrate collaboration, controlled integration, infrastructure automation, and progressive delivery.

## Repository Workflow

The repository follows a feature-branch → `develop` workflow for weekly deliverables. Each week's work is developed and tested on its own feature branch before being submitted for integration into `develop`.

### Branch Structure

The repository currently contains the following feature branches:

* `feature/starter-kit-files` — Contains the **Week 2 DevOps Foundation** work, including cloud model selection, region and availability-zone reasoning, least-privilege IAM, network topology, and Flow/Feedback/Learning documentation.
* `feature/week3-production-foundation` — Contains the **Week 3 Production Server Foundation** work, including the idempotent provisioning script, system hardening, service accounts, systemd configuration, firewall rules, journald, logrotate, verification evidence, and integration documentation.
* `feature/week4-iac-pipeline` — Contains the **Week 4 Full IaC Pipeline** work, including Terraform, Ansible, the automated Terraform-to-Ansible pipeline, remote state configuration, server hardening, idempotency evidence, and deployment verification.

The main repository branches have the following roles:

* `main` — Repository baseline and project documentation. The README is maintained here to provide a clear guide to the weekly deliverables and their respective branches.
* `develop` — Integration branch. **Week 2 is currently the only weekly deliverable merged into this branch.**
* `feature/*` — Feature branches used to develop, test, document, and submit individual weekly deliverables before integration.

### Weekly Integration Status

| Week | Feature Branch | Pull Request | Integration Status |
|---|---|---|---|
| Week 2 | `feature/starter-kit-files` | PR #1 | Merged into `develop` |
| Week 3 | `feature/week3-production-foundation` | PR #2 | Open, targeting `develop` |
| Week 4 | `feature/week4-iac-pipeline` | PR #3 | Open, targeting `develop` |

Weekly work is therefore intentionally kept on its respective feature branch until the corresponding pull request is integrated into `develop`. The sections below identify the location and contents of each week's work.

## Week 2 — KijaniKiosk DevOps Foundation

The Week 2 deliverables are located on the `develop` branch inside:

`starter-kit/`

The folder contains:

* `delivery-notes.md` — Flow, Feedback, and Learning in the DevOps workflow.
* `cloud-model.md` — IaaS, PaaS, and SaaS comparison and the selected cloud approach.
* `regions-azs.md` — Region and multi-availability-zone reliability reasoning.
* `iam-least-privilege.md` — Least-privilege IAM design for a defined application task.
* `network-topology.png` — Public/private subnet architecture and routing.
* `reflection.md` — Project reflection.

### Week 2 Git Evidence

The Week 2 work was developed on:

`feature/starter-kit-files`

It was submitted through **Pull Request #1** and merged into:

`develop`

## Week 3 — KijaniKiosk Production Server Foundation

The Week 3 deliverables are located on the branch:

`feature/week3-production-foundation`

inside:

`week3/friday/`

The folder contains the production provisioning script, execution logs, system hardening documentation, access-control documentation, verification evidence, integration notes, and screenshots.

### Week 3 Git Evidence

The Week 3 work was developed on:

`feature/week3-production-foundation`

It was submitted through **Pull Request #2** targeting:

`develop`

The pull request contains the complete Week 3 production foundation work.

## Week 4 — KijaniKiosk Full IaC Pipeline

The Week 4 deliverables are located on the branch:

`feature/week4-iac-pipeline`

inside:

`week4/friday/`

Week 4 extends the production foundation into a full Infrastructure-as-Code and configuration-management pipeline using Terraform and Ansible.

The primary lab environment uses:

* Multipass Ubuntu 22.04 virtual machines for the API, payments, and logs servers.
* Local MinIO as the S3-compatible remote Terraform state backend.
* Terraform for infrastructure discovery, SSH connectivity validation, state management, and outputs.
* Ansible for repeatable seven-phase server configuration.
* Systemd, UFW, journald, logrotate, and least-privilege service accounts for production hardening.

### Week 4 Key Deliverables

The `week4/friday/` folder contains:

* `terraform/` — Terraform root configuration and reusable `app_server` module.
* `ansible/` — Ansible playbook, inventory, group variables, host variables, and templates.
* `pipeline.sh` — Automated Terraform-to-Ansible deployment pipeline.
* `pipeline-run1.log` — Evidence from the first clean pipeline run.
* `pipeline-run2.log` — Evidence from the second clean pipeline run.
* `week4-second-plan-proof.txt` — Terraform no-change plan evidence.
* `hardening-decisions.md` — Nia-facing security and hardening decisions.
* `environment-setup.md` — Lab environment, tooling, and setup documentation.
* `destroy-output.txt` — Terraform destroy evidence and explanation of the local VM lifecycle.
* `reflection.md` — Week 4 project reflection.

### Week 4 Verification Evidence

The pipeline was executed twice successfully.

The second Terraform run reported that the infrastructure matched the configuration with no changes. The Ansible repeat run reported `changed=0` on all three servers, demonstrating idempotent configuration.

The `kk-payments` service was also verified as active with a documented `systemd-analyze security` score of **1.4**, satisfying the required Week 4 security target.

The Week 4 environment intentionally documents the limitation that local MinIO provides S3-compatible remote state but does not provide native Terraform state locking. Production alternatives are documented in the Week 4 hardening decisions.

### Week 4 Git Evidence

The Week 4 work was developed on:

`feature/week4-iac-pipeline`

It was submitted through **Pull Request #3** targeting:

`develop`

## Repository Structure

```text
kijanikiosk-devops-foundation/
│
├── README.md
├── starter-kit/
│   ├── delivery-notes.md
│   ├── cloud-model.md
│   ├── regions-azs.md
│   ├── iam-least-privilege.md
│   ├── network-topology.png
│   └── reflection.md
│
├── week3/
│   └── friday/
│       ├── kijanikiosk-provision.sh
│       ├── pre-provisioning-audit.txt
│       ├── provision-run-dirty.log
│       ├── provision-run-clean.log
│       ├── access-model-final.md
│       ├── kk-payments-hardening.md
│       ├── hardening-decisions.md
│       ├── post-remediation-verification.txt
│       ├── integration-notes.md
│       └── screenshots/
│
└── week4/
    └── friday/
        ├── terraform/
        ├── ansible/
        ├── pipeline.sh
        ├── pipeline-run1.log
        ├── pipeline-run2.log
        ├── week4-second-plan-proof.txt
        ├── hardening-decisions.md
        ├── environment-setup.md
        ├── destroy-output.txt
        └── reflection.md

##Submission Note

The project follows a feature-branch workflow for weekly deliverables.

Week 2 → feature/starter-kit-files
Week 3 → feature/week3-production-foundation 
Week 4 → feature/week4-iac-pipeline 

The main branch currently serves as the repository documentation and baseline. For assessment, please select the relevant branch shown above to view the corresponding weekly deliverables.
