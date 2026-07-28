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





[↑ Index](index.md) | [Next →](02-2-architecture-design.md)
