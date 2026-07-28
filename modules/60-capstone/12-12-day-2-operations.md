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




[← Previous](11-11-security-hardening.md) | [↑ Index](index.md) | [Next →](13-incident-response-steps.md)
