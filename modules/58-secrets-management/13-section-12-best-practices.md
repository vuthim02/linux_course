## 🔍 Section 12: Best Practices

### Never Commit Secrets to Git

```
# .gitignore secrets, use gitleaks as pre-commit hook
gitleaks detect --source . -v
detect-secrets scan > .secrets.baseline
```

### Rotation Schedule

| Type | Frequency | Method |
|------|-----------|--------|
| Database passwords | 24h | Vault dynamic |
| TLS certs | 90 days | Vault PKI + cert-manager |
| Cloud access keys | 90 days | Vault AWS engine |
| Encryption keys | 1 year | Vault transit rotation |

### Least Privilege

```
# Bad: overly broad
path "secret/*" { capabilities = ["read"] }
# Good: scoped to app + path
path "secret/data/production/my-app/*" { capabilities = ["read"] }
# Best: dynamic credentials with TTL
path "database/creds/my-app-role" { capabilities = ["read"] }
```

### Backup & Disaster Recovery

```
vault operator raft snapshot save /backups/vault-$(date +%F).snap
vault operator raft snapshot restore /backups/vault-snapshot-2025-06-24.snap
```

Store unseal keys securely (HSM, password manager, printed safe). Test restore annually. Aim for RTO < 1 hour.

### Monitoring

```yaml
# Prometheus alert
groups:
- name: vault
  rules:
  - alert: VaultSealed
    expr: vault_core_unsealed == 0
    for: 1m
    labels: { severity: critical }
```

---



---

[← Previous](12-section-11-cloud-secrets-managers.md) | [↑ Index](index.md) | [Next →](14-15-hands-on-practices.md)
