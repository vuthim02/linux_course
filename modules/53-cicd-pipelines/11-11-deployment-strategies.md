## 11. Deployment Strategies

### Rolling Update

Replace instances one by one with zero downtime: `kubectl set image deployment/app app=myapp:1.2.0 && kubectl rollout status deployment/app`. Kubernetes parameters: `maxSurge: 1` (extra pod), `maxUnavailable: 0` (keep all running).

### Blue/Green Deployment

Two identical environments (blue/green). Deploy to inactive, switch traffic, drain old:
```bash
kubectl apply -f k8s/deployment-green.yaml
kubectl rollout status deployment/app-green -n production
kubectl patch service app -n production -p '{"spec":{"selector":{"version":"green"}}}'
kubectl scale deployment/app-blue --replicas=0 -n production
```

### Canary Deployment

Route traffic % to new version, gradually increase. Istio VirtualService: `weight: 10` → canary, `weight: 90` → stable. Progressive delivery with Flagger automates canary analysis and rollback based on metrics (error rate, latency).

### Deploying to Kubernetes from Pipeline

**kubectl (direct):**
```yaml
# GitLab CI
deploy:
  image: alpine/k8s:1.28
  script:
    - kubectl config set-cluster k8s --server=$K8S_SERVER --insecure-skip-tls-verify
    - kubectl config set-credentials deployer --token=$K8S_TOKEN
    - kubectl config set-context k8s --cluster=k8s --user=deployer
    - kubectl config use-context k8s
    - sed -i "s|image:.*|image: $CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA|" k8s/deployment.yaml
    - kubectl apply -f k8s/
    - kubectl rollout status deployment/my-app -n production --timeout=5m
```

**Helm:**
```yaml
# GitHub Actions — Helm deploy
jobs:
  helm-deploy:
    runs-on: ubuntu-22.04
    steps:
      - uses: actions/checkout@v4
      - name: Configure K8s context
        uses: azure/k8s-set-context@v3
        with:
          kubeconfig: ${{ secrets.KUBECONFIG }}
      - name: Deploy with Helm
        uses: bitovi/github-actions-deploy-helm-kubernetes@v1
        with:
          namespace: production
          releases: |
            app:
              chart: ./helm/app
              values: ./helm/values-production.yaml
              set:
                image.tag: ${{ github.sha }}
```

**GitOps with ArgoCD:**
```yaml
# Pipeline only updates the Git repo; ArgoCD syncs to cluster
jobs:
  gitops-update:
    runs-on: ubuntu-22.04
    permissions:
      contents: write
    steps:
      - uses: actions/checkout@v4
        with:
          repository: myorg/gitops-config
          token: ${{ secrets.GITOPs_TOKEN }}
      - name: Update image tag in GitOps repo
        run: |
          cd k8s/overlays/production
          kustomize edit set image my-app=ghcr.io/myorg/my-app:${{ github.sha }}
          git config user.name "CI Bot"
          git config user.email "ci@example.com"
          git add .
          git commit -m "Update my-app to ${{ github.sha }}"
          git push
```

**GitOps with Flux:**
```yaml
# Flux Image Update Automation
apiVersion: image.toolkit.fluxcd.io/v1beta2
kind: ImageUpdateAutomation
spec:
  interval: 5m
  sourceRef:
    kind: GitRepository
    name: flux-system
  update:
    strategy: Setters
    path: ./k8s/overlays/production
```

### Deploy to VMs/Cloud with Ansible

```yaml
# GitHub Actions — Ansible deploy
jobs:
  ansible-deploy:
    runs-on: ubuntu-22.04
    steps:
      - uses: actions/checkout@v4
      - name: Run Ansible playbook
        uses: dawidd6/action-ansible-playbook@v2
        with:
          playbook: deploy.yml
          directory: ./ansible
          key: ${{ secrets.SSH_PRIVATE_KEY }}
          inventory: |
            [web]
            10.0.1.100
            10.0.1.101
            [web:vars]
            ansible_user=deployer
```

```yaml
# deploy.yml
- hosts: web
  become: yes
  tasks:
    - name: Pull new Docker image
      docker_image:
        name: ghcr.io/myorg/my-app:{{ image_tag }}
        source: pull

    - name: Restart container
      docker_container:
        name: my-app
        image: ghcr.io/myorg/my-app:{{ image_tag }}
        state: started
        restart: yes
        ports:
          - "80:8080"
```

### Deploy with Terraform in Pipeline

```yaml
stages: [build, deploy, terraform]
terraform-plan:
  stage: terraform
  image: hashicorp/terraform:1.9
  script: terraform init && terraform plan -out=plan.tfplan -var="image_tag=$CI_COMMIT_SHORT_SHA"
  artifacts: { paths: [terraform/plan.tfplan] }
  rules: [{ if: $CI_MERGE_REQUEST_IID }, { if: $CI_COMMIT_BRANCH == "main" }]
terraform-apply:
  stage: terraform
  script: terraform apply plan.tfplan
  dependencies: [terraform-plan]
  rules: [{ if: $CI_COMMIT_BRANCH == "main", when: manual }]
```

---



---

[← Previous](10-10-testing-in-ci.md) | [↑ Index](index.md) | [Next →](12-12-monitoring-pipelines.md)
