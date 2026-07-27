# 🐧 Linux System Administrator — Complete Course
## Part 60 of ∞: Final Capstone — Production-Grade Infrastructure

---

> **🎯 Goal:** Build a complete production-grade microservice platform from scratch — end-to-end — covering every domain from Parts 1-59. By the end of this capstone, you will have deployed a real, cloud-native application with CI/CD, observability, auto-scaling, security hardening, and chaos-tested resilience.

> **⏱️ Estimated time:** 2-4 weeks (do not rush — this is your portfolio project)

---

## 1. Capstone Overview

### The Project

You will build and deploy a **multi-tier microservice platform** on Kubernetes in a cloud environment (AWS or GCP — choose one). The platform consists of:

- A **FastAPI microservice** exposing a REST API with PostgreSQL persistence and Redis caching
- A **React static frontend** served via CDN from S3/GCS
- A **background worker** consuming a message queue for async tasks
- A **CI/CD pipeline** that builds, scans, tests, and deploys automatically
- A **complete observability stack** (metrics, logs, traces)
- **SLO-based monitoring** with alerting
- **Chaos experiments** validated against the running system

### Skills Validated

| Domain | Parts | What You'll Prove |
|--------|-------|-------------------|
| Linux Fundamentals | 1-10 | Docker images, shell scripting in CI/CD |
| Essential Ops | 11-25 | systemd (for node agents), package management |
| Storage & Fs | 26-35 | PersistentVolumeClaims, backup strategies |
| Networking | 36-45 | CNI (Cilium), network policies, ingress, DNS |
| Servers & Apps | 46-55 | Web server (FastAPI), DB (PostgreSQL), Docker, K8s, monitoring, CI/CD, Terraform |
| Advanced | 56-59 | Kernel tuning for k8s nodes, performance, security, HA |

### Prerequisites

- Cloud account (AWS free tier or GCP free tier — credits available)
- Domain name (optional but recommended for full ingress experience)
- kubectl, helm, terraform, docker, gh CLI installed locally
- Part 59 (SRE) concepts: SLOs, error budgets, SLIs

---

## 2. Architecture Design

### Requirements

| Requirement | Implementation |
|-------------|---------------|
| High Availability | Multi-AZ (2+ AZs), PodDisruptionBudgets, anti-affinity |
| Auto-scaling | HPA (CPU/memory + custom metrics), cluster-autoscaler |
| Observability | Prometheus + Grafana + Loki + Tempo |
| Security | TLS everywhere, network policies, OIDC, image scanning |
| CI/CD | GitHub Actions with OIDC to cloud, Helm per env |
| Cost Efficiency | Spot instances for workers, right-sizing, Kubecost |

### System Design

```
┌─────────────────────────────────────────────────────────────────────┐
│                          Internet                                   │
├─────────────────────────────────────────────────────────────────────┤
│                              │                                      │
│                         [DNS (Route53)]                             │
│                              │                                      │
│                   [CloudFront / CDN]                                │
│                      │              │                               │
│                [ALB / GLB]    [S3 / GCS Static]                    │
│                      │                                              │
│            [Ingress-Nginx Controller]                               │
│                      │                                              │
│         ┌────────────┼────────────┐                                │
│         │            │            │                                │
│    [Frontend]   [API Pods]   [Worker Pods]                         │
│    (React)      (FastAPI)    (Celery/Python)                       │
│         │            │            │                                │
│         │       [Service]    [Service]                              │
│         │            │            │                                │
│         │    [Redis Cache]  [RabbitMQ/Redis]                       │
│         │            │                                              │
│         │    [PostgreSQL RDS]                                       │
│         │                                                           │
│    [EKS / GKE Cluster — 2 AZs, Node Groups]                        │
│         │                                                           │
│    [Prometheus/Grafana/Loki/Tempo — Observability]                 │
│         │                                                           │
│    [Velero — Cluster Backup]                                       │
└─────────────────────────────────────────────────────────────────────┘
```

### Component Inventory

| Component | Technology | Purpose |
|-----------|-----------|---------|
| Load Balancer | AWS ALB / GCP GLB | Single entry point, TLS termination |
| DNS | Route53 / Cloud DNS | Ingress DNS resolution |
| CDN | CloudFront / Cloud CDN | Static asset delivery |
| Kubernetes | EKS / GKE | Container orchestration |
| API Service | FastAPI (Python) | REST API with async endpoints |
| Database | RDS PostgreSQL (Aurora) | Persistent storage |
| Cache | ElastiCache Redis / Memorystore | Session caching, rate limiting |
| Queue | SQS / PubSub or RabbitMQ | Async task distribution |
| Container Registry | ECR / GCR / ACR | Image storage |
| CI/CD | GitHub Actions | Build, test, deploy automation |
| Observability | Prometheus + Grafana + Loki + Tempo | Metrics, logs, traces |
| Secrets | AWS Secrets Manager / GCP Secret Manager + External Secrets Operator | Credential management |
| Backup | Velero + RDS snapshots | Disaster recovery |
| Cost | Kubecost | Cloud cost monitoring |

---

## 3. Infrastructure Provisioning (Terraform)

### Terraform Structure

```
terraform/
├── main.tf                  # Provider config, backend, root module
├── variables.tf             # Input variables
├── outputs.tf               # Output values
├── versions.tf              # Terraform + provider version constraints
├── modules/
│   ├── vpc/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── eks/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── rds/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── redis/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── iam/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
└── environments/
    ├── dev.tfvars
    ├── staging.tfvars
    └── prod.tfvars
```

### VPC Module

```hcl
# terraform/modules/vpc/main.tf
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.cluster_name}-vpc"
    Environment = var.environment
  }
}

resource "aws_subnet" "public" {
  count             = length(var.public_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name                                         = "${var.cluster_name}-public-${count.index}"
    "kubernetes.io/cluster/${var.cluster_name}"  = "shared"
    "kubernetes.io/role/elb"                     = "1"
    Environment                                  = var.environment
  }
}

resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name                                         = "${var.cluster_name}-private-${count.index}"
    "kubernetes.io/cluster/${var.cluster_name}"  = "shared"
    "kubernetes.io/role/internal-elb"            = "1"
    Environment                                  = var.environment
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.cluster_name}-igw"
    Environment = var.environment
  }
}

resource "aws_eip" "nat" {
  count  = length(var.public_subnet_cidrs)
  domain = "vpc"

  tags = {
    Name        = "${var.cluster_name}-nat-${count.index}"
    Environment = var.environment
  }
}

resource "aws_nat_gateway" "main" {
  count         = length(var.public_subnet_cidrs)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name        = "${var.cluster_name}-nat-${count.index}"
    Environment = var.environment
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name        = "${var.cluster_name}-public-rt"
    Environment = var.environment
  }
}

resource "aws_route_table_association" "public" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  count  = length(var.private_subnet_cidrs)
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }

  tags = {
    Name        = "${var.cluster_name}-private-rt-${count.index}"
    Environment = var.environment
  }
}

resource "aws_route_table_association" "private" {
  count          = length(var.private_subnet_cidrs)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}
```

### EKS Cluster Module

```hcl
# terraform/modules/eks/main.tf
resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster.arn
  version  = var.kubernetes_version

  vpc_config {
    subnet_ids              = concat(var.public_subnet_ids, var.private_subnet_ids)
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = var.allowed_public_cidrs
  }

  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  encryption_config {
    provider {
      key_arn = aws_kms_key.eks.arn
    }
    resources = ["secrets"]
  }

  tags = {
    Name        = var.cluster_name
    Environment = var.environment
  }
}

resource "aws_eks_node_group" "system" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.cluster_name}-system"
  node_role_arn   = aws_iam_role.eks_nodes.arn
  subnet_ids      = var.private_subnet_ids
  instance_types  = var.system_node_instance_types
  disk_size       = var.system_node_disk_size

  scaling_config {
    desired_size = var.system_node_min_size
    min_size     = var.system_node_min_size
    max_size     = var.system_node_max_size
  }

  update_config {
    max_unavailable_percentage = 33
  }

  labels = {
    "node-type"           = "system"
    "nodepool"            = "system"
  }

  tags = {
    Name                                                            = "${var.cluster_name}-system"
    "k8s.io/cluster-autoscaler/${var.cluster_name}"                 = "owned"
    "k8s.io/cluster-autoscaler/enabled"                             = "true"
    Environment                                                     = var.environment
  }
}

resource "aws_eks_node_group" "application" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.cluster_name}-application"
  node_role_arn   = aws_iam_role.eks_nodes.arn
  subnet_ids      = var.private_subnet_ids
  instance_types  = var.application_node_instance_types
  disk_size       = var.application_node_disk_size

  scaling_config {
    desired_size = var.application_node_min_size
    min_size     = var.application_node_min_size
    max_size     = var.application_node_max_size
  }

  update_config {
    max_unavailable_percentage = 33
  }

  labels = {
    "node-type"           = "application"
    "nodepool"            = "application"
  }

  taint {
    key    = "dedicated"
    value  = "application"
    effect = "NO_SCHEDULE"
  }

  tags = {
    Name                                                            = "${var.cluster_name}-application"
    "k8s.io/cluster-autoscaler/${var.cluster_name}"                 = "owned"
    "k8s.io/cluster-autoscaler/enabled"                             = "true"
    Environment                                                     = var.environment
  }
}

resource "aws_iam_role" "eks_cluster" {
  name = "${var.cluster_name}-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster.name
}

resource "aws_iam_role_policy_attachment" "eks_cluster_AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks_cluster.name
}

resource "aws_iam_role" "eks_nodes" {
  name = "${var.cluster_name}-eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "nodes_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_iam_role_policy_attachment" "nodes_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_iam_role_policy_attachment" "nodes_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_kms_key" "eks" {
  description             = "EKS Secret Encryption Key"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

resource "aws_iam_openid_connect_provider" "main" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [var.eks_oidc_thumbprint]
  url             = aws_eks_cluster.main.identity[0].oidc[0].issuer
}
```

### RDS PostgreSQL Module

```hcl
# terraform/modules/rds/main.tf
resource "aws_db_subnet_group" "main" {
  name       = "${var.cluster_name}-rds-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name        = "${var.cluster_name}-rds-subnet-group"
    Environment = var.environment
  }
}

resource "aws_db_parameter_group" "main" {
  name   = "${var.cluster_name}-postgres16"
  family = "postgres16"

  parameter {
    name  = "log_min_duration_statement"
    value = "1000"
  }

  parameter {
    name  = "log_connections"
    value = "1"
  }

  parameter {
    name  = "log_disconnections"
    value = "1"
  }

  parameter {
    name  = "shared_preload_libraries"
    value = "pg_stat_statements,auto_explain"
  }
}

resource "aws_db_instance" "main" {
  identifier     = "${var.cluster_name}-database"
  engine         = "postgres"
  engine_version = "16.4"
  instance_class = var.instance_class

  db_name  = var.database_name
  username = var.database_username
  password = random_password.master.result

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_encrypted     = true
  storage_type          = "gp3"

  backup_retention_period = var.backup_retention_days
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"

  multi_az               = var.multi_az
  deletion_protection    = true
  skip_final_snapshot    = false
  final_snapshot_identifier = "${var.cluster_name}-final-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"

  performance_insights_enabled          = true
  performance_insights_retention_period = 7

  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  tags = {
    Name        = "${var.cluster_name}-database"
    Environment = var.environment
  }
}

resource "random_password" "master" {
  length  = 32
  special = false
}

resource "aws_secretsmanager_secret" "database" {
  name = "${var.cluster_name}-database-credentials"

  tags = {
    Environment = var.environment
  }
}

resource "aws_secretsmanager_secret_version" "database" {
  secret_id = aws_secretsmanager_secret.database.id
  secret_string = jsonencode({
    username = var.database_username
    password = random_password.master.result
    host     = aws_db_instance.main.address
    port     = aws_db_instance.main.port
    dbname   = var.database_name
    engine   = "postgresql"
  })
}

resource "aws_security_group" "rds" {
  name        = "${var.cluster_name}-rds-sg"
  description = "RDS PostgreSQL security group"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.eks_cluster_sg_id]
    description     = "Allow PostgreSQL from EKS cluster"
  }

  tags = {
    Name        = "${var.cluster_name}-rds-sg"
    Environment = var.environment
  }
}
```

### Root Module

