# KijaniKiosk DevOps Foundation

This repository contains the DevOps foundation work for the KijaniKiosk platform. The project uses a Git feature-branch workflow to demonstrate collaboration, infrastructure automation, continuous integration, controlled integration, security, and progressive delivery.

## Repository Workflow

Each week's deliverables are developed and documented on a dedicated feature branch. The work is then submitted through a pull request targeting `develop`. The `main` branch maintains the repository overview and documentation, while `develop` serves as the integration branch.

### Branch Structure

The repository includes the following weekly feature branches:

- `feature/starter-kit-files` — **Contains the Week 2: DevOps Foundation work**, covering cloud service models, region and availability-zone selection, least-privilege IAM, network topology, and Flow, Feedback, and Learning.
- `feature/week3-production-foundation` — **Contains the Week 3: Production Server Foundation work**, covering idempotent provisioning, system hardening, service accounts, systemd, firewall rules, journald, logrotate, and verification evidence.
- `feature/week4-iac-pipeline` — **Contains the Week 4: Full Infrastructure-as-Code Pipeline work**, covering Terraform, Ansible, remote state configuration, automated infrastructure provisioning, server hardening, idempotency, and deployment verification.
- `feature/week5-ci-pipeline` — **Contains the Week 5: Board-Ready CI Pipeline work**, covering the Jenkins continuous integration pipeline, parallel testing and security auditing, artifact archiving and publishing, fault injection, recovery evidence, credential auditing, and board-facing documentation.

The main repository branches have the following roles:

- `main` — Repository baseline and project documentation. The README is maintained here to guide visitors through the weekly deliverables and their respective branches.
- `develop` — Integration branch for weekly deliverables submitted through pull requests.
- `feature/*` — Feature branches used to develop, test, document, and submit individual weekly deliverables.

### Weekly Integration Status

| Week | Feature Branch | Pull Request | Integration Status |
|---|---|---|---|
| Week 2 | `feature/starter-kit-files` | PR #1 | Merged into `develop` |
| Week 3 | `feature/week3-production-foundation` | PR #2 | Open, targeting `develop` |
| Week 4 | `feature/week4-iac-pipeline` | PR #3 | Open, targeting `develop` |
| Week 5 | `feature/week5-ci-pipeline` | PR #4 | Open, targeting `develop` |

The status table reflects the current known state of the pull requests. Weekly deliverables remain on their respective feature branches until integrated into `develop`.

## Week 2 — KijaniKiosk DevOps Foundation

The Week 2 deliverables are located in:

`starter-kit/`

The folder contains:

- `delivery-notes.md` — Flow, Feedback, and Learning in the DevOps workflow.
- `cloud-model.md` — Comparison of IaaS, PaaS, and SaaS and the selected cloud approach.
- `regions-azs.md` — Region and multi-availability-zone reliability reasoning.
- `iam-least-privilege.md` — Least-privilege IAM design for a defined application task.
- `network-topology.png` — Public and private subnet architecture and routing.
- `reflection.md` — Project reflection.

### Week 2 Git Evidence

The work was developed on `feature/starter-kit-files`, submitted through PR #1, and merged into `develop`.

## Week 3 — KijaniKiosk Production Server Foundation

The Week 3 deliverables are located on:

`feature/week3-production-foundation`

inside:

`week3/friday/`

The folder contains the production provisioning script, execution logs, system-hardening documentation, access-control documentation, verification evidence, integration notes, and screenshots.

### Week 3 Git Evidence

The work was developed on `feature/week3-production-foundation` and submitted through PR #2 targeting `develop`.

## Week 4 — KijaniKiosk Full IaC Pipeline

The Week 4 deliverables are located on:

`feature/week4-iac-pipeline`

inside:

`week4/friday/`

Week 4 extends the production server foundation into an Infrastructure-as-Code and configuration-management workflow using Terraform and Ansible.

The primary lab environment uses:

- Multipass Ubuntu 22.04 virtual machines for the API, payments, and logs servers.
- Local MinIO as the S3-compatible remote Terraform state backend.
- Terraform for infrastructure discovery, SSH connectivity validation, state management, and outputs.
- Ansible for repeatable seven-phase server configuration.
- systemd, UFW, journald, logrotate, and least-privilege service accounts for server hardening.

### Week 4 Key Deliverables

The `week4/friday/` folder contains:

- `terraform/` — Terraform root configuration and reusable `app_server` module.
- `ansible/` — Ansible playbook, inventory, group variables, host variables, and templates.
- `pipeline.sh` — Automated Terraform-to-Ansible deployment pipeline.
- `pipeline-run1.log` — Evidence from the first pipeline run.
- `pipeline-run2.log` — Evidence from the second pipeline run.
- `week4-second-plan-proof.txt` — Terraform no-change plan evidence.
- `hardening-decisions.md` — Security and hardening decisions.
- `environment-setup.md` — Lab environment, tooling, and setup documentation.
- `destroy-output.txt` — Terraform destroy evidence and explanation of the local VM lifecycle.
- `reflection.md` — Week 4 project reflection.

### Week 4 Verification Evidence

