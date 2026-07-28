## Cost Optimization Tips

1. **Use spot instances** for non-critical workloads (40-60% savings on EC2)
2. **Right-size RDS** — use `db.r6g.large` only if CloudWatch shows >70% CPU; downgrade to `db.r6g.medium` if underutilized
3. **S3 Intelligent-Tiering** for backups — automatically moves objects between access tiers
4. **Set HPA limits** to prevent over-provisioning; pair with VPA for right-sizing recommendations
5. **Kubecost** — deploy to identify idle resources, unused PVCs, and over-provisioned deployments
6. **Delete unused load balancers** and EBS volumes (orphaned after scale-down events)
7. **Reserved Instances** — commit to 1-year for RDS and EC2 baseline (30-40% savings)

### Quick Savings Audit

```bash
# Find unattached EBS volumes
aws ec2 describe-volumes --filters Name=status,Values=available --query 'Volumes[*].[VolumeId,Size,CreateTime]' --output table

# Find idle load balancers (no targets)
aws elbv2 describe-target-groups --query 'TargetGroups[*].[TargetGroupArn,LoadBalancerArns]' --output table

# Check RDS utilization
aws cloudwatch get-metric-statistics --namespace AWS/RDS --metric-name CPUUtilization \
  --dimensions Name=DBInstanceIdentifier,Value=capstone-prod \
  --start-time $(date -u -d '7 days ago' +%FT%TZ) --end-time $(date -u +%FT%TZ) \
  --period 3600 --statistics Average

# Kubecost: install and check waste
kubectl cost -n kubecost top pods --window 7d
```

### Target Monthly Budget

| Category | Current | Optimized |
|----------|---------|-----------|
| Compute | $385 | $260 (spot + RI) |
| Database | $600 | $500 (right-sized) |
| Networking | $134 | $100 (NAT optimization) |
| Monitoring | $34 | $34 |
| **Total** | **~$1,288** | **~$894** |



[← Previous](22-monitoring-costs.md) | [↑ Index](index.md) | [Next →](24-hands-on-practices.md)