```hcl
# terraform/main.tf
terraform {
  required_version = ">= 1.7"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  backend "s3" {
    bucket         = "tf-state-capstone"
    key            = "capstone/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "tf-state-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project     = "capstone"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

module "vpc" {
  source = "./modules/vpc"

  cluster_name       = var.cluster_name
  environment        = var.environment
  vpc_cidr           = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
}

module "eks" {
  source = "./modules/eks"

  cluster_name                   = var.cluster_name
  environment                    = var.environment
  kubernetes_version             = var.kubernetes_version
  public_subnet_ids              = module.vpc.public_subnet_ids
  private_subnet_ids             = module.vpc.private_subnet_ids
  system_node_instance_types     = var.system_node_instance_types
  system_node_disk_size          = var.system_node_disk_size
  system_node_min_size           = var.system_node_min_size
  system_node_max_size           = var.system_node_max_size
  application_node_instance_types = var.application_node_instance_types
  application_node_disk_size     = var.application_node_disk_size
  application_node_min_size      = var.application_node_min_size
  application_node_max_size      = var.application_node_max_size
  allowed_public_cidrs           = var.allowed_public_cidrs
  eks_oidc_thumbprint            = var.eks_oidc_thumbprint
}

module "rds" {
  source = "./modules/rds"

  cluster_name         = var.cluster_name
  environment          = var.environment
  vpc_id               = module.vpc.vpc_id
  private_subnet_ids   = module.vpc.private_subnet_ids
  eks_cluster_sg_id    = module.eks.cluster_security_group_id
  instance_class       = var.rds_instance_class
  database_name        = var.database_name
  database_username    = var.database_username
  allocated_storage    = var.rds_allocated_storage
  max_allocated_storage = var.rds_max_allocated_storage
  backup_retention_days = var.rds_backup_retention_days
  multi_az             = var.rds_multi_az
}

module "redis" {
  source = "./modules/redis"

  cluster_name          = var.cluster_name
  environment           = var.environment
  vpc_id                = module.vpc.vpc_id
  private_subnet_ids    = module.vpc.private_subnet_ids
  eks_cluster_sg_id     = module.eks.cluster_security_group_id
  node_type             = var.redis_node_type
  num_cache_nodes       = var.redis_num_nodes
  engine_version        = var.redis_engine_version
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "cluster_ca_certificate" {
  value     = module.eks.cluster_certificate_authority_data
  sensitive = true
}

output "database_endpoint" {
  value     = module.rds.database_endpoint
  sensitive = true
}

output "redis_endpoint" {
  value     = module.redis.endpoint
  sensitive = true
}

output "oidc_provider_arn" {
  value = module.eks.oidc_provider_arn
}
```

---

## 4. Kubernetes Cluster Setup

### Cluster Access and Config

```bash
# Configure kubeconfig
aws eks update-kubeconfig --name capstone-cluster --region us-east-1

# Verify access
kubectl cluster-info
kubectl get nodes -o wide
```

### CNI — Cilium Installation

```bash
helm repo add cilium https://helm.cilium.io/
helm repo update

helm upgrade --install cilium cilium/cilium \
  --namespace kube-system \
  --set cluster.name=capstone-cluster \
  --set cluster.id=1 \
  --set ipam.mode=kubernetes \
  --set kubeProxyReplacement=strict \
  --set securityContext.capabilities.add="{NET_ADMIN,SYS_ADMIN}" \
  --set hubble.relay.enabled=true \
  --set hubble.ui.enabled=true \
  --set hubble.metrics.enabled="{dns,drop,tcp,flow,port-distribution,icmp,http}"
```

### Metrics Server

```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Verify
kubectl top nodes
kubectl top pods -A
```

