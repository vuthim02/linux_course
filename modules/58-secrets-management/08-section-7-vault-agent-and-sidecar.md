## 🔍 Section 7: Vault Agent and Sidecar

### Agent Configuration

```hcl
vault { address = "https://vault.example.com:8200" }
auto_auth {
  method "approle" {
    config { role_id_file_path = "/etc/vault/role-id"; secret_id_file_path = "/etc/vault/secret-id" }
  }
  sink "file" { config { path = "/tmp/vault-token" } }
}
cache { use_auto_auth_token = true }
listener "tcp" { address = "127.0.0.1:8200"; tls_disable = true }
template {
  source      = "/etc/vault/templates/db.tpl"
  destination = "/etc/secrets/db-creds.txt"
}
```

### Template Example

```go
{{- with secret "database/creds/app-readonly" -}}
DATABASE_URL=postgresql://{{ .Data.username }}:{{ urlquery .Data.password }}@postgres:5432/mydb
{{- end -}}
```

### Vault Agent Injector (K8s)

```yaml
annotations:
  vault.hashicorp.com/agent-inject: "true"
  vault.hashicorp.com/role: "my-app"
  vault.hashicorp.com/agent-inject-secret-database: "database/creds/my-app-role"
  vault.hashicorp.com/agent-inject-template-database: |
    {{- with secret "database/creds/my-app-role" -}}
    DATABASE_URL=postgresql://{{ .Data.username }}:{{ urlquery .Data.password }}@postgres:5432/myapp
    {{- end -}}
```





[← Previous](07-section-6-vault-in-production.md) | [↑ Index](index.md) | [Next →](09-section-8-external-secrets-operator.md)
