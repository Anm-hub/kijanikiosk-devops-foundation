# KijaniKiosk DevOps Foundation

This repository contains the DevOps foundation work for the KijaniKiosk platform. The project is developed using a Git branch workflow to demonstrate collaboration, controlled integration, and progressive delivery.

## Repository Workflow

The repository uses the following branch structure:

* `main` — Initial repository baseline and project documentation.
* `develop` — Integration branch containing completed weekly work.
* `feature/*` — Feature branches used to develop individual weekly deliverables before integration.

Weekly work is therefore not necessarily located directly on `main`. The README provides the locations of the completed and current work.

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

## Repository Structure

```text
kijanikiosk-devops-foundation/
│
├── README.md
│
├── starter-kit/
│   ├── delivery-notes.md
│   ├── cloud-model.md
│   ├── regions-azs.md
│   ├── iam-least-privilege.md
│   ├── network-topology.png
│   └── reflection.md
│
└── week3/
    └── friday/
        ├── kijanikiosk-provision.sh
        ├── pre-provisioning-audit.txt
        ├── provision-run-dirty.log
        ├── provision-run-clean.log
        ├── access-model-final.md
        ├── kk-payments-hardening.md
        ├── hardening-decisions.md
        ├── post-remediation-verification.txt
        ├── integration-notes.md
        └── screenshots/
```

## Submission Note

The project follows a feature-branch → `develop` workflow for weekly deliverables. The `main` branch currently serves as the initial repository baseline and contains this documentation to make the location of weekly work clear.

For assessment, please select the relevant branch shown above to view the corresponding weekly deliverables.