### Cluster Autoscaler

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: cluster-autoscaler
  namespace: kube-system
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::ACCOUNT_ID:role/cluster-autoscaler-role
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: cluster-autoscaler
rules:
  - apiGroups: [""]
    resources: ["nodes", "pods", "services", "replicationcontrollers", "persistentvolumeclaims",
                "persistentvolumes"]
    verbs: ["get", "list", "watch"]
  - apiGroups: ["apps"]
    resources: ["daemonsets", "replicasets", "statefulsets", "deployments"]
    verbs: ["get", "list", "watch"]
  - apiGroups: ["batch"]
    resources: ["jobs", "cronjobs"]
    verbs: ["get", "list", "watch"]
  - apiGroups: ["policy"]
    resources: ["poddisruptionbudgets"]
    verbs: ["get", "list", "watch"]
  - apiGroups: ["storage.k8s.io"]
    resources: ["storageclasses", "csinodes", "csidrivers", "csistoragecapacities"]
    verbs: ["get", "list", "watch"]
  - apiGroups: [""]
    resources: ["events"]
    verbs: ["create", "patch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: cluster-autoscaler
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-autoscaler
subjects:
  - kind: ServiceAccount
    name: cluster-autoscaler
    namespace: kube-system
EOF

helm upgrade --install cluster-autoscaler autoscaler/cluster-autoscaler \
  --repo https://kubernetes.github.io/autoscaler \
  --namespace kube-system \
  --set autoDiscovery.clusterName=capstone-cluster \
  --set awsRegion=us-east-1 \
  --set rbac.serviceAccount.name=cluster-autoscaler \
  --set rbac.serviceAccount.annotations."eks\.amazonaws\.com/role-arn"=arn:aws:iam::ACCOUNT_ID:role/cluster-autoscaler-role
```

### cert-manager

```bash
helm repo add jetstack https://charts.jetstack.io
helm repo update

helm upgrade --install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --set crds.enabled=true \
  --set global.leaderElection.namespace=cert-manager

# ClusterIssuer for Let's Encrypt (production)
cat <<'EOF' | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: admin@example.com
    privateKeySecretRef:
      name: letsencrypt-prod-private-key
    solvers:
      - http01:
          ingress:
            class: nginx
EOF
```

### ExternalDNS

```bash
helm upgrade --install external-dns external-dns/external-dns \
  --repo https://kubernetes-sigs.github.io/external-dns \
  --namespace external-dns \
  --create-namespace \
  --set provider=aws \
  --set aws.zoneType=public \
  --set txtOwnerId=capstone-cluster \
  --set rbac.create=true \
  --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"=arn:aws:iam::ACCOUNT_ID:role/external-dns-role
```

### Ingress-Nginx Controller

```bash
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --repo https://kubernetes.github.io/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.service.type=LoadBalancer \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/aws-load-balancer-type"=nlb \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/aws-load-balancer-scheme"=internet-facing \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/aws-load-balancer-ssl-cert"=arn:aws:acm:us-east-1:ACCOUNT_ID:certificate/xxxx \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/aws-load-balancer-ssl-ports"=443 \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/aws-load-balancer-backend-protocol"=http \
  --set controller.config.use-forwarded-headers=true \
  --set controller.metrics.enabled=true \
  --set controller.metrics.serviceMonitor.enabled=true \
  --set controller.autoscaling.enabled=true \
  --set controller.autoscaling.minReplicas=2 \
  --set controller.resources.requests.cpu=100m \
  --set controller.resources.requests.memory=128Mi

# Check the load balancer DNS name
kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

### Storage Class (EBS CSI Driver)

```bash
# Install EBS CSI driver add-on
eksctl create addon --cluster capstone-cluster --name aws-ebs-csi-driver \
  --service-account-role-arn arn:aws:iam::ACCOUNT_ID:role/ebs-csi-driver-role \
  --force

# Default storage class
cat <<'EOF' | kubectl apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: ebs-gp3-retained
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
provisioner: ebs.csi.aws.com
parameters:
  type: gp3
  iops: "3000"
  throughput: "125"
  encrypted: "true"
reclaimPolicy: Retain
allowVolumeExpansion: true
volumeBindingMode: WaitForFirstConsumer
EOF
```

---

## 5. Application Deployment

### Sample Microservice — FastAPI Application

```python
# app/main.py
import os
import time
import uuid
from contextlib import asynccontextmanager

import asyncpg
import redis.asynced as aioredis
from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from opentelemetry import trace
from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor
from opentelemetry.instrumentation.httpx import HTTPXClientInstrumentor
from opentelemetry.sdk.resources import Resource
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from prometheus_client import Counter, Histogram, generate_latest
from starlette.responses import Response

# Metrics
REQUEST_COUNT = Counter("app_requests_total", "Total requests", ["method", "endpoint", "status"])
REQUEST_DURATION = Histogram("app_request_duration_seconds", "Request duration in seconds",
                             ["method", "endpoint"], buckets=(0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10))
ERROR_COUNT = Counter("app_errors_total", "Total errors", ["method", "endpoint"])

pool = None
redis_client = None

@asynccontextmanager
async def lifespan(app: FastAPI):
    global pool, redis_client
    pool = await asyncpg.create_pool(
        dsn=os.getenv("DATABASE_URL"),
        min_size=5,
        max_size=20,
        command_timeout=30,
    )
    redis_client = aioredis.from_url(
        os.getenv("REDIS_URL", "redis://localhost:6379/0"),
        max_connections=20,
        decode_responses=True,
    )
    tracer_provider = TracerProvider(
        resource=Resource.create({"service.name": "api-service"})
    )
    tracer_provider.add_span_processor(
        BatchSpanProcessor(OTLPSpanExporter(endpoint=os.getenv("OTEL_EXPORTER_OTLP_ENDPOINT", "http://tempo:4318/v1/traces")))
    )
    trace.set_tracer_provider(tracer_provider)
    yield
    await pool.close()
    await redis_client.close()

app = FastAPI(title="Capstone API", version="1.0.0", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

FastAPIInstrumentor.instrument_app(app)
HTTPXClientInstrumentor().instrument()

@app.middleware("http")
async def metrics_middleware(request: Request, call_next):
    start = time.time()
    response = await call_next(request)
    duration = time.time() - start
    REQUEST_COUNT.labels(method=request.method, endpoint=request.url.path, status=response.status_code).inc()
    REQUEST_DURATION.labels(method=request.method, endpoint=request.url.path).observe(duration)
    if response.status_code >= 500:
        ERROR_COUNT.labels(method=request.method, endpoint=request.url.path).inc()
    return response

@app.get("/metrics")
async def metrics():
    return Response(content=generate_latest(), media_type="text/plain")

@app.get("/health")
async def health():
    try:
        async with pool.acquire() as conn:
            await conn.execute("SELECT 1")
        await redis_client.ping()
        return {"status": "healthy", "database": "connected", "cache": "connected"}
    except Exception as e:
        raise HTTPException(status_code=503, detail=str(e))

@app.get("/api/v1/items")
async def list_items():
    async with pool.acquire() as conn:
        rows = await conn.fetch("SELECT id, name, created_at FROM items ORDER BY created_at DESC LIMIT 100")
    return [dict(row) for row in rows]

@app.post("/api/v1/items")
async def create_item(name: str):
    item_id = str(uuid.uuid4())
    async with pool.acquire() as conn:
        await conn.execute("INSERT INTO items (id, name) VALUES ($1, $2)", item_id, name)
    await redis_client.set(f"item:{item_id}", name, ex=3600)
    return {"id": item_id, "name": name}

@app.get("/api/v1/items/{item_id}")
async def get_item(item_id: str):
    cached = await redis_client.get(f"item:{item_id}")
    if cached:
        return {"id": item_id, "name": cached, "source": "cache"}
    async with pool.acquire() as conn:
        row = await conn.fetchrow("SELECT id, name, created_at FROM items WHERE id = $1", item_id)
    if not row:
        raise HTTPException(status_code=404, detail="Item not found")
    await redis_client.set(f"item:{item_id}", row["name"], ex=3600)
    return {"id": row["id"], "name": row["name"], "source": "database"}
```

### Dockerfile — Multi-Stage Build

```dockerfile
# Dockerfile
FROM python:3.12-slim AS builder

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc libpq-dev && \
    rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir --user -r requirements.txt && \
    find /root/.local -name "*.pyc" -delete

FROM python:3.12-slim AS runtime

WORKDIR /app

RUN groupadd -r appuser && useradd -r -g appuser appuser && \
    apt-get update && apt-get install -y --no-install-recommends \
    libpq5 curl ca-certificates && \
    rm -rf /var/lib/apt/lists/*

COPY --from=builder /root/.local /home/appuser/.local
COPY app/ .

ENV PATH=/home/appuser/.local/bin:$PATH \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

USER appuser

EXPOSE 8000

HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "4", "--limit-concurrency", "256"]
```

### requirements.txt

```txt
fastapi==0.115.0
uvicorn[standard]==0.30.6
asyncpg==0.29.0
redis[hiredis]==5.1.1
prometheus-client==0.20.0
opentelemetry-api==1.27.0
opentelemetry-sdk==1.27.0
opentelemetry-exporter-otlp-proto-http==1.27.0
opentelemetry-instrumentation-fastapi==0.48b0
opentelemetry-instrumentation-httpx==0.48b0
httpx==0.27.2
```

### Database Schema Migration (Alembic)

```python
# alembic/env.py
from logging.config import fileConfig
from alembic import context
import asyncpg
import os

config = context.config
fileConfig(config.config_file_name)

target_metadata = None

def run_migrations_online():
    connectable = asyncpg.create_pool(dsn=os.getenv("DATABASE_URL"))

    async def do_migrations():
        async with connectable.acquire() as conn:
            await conn.execute("""
                CREATE TABLE IF NOT EXISTS items (
                    id UUID PRIMARY KEY,
                    name VARCHAR(255) NOT NULL,
                    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
                );
                CREATE INDEX IF NOT EXISTS idx_items_created_at ON items(created_at DESC);
            """)

    import asyncio
    asyncio.run(do_migrations())

run_migrations_online()
```

### Helm Chart Structure

```
helm/
├── Chart.yaml
├── values.yaml
├── values-staging.yaml
├── values-prod.yaml
└── templates/
    ├── _helpers.tpl
    ├── deployment.yaml
    ├── service.yaml
    ├── ingress.yaml
    ├── hpa.yaml
    ├── pdb.yaml
    ├── servicemonitor.yaml
    ├── configmap.yaml
    └── externalsecret.yaml
```

### Helm Chart — Deployment

```yaml
# helm/templates/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "capstone.fullname" . }}
  labels:
    {{- include "capstone.labels" . | nindent 4 }}
spec:
  replicas: {{ .Values.replicaCount }}
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 0
      maxSurge: 1
  selector:
    matchLabels:
      {{- include "capstone.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      labels:
        {{- include "capstone.selectorLabels" . | nindent 8 }}
        {{- if .Values.podLabels }}
        {{- toYaml .Values.podLabels | nindent 8 }}
        {{- end }}
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "8000"
        prometheus.io/path: "/metrics"
        checksum/config: {{ include (print $.Template.BasePath "/configmap.yaml") . | sha256sum }}
    spec:
      {{- if .Values.serviceAccount.create }}
      serviceAccountName: {{ include "capstone.serviceAccountName" . }}
      {{- end }}
      securityContext:
        {{- toYaml .Values.podSecurityContext | nindent 8 }}
      terminationGracePeriodSeconds: 60
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
            - weight: 100
              podAffinityTerm:
                labelSelector:
                  matchExpressions:
                    - key: app.kubernetes.io/name
                      operator: In
                      values:
                        - {{ include "capstone.name" . }}
                topologyKey: topology.kubernetes.io/zone
      {{- if .Values.nodeSelector }}
      nodeSelector:
        {{- toYaml .Values.nodeSelector | nindent 8 }}
      {{- end }}
      containers:
        - name: {{ .Chart.Name }}
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}"
          imagePullPolicy: {{ .Values.image.pullPolicy }}
          ports:
            - name: http
              containerPort: 8000
              protocol: TCP
          env:
            - name: DATABASE_URL
              valueFrom:
                secretKeyRef:
                  name: {{ include "capstone.fullname" . }}-db
                  key: database-url
            - name: REDIS_URL
              valueFrom:
                secretKeyRef:
                  name: {{ include "capstone.fullname" . }}-redis
                  key: redis-url
            - name: OTEL_EXPORTER_OTLP_ENDPOINT
              value: {{ .Values.otelEndpoint | quote }}
            - name: OTEL_SERVICE_NAME
              value: {{ include "capstone.fullname" . }}
          envFrom:
            - configMapRef:
                name: {{ include "capstone.fullname" . }}-config
          resources:
            {{- toYaml .Values.resources | nindent 12 }}
          livenessProbe:
            httpGet:
              path: /health
              port: http
            initialDelaySeconds: 10
            periodSeconds: 15
            timeoutSeconds: 5
            failureThreshold: 3
          readinessProbe:
            httpGet:
              path: /health
              port: http
            initialDelaySeconds: 5
            periodSeconds: 10
            timeoutSeconds: 3
            failureThreshold: 2
```

### Helm Chart — HPA

```yaml
# helm/templates/hpa.yaml
{{- if .Values.autoscaling.enabled }}
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: {{ include "capstone.fullname" . }}
  labels:
    {{- include "capstone.labels" . | nindent 4 }}
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: {{ include "capstone.fullname" . }}
  minReplicas: {{ .Values.autoscaling.minReplicas }}
  maxReplicas: {{ .Values.autoscaling.maxReplicas }}
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
        - type: Pods
          value: 1
          periodSeconds: 60
    scaleUp:
      stabilizationWindowSeconds: 0
      policies:
        - type: Percent
          value: 100
          periodSeconds: 15
        - type: Pods
          value: 4
          periodSeconds: 15
      selectPolicy: Max
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: {{ .Values.autoscaling.targetCPUUtilizationPercentage }}
    - type: Resource
      resource:
        name: memory
        target:
          type: Utilization
          averageUtilization: {{ .Values.autoscaling.targetMemoryUtilizationPercentage }}
    {{- if .Values.autoscaling.customMetrics }}
    {{- toYaml .Values.autoscaling.customMetrics | nindent 4 }}
    {{- end }}
{{- end }}
```

### Helm Chart — PDB

```yaml
# helm/templates/pdb.yaml
{{- if .Values.pdb.enabled }}
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: {{ include "capstone.fullname" . }}
  labels:
    {{- include "capstone.labels" . | nindent 4 }}
spec:
  minAvailable: {{ .Values.pdb.minAvailable }}
  selector:
    matchLabels:
      {{- include "capstone.selectorLabels" . | nindent 6 }}
{{- end }}
```

### Helm Chart — Ingress

```yaml
# helm/templates/ingress.yaml
{{- if .Values.ingress.enabled }}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ include "capstone.fullname" . }}
  labels:
    {{- include "capstone.labels" . | nindent 4 }}
  annotations:
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/use-regex: "true"
    nginx.ingress.kubernetes.io/rewrite-target: /$2
    {{- if .Values.ingress.certManager }}
    cert-manager.io/cluster-issuer: {{ .Values.ingress.certManager }}
    {{- end }}
    {{- if .Values.ingress.annotations }}
    {{- toYaml .Values.ingress.annotations | nindent 4 }}
    {{- end }}
spec:
  {{- if .Values.ingress.tls }}
  tls:
    {{- range .Values.ingress.tls }}
    - hosts:
        {{- range .hosts }}
        - {{ . | quote }}
        {{- end }}
      secretName: {{ .secretName }}
    {{- end }}
  {{- end }}
  rules:
    {{- range .Values.ingress.hosts }}
    - host: {{ .host | quote }}
      http:
        paths:
          {{- range .paths }}
          - path: {{ .path }}
            pathType: {{ .pathType }}
            backend:
              service:
                name: {{ include "capstone.fullname" $ }}
                port:
                  number: {{ $.Values.service.port }}
          {{- end }}
    {{- end }}
{{- end }}
```

### Helm Chart — ServiceMonitor

```yaml
# helm/templates/servicemonitor.yaml
{{- if .Values.serviceMonitor.enabled }}
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: {{ include "capstone.fullname" . }}
  labels:
    {{- include "capstone.labels" . | nindent 4 }}
    release: {{ .Values.serviceMonitor.release }}
spec:
  selector:
    matchLabels:
      {{- include "capstone.selectorLabels" . | nindent 6 }}
  endpoints:
    - port: http
      path: /metrics
      interval: {{ .Values.serviceMonitor.interval }}
      scrapeTimeout: {{ .Values.serviceMonitor.scrapeTimeout }}
  namespaceSelector:
    matchNames:
      - {{ .Release.Namespace }}
{{- end }}
```

### Helm Values

```yaml
# helm/values.yaml
replicaCount: 3

image:
  repository: ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/capstone-api
  tag: latest
  pullPolicy: IfNotPresent

serviceAccount:
  create: true
  name: ""

podSecurityContext:
  runAsNonRoot: true
  runAsUser: 1000
  fsGroup: 1000
  seccompProfile:
    type: RuntimeDefault

resources:
  requests:
    cpu: 250m
    memory: 256Mi
  limits:
    cpu: 500m
    memory: 512Mi

autoscaling:
  enabled: true
  minReplicas: 3
  maxReplicas: 20
  targetCPUUtilizationPercentage: 70
  targetMemoryUtilizationPercentage: 80

pdb:
  enabled: true
  minAvailable: 2

service:
  type: ClusterIP
  port: 80
  targetPort: 8000

ingress:
  enabled: true
  certManager: letsencrypt-prod
  hosts:
    - host: api.capstone.example.com
      paths:
        - path: /api(/|$)(.*)
          pathType: ImplementationSpecific
  tls:
    - hosts:
        - api.capstone.example.com
      secretName: api-tls

serviceMonitor:
  enabled: true
  release: kube-prometheus-stack
  interval: 15s
  scrapeTimeout: 10s

otelEndpoint: http://tempo.monitoring:4318/v1/traces

config:
  LOG_LEVEL: info
  MAX_ITEMS: 1000
  CACHE_TTL: 3600

nodeSelector:
  node-type: application
```

```yaml
# helm/values-prod.yaml
replicaCount: 5

autoscaling:
  minReplicas: 5
  maxReplicas: 30
  targetCPUUtilizationPercentage: 60
  targetMemoryUtilizationPercentage: 75

pdb:
  minAvailable: 3

resources:
  requests:
    cpu: 500m
    memory: 512Mi
  limits:
    cpu: 1000m
    memory: 1024Mi
```

---

## 6. CI/CD Pipeline

### GitHub Actions — Full Workflow

```yaml
# .github/workflows/deploy.yaml
name: CI/CD Pipeline

on:
  push:
    branches:
      - main
      - staging
  pull_request:
    branches:
      - main

permissions:
  id-token: write
  contents: read

env:
  AWS_REGION: us-east-1
  ECR_REPOSITORY: capstone-api
  K8S_NAMESPACE: production
  HELM_CHART_PATH: helm

jobs:
  lint:
    name: Lint and Format
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: "3.12"
      - run: pip install ruff mypy
      - run: ruff check app/ --fix
      - run: ruff format app/ --check
      - run: mypy app/ --ignore-missing-imports

  test:
    name: Run Tests
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:16-alpine
        env:
          POSTGRES_DB: testdb
          POSTGRES_USER: testuser
          POSTGRES_PASSWORD: testpass
        ports:
          - 5432:5432
      redis:
        image: redis:7-alpine
        ports:
          - 6379:6379
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: "3.12"
      - run: pip install -r requirements.txt pytest httpx
      - run: |
          cat > pytest.ini <<EOF
          [pytest]
          env =
            DATABASE_URL=postgresql://testuser:testpass@localhost:5432/testdb
            REDIS_URL=redis://localhost:6379/0
          EOF
      - run: pytest tests/ -v --cov=app --cov-report=term-missing --junitxml=test-results.xml
      - uses: dorny/test-reporter@v1
        if: success() || failure()
        with:
          name: Test Results
          path: test-results.xml
          reporter: java-junit

  build-and-push:
    name: Build and Push Image
    needs: [lint, test]
    if: github.ref == 'refs/heads/main' || github.ref == 'refs/heads/staging'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Configure AWS credentials via OIDC
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::${{ secrets.AWS_ACCOUNT_ID }}:role/github-actions-role
          aws-region: ${{ env.AWS_REGION }}
          role-session-name: GitHubActions

      - name: Login to Amazon ECR
        id: login-ecr
        uses: aws-actions/amazon-ecr-login@v2

      - name: Set image tag
        id: vars
        run: |
          SHORT_SHA=$(git rev-parse --short HEAD)
          BRANCH=${GITHUB_REF_NAME}
          echo "tag=${BRANCH}-${SHORT_SHA}-$(date +%s)" >> $GITHUB_OUTPUT
          echo "branch=${BRANCH}" >> $GITHUB_OUTPUT

      - name: Build Docker image
        env:
          ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
          IMAGE_TAG: ${{ steps.vars.outputs.tag }}
        run: |
          docker build \
            --build-arg BUILDKIT_INLINE_CACHE=1 \
            --cache-from $ECR_REGISTRY/$ECR_REPOSITORY:main-latest \
            -t $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG \
            -t $ECR_REGISTRY/$ECR_REPOSITORY:${{ steps.vars.outputs.branch }}-latest \
            .

      - name: Scan image for vulnerabilities
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: ${{ steps.login-ecr.outputs.registry }}/${{ env.ECR_REPOSITORY }}:${{ steps.vars.outputs.tag }}
          format: sarif
          output: trivy-results.sarif
          severity: CRITICAL,HIGH
          exit-code: 1

      - name: Upload Trivy results to GitHub Security
        uses: github/codeql-action/upload-sarif@v3
        if: always()
        with:
          sarif_file: trivy-results.sarif

      - name: Push Docker image
        env:
          ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
          IMAGE_TAG: ${{ steps.vars.outputs.tag }}
        run: |
          docker push $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG
          docker push $ECR_REGISTRY/$ECR_REPOSITORY:${{ steps.vars.outputs.branch }}-latest

      - name: Update image tag for deploy
        run: |
          echo "IMAGE_TAG=${{ steps.vars.outputs.tag }}" >> $GITHUB_ENV
          echo "ECR_REGISTRY=${{ steps.login-ecr.outputs.registry }}" >> $GITHUB_ENV

  deploy-staging:
    name: Deploy to Staging
    needs: build-and-push
    if: github.ref == 'refs/heads/staging'
    runs-on: ubuntu-latest
    environment: staging
    steps:
      - uses: actions/checkout@v4

      - name: Configure AWS credentials via OIDC
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::${{ secrets.AWS_ACCOUNT_ID }}:role/github-actions-role
          aws-region: ${{ env.AWS_REGION }}

      - name: Update kubeconfig
        run: |
          aws eks update-kubeconfig --name capstone-cluster --region $AWS_REGION

      - name: Deploy Helm chart
        run: |
          helm upgrade --install capstone-api ./$HELM_CHART_PATH \
            --namespace staging \
            --create-namespace \
            --values ./$HELM_CHART_PATH/values.yaml \
            --values ./$HELM_CHART_PATH/values-staging.yaml \
            --set image.tag=${{ env.IMAGE_TAG }} \
            --set image.repository=${{ env.ECR_REGISTRY }}/$ECR_REPOSITORY \
            --wait --timeout 5m

      - name: Integration test
        run: |
          sleep 30
          ENDPOINT=$(kubectl get ingress -n staging -o jsonpath='{.items[0].spec.rules[0].host}')
          curl -f --retry 5 --retry-delay 10 "https://${ENDPOINT}/health" || exit 1

  deploy-production:
    name: Deploy to Production
    needs: deploy-staging
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    environment:
      name: production
      url: https://api.capstone.example.com
    steps:
      - uses: actions/checkout@v4

      - name: Configure AWS credentials via OIDC
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::${{ secrets.AWS_ACCOUNT_ID }}:role/github-actions-role
          aws-region: ${{ env.AWS_REGION }}

      - name: Update kubeconfig
        run: |
          aws eks update-kubeconfig --name capstone-cluster --region $AWS_REGION

      - name: Deploy Helm chart
        run: |
          helm upgrade --install capstone-api ./$HELM_CHART_PATH \
            --namespace production \
            --create-namespace \
            --values ./$HELM_CHART_PATH/values.yaml \
            --values ./$HELM_CHART_PATH/values-prod.yaml \
            --set image.tag=${{ env.IMAGE_TAG }} \
            --set image.repository=${{ env.ECR_REGISTRY }}/$ECR_REPOSITORY \
            --wait --timeout 5m

      - name: Verify deployment
        run: |
          kubectl rollout status deployment/capstone-api -n production --timeout=3m
          kubectl get pods -n production -o wide

      - name: Smoke test
        run: |
          ENDPOINT=$(kubectl get ingress -n production -o jsonpath='{.items[0].spec.rules[0].host}')
          curl -f --retry 5 --retry-delay 10 "https://${ENDPOINT}/health" || exit 1
          curl -s "https://${ENDPOINT}/metrics" | grep -q "app_requests_total" || exit 1
```

### OIDC IAM Role for GitHub Actions

```hcl
# terraform/modules/iam/github-actions-role.tf
data "aws_iam_policy_document" "github_actions_assume" {
  statement {
    effect = "Allow"
    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }
    actions = ["sts:AssumeRoleWithWebIdentity"]
    condition {
      test     = "StringEquals"
      variable = "${replace(var.oidc_provider_url, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringLike"
      variable = "${replace(var.oidc_provider_url, "https://", "")}:sub"
      values   = ["repo:${var.github_org}/${var.github_repo}:*"]
    }
  }
}

resource "aws_iam_role" "github_actions" {
  name               = "${var.cluster_name}-github-actions-role"
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume.json
}

resource "aws_iam_role_policy" "github_actions" {
  name = "${var.cluster_name}-github-actions-policy"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
        ]
        Resource = var.ecr_repository_arns
      },
      {
        Effect = "Allow"
        Action = ["ecr:GetAuthorizationToken"]
        Resource = ["*"]
      },
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters",
        ]
        Resource = ["*"]
      },
    ]
  })
}
```

---

## 7. Database and Stateful Services

### PostgreSQL Schema Migration (Alembic)

```bash
# Initialize Alembic
pip install alembic asyncpg
alembic init alembic

# Generate initial migration
alembic revision --autogenerate -m "initial_schema"
```

```python
# alembic/versions/0001_initial_schema.py
"""initial_schema

Revision ID: 0001
Revises:
Create Date: 2024-01-01
"""
from alembic import op
import sqlalchemy as sa

revision = "0001"
down_revision = None
branch_labels = None
depends_on = None

def upgrade():
    op.create_table(
        "items",
        sa.Column("id", sa.UUID(), nullable=False),
        sa.Column("name", sa.String(255), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("idx_items_created_at", "items", ["created_at"], postgresql_using="brin")

def downgrade():
    op.drop_index("idx_items_created_at")
    op.drop_table("items")
```

### PgBouncer Connection Pooling

```yaml
# helm/pgbouncer/values.yaml
pgbouncer:
  image: edoburu/pgbouncer:1.22
  pool_mode: transaction
  default_pool_size: 25
  max_client_conn: 200
  reserve_pool_size: 5
  reserve_pool_timeout: 3
  query_timeout: 30
  idle_transaction_timeout: 60
  resources:
    requests:
      cpu: 100m
      memory: 128Mi
    limits:
      cpu: 200m
      memory: 256Mi
```

```yaml
# helm/pgbouncer/templates/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: pgbouncer
spec:
  replicas: 2
  selector:
    matchLabels:
      app: pgbouncer
  template:
    metadata:
      labels:
        app: pgbouncer
    spec:
      containers:
        - name: pgbouncer
          image: "{{ .Values.pgbouncer.image }}"
          ports:
            - containerPort: 5432
              name: postgres
          env:
            - name: DB_USER
              valueFrom:
                secretKeyRef:
                  name: capstone-api-db
                  key: username
            - name: DB_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: capstone-api-db
                  key: password
            - name: DB_HOST
              valueFrom:
                secretKeyRef:
                  name: capstone-api-db
                  key: host
            - name: DB_NAME
              valueFrom:
                secretKeyRef:
                  name: capstone-api-db
                  key: dbname
          envFrom:
            - configMapRef:
                name: pgbouncer-config
          resources:
            {{- toYaml .Values.pgbouncer.resources | nindent 12 }}
```

### RDS Automated Backups

```bash
# Manual snapshot
aws rds create-db-snapshot \
  --db-instance-identifier capstone-cluster-database \
  --db-snapshot-identifier manual-snapshot-$(date +%Y-%m-%d-%H%M)

# Copy snapshot to another region for DR
aws rds copy-db-snapshot \
  --source-db-snapshot-identifier arn:aws:rds:us-east-1:ACCOUNT_ID:snapshot:manual-snapshot-XXXX \
  --target-db-snapshot-identifier dr-snapshot-$(date +%Y-%m-%d) \
  --source-region us-east-1 \
  --region us-west-2

# Automated backup retention is set in Terraform (backup_retention_period)
```

### Database Backup Validation

```bash
#!/bin/bash
# scripts/validate-backup.sh
set -euo pipefail

SNAPSHOT_ID=$(aws rds describe-db-snapshots \
  --db-instance-identifier capstone-cluster-database \
  --query "DBSnapshots[-1].DBSnapshotIdentifier" \
  --output text)

echo "Validating snapshot: $SNAPSHOT_ID"

STATUS=$(aws rds describe-db-snapshots \
  --db-snapshot-identifier "$SNAPSHOT_ID" \
  --query "DBSnapshots[0].Status" \
  --output text)

if [ "$STATUS" = "available" ]; then
  echo "✅ Snapshot $SNAPSHOT_ID is available and valid"
  exit 0
else
  echo "❌ Snapshot $SNAPSHOT_ID status: $STATUS"
  exit 1
fi
```

---

## 8. Secrets and Configuration

### External Secrets Operator

```bash
helm repo add external-secrets https://charts.external-secrets.io
helm repo update

helm upgrade --install external-secrets external-secrets/external-secrets \
  --namespace external-secrets \
  --create-namespace \
  --set installCRDs=true \
  --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"=arn:aws:iam::ACCOUNT_ID:role/external-secrets-role
```

### SecretStore — AWS Secrets Manager

```yaml
# helm/templates/externalsecret.yaml
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: {{ include "capstone.fullname" . }}
spec:
  provider:
    aws:
      service: SecretsManager
      region: {{ .Values.awsRegion }}
      auth:
        jwt:
          serviceAccountRef:
            name: {{ include "capstone.serviceAccountName" . }}
---
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: {{ include "capstone.fullname" . }}-db
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: {{ include "capstone.fullname" . }}
    kind: SecretStore
  target:
    name: {{ include "capstone.fullname" . }}-db
    creationPolicy: Owner
  data:
    - secretKey: database-url
      remoteRef:
        key: capstone-database-credentials
        property: connection_string
---
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: {{ include "capstone.fullname" . }}-redis
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: {{ include "capstone.fullname" . }}
    kind: SecretStore
  target:
    name: {{ include "capstone.fullname" . }}-redis
    creationPolicy: Owner
  data:
    - secretKey: redis-url
      remoteRef:
        key: capstone-redis-credentials
        property: connection_string
```

### ConfigMap for App Configuration

```yaml
# helm/templates/configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "capstone.fullname" . }}-config
  labels:
    {{- include "capstone.labels" . | nindent 4 }}
data:
  LOG_LEVEL: {{ .Values.config.LOG_LEVEL | quote }}
  MAX_ITEMS: {{ .Values.config.MAX_ITEMS | quote }}
  CACHE_TTL: {{ .Values.config.CACHE_TTL | quote }}
  {{- if .Values.config.extra }}
  {{- toYaml .Values.config.extra | nindent 2 }}
  {{- end }}
```

---

## 9. Observability Stack

### kube-prometheus-stack

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --set prometheus.prometheusSpec.scrapeInterval=15s \
  --set prometheus.prometheusSpec.evaluationInterval=15s \
  --set prometheus.prometheusSpec.retention=30d \
  --set prometheus.prometheusSpec.retentionSize=50GB \
  --set prometheus.prometheusSpec.resources.requests.cpu=500m \
  --set prometheus.prometheusSpec.resources.requests.memory=2Gi \
  --set prometheus.prometheusSpec.resources.limits.cpu=1000m \
  --set prometheus.prometheusSpec.resources.limits.memory=4Gi \
  --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.storageClassName=ebs-gp3-retained \
  --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage=100Gi \
  --set alertmanager.enabled=true \
  --set alertmanager.alertmanagerSpec.replicas=2 \
  --set grafana.adminPassword=admin \
  --set grafana.defaultDashboardsEnabled=true \
  --set grafana.plugins="{grafana-piechart-panel}" \
  --set grafana.sidecar.dashboards.enabled=true \
  --set grafana.sidecar.dashboards.label=grafana_dashboard \
  --set grafana.sidecar.datasources.enabled=true
```

### Grafana Dashboards — Application SLO

```json
{
  "dashboard": {
    "title": "Capstone API - SLO Dashboard",
    "tags": ["slo", "capstone"],
    "timezone": "browser",
    "panels": [
      {
        "title": "Request Rate",
        "type": "graph",
        "gridPos": {"h": 8, "w": 12, "x": 0, "y": 0},
        "targets": [
          {
            "expr": "sum(rate(app_requests_total[5m]))",
            "legendFormat": "Total Requests/s"
          }
        ]
      },
      {
        "title": "Error Rate (5xx)",
        "type": "graph",
        "gridPos": {"h": 8, "w": 12, "x": 12, "y": 0},
        "targets": [
          {
            "expr": "sum(rate(app_errors_total[5m]))",
            "legendFormat": "Errors/s"
          }
        ]
      },
      {
        "title": "Latency P50 / P95 / P99",
        "type": "graph",
        "gridPos": {"h": 8, "w": 12, "x": 0, "y": 8},
        "targets": [
          {
            "expr": "histogram_quantile(0.50, sum(rate(app_request_duration_seconds_bucket[5m])) by (le))",
            "legendFormat": "P50"
          },
          {
            "expr": "histogram_quantile(0.95, sum(rate(app_request_duration_seconds_bucket[5m])) by (le))",
            "legendFormat": "P95"
          },
          {
            "expr": "histogram_quantile(0.99, sum(rate(app_request_duration_seconds_bucket[5m])) by (le))",
            "legendFormat": "P99"
          }
        ]
      },
      {
        "title": "SLO: Error Budget Remaining (30d rolling)",
        "type": "stat",
        "gridPos": {"h": 8, "w": 12, "x": 12, "y": 8},
        "targets": [
          {
            "expr": "1 - (sum(rate(app_errors_total[30d])) / sum(rate(app_requests_total[30d])))",
            "legendFormat": "Availability"
          }
        ],
        "thresholds": [
          {"value": 0.999, "color": "green"},
          {"value": 0.995, "color": "yellow"},
          {"value": 0.99, "color": "red"}
        ]
      },
      {
        "title": "Active Pods (per version)",
        "type": "graph",
        "gridPos": {"h": 8, "w": 24, "x": 0, "y": 16},
        "targets": [
          {
            "expr": "count(kube_pod_info{namespace=\"production\"}) by (created_by_kind)",
            "legendFormat": "{{created_by_kind}}"
          }
        ]
      }
    ],
    "schemaVersion": 27,
    "version": 1
  }
}
```

### Loki + Promtail for Logs

```bash
helm upgrade --install loki grafana/loki \
  --namespace monitoring \
  --set loki.commonConfig.replication_factor=1 \
  --set loki.storage.type=filesystem \
  --set loki.auth_enabled=false \
  --set singleBinary.replicas=1 \
  --set test.enabled=false

helm upgrade --install promtail grafana/promtail \
  --namespace monitoring \
  --set config.lokiAddress=http://loki.monitoring:3100/loki/api/v1/push \
  --set config.clients[0].url=http://loki.monitoring:3100/loki/api/v1/push \
  --set config.snippets.scrapeConfigs[0].pipelineStages[0].regex.source="(?P<level>(ERROR|WARN|INFO|DEBUG))"
```

### Tempo for Distributed Tracing

```bash
helm upgrade --install tempo grafana/tempo \
  --namespace monitoring \
  --set traces.otlp.grpc.enabled=true \
  --set traces.otlp.http.enabled=true \
  --set storage.trace.backend=local \
  --set storage.trace.local.path=/var/tempo/traces \
  --set server.http_listen_port=3200
```

---

## 10. Scaling and Resilience

### HPA — Advanced Configuration

```yaml
# Custom metrics HPA example
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: capstone-api-custom
  namespace: production
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: capstone-api
  minReplicas: 3
  maxReplicas: 50
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
        - type: Pods
          value: 2
          periodSeconds: 60
    scaleUp:
      stabilizationWindowSeconds: 0
      policies:
        - type: Pods
          value: 10
          periodSeconds: 15
        - type: Percent
          value: 200
          periodSeconds: 15
      selectPolicy: Max
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70
    - type: Resource
      resource:
        name: memory
        target:
          type: Utilization
          averageUtilization: 80
    - type: Pods
      pods:
        metric:
          name: app_requests_per_second
        target:
          type: AverageValue
          averageValue: 1000
```

### Cluster Autoscaler Verification

```bash
# Check cluster-autoscaler status
kubectl logs -n kube-system -l app.kubernetes.io/name=cluster-autoscaler --tail=50

# Simulate scale-up by deploying many pods
kubectl create deployment stress-test --image=nginx --replicas=100
watch kubectl get pods
# Observe new nodes being added

# Clean up
kubectl delete deployment stress-test
# Observe nodes being drained and removed
```

### PodDisruptionBudget Verification

```yaml
# Test PDB with eviction
kubectl drain NODE_NAME --ignore-daemonsets
# Without PDB: pods get evicted immediately
# With PDB: eviction waits until minAvailable is satisfied
```

### Anti-Affinity Rules

```yaml
# Verified by checking pod distribution across zones
kubectl get pods -n production -o wide --sort-by=.spec.nodeName

# Confirm pods are spread
kubectl get pods -n production -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.nodeName}{"\n"}{end}'
```

---

## 11. Security Hardening

### Pod Security Standards — Restricted Profile

```yaml
# Apply restricted PodSecurityStandard via label
kubectl label ns production pod-security.kubernetes.io/enforce=restricted

