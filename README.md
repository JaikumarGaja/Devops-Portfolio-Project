# DevOps Portfolio Project: 3-Tier Architecture Evolution

This repository demonstrates the progressive evolution of a cloud-native, 3-tier microservice architecture (Frontend, Backend, Database). The project is divided into three distinct phases, showcasing the transition from manual virtual machine deployments to a fully automated, self-healing Kubernetes cluster.

## Architecture & Tech Stack
* **Frontend:** Node.js / Express.js (User Registration UI)
* **Backend:** Python / Flask (RESTful API)
* **Database:** MongoDB Atlas (Cloud NoSQL)
* **Infrastructure as Code (IaC):** Terraform
* **Containerization:** Docker, Docker Compose
* **Continuous Integration (CI):** GitHub Actions
* **Continuous Deployment (CD):** Jenkins
* **Orchestration:** Kubernetes (AWS EKS - *In Progress*)

---

## 🟢 Phase 1: The Automated Foundation (Completed)
**Goal:** Automate infrastructure provisioning and establish a CI/CD pipeline to deploy containerized applications to a standalone EC2 server.

* **Infrastructure Provisioning:** Utilized **Terraform** to provision AWS EC2 instances (t2.micro) and configure Security Groups with strict ingress rules (SSH, Jenkins UI, Application ports).
* **Continuous Integration:** Configured **GitHub Actions** workflows triggered by path-specific repository pushes to build OCI-compliant Docker images and push them to Docker Hub.
* **Continuous Deployment:** Self-hosted **Jenkins** on an isolated EC2 instance. The declarative `Jenkinsfile` utilizes SSH Agents to securely authenticate with the Application Server, pull the latest images, and orchestrate deployment via `docker-compose`.
* **Pipeline Synchronization:** Eliminated CI/CD race conditions by decoupling the Jenkins webhook and utilizing authenticated API remote triggers via GitHub Actions `curl` commands, ensuring Jenkins only deploys after images are fully hosted.

## Phase 2: Cloud-Native Migration (Kubernetes & EKS)
**Status:** Completed

In Phase 2, the architecture was upgraded from a standalone EC2 server running Docker Compose to a highly available, self-healing Kubernetes cluster on AWS EKS. This enables zero-downtime rolling updates and enterprise-grade security.

### Architecture Changes
* **Infrastructure as Code:** Replaced the default AWS network with a Custom VPC module in Terraform, explicitly enabling DNS hostnames and auto-assigning public IPs to resolve EKS worker node registration timeouts.
* **Zero-Trust Authentication:** Eliminated the use of hardcoded AWS IAM Access Keys and SSH PEM keys. Created an AWS IAM Instance Profile in Terraform and attached it directly to the Jenkins EC2 server, granting it native permissions to authenticate with the EKS Control Plane.
* **Kubernetes Orchestration:**
  * Created `Deployment` manifests for the frontend (React) and backend (Flask/Node) microservices.
  * Configured `NodePort` Services to expose the application through the AWS Security Groups.
  * Implemented Kubernetes `Secrets` to securely manage the MongoDB connection string.
* **Pipeline Upgrade:** Updated the Jenkinsfile to execute `kubectl apply` and `kubectl rollout restart`, forcing dynamic image pulls from Docker Hub to ensure zero-downtime updates.

### Challenges Solved (War Stories)
1. **EKS VPC Routing Limits:** Discovered that EKS worker nodes deployed in a Default VPC fail to communicate with the control plane due to missing NAT Gateways and VPC-CNI plugin failures. Resolved by architecting a dedicated EKS VPC with public subnets.
2. **Terraform State Immutability:** Encountered state corruption when attempting to move an existing EKS cluster to a new VPC. Bypassed the limitation by renaming the cluster, forcing Terraform to provision a clean environment.
3. **API Versioning Conflicts:** Troubleshot a Jenkins pipeline `Exit Code 1` error caused by an outdated AWS CLI v1 injecting `v1alpha1` tokens that Kubernetes 1.30 rejected. Manually upgraded the CI server to AWS CLI v2 to generate modern, compatible auth tokens.

## 🔴 Phase 3: The Observability Layer (Planned)
**Goal:** Introduce enterprise-grade monitoring and alerting to the Kubernetes cluster.

* **Planned Implementation:** 
  * Deploying Prometheus for time-series metric collection (CPU/Memory utilization).
  * Deploying Grafana for data visualization dashboards.
  * Configuring alert managers for automated Slack/Discord notifications on Pod failure.

---
*Developed by Jaikumar Gaja.*