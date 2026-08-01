## Section 9: CircleCI, ArgoCD, and Tekton

### CircleCI — Cloud-Native CI/CD

```yaml
# .circleci/config.yml
version: 2.1
jobs:
  build:
    docker:
      - image: cimg/node:20.0
    steps:
      - checkout
      - run: npm install
      - run: npm test
workflows:
  version: 2
  build-and-test:
    jobs:
      - build
```

### ArgoCD — GitOps for Kubernetes

```bash
# Install ArgoCD
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Create an application
argocd app create myapp \
  --repo https://github.com/user/repo.git \
  --path k8s \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace default

# Sync
argocd app sync myapp
```

### Tekton — Kubernetes-Native Pipelines

```yaml
apiVersion: tekton.dev/v1beta1
kind: Task
metadata:
  name: build-docker
spec:
  steps:
    - name: build-and-push
      image: gcr.io/kaniko-project/executor:latest
      args: ["--dockerfile=Dockerfile", "--destination=gcr.io/myapp:latest"]
```