# Verify with dry-run first
kubectl label --dry-run=server ns production pod-security.kubernetes.io/enforce=restricted

# If a pod violates, it will not be admitted
kubectl run bad-pod --image=nginx --privileged -n production
# Error: violates PodSecurity "restricted:latest" (privileged, allowPrivilegeEscalation=true)
```

### Network Policies — Cilium L3/L7

```yaml
# Default deny-all ingress
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-ingress
  namespace: production
spec:
  podSelector: {}
  policyTypes:
    - Ingress
---
# Allow API traffic from ingress controller only
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-api-ingress
  namespace: production
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: capstone-api
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: ingress-nginx
          podSelector:
            matchLabels:
              app.kubernetes.io/component: controller
      ports:
        - port: 8000
---
# Allow database access only from app pods
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-db-access
  namespace: production
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: pgbouncer
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app.kubernetes.io/name: capstone-api
      ports:
        - port: 5432
---
# Cilium L7 policy — allow only GET /api/v1/items
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: allow-api-read-only
  namespace: production
spec:
  endpointSelector:
    matchLabels:
      app.kubernetes.io/name: capstone-api
  ingress:
    - fromEndpoints:
        - matchLabels:
            app.kubernetes.io/component: controller
      toPorts:
        - ports:
            - port: "8000"
              protocol: TCP
          rules:
            http:
              - method: GET
                path: /api/v1/items/?$
              - method: GET
                path: /health$
              - method: GET
                path: /metrics$
