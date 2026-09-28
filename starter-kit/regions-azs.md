# Region Selection & Multi-AZ Reliability Architecture

## 1. Region Selection: Africa / Nairobi Proximity Focus
- **Primary Region**: `eu-west-1` (Ireland) or `af-south-1` (Cape Town) depending on primary target low-latency routes to Nairobi, Kenya.
- **Selection Criteria**:
  - **Latency**: Minimal round-trip time (RTT) for users interacting with KijaniKiosk endpoints in East Africa.
  - **Data Sovereignty & Compliance**: Adherence to local privacy laws regarding user and business transactional data storage.
  - **Service Availability**: Availability of key managed services (Managed Relational Databases, Container Engines, IAM).

---

## 2. Multi-Availability Zone (Multi-AZ) Reliability Design
An Availability Zone (AZ) consists of one or more discrete data centers with independent power, networking, and cooling.

              +-------------------------------------------------+
              |                    AWS REGION                   |
              |                                                 |
              |   +-------------------+   +-----------------+   |
              |   |  Zone A (AZ-1)    |   |  Zone B (AZ-2)  |   |
              |   |                   |   |                 |   |
              |   |  +-------------+  |   |  +-----------+  |   |
              |   |  | Public App  |  |   |  | Public App|  |   |
              |   |  +-------------+  |   |  +-----------+  |   |
              |   |         |         |   |        |        |   |
              |   |  +-------------+  |   |  +-----------+  |   |
              |   |  | Primary DB  |==|===|==| Standby DB|  |   |
              |   |  +-------------+  |   |  +-----------+  |   |
              |   +-------------------+   +-----------------+   |
              +-------------------------------------------------+

### Key Reliability Practices:
1. **High Availability (HA)**: Application workloads are deployed across a minimum of **2 Availability Zones**. If AZ-1 suffers an outage, traffic automatically routes to AZ-2 via the Application Load Balancer (ALB).
2. **Database Redundancy**: Database services (e.g., Amazon RDS PostgreSQL) run in a Multi-AZ configuration with real-time synchronous replication from Primary (AZ-1) to Standby (AZ-2).
3. **Disaster Recovery (DR)**: Automated multi-region database backups and storage snapshots ensure low Recovery Point Objective (RPO) and Recovery Time Objective (RTO).
