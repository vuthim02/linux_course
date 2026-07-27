## 🔍 Section 9: SOPS (Mozilla)

Encrypts YAML/JSON/ENV files so they can be safely stored in Git. Encrypts only values; structure remains readable.

### With age (modern PGP alternative)

```
age-keygen -o ~/.sops/age/keys.txt                    # generate key
sops --encrypt --age age1abc... --encrypted-regex "^(password|key|secret)$" config.yaml > config.enc.yaml
sops --decrypt config.enc.yaml
sops config.enc.yaml                                    # edit in $EDITOR
```

Encrypted YAML:
```yaml
database:
  password: ENC[AES256_GCM,data:abc123...,iv:def...,tag:ghi...]
sops:
  age:
    - recipient: age1abc...
      enc: |-
        -----BEGIN AGE ENCRYPTED FILE-----
        ...
  lastmodified: "2025-06-24T12:00:00Z"
  mac: ENC[...]
  version: 3.8.0
```

### With AWS KMS

```
sops --encrypt --kms arn:aws:kms:us-east-1:123456789012:key/abc-123 secrets.yaml
```

### With GCP KMS

```
sops --encrypt --gcp-kms projects/my-project/locations/global/keyRings/sops/cryptoKeys/sops-key secrets.yaml
```

### With Azure Key Vault

```
sops --encrypt --azure-kv https://my-vault.vault.azure.net/keys/sops-key/abc123 secrets.yaml
```

### .sops.yaml Configuration

```yaml
creation_rules:
  - path_regex: secrets/.*\.yaml
    age: age1abc...
    encrypted_regex: "^(password|secret|key|token)$"
  - path_regex: terraform/.*\.tfvars
    kms: arn:aws:kms:...
  - path_regex: \.env$
    age: age1abc...
```

### SOPS in CI

```yaml
# GitHub Actions
- uses: age-identity/actions/setup-age-identity@v1
  with:
    identity: ${{ secrets.SOPS_AGE_KEY }}
- run: sops --decrypt secrets/terraform.tfvars.enc > terraform/terraform.tfvars
```

---



---

[← Previous](09-section-8-external-secrets-operator.md) | [↑ Index](index.md) | [Next →](11-section-10-sealed-secrets-bitnami.md)
