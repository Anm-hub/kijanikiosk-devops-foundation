# Week 8 Reflection

## 1. Hardest Automation Step and Failure Mode

The most challenging part of the work was coordinating the production image tag across the build, GitHub Container Registry and Kubernetes Deployment. The image needed to use the application's actual version and a short Git commit identifier so that the published artifact could be traced back to its source. A mismatch between the published tag and the Deployment image reference could prevent Kubernetes from retrieving the correct image. An incorrect or expired registry credential could also cause an image pull failure, leaving Pods in an ImagePullBackOff state.

The registry workflow was verified by pushing the image, removing its local reference, pulling it again and running it successfully. The fresh container became healthy and returned the expected application version.

## 2. Rewriting a Sentence for Tendo

Original sentence for a nontechnical audience:

"A blue-green deployment prepares a new version separately before switching users to it, allowing the team to return to the previous version if a problem occurs."

Technical version for Tendo:

"Blue-green deployment provisions the inactive environment with the new release, validates its health, and switches the reverse proxy upstream to the new environment; if verification fails, the upstream can be switched back to the previous environment."

The technical version gives Tendo more operational detail by identifying the inactive environment, health validation and reverse-proxy traffic switching. This makes the deployment and rollback mechanism clearer to an engineer. However, it uses terms that may be less accessible to a nontechnical audience, so some simplicity is lost.

## 3. Configuration Values That Should Be Externalised

Application-specific settings such as the listening port, log level and feature flags should be managed through a ConfigMap where appropriate. Sensitive values such as database passwords, API keys and registry credentials should be stored in Kubernetes Secrets rather than written directly into application configuration or committed to source control.

The current Deployment also contains fixed operational values, including the image tag, replica count, resource requests and limits, and container port. These should be managed through environment-specific deployment configuration or tools such as Helm or Kustomize rather than treating all of them as ConfigMap or Secret values. Leaving these settings hardcoded can make deployments harder to adapt between development, testing and production. It can also lead to inconsistent configurations, accidental deployment of an unintended image version and unnecessary manual changes. Separating configuration from application code makes updates easier to review and reduces the risk of exposing sensitive information.
