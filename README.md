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
* **Orchestration:** Kubernetes (AWS EKS)
* **Observability:** Prometheus, Grafana

---

## 🟢 Phase 1: The Automated Foundation (Completed)
**Goal:** Automate infrastructure provisioning and establish a CI/CD pipeline to deploy containerized applications to a standalone EC2 server.

* **Infrastructure Provisioning:** Utilized **Terraform** to provision AWS EC2 instances (t2.micro) and configure Security Groups with strict ingress rules (SSH, Jenkins UI, Application ports).
* **Continuous Integration:** Configured **GitHub Actions** workflows triggered by path-specific repository pushes to build OCI-compliant Docker images and push them to Docker Hub.
* **Continuous Deployment:** Self-hosted **Jenkins** on an isolated EC2 instance. The declarative `Jenkinsfile` utilizes SSH Agents to securely authenticate with the Application Server, pull the latest images, and orchestrate deployment via `docker-compose`.
* **Pipeline Synchronization:** Eliminated CI/CD race conditions by decoupling the Jenkins webhook and utilizing authenticated API remote triggers via GitHub Actions `curl` commands, ensuring Jenkins only deploys after images are fully hosted.

---

## 🟢 Phase 2: Cloud-Native Migration (Kubernetes & EKS)
**Goal:** Upgrade from a standalone EC2 server running Docker Compose to a highly available, self-healing Kubernetes cluster on AWS EKS to enable zero-downtime rolling updates and enterprise-grade security.

### Architecture Changes
* **Infrastructure as Code:** Replaced the default AWS network with a Custom VPC module in Terraform, explicitly enabling DNS hostnames and auto-assigning public IPs to resolve EKS worker node registration timeouts.
* **Zero-Trust Authentication:** Eliminated the use of hardcoded AWS IAM Access Keys and SSH PEM keys. Created an AWS IAM Instance Profile in Terraform and attached it directly to the Jenkins EC2 server, granting it native permissions to authenticate with the EKS Control Plane.
* **Dynamic Configuration Management:** Configured Terraform via the GitHub Provider to automatically capture dynamic EC2 IP addresses upon creation and securely inject them into GitHub Actions Secrets (`JENKINS_URL`), eliminating manual pipeline updates when infrastructure scales or restarts.
* **Kubernetes Orchestration:**
  * Created `Deployment` manifests for the frontend and backend microservices.
  * Configured `NodePort` Services to expose the application through the AWS Security Groups.
  * Implemented Kubernetes `Secrets` to securely manage the MongoDB connection string.
* **Pipeline Upgrade:** Updated the Jenkinsfile to execute `kubectl apply` and `kubectl rollout restart`, forcing dynamic image pulls from Docker Hub to ensure zero-downtime updates, and automated idempotent secret injection (`withCredentials`) to handle cluster rebuilds.

### Challenges Solved (War Stories)
1. **EKS VPC Routing Limits:** Discovered that EKS worker nodes deployed in a Default VPC fail to communicate with the control plane due to missing NAT Gateways and VPC-CNI plugin failures. Resolved by architecting a dedicated EKS VPC with public subnets.
2. **Terraform State Immutability:** Encountered state corruption when attempting to move an existing EKS cluster to a new VPC. Bypassed the limitation by renaming the cluster, forcing Terraform to provision a clean environment.
3. **API Versioning Conflicts:** Troubleshot a Jenkins pipeline `Exit Code 1` error caused by an outdated AWS CLI v1 injecting `v1alpha1` tokens that Kubernetes 1.30 rejected. Manually upgraded the CI server to AWS CLI v2 to generate modern, compatible auth tokens.
4. **Ephemeral Secret Management:** Debugged a `CreateContainerConfigError` caused by manual Kubernetes secrets being wiped during a Terraform cluster rebuild. Engineered an idempotent automated secret injection block within the Jenkinsfile to ensure secrets persist across ephemeral infrastructure rebuilds.

---

## 🟢 Phase 3: Observability & Monitoring
**Goal:** Implement a comprehensive monitoring stack to gain real-time visibility into cluster health, resource utilization, and application performance.

### Architecture Changes
* **Package Management:** Utilized Helm to deploy the `kube-prometheus-stack`, abstracting the complexity of managing dozens of raw Kubernetes monitoring manifests.
* **Metrics Scraping:** Configured Prometheus to automatically discover and scrape metrics from the EKS control plane, worker nodes (via Node Exporter), and internal pods (via cAdvisor).
* **Data Visualization:** Exposed Grafana via a dynamically provisioned Kubernetes NodePort and updated the AWS Security Group via Terraform to allow secure web access. 

---

## 📅 Engineering Log

### 07-October-2026 - Cloud IaC
**Objective:** Migrate Terraform state to a remote AWS S3 backend to enable cloud-based CI/CD infrastructure deployments, and begin architecting a GitOps workflow.
* **Progress:** 
  * Re-architected Terraform to utilize an AWS S3 remote backend, effectively separating the infrastructure code (GitHub) from the state data (S3).
  * Engineered a GitHub Actions workflow using `workflow_dispatch` to manually trigger `terraform apply` and `terraform destroy` directly from the cloud UI, completely removing the need for local execution.
  * Injected GitHub Secrets as `TF_VAR_` environment variables to securely pass MongoDB URIs and GitHub tokens into the cloud runner without hardcoding them.
  * Successfully spun up the AWS EKS cluster entirely through the automated cloud pipeline. 
  * **Next Step:** Deprecate Jenkins and install Argo CD for pull-based GitOps deployments.

### 16-October-2026 - Cluster Access & Manual Argo CD Exploration
**Objective:** Establish local administrative access to the EKS cluster, manually deploy Argo CD to understand its architecture, and prepare the environment for full GitOps automation.
* **Progress:** 
  * Configured local machine access to the newly built EKS cluster using `aws eks update-kubeconfig`.
  * Manually installed Argo CD via `kubectl` to study its underlying Custom Resource Definitions (CRDs) and component architecture.
  * Extracted and base64-decoded the `argocd-initial-admin-secret` to access the Argo CD GUI locally via port-forwarding.
  * Navigated the Argo CD UI to manually connect the GitHub repository and validate the pull-based GitOps deployment model.
  * Identified state conflicts and orphaned CRDs during manual teardowns, mapping out the requirements for a fully idempotent automated pipeline.
* **Next Step:** Translate these manual steps into pure Infrastructure-as-Code using Terraform's Helm provider to achieve a zero-touch, fully automated GitOps pipeline.

### 19-October-2026 - Pure GitOps Migration & Automated App Bootstrapping
**Objective:** Transition the legacy application deployment from Jenkins to Argo CD, automate database secret injection, and codify the application sync process using Terraform.
* **Progress:** 
  * Formally deprecated Jenkins in favor of a declarative, pull-based GitOps architecture.
  * Engineered `kubernetes_secret_v1` in Terraform to dynamically inject the MongoDB URI into EKS, eliminating manual credential management.
  * Debugged and resolved a critical Terraform provider race condition between the EKS module output and the Kubernetes provider initialization.
  * Implemented a secondary `helm_release` (`argocd-apps`) to inject the declarative application manifest directly into Argo CD upon boot, achieving a true zero-touch deployment.
  * Adopted GitFlow best practices by isolating infrastructure changes in a `feature/argocd` branch before cleanly merging into `main`.
  * **Next Step:** Create the `feature/5-pod-queue` branch to architect and deploy the asynchronous 5-pod task queue microservice (React, Node.js, Redis, Python, MongoDB).

---

*Developed by Jaikumar Gaja.*