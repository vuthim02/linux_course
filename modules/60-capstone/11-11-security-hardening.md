## 11. Security Hardening

### Pod Security Standards — Restricted Profile

```yaml
# Apply restricted PodSecurityStandard via label
kubectl label ns production pod-security.kubernetes.io/enforce=restricted

# Verify with dry-run first
kubectl label --dry-run=server ns production pod-security.kubernetes.io/enforce=restricted

# If a pod violates, it will not be admitted
kubectl run bad-pod --image=nginx --privileged -n production
# Error: violates PodSecurity "restricted:latest" (privileged, allowPrivilegeEscalation=true)
```

### Network Policies — Cilium L3/L7

```yaml
# Default deny-all ingress
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-ingress
  namespace: production
spec:
  podSelector: {}
  policyTypes:
    - Ingress
---
# Allow API traffic from ingress controller only
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-api-ingress
  namespace: production
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: capstone-api
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: ingress-nginx
          podSelector:
            matchLabels:
              app.kubernetes.io/component: controller
      ports:
        - port: 8000
---
# Allow database access only from app pods
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-db-access
  namespace: production
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: pgbouncer
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app.kubernetes.io/name: capstone-api
      ports:
        - port: 5432
---
# Cilium L7 policy — allow only GET /api/v1/items
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: allow-api-read-only
  namespace: production
spec:
  endpointSelector:
    matchLabels:
      app.kubernetes.io/name: capstone-api
  ingress:
    - fromEndpoints:
        - matchLabels:
            app.kubernetes.io/component: controller
      toPorts:
        - ports:
            - port: "8000"
              protocol: TCP
          rules:
            http:
              - method: GET
                path: /api/v1/items/?$
              - method: GET
                path: /health$
              - method: GET
                path: /metrics$
```

### Kyverno — Policy Enforcement

```bash
helm repo add kyverno https://kyverno.github.io/kyverno/
helm repo update

helm upgrade --install kyverno kyverno/kyverno \
  --namespace kyverno \
  --create-namespace \
  --set admissionController.replicas=2 \
  --set backgroundController.enabled=true \
  --set cleanupController.enabled=true
```

```yaml
# Require resource limits on all pods
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-resource-limits
spec:
  validationFailureAction: Enforce
  rules:
    - name: check-resources
      match:
        any:
          - resources:
              kinds:
                - Pod
      validate:
        message: "All containers must have resource limits defined"
        pattern:
          spec:
            containers:
              - resources:
                  limits:
                    memory: "?*"
                    cpu: "?*"
---
# Disallow latest tag
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: disallow-latest-tag
spec:
  validationFailureAction: Enforce
  rules:
    - name: require-image-tag
      match:
        any:
          - resources:
              kinds:
                - Pod
      validate:
        message: "Using 'latest' tag is not allowed"
        pattern:
          spec:
            containers:
              - image: "!*:latest"
```

### IAM Roles for Service Accounts (IRSA)

```yaml
# ServiceAccount with IAM role annotation
apiVersion: v1
kind: ServiceAccount
metadata:
  name: capstone-api
  namespace: production
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::ACCOUNT_ID:role/capstone-api-role
---
apiVersion: v1
kind: Pod
metadata:
  name: capstone-api-pod
  namespace: production
spec:
  serviceAccountName: capstone-api
  containers:
    - name: app
      image: ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/capstone-api:latest
```

### TLS Everywhere with cert-manager

```yaml
# Ingress with TLS
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: capstone-api
  namespace: production
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  tls:
    - hosts:
        - api.capstone.example.com
      secretName: api-tls
  rules:
    - host: api.capstone.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: capstone-api
                port:
                  number: 80
```

### Container Image Scanning in CI

```yaml
# Trivy scan integrated in GitHub Actions (see CI/CD section)
# For ad-hoc scanning:
trivy image ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/capstone-api:latest \
  --severity CRITICAL,HIGH \
  --exit-code 1 \
  --format table

# Scan in Kubernetes
kubectl run trivy-scan --rm -it --restart=Never \
  --image docker.io/aquasec/trivy:latest \
  --command -- trivy image ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/capstone-api:latest
```

---



---

[← Previous](10-10-scaling-and-resilience.md) | [↑ Index](index.md) | [Next →](12-12-day-2-operations.md)