```

### Kyverno — Policy Enforcement

```bash
helm repo add kyverno https://kyverno.github.io/kyverno/
helm repo update

helm upgrade --install kyverno kyverno/kyverno \
  --namespace kyverno \
  --create-namespace \
  --set admissionController.replicas=2 \
  --set backgroundController.enabled=true \
  --set cleanupController.enabled=true
```

```yaml
# Require resource limits on all pods
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-resource-limits
spec:
  validationFailureAction: Enforce
  rules:
    - name: check-resources
      match:
        any:
          - resources:
              kinds:
                - Pod
      validate:
        message: "All containers must have resource limits defined"
        pattern:
          spec:
            containers:
              - resources:
                  limits:
                    memory: "?*"
                    cpu: "?*"
---
# Disallow latest tag
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: disallow-latest-tag
spec:
  validationFailureAction: Enforce
  rules:
    - name: require-image-tag
      match:
        any:
          - resources:
              kinds:
                - Pod
      validate:
        message: "Using 'latest' tag is not allowed"
        pattern:
          spec:
            containers:
              - image: "!*:latest"
```

### IAM Roles for Service Accounts (IRSA)

```yaml
# ServiceAccount with IAM role annotation
apiVersion: v1
kind: ServiceAccount
metadata:
  name: capstone-api
  namespace: production
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::ACCOUNT_ID:role/capstone-api-role
---
apiVersion: v1
kind: Pod
metadata:
  name: capstone-api-pod
  namespace: production
spec:
  serviceAccountName: capstone-api
  containers:
    - name: app
      image: ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/capstone-api:latest
```

### TLS Everywhere with cert-manager

```yaml
# Ingress with TLS
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: capstone-api
  namespace: production
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  tls:
    - hosts:
        - api.capstone.example.com
      secretName: api-tls
  rules:
    - host: api.capstone.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: capstone-api
                port:
                  number: 80
```

### Container Image Scanning in CI

```yaml
# Trivy scan integrated in GitHub Actions (see CI/CD section)
# For ad-hoc scanning:
trivy image ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/capstone-api:latest \
  --severity CRITICAL,HIGH \
  --exit-code 1 \
  --format table

# Scan in Kubernetes
kubectl run trivy-scan --rm -it --restart=Never \
  --image docker.io/aquasec/trivy:latest \
  --command -- trivy image ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/capstone-api:latest
```

---

## 12. Day-2 Operations

### Velero — Cluster Backup and Restore

```bash
# Install Velero
velero install \
  --provider aws \
  --plugins velero/velero-plugin-for-aws:v1.9 \
  --bucket capstone-velero-backups \
  --backup-location-config region=us-east-1 \
  --snapshot-location-config region=us-east-1 \
  --use-volume-snapshots=true \
  --service-account-name velero \
  --namespace velero

# Create a backup
velero backup create daily-backup-$(date +%Y-%m-%d) --include-namespaces production,staging,monitoring

# Schedule daily backups
velero schedule create daily-backup --schedule="0 2 * * *" --include-namespaces production,monitoring --ttl 720h

# Restore from backup
velero restore create --from-backup daily-backup-2024-01-15 --namespace-mappings production:production-restored

# List backups
velero backup get
```

### EKS Cluster Upgrade Procedure

```bash
# 1. Check current version and available upgrades
aws eks describe-cluster --name capstone-cluster --query "cluster.version"
aws eks describe-cluster --name capstone-cluster --query "cluster.platformVersion"

# 2. Upgrade control plane
aws eks update-cluster-version --name capstone-cluster --kubernetes-version 1.30

# 3. Monitor upgrade status
aws eks describe-cluster --name capstone-cluster --query "cluster.status"
kubectl get nodes

# 4. Before upgrading node groups — drain nodes
for node in $(kubectl get nodes -l nodepool=application -o name); do
  kubectl drain "$node" --ignore-daemonsets --delete-emptydir-data
done

# 5. Upgrade node group
aws eks update-nodegroup-version \
  --cluster-name capstone-cluster \
  --nodegroup-name capstone-cluster-application \
  --force

# 6. Wait for new nodes and uncordon
kubectl get nodes -w
for node in $(kubectl get nodes -l nodepool=application -o name); do
  kubectl uncordon "$node"
done
```

### RDS Upgrade Procedure

```bash
# Check available engine versions
aws rds describe-db-engine-versions \
  --engine postgres \
  --engine-version 16.4

# Create a pre-upgrade snapshot
aws rds create-db-snapshot \
  --db-instance-identifier capstone-cluster-database \
  --db-snapshot-identifier pre-upgrade-$(date +%Y-%m-%d-%H%M)

# Modify instance for minor version upgrade
aws rds modify-db-instance \
  --db-instance-identifier capstone-cluster-database \
  --engine-version 16.5 \
  --apply-immediately \
  --allow-major-version-upgrade

# Monitor upgrade progress
aws rds describe-db-instances \
  --db-instance-identifier capstone-cluster-database \
  --query "DBInstances[0].DBInstanceStatus"
```

### Incident Response Runbook Template

```markdown
# Incident Response: High Latency

## Severity: SEV2
## Symptoms: API latency > 500ms P99 for > 5 minutes

## Steps

1. **ACK** — Acknowledge alert in PagerDuty/OpsGenie
2. **ASSESS** — Open Grafana and check:
   - App dashboard → Latency P50/P95/P99
   - Prometheus → CPU/Memory usage per pod
   - Loki → ERROR-level logs in last 15 minutes
3. **CHECK** database:
   ```
   kubectl exec -it deployment/pgbouncer -n production -- psql -c "SELECT * FROM pg_stat_activity;"
   kubectl exec -it deployment/pgbouncer -n production -- psql -c "SELECT * FROM pg_stat_statements ORDER BY total_exec_time DESC LIMIT 10;"
   ```
4. **CHECK** Redis:
   ```
   kubectl exec -it deployment/capstone-api -n production -- redis-cli INFO stats
   ```
5. **SCALE** if needed:
   ```
   kubectl scale deployment/capstone-api -n production --replicas=20
   ```
6. If database is the bottleneck, check RDS metrics in CloudWatch
7. **RESOLVE** — Document root cause and remediation

