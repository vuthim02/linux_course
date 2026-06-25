# Internship — Level 4, Week 21-22
## CI/CD Pipeline + Kubernetes Deployment

### Real-World Scenario

Your team has a microservice application that needs a fully automated deployment pipeline. Code pushed to `main` should be automatically built, tested, containerized, security-scanned, and deployed to a Kubernetes cluster. You'll build the entire pipeline.

### Requirements

#### Part A: GitHub Actions Pipeline

`.github/workflows/deploy.yml`:

```yaml
name: Build, Test, and Deploy

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}
  K8S_NAMESPACE: production

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run unit tests
        run: make test
      - name: Run linting
        run: make lint
      - name: SAST scan
        uses: github/codeql-action/analyze@v3
        with:
          languages: python

  build:
    needs: test
    runs-on: ubuntu-latest
    outputs:
      image-tag: ${{ steps.tag.outputs.tag }}
    steps:
      - uses: actions/checkout@v4
      - name: Generate image tag
        id: tag
        run: echo "tag=${{ github.sha }}-$(date +%Y%m%d)" >> $GITHUB_OUTPUT
      - name: Build Docker image
        run: docker build -t $REGISTRY/$IMAGE_NAME:${{ steps.tag.outputs.tag }} .
      - name: Scan for vulnerabilities
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: $REGISTRY/$IMAGE_NAME:${{ steps.tag.outputs.tag }}
          format: sarif
          output: trivy-results.sarif
          severity: CRITICAL,HIGH
      - name: Upload scan results
        uses: github/codeql-action/upload-sarif@v3
        with:
          sarif_file: trivy-results.sarif
      - name: Sign image with Cosign
        run: |
          cosign sign --key env://COSIGN_PRIVATE_KEY \
            $REGISTRY/$IMAGE_NAME:${{ steps.tag.outputs.tag }}
      - name: Push image
        run: |
          echo ${{ secrets.GITHUB_TOKEN }} | docker login ghcr.io -u ${{ github.actor }} --password-stdin
          docker push $REGISTRY/$IMAGE_NAME:${{ steps.tag.outputs.tag }}

  deploy-staging:
    needs: build
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    environment: staging
    steps:
      - uses: actions/checkout@v4
      - name: Deploy to staging K8s
        run: |
          helm upgrade --install myapp ./helm \
            --namespace staging \
            --set image.tag=${{ needs.build.outputs.image-tag }} \
            --wait --timeout 5m
      - name: Integration test
        run: |
          curl -f --retry 10 --retry-delay 10 \
            https://staging.myapp.com/health

  deploy-production:
    needs: deploy-staging
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    environment:
      name: production
      url: https://myapp.com
    steps:
      - name: Deploy to production K8s
        run: |
          helm upgrade --install myapp ./helm \
            --namespace production \
            --set image.tag=${{ needs.build.outputs.image-tag }} \
            --wait --timeout 5m
      - name: Verify deployment
        run: |
          kubectl rollout status deployment/myapp -n production
          kubectl get pods -n production -l app=myapp
```

#### Part B: Helm Chart

Directory structure:
```
helm/
├── Chart.yaml          # name, version, description
├── values.yaml         # default values
├── values-prod.yaml    # production overrides
├── values-staging.yaml # staging overrides
└── templates/
    ├── _helpers.tpl
    ├── deployment.yaml
    ├── service.yaml
    ├── ingress.yaml
    ├── hpa.yaml
    ├── pdb.yaml
    ├── serviceaccount.yaml
    ├── configmap.yaml
    └── tests/
        └── test-connection.yaml
```

**deployment.yaml:**
- 3 replicas (production), 1 replica (staging)
- Rolling update: maxSurge=1, maxUnavailable=0
- Resource requests/limits: production 512m CPU / 1Gi memory
- Liveness probe: `GET /health`
- Readiness probe: `GET /ready`
- Pod anti-affinity: prefer different nodes
- Security context: readOnlyRootFilesystem, runAsNonRoot, capabilities drop all

**hpa.yaml:**
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: myapp
spec:
  maxReplicas: 10
  minReplicas: 3
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70
    - type: Resource
      resource:
        name: memory
        target:
          type: Utilization
          averageUtilization: 80
```

**pdb.yaml:**
```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: myapp
spec:
  minAvailable: 2
  selector:
    matchLabels:
      app: myapp
```

**ingress.yaml:**
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: myapp
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
spec:
  ingressClassName: nginx
  tls:
    - hosts:
        - myapp.com
      secretName: myapp-tls
  rules:
    - host: myapp.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: myapp
                port:
                  number: 80
```

#### Part C: Kubernetes Manifests (alternative to Helm)

Also provide plain K8s manifests:
- `k8s/namespace.yaml`
- `k8s/deployment.yaml`
- `k8s/service.yaml`
- `k8s/ingress.yaml`
- `k8s/hpa.yaml`
- `k8s/pdb.yaml`
- `k8s/serviceaccount.yaml`
- `k8s/networkpolicy.yaml` — deny-all by default, allow specific

### Validation

```bash
# Test Helm chart locally
helm lint ./helm
helm template myapp ./helm --namespace production

# Dry-run deploy
helm upgrade --install myapp ./helm --namespace production --dry-run --debug

# Test K8s manifests
kubectl apply -f k8s/ --dry-run=client

# Verify HPA
kubectl get hpa -n production
kubectl describe hpa myapp -n production

# Simulate load
kubectl run -i --tty load-generator --rm --image=busybox -- \
  sh -c "while true; do wget -q -O- http://myapp.production.svc; done"
```

### Deliverables

- `~/internship/cicd/.github/workflows/deploy.yml`
- `~/internship/cicd/helm/` — complete Helm chart
- `~/internship/cicd/k8s/` — plain Kubernetes manifests
- `~/internship/cicd/README.md` — how to set up, secrets needed, architecture

### Hints

- Use GitHub Environments to gate production deployments with approval
- OIDC auth: configure `roles:write` and use `aws-actions/configure-aws-credentials@v4` with `role-to-assume`
- For Cosign keyless signing: use `cosign sign --keyless` with GitHub OIDC token
- Trivy: use `--severity CRITICAL,HIGH --exit-code 1` to fail the build on criticals
- `helm install --wait --timeout 5m` waits for all pods to be ready
- `kubectl rollout status deployment/myapp -n production` to confirm rollout
