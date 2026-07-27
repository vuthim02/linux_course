## 10. RBAC — Role-Based Access Control

### ServiceAccounts

A ServiceAccount provides an identity for pods. Each namespace has a `default` ServiceAccount automatically.

```bash
kubectl create serviceaccount my-sa -n production
kubectl get serviceaccounts -A
kubectl describe sa my-sa -n production
```

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: my-sa
  namespace: production
automountServiceAccountToken: true    # auto-mount API token in pods
---
apiVersion: v1
kind: Pod
metadata:
  name: app-pod
spec:
  serviceAccountName: my-sa
  containers:
  - name: app
    image: myapp:1.0
```

### Roles and ClusterRoles

**Role** — namespace-scoped permissions.

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader
  namespace: production
rules:
- apiGroups: [""]              # core API group
  resources: ["pods"]
  verbs: ["get", "list", "watch"]
- apiGroups: [""]
  resources: ["pods/log"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["apps"]
  resources: ["deployments"]
  verbs: ["get", "list", "watch"]
```

**ClusterRole** — cluster-wide permissions (resources, non-resource URLs, namespaced resources across all namespaces).

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: cluster-reader
rules:
- apiGroups: [""]
  resources: ["nodes", "namespaces", "persistentvolumes"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["rbac.authorization.k8s.io"]
  resources: ["clusterroles", "clusterrolebindings"]
  verbs: ["get", "list", "watch"]
- nonResourceURLs: ["/healthz", "/livez", "/readyz"]
  verbs: ["get"]
```

### RoleBindings and ClusterRoleBindings

**RoleBinding** — binds a Role to subjects (Users, Groups, ServiceAccounts) within a namespace.

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: pod-reader-binding
  namespace: production
subjects:
- kind: ServiceAccount
  name: my-sa
  namespace: production
- kind: User
  name: alice@example.com
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

**ClusterRoleBinding** — binds a ClusterRole to subjects cluster-wide.

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: cluster-reader-binding
subjects:
- kind: ServiceAccount
  name: monitoring-sa
  namespace: monitoring
- kind: User
  name: admin@example.com
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: cluster-reader
  apiGroup: rbac.authorization.k8s.io
```

**Combine ClusterRole + RoleBinding** — grants cluster-wide permissions (like read all pods) within a specific namespace:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: cluster-reader-binding-ns
  namespace: production
subjects:
- kind: ServiceAccount
  name: my-sa
  namespace: production
roleRef:
  kind: ClusterRole
  name: cluster-reader             # references a ClusterRole
  apiGroup: rbac.authorization.k8s.io
```

### Default Cluster Roles

| ClusterRole | Purpose |
|---|---|
| `cluster-admin` | Full access to everything |
| `admin` | Full access within a namespace |
| `edit` | Read/write within a namespace (no RBAC) |
| `view` | Read-only within a namespace |

```bash
# Give a user admin access to a namespace
kubectl create rolebinding alice-admin -n production --clusterrole=admin --user=alice@example.com

# Give SA read-only access across all namespaces
kubectl create clusterrolebinding sa-reader --clusterrole=view --serviceaccount=production:my-sa
```

### RBAC Debugging

```bash
# Check what a user/SA can do
# Requires kubectl-sudo plugin or:
kubectl auth can-i create deployments --as system:serviceaccount:production:my-sa
kubectl auth can-i get pods --as alice@example.com

# For the current user
kubectl auth can-i delete pods

# Check binding
kubectl get rolebindings -n production -o wide
kubectl get clusterrolebindings -o wide

# What permissions does a role grant?
kubectl describe role pod-reader -n production
kubectl describe clusterrole cluster-admin
```

### RBAC Best Practices

- **Least privilege**: Grant only what is needed.
- **Use ServiceAccounts for pods, not user tokens.**
- **Use Groups** for managing teams (tied to your OIDC provider).
- **Regularly audit** with tools like `kubectl audit` or `kubectx` + `kubectl auth can-i`.
- **Enable RBAC** (it is on by default in 1.6+).
- **Never bind `cluster-admin` to a user unless absolutely necessary.**

---



---

[← Previous](09-9-storage.md) | [↑ Index](index.md) | [Next →](11-11-horizontal-pod-autoscaler-hpa.md)
