# Week 8 — KijaniKiosk Container Delivery Pipeline

This folder contains the Week 8 work for the KijaniKiosk DevOps Foundation project. The objective was to build a reliable container delivery workflow for the KijaniKiosk Payments application, progressing from production image creation to private registry publishing, deployment, service exposure, and self-healing verification.

The work is organised chronologically from Monday to Friday. Each folder represents a stage in the development and verification process.

## Weekly Objectives

The Week 8 project focused on:

- Creating a production-ready container image using a multi-stage build.
- Reducing image size and excluding unnecessary development tools.
- Running the application as a non-root user.
- Tagging images using the application version and source Git commit.
- Publishing the production image to a private container registry.
- Deploying the application with multiple replicas.
- Exposing the application through a Kubernetes NodePort service.
- Verifying service discovery and application health.
- Testing automatic recovery when a running application instance is deleted.
- Documenting the implementation, results, limitations, and possible improvements.

## Folder Structure

```text
week8/
│
├── monday/
│   ├── Dockerfile
│   └── .dockerignore
│
├── tuesday/
│   ├── Dockerfile.production
│   ├── .dockerignore
│   └── verification-output.txt
│
├── wednesday/
│   ├── tag-image.sh
│   └── registry-output.txt
│
├── thursday/
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── kubernetes-output.txt
│   └── self-healing-output.txt
│
├── friday/
│   ├── Dockerfile.production
│   ├── .dockerignore
│   ├── kk-payments-deployment.yaml
│   ├── kk-payments-service.yaml
│   ├── build-verification.txt
│   ├── rebuild-output.txt
│   ├── registry-push.txt
│   ├── deploy-output.txt
│   ├── service-output.txt
│   ├── self-healing-rerun.txt
│   ├── nia-comparison.md
│   ├── reflection.md
│   └── pr-summary.md
│
└── README.md
```

## Monday — Initial Container Build

Location: `week8/monday/`

Monday introduced the initial containerisation of the KijaniKiosk Payments application.

Files:

- `Dockerfile` — Initial instructions for building the application container image.
- `.dockerignore` — Specifies files and directories that should be excluded from the Docker build context.

This stage established the initial container build configuration before production-specific optimisation.

## Tuesday — Production Image Build and Verification

Location: `week8/tuesday/`

Tuesday developed the production image using a multi-stage build approach.

Files:

- `Dockerfile.production` — Production-oriented Dockerfile that separates build-time requirements from the final runtime image.
- `.dockerignore` — Excludes unnecessary files from the build context.
- `verification-output.txt` — Records the output from the production image verification process.

The focus was on reducing the final image size, limiting unnecessary tools in the runtime environment, and running the application with reduced privileges.

## Wednesday — Image Tagging and Registry Publishing

Location: `week8/wednesday/`

Wednesday focused on preparing the production image for distribution through a private container registry.

Files:

- `tag-image.sh` — Script used to build, tag, and publish the application image using its package version and source Git commit identifier.
- `registry-output.txt` — Records the registry publishing process and its output.

The version-and-commit-based image tag provides a traceable link between the published image and the source revision used to build it.

## Thursday — Application Deployment and Service Configuration

Location: `week8/thursday/`

Thursday introduced the deployment and networking configuration needed to run the application in Kubernetes.

Files:

- `deployment.yaml` — Defines the application Deployment, including its replicas and container configuration.
- `service.yaml` — Defines the service used to expose the application.
- `kubernetes-output.txt` — Records deployment and service verification output.
- `self-healing-output.txt` — Records the initial test of automatic recovery after an application instance was deleted.

This stage demonstrated how the application could run with multiple replicas and how the orchestration platform could restore the desired replica count after a failure.

## Friday — Final Production Delivery and Assessment Evidence

Location: `week8/friday/`

Friday consolidates the production image, deployment configuration, final verification results, and assessment documentation. It contains the final versions of the key configuration files and evidence from the completed delivery workflow.

### Production Build Files

- `Dockerfile.production` — Final production multi-stage Dockerfile.
- `.dockerignore` — Excludes unnecessary files from the production build context.

### Deployment and Service Manifests

- `kk-payments-deployment.yaml` — Final Kubernetes Deployment manifest. It specifies the production image, two replicas, resource requests and limits, and the private registry image-pull secret.
- `kk-payments-service.yaml` — Final NodePort service manifest for exposing the application.

### Build and Registry Evidence

- `build-verification.txt` — Summarises the production image build and verification results, including image size, runtime user, health status, and test results.
- `rebuild-output.txt` — Records the production image rebuild output.
- `registry-push.txt` — Documents the image tag, private registry push, image digest, and successful fresh-pull verification.

### Deployment and Recovery Evidence

- `deploy-output.txt` — Records the final deployment rollout, running replicas, and deployed image.
- `service-output.txt` — Records the NodePort service, service endpoints, external health check, and in-cluster DNS health check.
- `self-healing-rerun.txt` — Documents the final self-healing test, including the deleted application instance, replacement instance, and measured recovery time.

### Written Documentation

- `nia-comparison.md` — Compares the Week 7 deployment concepts with the Week 8 implementation, including deployment mechanisms, rollback, failure recovery, and scaling.
- `reflection.md` — Discusses the implementation experience, challenges, technical decisions, and areas for improvement.
- `pr-summary.md` — Summarises the completed work, key design decision, and proposed improvement.


## Known Limitations and Future Improvements

The implementation demonstrates production image creation, registry publishing, deployment, service exposure, health verification, and automatic instance replacement.

Further improvements could include readiness and liveness probes, externalised application configuration, more comprehensive secret management, automated horizontal scaling, and additional recovery testing involving application health failures rather than only manual instance deletion.

The build also reported dependency vulnerabilities during the npm audit. These were recorded for follow-up dependency-security work.

## Git and Pull Request Evidence

The Week 8 work was developed on:

`feature/week8-container-delivery`

The work was submitted through:

**PR #5 — Week 8: KijaniKiosk Container Delivery Pipeline**

Target branch: `develop`

Pull request: https://github.com/Anm-hub/kijanikiosk-devops-foundation/pull/5

The pull request contains the Week 8 deliverables and supporting evidence for review.
