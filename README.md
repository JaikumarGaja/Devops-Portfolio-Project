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

## 🟡 Phase 2: The Kubernetes Upgrade (In Progress)
**Goal:** Migrate the standalone EC2 application to an Amazon Elastic Kubernetes Service (EKS) cluster to eliminate deployment downtime and introduce container orchestration.

* **Planned Architecture:** 
  * Deprecating `docker-compose` in favor of Kubernetes `Deployments` and `Services`.
  * Implementing internal DNS routing between frontend and backend Pods.
  * Enabling Rolling Updates for zero-downtime CI/CD deployments.
  * Updating Terraform configurations to provision the EKS Control Plane and Worker Nodes.

## 🔴 Phase 3: The Observability Layer (Planned)
**Goal:** Introduce enterprise-grade monitoring and alerting to the Kubernetes cluster.

* **Planned Implementation:** 
  * Deploying Prometheus for time-series metric collection (CPU/Memory utilization).
  * Deploying Grafana for data visualization dashboards.
  * Configuring alert managers for automated Slack/Discord notifications on Pod failure.

---
*Developed by Jaikumar Gaja.*