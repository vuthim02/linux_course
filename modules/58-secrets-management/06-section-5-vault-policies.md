## 🔍 Section 5: Vault Policies

HCL format with path-based capabilities.

| Capability | HTTP | Description |
|------------|------|-------------|
| `create` | POST | Create at path |
| `read` | GET | Read data |
| `update` | POST/PUT | Update existing |
| `delete` | DELETE | Delete |
| `list` | LIST | List sub-paths |
| `sudo` | varies | Sudo-level ops |
| `deny` | all | Deny (overrides all) |

```
# app-policy.hcl
path "secret/data/production/*" {
  capabilities = ["read", "list"]
}
path "secret/data/staging/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}
path "secret/data/production/database/admin" {
  capabilities = ["deny"]
}
path "database/creds/my-app-role" {
  capabilities = ["read"]
}
```

```
vault policy write app-policy @app-policy.hcl
vault token create -policy=app-policy
vault token capabilities <token> secret/data/production/db
```

Multiple policies: most permissive wins unless `deny` is present (deny takes precedence).

---



---

[← Previous](05-section-4-vault-secret-engines.md) | [↑ Index](index.md) | [Next →](07-section-6-vault-in-production.md)
