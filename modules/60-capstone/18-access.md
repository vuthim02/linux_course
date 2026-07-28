## Access

### Service Endpoints

| Service | URL | Credentials |
|---------|-----|-------------|
| API | https://api.capstone.example.com | IAM role |
| Grafana | https://grafana.capstone.example.com | admin / `kubectl get secret` |
| Prometheus | https://prometheus.capstone.example.com | IAM role |
| Kibana | https://kibana.capstone.example.com | SSO via OIDC |
| Vault | https://vault.capstone.example.com | AppRole auth |

### How to Get Access

```bash
# Get kubeconfig for EKS cluster
aws eks update-kubeconfig --name capstone-prod --region us-east-1

# Get Grafana admin password
kubectl get secret grafana-admin -n monitoring -o jsonpath='{.data.password}' | base64 -d

# Port-forward Prometheus (if not exposed via ingress)
kubectl port-forward svc/prometheus -n monitoring 9090:9090

# Port-forward Grafana
kubectl port-forward svc/grafana -n monitoring 3000:3000
```

### Required Tools

Ensure you have these installed before starting: `kubectl`, `aws-cli`, `helm`, `vault`, `terraform`.


[← Previous](17-quick-start.md) | [↑ Index](index.md) | [Next →](19-troubleshooting-503.md)
