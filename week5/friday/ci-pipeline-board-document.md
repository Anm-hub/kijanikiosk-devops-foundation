# KijaniKiosk CI Pipeline: Board-Ready Delivery

## Purpose

The KijaniKiosk payments pipeline provides a repeatable way to check, package and publish application changes. Instead of relying on a developer to remember every release step, Jenkins runs the defined checks in sequence whenever the configured job receives a build. The goal is to catch problems early, keep release evidence, and make published packages identifiable.

## From a change to a published package

The process begins with the application's source code and its package configuration. Jenkins runs the pipeline using a pinned Node.js container image, `node:18.20.8-alpine`, so the build uses a known runtime rather than whichever Node.js version happens to be installed on a machine. The pipeline installs the project's dependencies and checks the code before attempting to release anything.

| Stage | What it does | Confirmation or failure response |
|---|---|---|
| Lint | Checks source code for configured style and code-quality problems. | ESLint must pass before the build stage proceeds. |
| Build | Produces the application output in `dist/`. | The output directory must exist and contain files. |
| Verify | Runs automated tests and a production-dependency security audit in parallel. | A failed test or audit prevents the pipeline from reaching Archive and Publish. |
| Archive | Stores the generated build output in Jenkins and fingerprints the artifacts. | Jenkins must find files matching the configured artifact pattern. |
| Publish | Publishes a versioned npm package to the hosted Nexus repository. | A successful registry response and the final success message confirm publication. |

## Why stages run in this order

Lint and Build are early checks: there is little value in spending time verifying or releasing code that cannot pass basic quality checks or produce usable output. Within Verify, the Test and Security Audit branches run in parallel to make better use of time. Both must complete successfully for the pipeline to advance. Archive then preserves the build output, and Publish is last so an unsuccessful change is not released through this pipeline.

The package version combines the version in `package.json` with a short Git commit identifier. For example, build #12 published `1.1.0-d8acf23`. This makes each published build traceable to a specific source revision and reduces confusion between packages that share the same base version. Jenkins also retains a bounded history of recent builds, applies a pipeline timeout, prevents concurrent executions of the same job, and cleans the workspace after the run.

## What Happens When Something Goes Wrong

A failed check marks the pipeline as unsuccessful and prevents dependent later stages from running. The team can inspect the Jenkins console output to see which stage failed and use the retained log as evidence. This was tested deliberately: an unused variable stopped Lint; an injected exception stopped Build; a failing automated test stopped Verify; a nonexistent artifact pattern stopped Archive; and an invalid Nexus repository path caused Publish to fail. Each fault was removed, and the subsequent recovery build returned to success.

This behaviour matters because a failed release attempt should be visible rather than mistaken for a successful delivery. It also makes troubleshooting more focused: the team can start with the stage that reported the error instead of assuming that the entire application is at fault.

## Security and release visibility

Nexus stores the versioned npm packages, while Jenkins records the build and publication result. Publication credentials are supplied through Jenkins credentials rather than hard-coded as a password in the pipeline. The publish step disables shell command tracing while handling credentials and creates a temporary npm configuration file that is removed when the step exits.

The security audit is deliberately scoped to production dependencies using `npm audit --omit=dev --audit-level=high`. This checks for high-severity or critical findings in the production dependency set under the configured audit policy; it does not certify that every dependency is vulnerability-free. The full dependency installation reported vulnerabilities among development dependencies, so those findings remain a separate item for review.

## Scope acknowledgement

This is a demonstration CI pipeline using one Jenkins controller, Docker-based build execution, and a locally hosted Nexus repository. It demonstrates automated checks, artifact archiving, versioned publication, credential handling and controlled fault recovery. It is not yet a highly available or fully hardened production delivery platform, and additional work would be required for broader security scanning, access governance, monitoring, backup and recovery, and production infrastructure resilience.
