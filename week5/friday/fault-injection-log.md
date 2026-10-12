# Week 5 Fault-Injection Log

## Purpose

Five controlled faults were introduced independently into the KijaniKiosk CI pipeline. Each fault was used to check whether the relevant stage detected the problem and whether later stages were prevented from publishing an invalid release. After each test, the fault was removed and a successful recovery build was confirmed.

| Pipeline stage | Fault build | Injected fault and observed result | Downstream behaviour | Recovery |
|---|---:|---|---|---|
| Lint | #3 | Added an unused variable to `src/payments.js`. ESLint reported `no-unused-vars` and failed the build. | Build, Verify, Archive and Publish were skipped. The Test and Security Audit branches did not execute. | Build #4 — SUCCESS |
| Build | #5 | Added an intentional exception to `scripts/build.js`. The build stopped with `FAULT_INJECTION_BUILD`. | Verify, Archive and Publish were skipped; the Test and Security Audit branches did not execute. | Build #6 — SUCCESS |
| Verify (Test branch) | #7 | Added a deliberately failing test named `FAULT_INJECTION_TEST`. The test suite reported one failed test and nine passed tests. | Test and Security Audit ran as parallel branches. Archive and Publish were skipped because verification failed. | Build #8 — SUCCESS |
| Archive | #9 | Changed the artifact pattern to a nonexistent directory. Jenkins reported that no artifacts matched the configured pattern. | Publish was skipped. Lint, Build and Verify had completed before the archive failure. | Build #10 — SUCCESS |
| Publish | #11 | Changed the Nexus repository URL to a nonexistent repository. Nexus returned HTTP 404 during publication. | Publish failed after earlier stages had completed. No later pipeline stage existed to skip. | Build #12 — SUCCESS |

## Stage-specific rationale

- **Lint:** Unused-variable checks catch basic code-quality problems before packaging or testing proceeds.
- **Build:** An intentional build exception verifies that an unsuccessful build cannot advance to verification or release.
- **Verify:** A failing test checks that test results affect the pipeline outcome and prevent publication of unverified output. Security Audit was configured to run in parallel with Test.
- **Archive:** An invalid artifact pattern checks that Jenkins detects missing build outputs rather than silently treating an incomplete archive as successful.
- **Publish:** An invalid repository path checks that a registry publication error is reported as a pipeline failure.

## Recovery and evidence

Each fault was removed or reverted before the next test. Recovery builds #4, #6, #8, #10 and #12 completed successfully. The final successful build, #12, published version `1.1.0-d8acf23`.

The five original failure logs are stored in `evidence/`:

- `build-3-lint-fault.txt`
- `build-5-build-fault.txt`
- `build-7-test-fault.txt`
- `build-9-archive-fault.txt`
- `build-11-publish-fault.txt`

The full successful console log is stored in `green-pipeline-run.txt`. The Nexus versions screenshot provides additional evidence of versioned package publication.

These tests demonstrate the behaviour observed in this Jenkins job and environment. They do not establish that every possible fault or production failure has been tested.
