## 🔍 Section 10: Sealed Secrets (Bitnami)

Kubernetes-native encryption. Controller holds private key; kubeseal CLI encrypts with public key.

```
helm repo add sealed-secrets https://bitnami-labs.github.io/sealed-secrets
helm install sealed-secrets sealed-secrets/sealed-secrets -n sealed-secrets --create-namespace
```

### Workflow

```
kubeseal CLI ──encrypt──► SealedSecret ──Git──► kubectl apply ──► Controller decrypts ──► K8s Secret
```

### Usage

```
# Create regular Secret, then seal it
kubeseal --format yaml < secret.yaml > sealed-secret.yaml

# Fetch public key for offline sealing
kubeseal --fetch-cert > public-key.pem
kubeseal --cert public-key.pem --format yaml < secret.yaml > sealed-secret.yaml
```

SealedSecret YAML:
```yaml
apiVersion: bitnami.com/v1alpha1
kind: SealedSecret
metadata:
  name: my-secret
  namespace: production
spec:
  encryptedData:
    password: AgBv5Hqk2j...
    api-key: AgC6t7Uv8w...
  template:
    type: Opaque
```

### Sealing Scope

| Scope | Encrypted | Use |
|-------|-----------|-----|
| `strict` (default) | name + namespace | Exact match only |
| `namespace-wide` | namespace only | Same NS, any name |
| `cluster-wide` | nothing | Any NS/name |

### Key Rotation

Controller auto-rotates keys. Old keys retained — previously sealed items remain decryptable.

```
kubectl delete secret -n sealed-secrets -l sealedsecrets.bitnami.com/sealed-secrets-key
```

---



---

[← Previous](10-section-9-sops-mozilla.md) | [↑ Index](index.md) | [Next →](12-section-11-cloud-secrets-managers.md)