## Resolution Log
| Time | Action | Who |
|------|--------|-----|
| T+0 | Alert received | SRE on-call |
| T+2 | Identified slow query on items table | SRE |
| T+5 | Added missing index | SRE |
| T+10 | Latency back to normal | Auto-verified |
```

### Kubecost — Cost Monitoring

```bash
helm repo add kubecost https://kubecost.github.io/cost-analyzer/
helm repo update

helm upgrade --install kubecost kubecost/cost-analyzer \
  --namespace kubecost \
  --create-namespace \
  --set kubecostToken="ZXhhbXBsZS10b2tlbi1mb3ItdGVzdGluZw==" \
  --set prometheus.kube-state-metrics.enabled=true \
  --set prometheus.node-exporter.enabled=true \
  --set global.prometheus.enabled=false \
  --set global.prometheus.fqdn=http://kube-prometheus-stack-prometheus.monitoring:9090

# Access Kubecost UI
kubectl port-forward -n kubecost service/kubecost-cost-analyzer 9090:9090
# Open http://localhost:9090
```

### Secrets Rotation

```bash
#!/bin/bash
# scripts/rotate-db-password.sh
set -euo pipefail

echo "Generating new password..."
NEW_PASSWORD=$(openssl rand -base64 32)

echo "Updating RDS master password..."
aws rds modify-db-instance \
  --db-instance-identifier capstone-cluster-database \
  --master-user-password "$NEW_PASSWORD" \
  --apply-immediately

echo "Updating Secrets Manager..."
CURRENT_SECRET=$(aws secretsmanager get-secret-value \
  --secret-id capstone-database-credentials \
  --query SecretString \
  --output text)

UPDATED_SECRET=$(echo "$CURRENT_SECRET" | jq --arg pwd "$NEW_PASSWORD" '.password = $pwd')

aws secretsmanager put-secret-value \
  --secret-id capstone-database-credentials \
  --secret-string "$UPDATED_SECRET"

echo "Restarting application pods to pick up new secret..."
kubectl rollout restart deployment/capstone-api -n production

echo "✅ Database password rotated successfully"
```

### Certificate Rotation

```bash
# cert-manager auto-renews Let's Encrypt certificates
# Check certificate expiry
kubectl get certificate -n production -o wide

# Force renewal
kubectl annotate certificate api-tls -n production cert-manager.io/issue-temporary-certificate="true"

# Check renewal logs
kubectl logs -n cert-manager -l app.kubernetes.io/name=cert-manager --tail=50
```

---

## 13. Testing the System

### Load Test with k6

```javascript
// tests/load-test.js
import http from 'k6/http';
import { check, sleep, group } from 'k6';
import { Rate, Trend } from 'k6/metrics';

const errorRate = new Rate('errors');
const latencyTrend = new Trend('latency');

export const options = {
  stages: [
    { duration: '2m', target: 50 },    // Ramp up to 50 users
    { duration: '5m', target: 200 },   // Ramp to 200 users
    { duration: '10m', target: 500 },  // Ramp to 500 users
    { duration: '5m', target: 1000 },  // Peak: 1000 users
    { duration: '5m', target: 500 },   // Scale down
    { duration: '2m', target: 0 },     // Cool down
  ],
  thresholds: {
    http_req_duration: ['p(95)<500', 'p(99)<1000'],
    errors: ['rate<0.01'],
    http_reqs: ['rate>100'],
  },
};

const BASE_URL = __ENV.API_URL || 'http://localhost:8000';

export default function () {
  group('health check', () => {
    const res = http.get(`${BASE_URL}/health`);
    check(res, { 'health status is 200': (r) => r.status === 200 });
    latencyTrend.add(res.timings.duration);
  });

  group('list items', () => {
    const res = http.get(`${BASE_URL}/api/v1/items`);
    check(res, {
      'list items status is 200': (r) => r.status === 200,
      'response is array': (r) => Array.isArray(JSON.parse(r.body)),
    });
    errorRate.add(res.status >= 400);
    latencyTrend.add(res.timings.duration);
  });

  group('create item', () => {
    const payload = { name: `load-test-${__VU}-${__ITER}` };
    const res = http.post(`${BASE_URL}/api/v1/items?name=${payload.name}`);
    check(res, {
      'create item status is 200': (r) => r.status === 200,
      'has id': (r) => JSON.parse(r.body).id !== undefined,
    });
    errorRate.add(res.status >= 400);
  });

  sleep(1);
}
```

```bash
# Run load test
k6 run tests/load-test.js -e API_URL=https://api.capstone.example.com

# Run with output to Grafana
k6 run tests/load-test.js \
  -e API_URL=https://api.capstone.example.com \
  --out influxdb=http://influxdb.monitoring:8086/k6
```

### Chaos Experiment — LitmusChaos

```bash
# Install LitmusChaos
helm repo add litmus https://litmuschaos.github.io/litmus-helm/
helm repo update

helm upgrade --install litmus litmus/litmus \
  --namespace litmus \
  --create-namespace \
  --set portal.frontend.service.type=ClusterIP

# Access Litmus UI
kubectl port-forward -n litmus service/litmus-frontend 9091:9091
# Open http://localhost:9091
```

```yaml
# chaos/pod-kill.yaml
apiVersion: litmuschaos.io/v1alpha1
kind: ChaosEngine
metadata:
  name: pod-kill-chaos
  namespace: production
spec:
  engineState: active
  annotationCheck: false
  appinfo:
    appns: production
    applabel: app.kubernetes.io/name=capstone-api
    appkind: deployment
  chaosServiceAccount: litmus-sa
  experiments:
    - name: pod-delete
      spec:
        components:
          env:
            - name: TOTAL_CHAOS_DURATION
              value: "60"
            - name: CHAOS_INTERVAL
              value: "10"
            - name: FORCE
              value: "true"
            - name: RAMP_TIME
              value: "10"
        probe:
          - name: check-app-availability
            type: httpProbe
            httpProbe/inputs:
              url: http://capstone-api.production:80/health
              expectedStatusCode: 200
            mode: Continuous
            runProperties:
              probeTimeout: 5s
              interval: 2s
              retry: 1
---
# chaos/network-partition.yaml
apiVersion: litmuschaos.io/v1alpha1
kind: ChaosEngine
metadata:
  name: network-partition
  namespace: production
spec:
  engineState: active
  annotationCheck: false
  appinfo:
    appns: production
    applabel: app.kubernetes.io/name=capstone-api
    appkind: deployment
  chaosServiceAccount: litmus-sa
  experiments:
    - name: pod-network-partition
      spec:
        components:
          env:
            - name: TOTAL_CHAOS_DURATION
              value: "30"
            - name: CHAOS_INTERVAL
              value: "10"
            - name: TARGET_PODS
              value: "1"
---
# chaos/cpu-stress.yaml
apiVersion: litmuschaos.io/v1alpha1
kind: ChaosEngine
metadata:
  name: cpu-stress
  namespace: production
spec:
  engineState: active
  annotationCheck: false
  appinfo:
    appns: production
    applabel: app.kubernetes.io/name=capstone-api
    appkind: deployment
  chaosServiceAccount: litmus-sa
  experiments:
    - name: pod-cpu-hog
      spec:
        components:
          env:
            - name: TOTAL_CHAOS_DURATION
              value: "60"
            - name: CPU_CORE
              value: "2"
            - name: TARGET_PODS
              value: "1"
```

### Observing Self-Healing

```bash
# Start watching HPA and pods in one window
watch -n 2 'kubectl get pods -n production -o wide && echo "---" && kubectl get hpa -n production'

# In another window, run chaos experiment
kubectl apply -f chaos/pod-kill.yaml

# Observe:
# 1. Pods get terminated
# 2. ReplicaSet creates replacements
# 3. HPA may scale up due to increased load
# 4. Cluster-autoscaler may add nodes
# 5. Everything recovers automatically

# Verify SLOs during chaos
# In Grafana, observe:
# - Request rate dips then recovers
# - Error rate spikes briefly
# - Latency increases during recovery
# - Error budget consumed slightly
```

### Rollback Verification

```bash
# Rollback to previous Helm revision
helm history capstone-api -n production
helm rollback capstone-api 1 -n production --wait --timeout 5m

# Verify
kubectl rollout status deployment/capstone-api -n production

# Git revert for permanent rollback
git revert HEAD --no-edit
git push origin main
```

---

## 14. Documentation and Handover

### Architecture Diagram (PlantUML)

```plantuml
@startuml
!define AWSPUML https://raw.githubusercontent.com/awslabs/aws-icons-for-plantuml/v16.0/dist

!includeurl AWSPUML/AWSCommon.puml
!includeurl AWSPUML/NetworkingContentDelivery/AmazonRoute53.puml
!includeurl AWSPUML/NetworkingContentDelivery/AmazonCloudFront.puml
!includeurl AWSPUML/Compute/AmazonEKS.puml
!includeurl AWSPUML/Database/AmazonRDS.puml
!includeurl AWSPUML/Storage/AmazonS3.puml

title Capstone Production Infrastructure

actor User as "End User"

User -> AmazonRoute53: api.capstone.example.com
AmazonRoute53 -> AmazonCloudFront: DNS resolution
AmazonCloudFront -> ALB: HTTPS request

rectangle "VPC" {
  rectangle "Public Subnet AZ-A" {
    component ALB as "Application Load Balancer"
  }
  rectangle "Private Subnet AZ-A" {
    AmazonEKS as "EKS Cluster"
    component Ingress as "Ingress-Nginx"
    component API as "API Pods"
    component Cache as "ElastiCache Redis"
  }
  rectangle "Private Subnet AZ-B" {
    AmazonRDS as "RDS PostgreSQL"
  }
}

AmazonRDS <.. API: TCP 5432
Cache <.. API: TCP 6379

rectangle "Monitoring" {
  component Prom as "Prometheus"
  component Graf as "Grafana"
  component Loki as "Loki"
}

API ..> Prom: /metrics
Prom ..> Graf: datasource
Prom ..> Loki: logs

AmazonS3 as "S3 Static Assets"
AmazonCloudFront -> AmazonS3: static content

@enduml
```

### README Template

```markdown
# Capstone Production Platform

## Overview
Production-grade microservice platform deployed on AWS EKS with full CI/CD, observability, auto-scaling, and security hardening.

## Architecture
![Architecture Diagram](docs/architecture.png)

## Prerequisites
- AWS CLI configured
- kubectl >= 1.29
- helm >= 3.14
- terraform >= 1.7
- Docker

## Quick Start

### 1. Provision Infrastructure
```bash
cd terraform
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

### 2. Configure Cluster
```bash
aws eks update-kubeconfig --name capstone-cluster --region us-east-1
kubectl get nodes
```

### 3. Deploy Kubernetes Add-ons
```bash
./scripts/install-addons.sh
```

### 4. Build and Push Application
```bash
docker build -t capstone-api:latest .
docker tag capstone-api:latest ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/capstone-api:latest
docker push ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/capstone-api:latest
```

### 5. Deploy Application
```bash
helm upgrade --install capstone-api ./helm \
  --namespace production --create-namespace \
  --values ./helm/values.yaml
```

## CI/CD
The GitHub Actions workflow in `.github/workflows/deploy.yaml`:
1. Lints and tests code
2. Builds Docker image
3. Scans for vulnerabilities with Trivy
4. Pushes to ECR
5. Deploys to staging
6. Runs integration tests
7. Promotes to production

## Access
| Service | URL |
|---------|-----|
| API | https://api.capstone.example.com |
| Grafana | https://grafana.capstone.example.com |
| Prometheus | https://prometheus.capstone.example.com |

## Monitoring
- **Metrics**: Prometheus scrapes all pods via ServiceMonitors
- **Logs**: Loki collects logs via Promtail
- **Traces**: OpenTelemetry sends traces to Tempo
- **Dashboards**: Grafana with pre-configured SLO dashboards
```

### Runbooks

```markdown
# Runbook: Pod CrashLoopBackOff

## Symptoms
- Pods in CrashLoopBackOff state
- Application unavailable
- Alert: PodCrashLooping fires

## Diagnosis
```bash
# Check pod status
kubectl get pods -n production
kubectl describe pod <pod-name> -n production

# Check logs
kubectl logs <pod-name> -n production --previous

# Check events
kubectl get events -n production --sort-by=.lastTimestamp
```

## Common Causes
1. Configuration error → check ConfigMap
2. Database unreachable → check Secret for DB_URL
3. Out of memory → check resource limits
4. Image pull failure → check ECR permissions

## Resolution
```bash
# 1. Rollback to last working version
helm rollback capstone-api <previous-revision> -n production

