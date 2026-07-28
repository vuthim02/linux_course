## 🔍 Section 3: Vault Auth Methods

### Token (built-in)
```
vault token create -policy=my-policy -ttl=24h
```

### AppRole (machine-to-machine)

Two-part credential: `role_id` (static, like username) + `secret_id` (ephemeral, like password).

```
vault auth enable approle
vault write auth/approle/role/my-app secret_id_ttl=10m token_ttl=1h token_policies=my-app-policy
vault read auth/approle/role/my-app/role-id                            # get role_id
vault write -f auth/approle/role/my-app/secret-id                       # generate secret_id
vault write auth/approle/login role_id=... secret_id=...                 # get token
```

### Kubernetes Auth

Vault verifies the K8s ServiceAccount token. Pod's SA, namespace, and optionally pod name are validated against the role.

```
vault auth enable kubernetes
vault write auth/kubernetes/config \
    kubernetes_host=https://kubernetes.default.svc \
    token_reviewer_jwt=@/var/run/secrets/kubernetes.io/serviceaccount/token

vault write auth/kubernetes/role/my-app \
    bound_service_account_names=my-app-sa \
    bound_service_account_namespaces=production \
    token_ttl=1h token_policies=my-app-policy
```

### AWS Auth (IAM / EC2)

```
vault auth enable aws
vault write auth/aws/config/client secret_key=... access_key=...
vault write auth/aws/role/developer auth_type=iam \
    bound_iam_principal_arn=arn:aws:iam::123456789012:role/developer \
    token_ttl=1h token_policies=developer-policy
```

### GCP Auth (GCE / IAM)

```
vault auth enable gcp
vault write auth/gcp/config credentials=@service-account.json
vault write auth/gcp/role/my-instance type=gce \
    bound_projects=my-project bound_zones=us-central1-a token_policies=my-policy
```

### Auth Method Tuning

```
vault auth tune approle/ default_lease_ttl=12h max_lease_ttl=48h
```





[← Previous](03-section-2-hashicorp-vault-architecture.md) | [↑ Index](index.md) | [Next →](05-section-4-vault-secret-engines.md)
