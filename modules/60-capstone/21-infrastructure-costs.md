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




[← Previous](20-troubleshooting-memory.md) | [↑ Index](index.md) | [Next →](22-monitoring-costs.md)
