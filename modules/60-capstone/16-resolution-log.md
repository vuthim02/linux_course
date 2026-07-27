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



---

[← Previous](15-steps.md) | [↑ Index](index.md) | [Next →](17-13-testing-the-system.md)
