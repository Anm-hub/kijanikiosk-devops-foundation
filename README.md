## Week 5 — KijaniKiosk CI Pipeline

### Week 5 Branch Structure and Integration

The `feature/week5-ci-pipeline` branch was created from the `develop` integration branch. Since the Week 2 starter kit had already been merged into `develop`, the `starter-kit/` directory is visible in the Week 5 branch as inherited repository history. Any other content already present in `develop` is likewise inherited by the feature branch.

The earlier weekly deliverables are **not part of the Week 5 implementation or Week 5 changes**. The Week 5 work consists of the `Jenkinsfile` at the repository root and the evidence and documentation contained in `week5/friday/`, including the `evidence/` subfolder with the Jenkins build logs.

The Week 5 pull request compares `feature/week5-ci-pipeline` against `develop` and presents the changes introduced by Week 5. This preserves the repository's integration workflow while keeping the weekly deliverables separate.
The Week 5 deliverables are located on the branch:

`feature/week5-ci-pipeline`

inside:

`week5/friday/`

Week 5 extends the KijaniKiosk DevOps workflow by introducing a Jenkins continuous integration pipeline for the payments application. The pipeline automates linting, building, testing, security auditing, artifact archiving, and publishing versioned packages to Nexus.

### Week 5 Key Deliverables

The `week5/friday/` folder contains:

- `evidence/` — Contains the Jenkins build logs for the successful pipeline run, fault-injection runs, and recovery runs. These logs provide evidence of pipeline execution, stage failures, downstream stage behaviour, and successful recovery.
- `green-pipeline-run.txt` — Summary evidence of the successful pipeline run, including the published package version and artifact URL.
- `nexus-versions-screenshot.png` — Screenshot showing multiple published versions of the `kijanikiosk-payments` package in Nexus.
- `fault-injection-log.md` — Documents the five controlled fault-injection scenarios, their outcomes, downstream stage behaviour, and recovery results.
- `ci-pipeline-board-document.md` — Explains the pipeline, delivery stages, failure handling, and limitations in plain language.
- `credential-audit.txt` — Records the credential and secret-pattern audit checks.
- `reflection.md` — Discusses design decisions, communication between technical and non-technical audiences, and scaling considerations.
- `pr-description.md` — Summarises the work completed, a key design decision, and a proposed next improvement.

The `Jenkinsfile` is located at the repository root and defines the CI pipeline.

### Week 5 Git Evidence

The Week 5 work was developed on:

`feature/week5-ci-pipeline`

It was submitted through **Pull Request #4** targeting:

`develop`

The pull request contains the CI pipeline, supporting evidence, and documentation for review and integration.
