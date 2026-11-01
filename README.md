# KijaniKiosk DevOps Foundation

This repository contains the DevOps foundation work for the KijaniKiosk platform. The project uses a Git feature-branch workflow to demonstrate collaboration, infrastructure automation, continuous integration, controlled integration, security, containerisation, and progressive delivery.

## Repository Workflow

Weekly deliverables are developed and documented on dedicated feature branches. Each completed week's work is submitted through a pull request targeting `develop`.

The `main` branch maintains the repository overview and navigation documentation, while `develop` serves as the integration branch. Feature branches preserve the work completed for each weekly project.

## Branch Structure

The repository includes the following weekly feature branches:

- `feature/starter-kit-files` — Week 2: DevOps Foundation. Covers cloud service models, region and availability-zone selection, least-privilege IAM, network topology, and Flow, Feedback, and Learning.
- `feature/week3-production-foundation` — Week 3: Production Server Foundation. Covers idempotent provisioning, system hardening, service accounts, systemd, firewall rules, journald, logrotate, and verification evidence.
- `feature/week4-iac-pipeline` — Week 4: Full Infrastructure-as-Code Pipeline. Covers Terraform, Ansible, remote state configuration, automated infrastructure provisioning, server hardening, idempotency, and deployment verification.
- `feature/week5-ci-pipeline` — Week 5: Board-Ready CI Pipeline. Covers Jenkins continuous integration, parallel testing and security auditing, artifact archiving and publishing, fault injection, recovery evidence, credential auditing, and board-facing documentation.
- `feature/week8-container-delivery` — Week 8: Container Delivery Pipeline. Covers production container builds, image verification, private registry publishing, Kubernetes deployment, service exposure, service discovery, and self-healing verification.

The main repository branches have the following roles:

- `main` — Repository baseline and project documentation. The README is maintained here to guide visitors through the weekly deliverables and their respective branches.
- `develop` — Integration branch for weekly deliverables submitted through pull requests.
- `feature/*` — Feature branches used to develop, test, document, and submit individual weekly deliverables.

## Weekly Pull Request Status

| Week | Feature Branch | Pull Request | Status |
|---|---|---|---|
| Week 2 | `feature/starter-kit-files` | PR #1 | Merged into `develop` |
| Week 3 | `feature/week3-production-foundation` | PR #2 | Open |
| Week 4 | `feature/week4-iac-pipeline` | PR #3 | Open |
| Week 5 | `feature/week5-ci-pipeline` | PR #4 | Open |
| Week 8 | `feature/week8-container-delivery` | PR #5 | Open |

The pull requests for Weeks 3, 4, 5, and 8 were submitted targeting `develop` and remain open. Week 2 is the only project currently merged into `develop`.

---

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

Inside:

`week3/friday/`

The folder contains the production provisioning script, execution logs, system-hardening documentation, access-control documentation, verification evidence, integration notes, and screenshots.

### Week 3 Git Evidence

The work was developed on `feature/week3-production-foundation` and submitted through PR #2 targeting `develop`. The pull request remains open.

## Week 4 — KijaniKiosk Full IaC Pipeline

The Week 4 deliverables are located on:

`feature/week4-iac-pipeline`

Inside:

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

- `terraform/` — Terraform root configuration and reusable app_server module.
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

The `kk-payments` service was verified as active, with a documented `systemd-analyze security` score of 1.4, meeting the required Week 4 security target.

The documentation also explains the limitation that local MinIO provides an S3-compatible remote state backend but does not provide native Terraform state locking. Production alternatives are documented in the Week 4 hardening decisions.

### Week 4 Git Evidence

The work was developed on `feature/week4-iac-pipeline` and submitted through PR #3 targeting `develop`. The pull request remains open.

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

The work was developed on `feature/week5-ci-pipeline` and submitted through PR #4 targeting `develop`. The pull request remains open.

## Week 8 — KijaniKiosk Container Delivery Pipeline

The Week 8 deliverables are located on:

`feature/week8-container-delivery`

The weekly work is organised into:

- `week8/monday/`
- `week8/tuesday/`
- `week8/wednesday/`
- `week8/thursday/`
- `week8/friday/`

Week 8 extends the KijaniKiosk DevOps workflow into production container delivery. The project progresses from creating and verifying a production image to publishing it in a private registry, deploying it with multiple replicas, exposing the service, and testing automatic recovery when an application instance is removed.

### Week 8 Key Deliverables

- **Monday** — Initial container build configuration and Docker build-context exclusions.
- **Tuesday** — Production multi-stage container build, image exclusions, and verification output.
- **Wednesday** — Image tagging and private registry publishing script, with registry execution evidence.
- **Thursday** — Deployment and service manifests, deployment output, and an initial self-healing test.
- **Friday** — Consolidated production Dockerfile, deployment and service manifests, build verification, registry push and fresh-pull evidence, deployment output, service checks, self-healing rerun, comparison document, reflection, and PR summary.

### Week 8 Verification Evidence

The final production image was built and verified with a size of 82 MB, compared with the 274 MB baseline image. The image ran as a non-root user, and development tooling was excluded from the production image.

The image was tagged using the application version and source Git commit identifier, published to a private registry, removed from the local image cache, and successfully pulled again.

The application was deployed with two replicas. The service was exposed through a NodePort, and both external and in-cluster health checks returned a successful response. A self-healing test confirmed that the deployment replaced a manually deleted application instance and restored two ready replicas in 33 seconds.

The Friday folder contains the supporting evidence and written assessment documents.

For a detailed guide to the Week 8 folder structure and deliverables, see `week8/README.md` on the Week 8 feature branch.

### Week 8 Git Evidence

The work was developed on `feature/week8-container-delivery` and submitted through PR #5 targeting `develop`. The pull request remains open.

---

## Repository Structure

The following is a simplified overview of the repository's main files and weekly deliverables. Week 3, Week 4, Week 5, and Week 8 content is documented on their respective feature branches. Week 2 is integrated into `develop`.

```text
kijanikiosk-devops-foundation/
│
├── README.md
├── Jenkinsfile
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

week8/                                   # Week 8 deliverables
    ├── monday/
    ├── tuesday/
    ├── wednesday/
    ├── thursday/
    ├── friday/
    └── README.md
```

## Submission Note

The project uses a feature-branch workflow for weekly deliverables:

- Week 2 → `feature/starter-kit-files`
- Week 3 → `feature/week3-production-foundation`
- Week 4 → `feature/week4-iac-pipeline`
- Week 5 → `feature/week5-ci-pipeline`
- Week 8 → `feature/week8-container-delivery`

The `main` branch serves as the repository documentation and baseline. The `develop` branch serves as the integration branch. Each weekly pull request identifies the feature branch containing the relevant assessment work.

For assessment, select the relevant branch shown above to view the corresponding weekly deliverables.
