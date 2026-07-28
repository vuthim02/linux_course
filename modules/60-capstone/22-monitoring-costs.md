## Monitoring & Tooling

| Service | Configuration | Cost |
|---------|--------------|------|
| Prometheus/Grafana (self-hosted) | Runs on system nodes | $0 |
| Velero backups to S3 | Daily snapshots, 30d retention | $3.00 |
| CloudWatch Logs | ~50GB ingestion/month | $10.00 |
| PagerDuty | 10 users, Professional plan | $21.00 |
| GitHub Actions | 2000 min/month (private repos) | $0 |
| **Total monitoring** | | **~$34.00** |

### Why Self-Hosted Monitoring Saves Money

At this scale, self-hosted Prometheus + Grafana costs nothing beyond the EC2 instances already running for system workloads. Cloud-managed alternatives (Amazon Managed Prometheus at ~$0.90/million samples, Amazon Managed Grafana at $7.31/dashboard/month) make sense only when you need multi-region federation or SLA-backed uptime.

### Cost Breakdown by Category

| Category | Monthly | % of Total |
|----------|---------|-----------|
| Compute (EKS + EC2) | $385 | 30% |
| Database (RDS + Redis) | $600 | 47% |
| Networking (NAT + ALB + transfer) | $134 | 10% |
| Storage (S3 + ECR) | $5.50 | <1% |
| Monitoring & Tooling | $34 | 3% |
| **Total** | **~$1,288** | |


[← Previous](21-infrastructure-costs.md) | [↑ Index](index.md) | [Next →](23-cost-optimization.md)
