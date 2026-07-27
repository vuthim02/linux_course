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



---

[← Previous](01-1-capstone-overview.md) | [↑ Index](index.md) | [Next →](03-3-infrastructure-provisioning-terraform.md)