The pipeline was executed twice successfully. The second Terraform run reported no infrastructure changes, while the repeated Ansible run reported `changed=0` on all three servers, demonstrating idempotent configuration.

The `kk-payments` service was verified as active, with a documented `systemd-analyze security` score of **1.4**, meeting the required Week 4 security target.

The documentation also explains the limitation that local MinIO provides an S3-compatible remote state backend but does not provide native Terraform state locking. Production alternatives are documented in the Week 4 hardening decisions.

### Week 4 Git Evidence

The work was developed on `feature/week4-iac-pipeline` and submitted through PR #3 targeting `develop`.

## Week 5 — KijaniKiosk Board-Ready CI Pipeline

The Week 5 deliverables are located on:

`feature/week5-ci-pipeline`

The primary evidence and documentation are stored in:

`week5/friday/`

Week 5 extends the DevOps workflow into continuous integration and artifact delivery for the KijaniKiosk payments application. The pipeline uses Jenkins and Docker to run automated checks, build the application, archive the output, and publish a versioned package to a Nexus npm registry.

### Week 5 Key Deliverables

The repository root contains:

- `Jenkinsfile` — Declarative Jenkins pipeline configuration for linting, building, parallel verification, artifact archiving, and publishing.

The `week5/friday/` folder contains:

- `green-pipeline-run.txt` — Evidence from a successful pipeline run, including the Docker image, parallel stages, masked credentials, versioned artifact URL, and execution output.
- `nexus-versions-screenshot.png` — Screenshot showing multiple published versions of the `kijanikiosk-payments` package in Nexus.
- `fault-injection-log.md` — Documentation of five controlled pipeline failures, their observed outcomes, and successful recovery runs.
- `ci-pipeline-board-document.md` — Plain-language explanation of the CI delivery process, stage confirmations, failure handling, and scope limitations.
- `credential-audit.txt` — Results of credential and secret-pattern checks against Git history and saved evidence.
- `reflection.md` — Reflection on design decisions, communication between technical and non-technical audiences, and scaling considerations.
- `pr-description.md` — Pull request description covering the work completed, a key design decision, and a proposed next improvement.

### Week 5 Pipeline Stages

The pipeline follows five main stages:

1. **Lint** — Checks source code for linting errors.
2. **Build** — Builds the application and verifies that the expected output exists.
3. **Verify** — Runs automated tests and a production-dependency security audit in parallel.
4. **Archive** — Archives and fingerprints the successful build artifacts in Jenkins.
5. **Publish** — Publishes a versioned package to the Nexus registry.

The package version includes the application's package version and a short Git commit identifier, making it easier to trace a published artifact back to its source revision.

### Week 5 Fault Injection and Recovery

Five controlled fault-injection scenarios were documented, covering Lint, Build, Verify, Archive, and Publish. Each scenario records the injected fault, the pipeline's response, the downstream stages that ran or were skipped, and the recovery run.

The successful pipeline evidence records the published package version and artifact URL. The execution completed in approximately 93 seconds, comfortably below the assignment's ten-minute runtime target.

The credential audit documents its checks and their limitations. The security audit is scoped to production dependencies; it should not be interpreted as evidence that every development dependency is free of vulnerabilities.

### Week 5 Git Evidence

The work was developed on `feature/week5-ci-pipeline` and submitted through **PR #4**, targeting `develop`.

The pull request is intended to integrate the Week 5 CI pipeline and its supporting evidence into the repository's integration branch.

## Repository Structure

The following is a simplified overview of the repository's main files and weekly deliverables. Week 3, Week 4, and Week 5 content is shown on its respective feature branch; Week 2 is integrated into `develop`.

```text
kijanikiosk-devops-foundation/
│
├── README.md
├── Jenkinsfile                         # Week 5 CI pipeline
├── starter-kit/                         # Week 2 deliverables
│   ├── delivery-notes.md
│   ├── cloud-model.md
│   ├── regions-azs.md
│   ├── iam-least-privilege.md
│   ├── network-topology.png
│   └── reflection.md
│
├── week3/
│   └── friday/                          # Week 3 deliverables
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
├── week4/
│   └── friday/                          # Week 4 deliverables
│       ├── terraform/
│       ├── ansible/
│       ├── pipeline.sh
│       ├── pipeline-run1.log
│       ├── pipeline-run2.log
│       ├── week4-second-plan-proof.txt
│       ├── hardening-decisions.md
│       ├── environment-setup.md
│       ├── destroy-output.txt
│       └── reflection.md
│
└── week5/
    └── friday/                          # Week 5 evidence and documentation
        ├── green-pipeline-run.txt
        ├── nexus-versions-screenshot.png
        ├── fault-injection-log.md
        ├── ci-pipeline-board-document.md
        ├── credential-audit.txt
        ├── reflection.md
        └── pr-description.md
```

## Submission Note

The project uses a feature-branch workflow for weekly deliverables:

- Week 2 → `feature/starter-kit-files`
- Week 3 → `feature/week3-production-foundation`
- Week 4 → `feature/week4-iac-pipeline`
- Week 5 → `feature/week5-ci-pipeline`

The main branch currently serves as the repository documentation and baseline. For assessment, please select the relevant branch shown above to view the corresponding weekly deliverables.
