## 🔍 Section 11: Multi-Cloud Comparison

### Equivalent Services

| Category | AWS | GCP | Azure |
|----------|-----|-----|-------|
| Compute | EC2 | Compute Engine | Virtual Machines |
| Container | ECS/EKS | GKE | AKS |
| Serverless | Lambda | Cloud Functions | Azure Functions |
| Object Storage | S3 | Cloud Storage | Blob Storage |
| Block Storage | EBS | Persistent Disk | Managed Disks |
| File Storage | EFS | Filestore | Azure Files |
| DNS | Route 53 | Cloud DNS | Azure DNS |
| CDN | CloudFront | Cloud CDN | Azure CDN |
| Load Balancer | ALB/NLB | Cloud LB | Azure Load Balancer |
| Database (SQL) | RDS | Cloud SQL | Azure SQL |
| Database (NoSQL) | DynamoDB | Firestore | Cosmos DB |
| Caching | ElastiCache | Memorystore | Azure Cache for Redis |
| Queue | SQS | Pub/Sub | Queue Storage |
| Email | SES | - | SendGrid |
| Monitoring | CloudWatch | Cloud Monitoring | Azure Monitor |
| Logging | CloudWatch Logs | Cloud Logging | Log Analytics |
| IAM | IAM | Cloud IAM | Azure RBAC |
| VPC | VPC | VPC | VNet |
| Bastion | SSM Session Manager | IAP TCP Forwarding | Azure Bastion |
| Budgets | AWS Budgets | GCP Budgets | Cost Management |
| Terraform | provider "aws" | provider "google" | provider "azurerm" |

### Common Multi-Cloud Patterns

```
1. Active-Passive: Primary on AWS, DR on GCP
   - Route 53 fails over to GCP LB
   - Data replicated via S3 → GCS transfer

2. Best-of-Breed: Choose each service from its strongest provider
   - AWS: EC2, S3, DynamoDB
   - GCP: BigQuery, Dataflow
   - Azure: Active Directory, Office 365

3. Avoid Lock-in: Use cloud-agnostic tools
   - Terraform (all three)
   - Kubernetes (AKS, EKS, GKE)
   - Prometheus + Grafana (monitoring)
   - Crossplane (control plane)
```

### Vendor Lock-In Considerations

```
High Lock-In Risk:
  - AWS DynamoDB (NoSQL API is proprietary)
  - GCP BigQuery (SQL dialect, pricing model)
  - Azure Cosmos DB (API is proprietary)
  - Cloud-native serverless (Lambda, Cloud Functions, Azure Functions)
  - Managed Kubernetes (control plane differences)

Low Lock-In Risk:
  - Compute (you control the OS, portable across clouds)
  - Object Storage (S3 API is de facto standard)
  - Kubernetes (standard API, portable workloads)
  - Terraform/HCL (same config works across clouds)
  - SQL databases (PostgreSQL, MySQL are portable)

Mitigation Strategies:
  - Use S3-compatible storage API (MinIO, Ceph)
  - Use standard Kubernetes (EKS, GKE, AKS all support standard K8s)
  - Use Terraform for all infrastructure definitions
  - Avoid proprietary database services unless necessary
  - Abstract cloud SDK calls behind your own interfaces
```

---



---

[← Previous](11-section-10-cloud-cost-management.md) | [↑ Index](index.md) | [Next →](13-practice-section-15-hands-on-exercises.md)