# 2. If config issue, fix and redeploy
helm upgrade --install capstone-api ./helm -n production --values ./helm/values.yaml --set image.tag=fixed-tag

# 3. Force restart
kubectl rollout restart deployment/capstone-api -n production
```
```

### Troubleshooting Guide

```markdown
# Troubleshooting Guide

## API Returns 503

### Check 1: Is the application running?
```bash
kubectl get pods -n production -l app.kubernetes.io/name=capstone-api
```
If pods are not running: `kubectl describe pod <name>` to see why.

### Check 2: Is the database reachable?
```bash
kubectl exec -it deployment/capstone-api -n production -- curl -f http://localhost:8000/health
```
If health check fails on DB: check RDS connectivity and credentials.

### Check 3: Is the ingress working?
```bash
kubectl get ingress -n production
kubectl describe ingress capstone-api -n production
```

## High Memory Usage

### Check per-pod memory
```bash
kubectl top pods -n production
```

### Check if HPA needs tuning
```bash
kubectl describe hpa capstone-api -n production
```

### Consider increasing resource limits in values.yaml

## Slow Database Queries

### Check active queries
```bash
kubectl exec -it deployment/pgbouncer -n production -- psql -c "SELECT pid, state, query, query_start FROM pg_stat_activity WHERE state != 'idle' ORDER BY query_start;"
```

### Check slow queries
```bash
kubectl exec -it deployment/pgbouncer -n production -- psql -c "SELECT query, calls, total_exec_time, mean_exec_time, rows FROM pg_stat_statements ORDER BY total_exec_time DESC LIMIT 10;"
```
```

### Cost Breakdown

```markdown
# Cost Breakdown — Monthly Estimated

## Infrastructure Costs (AWS us-east-1)
| Service | Configuration | Estimated Monthly |
|---------|--------------|-------------------|
| EKS Cluster | 1 control plane | $73.00 |
| EC2 — System Nodes | 2 x t3.medium (system) | $60.00 |
| EC2 — App Nodes | 3 x t3.large (application) | $202.00 |
| EC2 — Spot Workers | 5 x t3.medium (spot, ~60% savings) | $50.00 |
| RDS PostgreSQL | db.r6g.large, multi-AZ | $350.00 |
| ElastiCache Redis | cache.r6g.large, 2 nodes | $250.00 |
| NAT Gateway | 2 x NAT Gateway | $64.00 |
| Data Transfer | Egress (~500GB) | $45.00 |
| S3 Standard | 100GB storage + requests | $5.00 |
| ECR Storage | 5GB image storage | $0.50 |
| ALB | 1 ALB + LCU charges | $25.00 |

## Monitoring & Tooling
| Service | Cost |
|---------|------|
| Prometheus/Grafana (self-hosted) | $0 (runs on system nodes) |
| Velero backups to S3 | $3.00 |
| CloudWatch Logs | $10.00 |

## Total Estimated: ~$1,137/month

## Cost Optimization Tips
1. Use spot instances for non-critical workloads (40-60% savings)
2. Right-size RDS based on actual utilization
3. Use S3 Intelligent-Tiering for backups
4. Set HPA limits to prevent over-provisioning
5. Use Kubecost to identify waste
6. Delete unused load balancers and volumes
```

---

## 15. Hands-On Practices

### Practice 1: Design Architecture and Create Topology Diagram

```bash
# Create the architecture directory
mkdir -p docs

# Draw topology using draw.io CLI or PlantUML
# Option A: PlantUML
cat > docs/architecture.puml << 'EOF'
@startuml
!define AWSPUML https://raw.githubusercontent.com/awslabs/aws-icons-for-plantuml/v16.0/dist
!includeurl AWSPUML/AWSCommon.puml
!includeurl AWSPUML/Compute/AmazonEKS.puml
!includeurl AWSPUML/Database/AmazonRDS.puml
!includeurl AWSPUML/Storage/AmazonS3.puml

title Capstone Architecture
AmazonEKS --> AmazonRDS : PostgreSQL
AmazonEKS --> AmazonS3 : Static Assets
@enduml
EOF

# Generate PNG (requires plantuml installed)
# plantuml -tpng docs/architecture.puml -o images/
```

**Deliverable:** `docs/architecture.png` (or `.puml`) showing all components with data flow arrows.

---

### Practice 2: Write Terraform for VPC + EKS + RDS

```bash
# Initialize and apply Terraform
cd terraform
terraform init
terraform workspace new dev || terraform workspace select dev
terraform plan -var-file=environments/dev.tfvars -out=tfplan
terraform apply tfplan

# Verify resources created
aws ec2 describe-vpcs --filters "Name=tag:Name,Values=capstone-vpc"
aws eks describe-cluster --name capstone-cluster
aws rds describe-db-instances --db-instance-identifier capstone-cluster-database
```

**Deliverable:** Running VPC, EKS cluster (control plane), RDS instance.

---

### Practice 3: Deploy Kubernetes Cluster with Cilium and Add-ons

```bash
# Configure kubectl
aws eks update-kubeconfig --name capstone-cluster --region us-east-1

# Install Cilium
helm upgrade --install cilium cilium/cilium \
  --namespace kube-system \
  --set kubeProxyReplacement=strict \
  --set hubble.relay.enabled=true \
  --set hubble.ui.enabled=true

# Verify Cilium is running
kubectl -n kube-system get pods -l k8s-app=cilium

# Install all add-ons (combine into a script)
cat > scripts/install-addons.sh << 'SCRIPT'
#!/bin/bash
set -euo pipefail

echo "Installing metrics-server..."
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

echo "Installing cert-manager..."
helm upgrade --install cert-manager jetstack/cert-manager \
  --namespace cert-manager --create-namespace \
  --set crds.enabled=true

echo "Installing cluster-autoscaler..."
helm upgrade --install cluster-autoscaler autoscaler/cluster-autoscaler \
  --repo https://kubernetes.github.io/autoscaler \
  --namespace kube-system \
  --set autoDiscovery.clusterName=capstone-cluster \
  --set awsRegion=us-east-1

echo "Installing ingress-nginx..."
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --repo https://kubernetes.github.io/ingress-nginx \
  --namespace ingress-nginx --create-namespace \
  --set controller.service.type=LoadBalancer

echo "Installing external-secrets..."
helm upgrade --install external-secrets external-secrets/external-secrets \
  --namespace external-secrets --create-namespace --set installCRDs=true

echo "All add-ons installed."
SCRIPT

chmod +x scripts/install-addons.sh
./scripts/install-addons.sh
```

**Deliverable:** Running cluster with Cilium, metrics-server, cert-manager, cluster-autoscaler, ingress-nginx, external-secrets.

---

### Practice 4: Containerize the Sample App with Multi-Stage Build

```bash
# Create the application directory
mkdir -p app tests

# Write main.py (use code from Section 5)
cat > app/main.py << 'PYEOF'
# ... put the FastAPI code from Section 5 here
PYEOF

cat > app/requirements.txt << 'TXT'
fastapi==0.115.0
uvicorn[standard]==0.30.6
asyncpg==0.29.0
redis[hiredis]==5.1.1
prometheus-client==0.20.0
opentelemetry-api==1.27.0
opentelemetry-sdk==1.27.0
opentelemetry-exporter-otlp-proto-http==1.27.0
opentelemetry-instrumentation-fastapi==0.48b0
opentelemetry-instrumentation-httpx==0.48b0
httpx==0.27.2
TXT

# Build the image
docker build -t capstone-api:latest .

# Verify
docker run -d -p 8000:8000 \
  -e DATABASE_URL=postgresql://user:pass@host:5432/db \
  -e REDIS_URL=redis://host:6379/0 \
  --name capstone-api capstone-api:latest

curl http://localhost:8000/health
curl http://localhost:8000/metrics

# Clean up
docker stop capstone-api && docker rm capstone-api
```

**Deliverable:** Running container locally, responding on port 8000 with `/health` and `/metrics`.

---

### Practice 5: Push Image to Container Registry

```bash
# Authenticate to ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com

# Create repository
aws ecr create-repository --repository-name capstone-api

# Tag and push
docker tag capstone-api:latest ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/capstone-api:v1.0.0
docker push ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/capstone-api:v1.0.0

# Verify
aws ecr describe-images --repository-name capstone-api
```

**Deliverable:** Image pushed to ECR, visible in AWS Console.

---

### Practice 6: Write Helm Chart (Deployment, Service, Ingress, HPA, PDB)

```bash
# Create Helm chart
helm create capstone-api-chart
# (This creates a template chart — customize it)

# or create manually:
mkdir -p helm/templates

# Write all templates from Section 5
# Chart.yaml
cat > helm/Chart.yaml << 'EOF'
apiVersion: v2
name: capstone-api
description: Capstone API microservice
type: application
version: 1.0.0
appVersion: 1.0.0
EOF

# Dry-run the install
helm upgrade --install capstone-api ./helm \
  --namespace production --create-namespace \
  --values ./helm/values.yaml \
  --dry-run --debug | less

# Validate templates
helm lint ./helm
helm template ./helm
```

**Deliverable:** Complete Helm chart passing `helm lint` with all required templates.

---

### Practice 7: Set Up GitHub Actions CI/CD Pipeline

```bash
# Create GitHub Actions directory
mkdir -p .github/workflows

# Write the workflow (use code from Section 6)
cat > .github/workflows/deploy.yaml << 'YAML'
# ... full workflow from Section 6
YAML

# Set up GitHub secrets
gh secret set AWS_ACCOUNT_ID --body "123456789012"
gh secret set OIDC_ROLE_ARN --body "arn:aws:iam::123456789012:role/github-actions-role"

# Test by pushing to staging branch
git checkout -b staging
git add .
git commit -m "ci: add deployment pipeline"
git push origin staging
```

**Deliverable:** GitHub Actions workflow running successfully — builds and deploys to staging.

---

### Practice 8: Configure External Secrets Operator with AWS Secrets Manager

```bash
# Create SecretStore
kubectl apply -f - << 'EOF'
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: aws-secrets-store
  namespace: production
spec:
  provider:
    aws:
      service: SecretsManager
      region: us-east-1
      auth:
        jwt:
          serviceAccountRef:
            name: capstone-api
EOF

# Create ExternalSecret
kubectl apply -f - << 'EOF'
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: capstone-api-db
  namespace: production
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: aws-secrets-store
    kind: SecretStore
  target:
    name: capstone-api-db
    creationPolicy: Owner
  data:
    - secretKey: database-url
      remoteRef:
        key: capstone-database-credentials
        property: connection_string
EOF

# Verify secret was created
kubectl get secret capstone-api-db -n production
kubectl get secret capstone-api-db -n production -o jsonpath='{.data.database-url}' | base64 -d
```

**Deliverable:** Secrets successfully synced from AWS Secrets Manager to Kubernetes Secrets.

---

### Practice 9: Deploy kube-prometheus-stack

```bash
helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring --create-namespace \
  --set grafana.adminPassword=admin

# Verify all components
kubectl get pods -n monitoring
kubectl get servicemonitors -n monitoring
kubectl get prometheusrules -n monitoring

# Access Prometheus
kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090 &
curl http://localhost:9090/api/v1/query?query=up

# Access Grafana
kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80 &
# Open http://localhost:3000 (admin/admin)
```

**Deliverable:** Running Prometheus + Grafana in monitoring namespace, scraping cluster metrics.

---

### Practice 10: Create Grafana Dashboards for Application

```json
# Import the following dashboard JSON via Grafana UI:
# (Use the dashboard JSON from Section 9)

# Or use the Grafana API
GRAFANA_URL="http://localhost:3000"
curl -X POST "$GRAFANA_URL/api/dashboards/db" \
  -H "Authorization: Basic $(echo -n admin:admin | base64)" \
  -H "Content-Type: application/json" \
  -d @grafana-dashboard.json

# Verify metrics are being scraped
kubectl get servicemonitor -n production
curl -s http://localhost:8000/metrics | grep -c "app_requests_total"
```

**Deliverable:** Grafana dashboard showing request rate, latency P50/P95/P99, and error rate.

---

### Practice 11: Set Up Loki + Promtail for Log Aggregation

```bash
# Install Loki
helm upgrade --install loki grafana/loki \
  --namespace monitoring \
  --set loki.commonConfig.replication_factor=1 \
  --set loki.storage.type=filesystem

# Install Promtail
helm upgrade --install promtail grafana/promtail \
  --namespace monitoring

# Query logs in Grafana Explore
# Add Loki as datasource (http://loki:3100)
# Run LogQL query:
# {namespace="production"} |= "ERROR"
```

