# Week 7 and Week 8: Deployment and Reliability Comparison

## Introduction

Week 7 introduced application deployment strategies and ways of maintaining service reliability during software updates. It covered rolling, blue-green and canary deployments, automated deployment scripts, traffic switching, health monitoring and rollback. Week 8 built on these ideas by introducing container-based delivery and container orchestration. The main difference is that Week 7 focused on deployment approaches and automation concepts, while Week 8 applied containerisation and orchestration to the KijaniKiosk Payments application.

The Week 7 materials were instructional practice rather than a completed project. Therefore, the Week 7 column below describes the approaches taught, not measured results from an implementation. Week 8 figures are based on the actual project tests.

## Comparison

| Concern | Week 7 | Week 8 |
|---|---|---|
| Deployment mechanism | Rolling, blue-green and canary strategies were taught. Blue-green was recommended for the example because it allows traffic to switch between two environments. | The application was packaged into a multi-stage container image and deployed through Kubernetes using two running replicas. |
| Rollback mechanism | The lessons demonstrated the idea of switching traffic back to the previous environment after a failed health check. Blue-green switching was expected to make rollback very fast. | Kubernetes Deployments support rolling back to an earlier revision. However, a rollback was not performed or timed in this project. |
| Failure recovery | The lessons introduced health monitoring and automatic rollback when availability, latency or error-rate thresholds are exceeded. | Kubernetes replaced a manually deleted Pod and restored the desired replica count. The observed time from deletion to a ready replacement was 33 seconds. |
| Scaling | Rolling and canary strategies manage how application instances receive updates, while blue-green requires two environments. The lessons also discussed maintaining capacity during deployment. | The Deployment was configured with two replicas, allowing Kubernetes to maintain two application instances. Automatic horizontal scaling was not implemented or tested. |

## Deployment Mechanism

Week 7 explained how different deployment strategies can reduce disruption when releasing a new application version. Rolling deployment updates instances gradually, blue-green deployment prepares a separate environment before switching traffic, and canary deployment exposes a small proportion of users to a new version before expanding the release. These approaches help teams choose a release method based on risk, available resources and recovery requirements.

In Week 8, the Payments application was packaged into a production container using a multi-stage build. The final image ran as a non-root user and excluded development tooling. Its measured image size on disk was 82 MB, compared with 274 MB for the baseline image, representing an approximate 70.1% reduction. The image was then published to GitHub Container Registry using a version and commit-based tag. The orchestration platform deployed two replicas of that image, making the delivery process more consistent because the application was packaged with its runtime environment.

## Rollback and Failure Recovery

Week 7 introduced blue-green rollback as a way of returning traffic to a previous working environment when a release fails. It also discussed health checks and monitoring thresholds that could trigger an automatic rollback. These were taught approaches; no Week 7 rollback was implemented or measured for this project.

Week 8 demonstrated a different recovery capability. When one running application instance was deleted, the automated deployment controller created a replacement to restore the required number of replicas. The observed recovery interval was 33 seconds. This demonstrates self-healing at the orchestration level. It should not be confused with rolling back a faulty application release: deleting an application instance does not automatically restore an earlier application version.

## Scaling and Operational Management

Week 7 explored how deployment strategies affect available capacity and how teams can avoid exposing all users to an untested release. Week 8 used two replicas to provide more than one running instance of the application. The Service distributed access to the selected application Pods through a stable network endpoint. This makes it easier to maintain access when an individual Pod is replaced. However, two replicas are a configured capacity level, not proof of automatic scaling. Horizontal autoscaling was outside the completed implementation.

## Gaps and Next Steps for Week 9

The Week 8 implementation successfully demonstrated production image creation, registry publishing, application deployment, service discovery and automatic instance replacement. However, several improvements remain. The observed 33-second recovery interval should be investigated to understand how much time was spent detecting the deletion, scheduling the replacement and waiting for readiness. A failed application health check should also be tested separately from manual Pod deletion. The deployment currently uses fixed configuration values, and environment-specific settings should be separated from application secrets.

Week 9 should build on this work by introducing readiness and health checks, configuration management, secret handling and more deliberate recovery testing. Monitoring should capture recovery times and application health so that operational decisions are based on measurable evidence. These improvements would make the delivery process more secure, observable and reliable.
