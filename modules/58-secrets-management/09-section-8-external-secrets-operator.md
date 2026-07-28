## 🔍 Section 8: External Secrets Operator (ESO)

Syncs secrets from external providers (Vault, AWS, GCP, Azure) into Kubernetes Secrets.

```
helm repo add external-secrets https://charts.external-secrets.io
helm install external-secrets external-secrets/external-secrets -n external-secrets --create-namespace
```

### SecretStore / ClusterSecretStore

```yaml
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: vault-backend
spec:
  provider:
    vault:
      server: "https://vault.example.com:8200"
      path: "secret"
      version: "v2"
      auth:
        approle:
          path: "approle"
          roleId: "6b2b6f5c-..."
          secretRef:
            name: vault-auth
            key: secret-id
apiVersion: v1
kind: Secret
metadata:
  name: vault-auth
data:
  secret-id: <base64>
```

ClusterSecretStore (cluster-wide) uses Kubernetes auth:

```yaml
spec:
  provider:
    vault:
      auth:
        kubernetes:
          mountPath: "kubernetes"
          role: "external-secrets-role"
          serviceAccountRef:
            name: external-secrets-sa
            namespace: external-secrets
```

AWS, GCP, Azure SecretStore variants:

```yaml
# AWS
spec:
  provider:
    aws:
      service: SecretsManager
      region: us-east-1
      auth:
        secretRef:
          accessKeyIDSecretRef: {name: aws-creds, key: access-key}
          secretAccessKeySecretRef: {name: aws-creds, key: secret-key}
# GCP
spec:
  provider:
    gcpsm:
      projectID: my-project
      auth:
        secretRef:
          secretAccessKeySecretRef: {name: gcp-creds, key: credentials}
# Azure
spec:
  provider:
    azurekv:
      vaultUrl: "https://my-vault.vault.azure.net"
      authSecretRef:
        clientId: {name: azure-creds, key: client-id}
        clientSecret: {name: azure-creds, key: client-secret}
```

### ExternalSecret

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: database-credentials
spec:
  refreshInterval: "30m"
  secretStoreRef:
    name: vault-backend
    kind: SecretStore
  target:
    name: db-creds
    creationPolicy: Owner
  data:
  - secretKey: password
    remoteRef:
      key: database/postgres
      property: password
  - secretKey: username
    remoteRef:
      key: database/postgres
      property: username
```





[← Previous](08-section-7-vault-agent-and.md) | [↑ Index](index.md) | [Next →](10-section-9-sops-mozilla.md)
