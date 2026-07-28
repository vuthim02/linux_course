## Quick Start

### 1. Provision Infrastructure
```bash
cd terraform
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

### 2. Configure Cluster
```bash
aws eks update-kubeconfig --name capstone-cluster --region us-east-1
kubectl get nodes
```

### 3. Deploy Kubernetes Add-ons
```bash
./scripts/install-addons.sh
```

### 4. Build and Push Application
```bash
docker build -t capstone-api:latest .
docker tag capstone-api:latest ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/capstone-api:latest
docker push ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/capstone-api:latest
```

### 5. Deploy Application
```bash
helm upgrade --install capstone-api ./helm \
  --namespace production --create-namespace \
  --values ./helm/values.yaml
```




[← Previous](16-documentation-and-handover.md) | [↑ Index](index.md) | [Next →](18-access.md)
