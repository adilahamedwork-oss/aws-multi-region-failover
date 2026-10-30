🌍 Multi-Region Active-Active Failover Architecture on AWS

A hands-on cloud engineering project exploring multi-region application availability, automated failover, DNS routing, infrastructure automation, and cross-region data replication using AWS technologies.

Project status: In progress — local implementation and testing completed; real AWS multi-region deployment remains pending.

⸻

📌 Project Overview

Cloud applications can experience downtime when an application endpoint or an entire region becomes unavailable.

This project explores how a multi-region architecture can improve application resilience by combining:

* Amazon Route 53 for DNS routing and health checks
* Amazon EC2 for application workloads
* Elastic Load Balancing for traffic distribution
* Amazon DynamoDB Global Tables for cross-region data replication
* Terraform for Infrastructure as Code
* Python and Boto3 for automation and verification
* Docker and LocalStack for local cloud-service simulation

The long-term objective is to build and validate an architecture in which application workloads operate across two AWS regions and traffic can be directed to a healthy region when a failure occurs.

🏗️ Architecture

The following illustration represents the target architecture for the project.

Architecture Components

Component	Purpose
Amazon Route 53	DNS routing and health-based traffic management
Application Load Balancer	Distributes incoming application traffic
Amazon EC2	Hosts application workloads
Amazon DynamoDB Global Tables	Supports multi-region data replication
Terraform	Defines and provisions infrastructure
Python / Boto3	Automates checks and verification
Docker / LocalStack	Provides a local AWS service simulation environment

Architecture note: The diagram illustrates the intended AWS design. The current local implementation is a simulation and does not represent a completed production deployment.

🧪 Implementation and Testing

Completed and locally verified

* [x]	Configured a LocalStack environment using Docker.
* [x]	Created a DynamoDB table in the local environment.
* [x]	Configured a second-region DynamoDB replica simulation.
* [x]	Verified that an item written in one simulated region could be read independently from the other.
* [x]	Created a Route 53 hosted zone and primary/secondary failover record configuration in LocalStack.
* [x]	Built Python application endpoints for primary and secondary regions.
* [x]	Implemented HTTP health-check-based application routing.
* [x]	Simulated primary application failure and recovery.
* [x]	Ran automated application failover tests: 3 out of 3 passed.

Current development status

* [ ]	Deploy application workloads in two real AWS regions.
* [ ]	Configure and verify real AWS DynamoDB Global Tables.
* [ ]	Configure real Route 53 health checks and traffic-routing policies.
* [ ]	Validate actual DNS failover between deployed regional endpoints.
* [ ]	Measure observed recovery time and data replication behavior.
* [ ]	Complete and validate the Terraform deployment for the target architecture.

🔄 Application Failover Simulation

The local Python application demonstrates health-check-based routing.

The tested scenarios include:

1. Normal operation: The router detects a healthy primary endpoint and sends traffic to it.
2. Primary failure: The primary endpoint becomes unavailable, and the router selects the secondary endpoint.
3. Primary recovery: Once the primary endpoint becomes healthy again, the router returns traffic to it.

The automated local test suite successfully passed all three scenarios.

Important: This is application-level failover simulation. It is not proof of real Route 53 DNS failover or an actual AWS regional outage.

🗄️ DynamoDB Replication Simulation

The local implementation uses DynamoDB in LocalStack to explore cross-region replication.

The verification process:

1. Writes a unique item to the first simulated region.
2. Independently reads the item from the second simulated region.
3. Confirms that the expected item is available.

This validates the configured local replication simulation. Real AWS DynamoDB Global Tables behavior and replication latency have not yet been measured.

🛠️ Technology Stack

Category	Technologies
Cloud platform	Amazon Web Services
DNS and routing	Amazon Route 53
Compute	Amazon EC2
Load balancing	Application Load Balancer
Database	Amazon DynamoDB
Infrastructure as Code	Terraform (HCL)
Programming	Python
AWS SDK	Boto3
Containers	Docker
Local cloud simulation	LocalStack
Version control	Git and GitHub

📂 Repository Structure

aws-multi-region-failover/
│
├── images/
│   └── architecture.png
│
├── terraform/
│   └── Terraform configuration files
│
├── docker-compose.yml
├── verify_failover.py
├── .gitignore
└── README.md

🚀 Running the Local Environment

Prerequisites

* Docker
* Docker Compose
* Python 3
* Terraform
* Python Boto3 package

1. Clone the repository

git clone https://github.com/adilahamedwork-oss/aws-multi-region-failover.git
cd aws-multi-region-failover

2. Start the LocalStack environment

docker compose up -d

Check the container:

docker ps

3. Install the Python dependency

python3 -m pip install boto3

4. Run the verification script

python3 verify_failover.py

The verification script checks the configured local DynamoDB replication and Route 53 resources.

Note: These instructions describe the local simulation. Terraform deployment against real AWS is not part of the verified local test procedure. Review the Terraform configuration, AWS account permissions, and execution plan before any real AWS apply operation.

📊 Validation and Results

Test	Result
LocalStack environment	Verified
Simulated cross-region data read	Passed
Route 53 configuration inspection	Passed
Primary application routing	Passed
Secondary application routing during simulated outage	Passed
Primary recovery	Passed
Automated application failover scenarios	3/3 passed
Real AWS regional failover	Not yet tested
Production DNS failover	Not yet tested
Production RPO / RTO	Not yet measured

No production RPO or RTO guarantees are claimed at this stage.

🎯 Learning Objectives

Through this project, I am developing practical knowledge of:

* Multi-region cloud architecture
* High availability and disaster recovery
* DNS-based traffic management
* Application health checks
* Database replication concepts
* Infrastructure as Code
* Python cloud automation
* Failure simulation and recovery testing

🔮 Future Improvements

* Deploy application workloads in two real AWS regions.
* Implement real multi-region DynamoDB Global Tables.
* Configure Route 53 latency-based or other suitable health-aware routing.
* Validate traffic distribution and regional failover.
* Measure actual recovery time and replication behavior.
* Improve infrastructure automation and testing.
* Add monitoring, logging, and operational visibility.

👨‍💻 Author

Adil Ahamed B

Aspiring Cloud Security / Cloud Engineer

* GitHub: https://github.com/adilahamedwork-oss
* Portfolio: https://adil-ahamed-b.vercel.app
* LinkedIn: https://www.linkedin.com/in/adil-ahamed-b-13b935279/

⸻

Built as a hands-on cloud engineering learning project. The implementation is evolving from local infrastructure simulation toward a validated multi-region AWS deployment.
