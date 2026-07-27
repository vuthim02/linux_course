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



---

[← Previous](36-cost-optimization-tips.md) | [↑ Index](index.md) | [Next →](38-course-complete-what-youve-achieved.md)