**Deliverable:** Application logs flowing into Loki, searchable in Grafana.

---

### Practice 12: Configure HPA + Cluster Autoscaler

```bash
# Verify HPA is working
kubectl get hpa -n production
kubectl describe hpa capstone-api -n production

# Generate load to trigger autoscaling
kubectl run -i --tty load-generator --rm --image=busybox \
  --restart=Never -- sh -c "while true; do wget -q -O- http://capstone-api.production/health; done"

# Watch scaling
watch kubectl get pods -n production -o wide

# Verify cluster autoscaler adds nodes
kubectl get nodes
kubectl logs -n kube-system -l app.kubernetes.io/name=cluster-autoscaler --tail=20
```

**Deliverable:** Autoscaling working — pods increase under load, nodes added by cluster-autoscaler.

---

### Practice 13: Deploy Network Policies (Deny-All + Allow Specific)

```bash
# Apply default deny
kubectl apply -f - << 'EOF'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: production
spec:
  podSelector: {}
  policyTypes:
    - Ingress
    - Egress
EOF

# Test that inter-pod communication is blocked
kubectl run test-pod --image=busybox -n production --restart=Never -- sleep 30
kubectl exec test-pod -n production -- wget -q --timeout=5 http://capstone-api.production:8000/health
# Should hang/timeout

# Apply allow rules from Section 11
# ... apply all the allow network policies

# Test again
kubectl delete pod test-pod -n production
kubectl run test-pod --image=busybox -n production --restart=Never -- sleep 30
kubectl exec test-pod -n production -- wget -q --timeout=5 http://capstone-api.production:8000/health
# Should succeed (since test-pod is in the same namespace)
```

**Deliverable:** Network policies enforced — only allowed traffic flows between pods.

---

### Practice 14: Run Chaos Experiment (Pod Kill) and Observe Recovery

```bash
# Install LitmusChaos
helm upgrade --install litmus litmuschaos/litmus \
  --namespace litmus --create-namespace

# Run pod-delete chaos
kubectl apply -f chaos/pod-kill.yaml

# Watch recovery in real-time
watch -n 2 'echo "=== PODS ===" && kubectl get pods -n production -o wide && echo "=== HPA ===" && kubectl get hpa -n production'

# Check how many pods were killed
kubectl logs -n litmus -l app.kubernetes.io/component=chaos-exporter --tail=20

# Verify app remained available during chaos
# (Run k6 load test in parallel to confirm)
```

**Deliverable:** Chaos experiment completed; application self-healed; SLOs not violated.

---

### Practice 15: Final Integration — End-to-End Deployment

```bash
# The end-to-end flow:

# 1. Developer commits code
git add . && git commit -m "feat: add rate limiting middleware"
git push origin main

# 2. CI/CD pipeline triggers (observed in GitHub Actions UI)
#    - Lint → Test → Build → Scan → Push → Deploy Staging → Integration Test → Deploy Production

# 3. Watch deployment in real-time
kubectl get events -n production --watch

# 4. Verify application is accessible
curl https://api.capstone.example.com/health
curl https://api.capstone.example.com/metrics

# 5. Verify Prometheus is scraping
kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090 &
curl 'http://localhost:9090/api/v1/query?query=app_requests_total'

# 6. Verify Grafana dashboard shows SLO compliance
# Open Grafana, check Capstone SLO dashboard

# 7. Run load test to verify scaling
k6 run tests/load-test.js -e API_URL=https://api.capstone.example.com

# 8. Run chaos experiment to test resilience
kubectl apply -f chaos/pod-kill.yaml

# 9. Verify rollback capability
helm history capstone-api -n production
helm rollback capstone-api 1 -n production --wait --timeout 5m

# 10. Document findings
echo "Capstone deployment validated successfully on $(date)" >> docs/deployment-validation.md
```

**Deliverable:** Complete end-to-end deployment — commit to production in under 15 minutes, with full observability and resilience.

---

## 🎉 Course Complete — What You've Achieved

Congratulations! You have completed all 60 parts of the Linux System Administrator Course.

### Course Statistics

- **60 comprehensive parts** spanning Linux fundamentals to production-grade infrastructure
- **900+ hands-on practices** across all domains
- **Coverage from `ls` to Kubernetes**, from bash to eBPF

### Your Skill Map Now Includes

| Domain | Skills |
|--------|--------|
| **Linux System Administration** | Boot process, filesystem hierarchy, process management, networking stack, security subsystems |
| **Infrastructure as Code** | Terraform (VPC, EKS, RDS, Redis), Packer, Helm |
| **Cloud Computing** | AWS (EC2, EKS, RDS, ElastiCache, S3, IAM), GCP, Azure fundamentals |
| **Container Orchestration** | Docker multi-stage builds, Kubernetes (pods, deployments, services, ingress, HPA, PDB), Cilium CNI |
| **CI/CD and Automation** | GitHub Actions with OIDC, Helm deployments, Trivy scanning |
| **Observability** | Prometheus metrics, Grafana dashboards, Loki logs, Tempo traces, OpenTelemetry instrumentation |
| **Security** | Pod security standards, network policies, Kyverno policies, IRSA, cert-manager TLS, image scanning |
| **SRE Practices** | SLOs, error budgets, SLI monitoring, incident response |
| **Modern Networking** | eBPF, Cilium L7 policies, Hubble, WireGuard |
| **Day-2 Operations** | Velero backups, cluster upgrades, secret rotation, cost monitoring |

### What's Next?

1. **Get Certified**
   - **RHCSA** — Red Hat Certified System Administrator (validates your Linux fundamentals)
   - **CKA** — Certified Kubernetes Administrator (validates your K8s skills)
   - **AWS SAA** — AWS Solutions Architect Associate (validates your cloud skills)

2. **Contribute to Open Source**
   - Find projects on GitHub that use your tech stack
   - Fix documentation and small bugs to start
   - Build a portfolio of your contributions

3. **Specialize Further**
   - **Security Deep Dive:** Focus on Cilium Tetragon, Falco, eBPF security
   - **Platform Engineering:** Build an internal developer platform (IDP) with Backstage
   - **Service Mesh:** Istio or Link for advanced traffic management
   - **GitOps:** ArgoCD or Flux for declarative deployments

4. **Build More Projects**
   - Multi-region disaster recovery setup
   - Serverless platform on Kubernetes (Knative)
   - Machine learning infrastructure (Kubeflow)
   - Edge computing with K3s on Raspberry Pi

5. **Stay Current**
   - Subscribe to: Kubernetes Weekly, SRE Weekly, DevOps Newsletter
   - Follow: KubeCon talks, AWS re:Invent sessions
   - Practice: Regularly break and fix your own infrastructure

### Final Thought

> *"A sysadmin is not defined by the commands they know, but by the problems they can solve. You now have the foundation to solve any infrastructure problem. The rest is experience."*

The terminal is waiting. Go build something.

---

## 📝 Self-Test

1. **Architecture**: Draw a system diagram for the capstone platform. Label all components and data flows. What happens when a user hits `https://api.capstone.example.com/health`?

2. **Terraform**: What Terraform resources are needed to create the VPC with public and private subnets across 2 AZs? How does the EKS cluster know which subnets to use?

3. **Kubernetes Networking**: Explain how Cilium replaces kube-proxy. What is Hubble and how does it help with network observability?

4. **Docker Multi-Stage**: Why does the Dockerfile use two stages? What is the benefit of the `slim` base image and the non-root user?

5. **Helm**: In the Helm chart, what does the `checksum/config` annotation on the pod template do? Why is it important?

6. **CI/CD**: Explain the OIDC authentication flow between GitHub Actions and AWS. Why is this better than using long-lived access keys?

7. **External Secrets**: How does the External Secrets Operator sync secrets from AWS Secrets Manager to Kubernetes? What prevents the Kubernetes Secret from being out of date?

8. **ServiceMonitor**: How does Prometheus discover which pods to scrape? What labels on the ServiceMonitor and Service must match?

9. **HPA Behavior**: The HPA has a scale-down stabilization window of 300 seconds. What problem does this solve? What happens during a rapid traffic spike?

10. **Network Policies**: After applying a default-deny ingress policy, can pods in the same namespace still communicate? What must be configured to allow specific traffic?

11. **PodDisruptionBudget**: If `minAvailable: 2` is set and there are 5 replicas, can a node drain proceed if it would terminate 2 pods simultaneously?

12. **Chaos Engineering**: During the pod-kill chaos experiment, what mechanisms ensure the application remains available? How does the self-healing work?

13. **SLOs**: If the monthly SLO target is 99.9% availability and the service has 2 minutes of downtime in a 30-day month, is the SLO met? Show the calculation.

14. **Cost Optimization**: List 5 ways to reduce the monthly infrastructure cost of this capstone platform below $500/month.

15. **Troubleshooting**: The application pods are in CrashLoopBackOff. Describe your systematic approach to diagnose and resolve the issue.

<details>
<summary>Answer Key</summary>

1. **Architecture**: DNS → CloudFront → ALB → Ingress-Nginx → API Pod → (PostgreSQL RDS + Redis). Health endpoint checks DB + Redis connectivity and returns 200.

2. **Terraform Resources**: `aws_vpc`, `aws_subnet` (public + private × 2 AZs), `aws_internet_gateway`, `aws_nat_gateway`, `aws_route_table`, `aws_route_table_association`. The EKS cluster uses `subnet_ids` in `vpc_config`.

3. **Cilium**: Uses eBPF to implement services, replaces iptables-based kube-proxy with efficient BPF programs. Hubble provides flow visibility — can see L3/L7 traffic between pods.

4. **Multi-stage**: Builder stage has gcc/libpq-dev for compilation; runtime stage is minimal with only runtime deps. Slim base + non-root reduces attack surface and image size.

5. **checksum/config**: Forces pod restart when ConfigMap changes. Without it, changing a ConfigMap doesn't trigger a new rollout — running pods would be out of sync.

6. **OIDC Flow**: GitHub Actions requests a JWT token, AWS STS exchanges it for temporary credentials via the OIDC identity provider. No static keys to rotate or leak.

7. **ESO Sync**: ExternalSecret CRD defines the mapping, SecretStore configures AWS auth. The operator polls `refreshInterval` (1h). Changes in AWS Secrets Manager are reflected in the K8s Secret within that interval.

8. **ServiceMonitor matches**: `spec.selector.matchLabels` must match Service labels. `namespaceSelector` must match the Service's namespace. The release label connects to the Prometheus instance.

9. **Stabilization window**: Prevents flapping — rapid scale-down when traffic drops briefly. During spikes, `scaleUp` has no stabilization (0s), so HPA responds immediately.

10. **Default deny**: Blocks all ingress. Pods in the same namespace cannot communicate. Must create allow policies that specify `podSelector` and `from` sources explicitly.

11. **PDB behavior**: Node drain evicts pods gradually. With `minAvailable: 2`, at most 3 of 5 pods can be unavailable simultaneously. If draining 2 pods at once would leave 3 (< 2 minAvailable), the eviction is delayed.

12. **Self-healing**: ReplicaSet controller creates replacement pods. Readiness probes prevent routing traffic to unready pods. Service load balancer distributes to healthy pods. HPA may scale up if needed.

13. **SLO calculation**: 30 days = 43,200 minutes; 99.9% = 43,200 × 0.001 = 43.2 minutes allowed downtime. 2 minutes < 43.2 minutes. ✅ SLO is met.

14. **Cost optimization**: (1) Spot instances for all workloads, (2) Single-AZ RDS with automated failover via RDS proxy, (3) Right-size nodes, (4) Use Graviton instances (20% cheaper), (5) Scale to 0 at night, (6) Use S3 lifecycle policies for backups, (7) Remove NAT gateways (use VPC endpoints).

15. **Troubleshooting approach**: (1) `kubectl describe pod` for events, (2) `kubectl logs --previous` for last crash, (3) Check resource limits vs. actual usage, (4) Verify ConfigMap/Secret values, (5) Check if image exists in registry, (6) Test DB connectivity from another pod, (7) Rollback to last working version.
</details>

---

*Linux SysAdmin Course | Part 60 of ∞ | Reverse Engineering Approach*
*Previous → Part 59: Site Reliability Engineering (SRE)*
*Next → This is the final part. Revisit any section or begin your production journey!*

[← Previous](part59.md) and [-> Reference](reference.md)
