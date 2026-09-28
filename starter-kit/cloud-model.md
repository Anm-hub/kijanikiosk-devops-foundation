# KijaniKiosk Cloud Service Model Justification

## Selected Model: Platform as a Service (PaaS) with Selective IaaS Components

For the initial launch of the KijaniKiosk platform, I selected a **PaaS-centric hybrid model** (e.g., AWS Elastic Beanstalk / App Runner, Managed PostgreSQL, and S3).

---

## Architectural Comparison & Reasoning

| Cloud Model | Evaluation for KijaniKiosk | Decision |
| :--- | :--- | :--- |
| **SaaS** *(Software as a Service)* | Highly restrictive for proprietary core engine logic, custom kiosk hardware integrations, and database schemas. | **Rejected** (Used only for third-party tooling like GitHub and monitoring). |
| **IaaS** *(Infrastructure as a Service)* | Grants full control over VMs and networking, but introduces significant management overhead (OS patching, manual scaling, server maintenance). | **Rejected for application tier** (Adds unnecessary operational load before product-market fit). |
| **PaaS** *(Platform as a Service)* | Offloads OS management, auto-scaling, load balancing, and runtime patching to the cloud provider while giving full control over application code and configuration. | **SELECTED** |

---

## Trade-off Analysis & Business Alignment

1. **Focus on Core Value**: KijaniKiosk's engineering priority is delivering software functionality to users. PaaS allows the team to deploy containers or application code without maintaining virtual machine images or operating system patches.
2. **Managed Reliability & High Availability**: Services like AWS App Runner or Elastic Beanstalk seamlessly manage health checks, multi-AZ failovers, and auto-scaling out-of-the-box.
3. **Cost Efficiency at Launch**: Eliminates idle compute capacity. PaaS resources scale down during low-traffic hours, keeping early infrastructure costs predictable.
4. **Future Migration Path**: By containerizing the application using Docker, KijaniKiosk avoids vendor lock-in and retains the flexibility to migrate to an IaaS or Kubernetes-based (EKS/GKE) platform if scale demands it in the future.
