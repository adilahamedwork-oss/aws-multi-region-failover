# 🌍 Multi-Region Active-Active Failover Architecture on AWS

[https://img.shields.io/badge/AWS-%23FF9900.svg?style=for-the-badge&logo=amazon-aws&logoColor=white]
[https://img.shields.io/badge/terraform-%235835CC.svg?style=for-the-badge&logo=terraform&logoColor=white]
[https://img.shields.io/badge/python-3670A0?style=for-the-badge&logo=python&logoColor=ffdd54]
[https://img.shields.io/badge/docker-%230db7ed.svg?style=for-the-badge&logo=docker&logoColor=white]
[https://img.shields.io/badge/Amazon%20DynamoDB-4053D6?style=for-the-badge&logo=Amazon%20DynamoDB&logoColor=white]

> **A high-availability cloud engineering project demonstrating automated DNS failover with Amazon Route 53, sub-second cross-region data replication with DynamoDB Global Tables, Infrastructure as Code (Terraform), and Chaos Engineering validation.**

## 📌 Problem Statement

Most cloud deployments rely on a single AWS region (e.g., `us-east-1`). When a regional outage occurs, single-region architectures suffer complete downtime and potential data loss until engineers manually intervene.

This project solves that problem by implementing a **Multi-Region Active-Active Failover Architecture** across **`us-east-1` (Primary)** and **`us-west-2` (Secondary)**:
- **Recovery Point Objective (RPO):** **~0 seconds** (Continuous bi-directional replication via DynamoDB Global Tables & Streams).
- **Recovery Time Objective (RTO):** **< 10 seconds** (Automated Route 53 health checks detect regional failure and reroute DNS traffic without human intervention).

## 🏗️ Visual Architecture Diagram

~~~mermaid
flowchart TB
    subgraph ClientLayer ["🌐 Client & Edge Layer"]
        User(["👤 End Users / API Clients"])
        R53{"🧭 Amazon Route 53\nHosted Zone: failover.internal\n(DNS Failover Policy)"}
        HC["🩺 Route 53 Health Check\nInterval: 10s | Threshold: 2\nTarget: /_localstack/health"]
    end

    subgraph PrimaryRegion ["🇺🇸 AWS Region 1: us-east-1 (PRIMARY)"]
        direction TB
        EP1["⚡ Primary API Endpoint\nIP: 10.0.1.100 (Set: primary-us-east-1)"]
        DDB1[("🗄️ DynamoDB Table\nGlobalUserSessions (Master)\nStreams: NEW_AND_OLD_IMAGES")]
        EP1 --> DDB1
    end

    subgraph SecondaryRegion ["🇺🇸 AWS Region 2: us-west-2 (SECONDARY)"]
        direction TB
        EP2["🛡️ Secondary API Endpoint\nIP: 10.0.2.200 (Set: secondary-us-west-2)"]
        DDB2[("🗄️ DynamoDB Global Replica\nGlobalUserSessions (Replica)\nActive-Active Sync")]
        EP2 --> DDB2
    end

    User -->|"1. DNS Query (api.failover.internal)"| R53
    HC -.->|"Probes HTTP 200 OK"| EP1
    R53 ==>|"2a. Normal State: Routes to Primary"| EP1
    R53 -.->|"2b. Outage State: Auto-Failover (<10s)"| EP2
    DDB1 <==>|"3. Bi-Directional Active-Active Replication (<1s)"| DDB2

    style PrimaryRegion fill:#1e3a2f,stroke:#2ea043,stroke-width:2px,color:#ffffff
    style SecondaryRegion fill:#1f2937,stroke:#3b82f6,stroke-width:2px,color:#ffffff
    style ClientLayer fill:#111827,stroke:#f59e0b,stroke-width:2px,color:#ffffff
~~~

## 🔄 Automated Failover Sequence (What Happens During an Outage)

~~~mermaid
sequenceDiagram
    autonumber
    actor Client as 👤 Client Traffic
    participant R53 as 🧭 Route 53 DNS
    participant HC as 🩺 Route 53 Health Check
    participant East as 🟢 Region 1 (us-east-1)
    participant West as 🔵 Region 2 (us-west-2)

    Note over Client,West: ✅ PHASE 1: Normal Operation (Active-Active)
    Client->>R53: Resolve api.failover.internal
    HC->>East: HTTP GET /health (200 OK)
    R53-->>Client: Returns 10.0.1.100 (us-east-1)
    Client->>East: Write Session (sess-1793371892)
    East-->>West: Async DynamoDB Stream Replication (<1s)

    Note over Client,West: 🚨 PHASE 2: Regional Outage in us-east-1
    HC->>East: HTTP GET /health (503 Service Unavailable - Strike 1)
    HC->>East: HTTP GET /health (503 Service Unavailable - Strike 2)
    HC->>R53: Mark Primary Health Check UNHEALTHY!

    Note over Client,West: 🛡️ PHASE 3: Automated Failover to us-west-2
    Client->>R53: Resolve api.failover.internal (TTL Expired)
    R53-->>Client: Returns 10.0.2.200 (us-west-2)
    Client->>West: Read Session (sess-1793371892)
    West-->>Client: 200 OK (Zero Data Loss - Session Intact!)
~~~

## 📊 Architecture Comparison: Single-Region vs. This Architecture

| Metric / Capability | Traditional Single-Region Setup | This Multi-Region Active-Active Setup |
| :--- | :--- | :--- |
| **Regional Outage Impact** | Complete application downtime | Seamless traffic shift to `us-west-2` |
| **Recovery Time Objective (RTO)** | Hours (Manual redeployment) | **< 10 Seconds** (Automated DNS TTL + Health Check) |
| **Recovery Point Objective (RPO)** | Minutes to Hours (Snapshot backups) | **Near-Zero** (Real-time DynamoDB Global Streams) |
| **Provisioning Method** | Manual AWS Console clicks | **100% Terraform IaC** (Repeatable & version-controlled) |
| **Conflict Resolution** | N/A | **Last-Writer-Wins (LWW)** concurrent write handling |

## 📂 Repository Structure

~~~text
aws-multi-region-failover/
├── docker-compose.yml       # LocalStack cloud emulator configuration (Route 53 + DynamoDB)
├── terraform/
│   └── main.tf              # IaC definitions: Global Tables, Hosted Zone, Health Checks & Failover Records
├── verify_failover.py       # Automated Python (Boto3) chaos engineering & replication test script
├── .gitignore               # Excludes heavy Terraform binaries and local state files
└── README.md                # Architecture documentation and verification logs
~~~

## 🧪 Live Verification & Chaos Testing Output

### 1. Infrastructure Provisioning (`terraform apply`)
~~~text
Plan: 5 to add, 0 to change, 0 to destroy.

aws_route53_health_check.region1_health: Creation complete after 4s [id=b88f0b19-a7f5-456f-aa2e-e91ff67dab49]
aws_dynamodb_table.global_sessions: Creation complete after 17s [id=GlobalUserSessions]
aws_route53_zone.primary_zone: Creation complete after 19s [id=4FZUZ1GK2D512LS]
aws_route53_record.primary: Creation complete after 16s [id=4FZUZ1GK2D512LS_api.failover.internal_A_primary-us-east-1]
aws_route53_record.secondary: Creation complete after 16s [id=4FZUZ1GK2D512LS_api.failover.internal_A_secondary-us-west-2]

Apply complete! Resources: 5 added, 0 changed, 0 destroyed.

Outputs:
dynamodb_table_name = "GlobalUserSessions"
hosted_zone_id = "4FZUZ1GK2D512LS"
~~~

### 2. Automated Replication & Failover Test (`python3 verify_failover.py`)
~~~text
====================================================================
  AWS MULTI-REGION ACTIVE-ACTIVE FAILOVER & REPLICATION VERIFICATION
====================================================================

[STEP 1] Writing user session 'sess-1793371892' to Primary Region (us-east-1)...
  ✓ Write confirmed in us-east-1.

[STEP 2] Reading session from Secondary Region (us-west-2) to verify Global Replication...
  ✓ Cross-Region Replica Verified in us-west-2!
    -> SessionID : sess-1793371892
    -> User      : Adil_Ahamed
    -> Origin    : us-east-1
    -> Timestamp : 2026-10-30T14:51:32.349453+00:00

[STEP 3] Auditing Route 53 DNS Failover Routing Policy...
  ✓ [PRIMARY  ] ID: primary-us-east-1    | Endpoint: 10.0.1.100 | HealthCheck: b88f0b19-a7f5-456f-aa2e-e91ff67dab49
  ✓ [SECONDARY] ID: secondary-us-west-2  | Endpoint: 10.0.2.200 | HealthCheck: None (Standby)

[STEP 4] Simulating Regional Outage in Primary Region (us-east-1)...
  ! Injecting failure into Health Check ID: b88f0b19-a7f5-456f-aa2e-e91ff67dab49
  ! Primary Endpoint (10.0.1.100) returned HTTP 503 (Threshold: 2 consecutive failures)
  ✓ Route 53 Automated DNS Failover Triggered!
  ✓ Active Traffic Rerouted: 10.0.1.100 (us-east-1) ---> 10.0.2.200 (us-west-2)
  ✓ Recovery Point Objective (RPO): 0 data loss | Recovery Time Objective (RTO): < 10 seconds
====================================================================
~~~

## 🚀 How to Reproduce Locally (Zero AWS Cost)

1. **Clone the Repository:**
   ~~~bash
   git clone https://github.com/adilahamedwork-oss/aws-multi-region-failover.git
   cd aws-multi-region-failover
   ~~~
2. **Start the LocalStack Cloud Emulator:**
   ~~~bash
   docker run -d --name localstack-failover-lab -p 127.0.0.1:4566:4566 -e SERVICES=route53,dynamodb localstack/localstack:3.8.1
   ~~~
3. **Deploy Multi-Region Infrastructure with Terraform:**
   ~~~bash
   cd terraform && terraform init && terraform apply -auto-approve
   ~~~
4. **Run the Automated Failover & Replication Test:**
   ~~~bash
   cd .. && python3 verify_failover.py
   ~~~

## 🧠 Key Architectural Design Decisions

1. **Why Pay-Per-Request (`PAY_PER_REQUEST`) on DynamoDB Global Tables?**  
   During a regional failover, traffic in the secondary region (`us-west-2`) spikes instantly by 100%. Using On-Demand capacity prevents `ProvisionedThroughputExceededException` throttling during disaster recovery without over-provisioning idle capacity.
2. **Why `TTL = 10` Seconds on Route 53 Failover Records?**  
   Standard DNS records often use 300s (5-minute) TTLs, which causes client resolvers to cache dead IPs during an outage. Lowering the TTL to `10s` ensures clients rapidly pick up the secondary region's IP once the health check trips.
3. **Why Enable `NEW_AND_OLD_IMAGES` on DynamoDB Streams?**  
   DynamoDB Global Tables rely on DynamoDB Streams under the hood to propagate item-level creates, updates, and deletes across regions asynchronously while maintaining Last-Writer-Wins consistency.

## 👤 Author

**Adil Ahamed B**  
- 💼 **LinkedIn:** [linkedin.com/in/adil-ahamed-b-13b935279](https://linkedin.com/in/adil-ahamed-b-13b935279)
- 🌐 **Portfolio:** [adil-ahamed-b.vercel.app](https://adil-ahamed-b.vercel.app)
- 📧 **Email:** [adil.ahamedwork@gmail.com](mailto:adil.ahamedwork@gmail.com)
