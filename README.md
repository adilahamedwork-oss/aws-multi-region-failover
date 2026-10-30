# Multi-Region Active-Active Failover Architecture on AWS (Terraform & LocalStack)

## Overview
Designed and deployed a highly available, multi-region cloud architecture across **us-east-1 (Primary)** and **us-west-2 (Secondary)** using **Terraform**, **Amazon Route 53**, **Amazon DynamoDB Global Tables**, and **Docker/LocalStack**.

## Key Engineering Highlights
- **Infrastructure as Code (IaC):** Automated 100% of the multi-region topology using **Terraform (`hashicorp/aws`)**.
- **Zero Data Loss (RPO ~ 0):** Configured **DynamoDB Global Tables** with `NEW_AND_OLD_IMAGES` streams to asynchronously replicate user sessions across `us-east-1` and `us-west-2`.
- **Automated Disaster Recovery (RTO < 10s):** Implemented **Route 53 Health Checks** (`request_interval = 10s`, `failure_threshold = 2`) paired with `PRIMARY` and `SECONDARY` failover routing records.
- **Chaos & Failover Verification:** Built an automated Python (`boto3`) verification suite (`verify_failover.py`) to validate cross-region data replication and DNS failover under simulated regional outages.

## How to Run Locally
1. Start LocalStack:
   `docker-compose up -d`
2. Deploy with Terraform:
   `cd terraform && terraform init && terraform apply -auto-approve`
3. Run Failover Verification:
   `python3 verify_failover.py`
