## 🔍 Section 4: Vault Secret Engines

### KV v2 — Versioned Static Secrets

Each write creates a new version. Soft-delete can be undone; destroy is permanent.

```
vault secrets enable -version=2 -path=secret kv
vault kv put secret/database/postgres username=admin password=P@ss host=db.example.com
vault kv get secret/database/postgres
vault kv get -version=1 secret/database/postgres               # specific version
vault kv delete secret/database/postgres                       # soft delete
vault kv undelete -versions=2 secret/database/postgres         # restore
vault kv destroy -versions=1 secret/database/postgres          # permanent
vault kv metadata get secret/database/postgres                 # version metadata
vault kv metadata delete secret/database/postgres              # delete all
```

### Database Engine — Dynamic Credentials

Vault connects to the DB with admin creds, creates an ephemeral user with a short TTL, returns creds to the app, and auto-revokes when TTL expires.

```
Vault ──1.Configure connection──► PostgreSQL (admin creds)
  │                                    │
  ├──2.Create role with SQL template──►│
  │                                    │
  ◄──3.App requests creds─────────────│
  │                                    │
  ├──4.CREATE USER "v-xxx"───────────►│
  │    WITH PASSWORD, VALID UNTIL      │
  │                                    │
  ├──5.Return username+password──────►│ App
  │                                    │
  │   (TTL expires)                    │
  ├──6.DROP USER "v-xxx"─────────────►│
```

```
vault secrets enable database
vault write database/config/postgres plugin_name=postgresql-database-plugin \
    allowed_roles="*" \
    connection_url="postgresql://{{username}}:{{password}}@postgres:5432/mydb" \
    username=vault_admin password=AdminPass

vault write database/roles/app-readonly db_name=postgres \
    creation_statements="CREATE USER \"{{name}}\" WITH PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; GRANT SELECT ON ALL TABLES IN SCHEMA public TO \"{{name}}\";" \
    default_ttl=1h max_ttl=24h

vault read database/creds/app-readonly
# username: v-appreadonly-a1b2c3...
# password: p7x8R9t0...
```

MySQL and MongoDB work identically with different plugin names and creation statements.

### AWS Engine — Dynamic IAM/STS

```
vault secrets enable aws
vault write aws/config/root access_key=AKIA... secret_key=... region=us-east-1
vault write aws/roles/deploy-role credential_type=iam_user policy_document=@policy.json
vault read aws/creds/deploy-role
# access_key + secret_key generated dynamically, revoked on TTL expiry
```

### PKI Engine — Internal CA

Vault acts as a Certificate Authority, issuing TLS certificates on-demand.

```
vault secrets enable pki
vault secrets tune -max-lease-ttl=87600h pki
vault write pki/root/generate/internal common_name=example.com ttl=87600h key_type=rsa key_bits=4096

vault write pki/config/urls \
    issuing_certificates="http://vault:8200/v1/pki/ca" \
    crl_distribution_points="http://vault:8200/v1/pki/crl"

vault write pki/roles/server allowed_domains=example.com allow_subdomains=true \
    max_ttl=720h key_type=ecdsa key_bits=256

vault write -format=json pki/issue/server common_name=api.example.com ttl=168h \
    alt_names="api.internal.example.com" ip_sans="10.0.0.50" | jq -r '.data.certificate' > cert.pem

vault write pki/revoke serial_number=<serial>   # revoke certificate
```

Intermediate CA pattern (production): generate intermediate CSR → sign with root → import signed intermediate.

### Transit Engine — Encryption as a Service

Encrypt/decrypt data without the application ever seeing the encryption key.

```
vault secrets enable transit
vault write -f transit/keys/payment-data
vault write transit/encrypt/payment-data plaintext=$(echo -n "4111111111111111" | base64)
# ciphertext: vault:v1:abc123...
vault write transit/decrypt/payment-data ciphertext=vault:v1:abc123...
vault write -f transit/keys/payment-data/rotate                 # rotate key
```





[← Previous](04-section-3-vault-auth-methods.md) | [↑ Index](index.md) | [Next →](06-section-5-vault-policies.md)
