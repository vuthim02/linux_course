# 🐧 Linux System Administrator — Complete Course
## Part 58 of ∞: Secrets Management — Vault, SOPS, Sealed Secrets

---

> **Reverse Engineering Approach:** Every secret in a production system — database passwords, API tokens, TLS private keys, cloud credentials — is a liability when written to disk in plaintext, committed to Git, or echoed into a CI log. This part takes the perspective of an attacker who has gained read access to a filesystem, Git history, or Kubernetes pod. We trace every leakage path: plaintext secrets in YAML files, credentials baked into container images, service account tokens mounted needlessly, hardcoded database passwords. Then we build defenses from the ground up — HashiCorp Vault for dynamic ephemeral credentials with automatic rotation and audit trails; SOPS for encrypting config files at rest so they can live in Git safely; and Sealed Secrets for Kubernetes-native encryption of Secret manifests. By understanding exactly how secrets leak, you will understand exactly how to stop it.

---

## 🎯 What You Will Achieve

- Understand the secrets management landscape — encryption at rest, in transit, in use
- Deploy HashiCorp Vault in dev and production configurations
- Master seal/unseal including Shamir threshold and auto-unseal
- Configure auth methods: token, approle, kubernetes, cloud IAM
- Use KV v2 for static secrets with versioning and delete/undelete
- Set up database secret engine for dynamic PostgreSQL/MySQL credentials
- Operate PKI engine to issue and revoke TLS certificates
- Encrypt data with transit engine (encryption-as-a-service)
- Write Vault policies in HCL with path-based capabilities
- Deploy Vault in production HA with integrated raft storage
- Configure audit devices and inspect audit logs
- Run Vault Agent with auto-auth and templating
- Deploy External Secrets Operator to sync Vault secrets to K8s Secrets
- Use SOPS with age and cloud KMS to encrypt configs for safe Git storage
- Deploy Bitnami Sealed Secrets with kubeseal for K8s-native encryption
- Use cloud secrets managers (AWS, GCP, Azure)
- Apply secrets management best practices
- Complete **15 hands-on practices** including a real-world multi-platform integration

---

## 🔍 Section 1: Why Secrets Management?

### The Secrets Sprawl Problem

A typical microservice uses: database passwords, cloud access keys, TLS certs, API tokens, JWT signing keys, OAuth secrets, SSH keys, encryption keys, K8s ServiceAccount tokens, WireGuard PSKs. Most are hardcoded in config files, stored in env vars, committed to Git, or passed through CI logs. This is secrets sprawl.

### Attack Vectors

| Vector | How It Works | Example |
|--------|---|---|
| Git history | Developer commits secret, removes it — lives in history forever | 100K+ GitHub repos leak secrets daily |
| CI logs | Build script echos env var to debug output | CircleCI 2023 breach |
| ConfigMaps | ConfigMap mounted as env var — any pod reader gets it | Attacker with `pods/get` |
| Container images | `ENV PASSWORD=...` in Dockerfile — `docker history` reveals it | Registry leaks |
| Core dumps | Process crash dumps contain secrets in memory | Heartbleed |

### Encryption States: At Rest, In Transit, In Use

**At rest:** AES-256-GCM (Vault barrier, SOPS, Sealed Secrets, KMS)
**In transit:** TLS 1.3, mTLS, WireGuard Noise protocol, SSH
**In use:** AMD SEV-SNP, Intel TDX, Confidential Containers, AWS Nitro Enclaves

### Static vs Dynamic Secrets

| Aspect | Static | Dynamic |
|--------|--------|---------|
| Lifetime | Months/Years | Minutes/Hours |
| Rotation | Manual | Automatic |
| Leak window | Until rotated | Until TTL expiry |
| Blast radius | Entire resource | Single ephemeral user |

Dynamic secrets are generated on-demand with a short TTL and auto-revoked. A leaked dynamic DB password is valid for minutes, not years.

---

## 🔍 Section 2: HashiCorp Vault Architecture

### Core Architecture

```
┌─────────────────────────────────────────────┐
│               Vault Server                   │
│  ┌───────────────────────────────────────┐  │
│  │          HTTP API (TCP 8200)          │  │
│  │  auth │ sec.eng │ sys │ audit │ cache │  │
│  └──────────────────┬────────────────────┘  │
│  ┌──────────────────▼────────────────────┐  │
│  │            Token Store                │  │
│  │   (token → policy → metadata)        │  │
│  └──────────────────┬────────────────────┘  │
│  ┌──────────────────▼────────────────────┐  │
│  │   Barrier (AES-256-GCM master key)    │  │
│  │   All data encrypted before storage   │  │
│  └──────────────────┬────────────────────┘  │
│  ┌──────────────────▼────────────────────┐  │
│  │   Storage Backend (Raft/Consul/File)  │  │
│  └───────────────────────────────────────┘  │
└─────────────────────────────────────────────┘
```

### Sealed vs Unsealed

On startup Vault is **sealed** — the storage backend data is encrypted with a master key and cannot be read. The **unseal process** reconstructs the master key from Shamir shares (splits into N shares, threshold T required) or via auto-unseal (master key encrypted by cloud KMS).

**Shamir's Secret Sharing (5/3):** Master key split into 5 shares. Any 3 can reconstruct. Prevents any single person from unsealing Vault.

**Auto-Unseal flow:** Vault starts → reads encrypted master key from storage → sends to cloud KMS (AWS KMS/GCP KMS/Azure KV) for decryption → Vault decrypts master key in memory → unsealed. No human intervention needed.

### Storage Backends

| Backend | HA | Notes |
|---------|----|-------|
| Integrated Raft | Yes | No external dependency, production choice |
| Consul | Yes | External KV store, proven |
| File | No | Dev/test only |
| S3/GCS/Azure | No | + external HA coordination |

### Vault Agent

Vault Agent runs alongside apps to handle authentication, caching, and template rendering. Applications read secrets from local files/Unix socket instead of contacting Vault directly.

```
Pod ┌─────────────────────────────┐
    │ App Container               │
    │ reads /etc/secrets/*        │
    └─────────┬───────────────────┘
              │ localhost:8200
    ┌─────────▼───────────────────┐
    │ Vault Agent Sidecar         │
    │ auto-auth → cache → template│
    └─────────┬───────────────────┘
              │ mTLS
              ▼ Vault Server
```

---

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

---

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

---

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

## 🔍 Section 6: Vault in Production

### HA with Integrated Raft

```
┌──────────┐    ┌──────────┐    ┌──────────┐
│ Vault    │◄──►│ Vault    │◄──►│ Vault    │
│ Node 1   │    │ Node 2   │    │ Node 3   │
│ (leader) │    │(follower)│    │(follower)│
└────┬─────┘    └────┬─────┘    └────┬─────┘
     │               │               │
     └───────┬───────┴───────┬───────┘
             │ Load Balancer │
             └───────────────┘
```

Config (each node):
```hcl
storage "raft" {
  path = "/opt/vault/data"
  node_id = "node-1"
  retry_join { leader_api_addr = "http://node-1:8200" }
  retry_join { leader_api_addr = "http://node-2:8200" }
  retry_join { leader_api_addr = "http://node-3:8200" }
}
listener "tcp" { address = "0.0.0.0:8200"; tls_disable = true }
api_addr = "http://node-1:8200"
cluster_addr = "http://node-1:8201"
```

```
vault operator init -key-shares=5 -key-threshold=3               # init leader
vault operator raft join http://<leader>:8200                    # join followers
vault operator raft list-peers                                    # verify cluster
vault operator raft snapshot save /backups/vault-$(date +%F).snap # backup
```

### Performance Standby Nodes (Enterprise)

Handle read requests locally, forward writes to active node. Reduces latency for geo-distributed reads.

### Audit Devices

Log every request/response. Always enable in production.

```
vault audit enable file file_path=/var/log/vault/audit.log
vault audit enable syslog facility=AUTH tag=vault-audit
vault audit enable socket address=siem.example.com:514 socket_type=tcp
vault audit list
vault audit disable file/
```

Audit log entries show HMAC-hashed tokens and sensitive data:
```json
{
  "time": "2025-06-24T12:00:00Z",
  "type": "response",
  "auth": { "client_token": "hmac-sha256:abc...", "policies": ["my-policy"] },
  "request": { "operation": "read", "path": "database/creds/my-app-role" }
}
```

### Replication (Enterprise)

- **Performance Replication:** All data from primary → secondary clusters. Writes on primary, reads anywhere.
- **DR Replication:** Data replicated for DR. Secondary stays offline until promoted.

---

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

---

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
---
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

---

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

## 🔍 Section 11: Cloud Secrets Managers

### AWS Secrets Manager

```
aws secretsmanager create-secret --name production/db-password \
    --secret-string '{"username":"admin","password":"SuperS3cret!"}'
aws secretsmanager get-secret-value --secret-id production/db-password --query SecretString --output text
aws secretsmanager rotate-secret --secret-id production/db-password \
    --rotation-lambda-arn arn:aws:lambda:...:function:rotate-db
```

### GCP Secret Manager

```
gcloud secrets create production-db-password --replication-policy=user-managed --locations=us-east1
echo -n "SuperS3cret!" | gcloud secrets versions add production-db-password --data-file=-
gcloud secrets versions access latest --secret=production-db-password
gcloud secrets add-iam-policy-binding production-db-password \
    --member=serviceAccount:my-app-sa@... --role=roles/secretmanager.secretAccessor
```

### Azure Key Vault

```
az keyvault create --name my-vault --resource-group my-rg --enable-soft-delete true
az keyvault secret set --vault-name my-vault --name db-password --value "SuperS3cret!"
az keyvault secret show --vault-name my-vault --name db-password --query value --output tsv
az keyvault network-rule add --name my-vault --ip-address 10.0.0.0/24
```

### When to Run Vault vs Cloud Native

| Scenario | Choice |
|----------|--------|
| Single cloud, few secrets | Cloud native |
| Multi-cloud or on-prem | Vault |
| Dynamic DB creds needed | Vault |
| PKI/TLS needed | Vault |
| Encryption-as-a-service | Vault |
| Small team, minimal ops | Cloud native |

---

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

## 🛠️ 15 Hands-On Practices

### 1. Install Vault Dev Server, Unseal, KV v2 CRUD

```
wget -O- https://releases.hashicorp.com/vault/1.18.0/vault_1.18.0_linux_amd64.zip | zcat > /usr/local/bin/vault
chmod +x /usr/local/bin/vault
vault server -dev -dev-root-token-id=root-token &
export VAULT_ADDR='http://127.0.0.1:8200' VAULT_TOKEN='root-token'
vault status
vault kv put secret/database/postgres username=admin password=P@ssw0rd host=db.example.com
vault kv get secret/database/postgres
vault kv put secret/database/postgres password=NewP@ss       # version 2
vault kv metadata get secret/database/postgres
vault kv delete secret/database/postgres                     # soft delete
vault kv undelete -versions=2 secret/database/postgres       # restore
vault kv destroy -versions=1 secret/database/postgres        # permanent destroy
```

### 2. Configure AppRole Auth

```
vault auth enable approle
vault write auth/approle/role/my-app secret_id_ttl=10m token_ttl=1h token_policies=default
vault read auth/approle/role/my-app/role-id
vault write -f auth/approle/role/my-app/secret-id
vault write auth/approle/login role_id=<role_id> secret_id=<secret_id>
# Returns a token — use it for subsequent operations
```

### 3. Create Vault Policy for KV Path

```
cat > app-policy.hcl << 'EOF'
path "secret/data/production/*" { capabilities = ["read", "list"] }
path "secret/data/staging/*"    { capabilities = ["create", "read", "update", "delete", "list"] }
path "secret/data/production/database/admin" { capabilities = ["deny"] }
EOF
vault policy write app-policy @app-policy.hcl
vault token create -policy=app-policy
VAULT_TOKEN=<new-token> vault kv get secret/data/staging/test-key   # succeeds
VAULT_TOKEN=<new-token> vault kv delete secret/data/production/db   # denied (403)
```

### 4. Vault Database Dynamic Creds for PostgreSQL

```
docker run -d --name postgres -e POSTGRES_USER=vault_admin -e POSTGRES_PASSWORD=AdminPass \
    -e POSTGRES_DB=mydb -p 5432:5432 postgres:16
vault secrets enable database
vault write database/config/postgres plugin_name=postgresql-database-plugin \
    allowed_roles="*" connection_url="postgresql://{{username}}:{{password}}@127.0.0.1:5432/mydb" \
    username=vault_admin password=AdminPass
vault write database/roles/app-readonly db_name=postgres \
    creation_statements="CREATE USER \"{{name}}\" WITH PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; GRANT SELECT ON ALL TABLES IN SCHEMA public TO \"{{name}}\";" \
    default_ttl=1h max_ttl=24h
vault read database/creds/app-readonly
# Test with: PGPASSWORD=<password> psql -h 127.0.0.1 -U <username> -d mydb -c "SELECT current_user;"
vault lease revoke database/creds/app-readonly/<lease_id>
vault write -f database/rotate-root/postgres                    # rotate admin creds
```

### 5. Vault PKI — Issue and Revoke Certificate

```
vault secrets enable pki
vault secrets tune -max-lease-ttl=87600h pki
vault write pki/root/generate/internal common_name=mycompany.com ttl=87600h key_type=rsa key_bits=4096
vault write pki/config/urls issuing_certificates="http://127.0.0.1:8200/v1/pki/ca" crl_distribution_points="http://127.0.0.1:8200/v1/pki/crl"
vault write pki/roles/server allowed_domains=mycompany.com allow_subdomains=true max_ttl=720h key_type=ecdsa key_bits=256
vault write -format=json pki/issue/server common_name=api.mycompany.com ttl=168h > cert.json
cat cert.json | jq -r '.data.certificate' > server.crt
cat cert.json | jq -r '.data.private_key' > server.key
SERIAL=$(cat cert.json | jq -r '.data.serial_number')
vault write pki/revoke serial_number=$SERIAL
curl -s http://127.0.0.1:8200/v1/pki/crl | openssl crl -inform DER -text -noout | grep -A2 "Serial Number"
```

### 6. Enable Audit Device and Inspect Logs

```
vault audit enable file file_path=/tmp/vault-audit.log
vault kv put secret/database/creds user=admin password=secret     # generate activity
cat /tmp/vault-audit.log | python3 -m json.tool | head -40
vault audit list
vault audit disable file/
```

### 7. Vault Agent with Auto-Auth and Templating

```
cat > /tmp/agent-config.hcl << 'EOF'
vault { address = "http://127.0.0.1:8200" }
auto_auth { method "approle" { config { role_id_file_path = "/tmp/role-id"; secret_id_file_path = "/tmp/secret-id" } }
  sink "file" { config { path = "/tmp/vault-token" } } }
cache { use_auto_auth_token = true }
listener "tcp" { address = "127.0.0.1:8100"; tls_disable = true }
template { source = "/tmp/db-creds.tpl"; destination = "/tmp/db-creds.txt" }
EOF
echo "<role_id>" > /tmp/role-id
echo "<secret_id>" > /tmp/secret-id
cat > /tmp/db-creds.tpl << 'TPL'
{{- with secret "database/creds/app-readonly" -}}
DATABASE_URL=postgresql://{{ .Data.username }}:{{ urlquery .Data.password }}@postgres:5432/mydb
{{- end -}}
TPL
vault agent -config=/tmp/agent-config.hcl -log-level=debug &
sleep 3
cat /tmp/db-creds.txt       # rendered template with dynamic creds
pkill vault-agent
```

### 8. External Secrets Operator + Vault

```
helm repo add external-secrets https://charts.external-secrets.io
helm install external-secrets external-secrets/external-secrets -n external-secrets --create-namespace
kubectl create secret generic vault-auth --from-literal=secret-id=<secret_id>
kubectl apply -f - << 'EOF'
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: vault-backend
spec:
  provider:
    vault:
      server: "http://vault.example.com:8200"
      path: "secret"
      version: "v2"
      auth:
        approle:
          path: "approle"
          roleId: "<role_id>"
          secretRef:
            name: vault-auth
            key: secret-id
---
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: database-credentials
spec:
  refreshInterval: "1m"
  secretStoreRef:
    name: vault-backend
    kind: SecretStore
  target:
    name: db-creds
  data:
  - secretKey: password
    remoteRef:
      key: database/postgres
      property: password
  - secretKey: username
    remoteRef:
      key: database/postgres
      property: username
EOF
kubectl get secret db-creds -o jsonpath='{.data.password}' | base64 -d
```

### 9. Sealed Secrets — Seal and Deploy

```
helm install sealed-secrets sealed-secrets/sealed-secrets -n sealed-secrets --create-namespace
echo -n "SuperSecret123" | base64 > /tmp/pass.b64
echo -n "sk-abc123def456" | base64 > /tmp/key.b64
cat > secret.yaml << 'EOF'
apiVersion: v1
kind: Secret
metadata:
  name: my-secret
type: Opaque
data:
  password: $(cat /tmp/pass.b64)
  api-key: $(cat /tmp/key.b64)
EOF
kubeseal --format yaml < secret.yaml > sealed-secret.yaml
kubectl apply -f sealed-secret.yaml
kubectl get secret my-secret -o jsonpath='{.data.password}' | base64 -d
kubeseal --fetch-cert > public-key.pem
kubeseal --cert public-key.pem --format yaml < secret.yaml > sealed-offline.yaml
```

### 10. SOPS with age

```
# Install age + sops
mkdir -p ~/.sops/age && age-keygen -o ~/.sops/age/keys.txt
cat > config.yaml << 'EOF'
database: { host: postgres.example.com, password: SuperSecretPassword }
api: { key: sk-abc123def456 }
EOF
PUBKEY=$(cat ~/.sops/age/keys.txt | grep "# public key:" | cut -d: -f2 | tr -d ' ')
sops --encrypt --age $PUBKEY --encrypted-regex "^(password|key|secret)$" config.yaml > config.enc.yaml
cat config.enc.yaml
sops --decrypt config.enc.yaml
EDITOR=vim sops config.enc.yaml
```

### 11. SOPS with AWS KMS

```
KEY_ARN=$(aws kms describe-key --key-id alias/sops-key --query 'KeyMetadata.Arn' --output text)
cat > terraform.tfvars << 'EOF'
db_password = "SuperSecretPassword"
api_key = "sk-abc123def456"
EOF
sops --encrypt --kms $KEY_ARN terraform.tfvars > terraform.tfvars.enc
sops --decrypt terraform.tfvars.enc > terraform.tfvars
```

### 12. AWS Secrets Manager with Rotation

```
aws secretsmanager create-secret --name production/db-password \
    --secret-string '{"username":"db_admin","password":"InitialP@ssw0rd!"}'
aws secretsmanager get-secret-value --secret-id production/db-password --query SecretString --output text | jq .
aws secretsmanager rotate-secret --secret-id production/db-password \
    --rotation-rules '{"AutomaticallyAfterDays": 30}'
aws secretsmanager describe-secret --secret-id production/db-password --query RotationInfo
```

### 13. Vault Auto-Unseal with AWS KMS

```
# Create KMS key for Vault auto-unseal
aws kms create-key --description "Vault auto-unseal"
cat > vault-auto-unseal.hcl << 'EOF'
storage "raft" { path = "/opt/vault/data"; node_id = "node-1" }
listener "tcp" { address = "0.0.0.0:8200"; tls_disable = true }
seal "awskms" { region = "us-east-1"; kms_key_id = "arn:aws:kms:...:key/..." }
api_addr = "http://127.0.0.1:8200"
EOF
vault server -config=vault-auto-unseal.hcl &
vault operator init -key-shares=1 -key-threshold=1
vault status                # should show Sealed: false (auto-unsealed)
```

### 14. Vault HA with Integrated Raft

```
# On 3 nodes, same config with different node_id/api_addr
cat > /etc/vault/config.hcl << 'EOF'
storage "raft" { path = "/opt/vault/data"; node_id = "node-1"
  retry_join { leader_api_addr = "http://10.0.0.1:8200" }
  retry_join { leader_api_addr = "http://10.0.0.2:8200" }
  retry_join { leader_api_addr = "http://10.0.0.3:8200" } }
listener "tcp" { address = "0.0.0.0:8200"; tls_disable = true }
api_addr = "http://10.0.0.1:8200"; cluster_addr = "http://10.0.0.1:8201"
EOF
# Node 1: init + unseal
vault operator init -key-shares=5 -key-threshold=3 && vault operator unseal (x3)
# Nodes 2-3: join + unseal
vault operator raft join http://10.0.0.1:8200 && vault operator unseal (x3)
vault operator raft list-peers
# Test failover: kill leader, check new leader elected
```

### 15. Real-World Integration — Centralized Vault Platform

```
# Deploy Vault HA (3-node raft + auto-unseal)
# Configure approle + kubernetes auth + database engine + PKI + audit

vault auth enable approle
vault auth enable kubernetes
vault write auth/kubernetes/config kubernetes_host=https://kubernetes.default.svc
vault write auth/kubernetes/role/eso bound_service_account_names=external-secrets-sa \
    bound_service_account_namespaces=external-secrets token_ttl=1h token_policies=eso-policy

vault write database/roles/service-a db_name=postgres-prod default_ttl=30m \
    creation_statements="CREATE USER \"{{name}}\" WITH PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; GRANT SELECT, INSERT ON ALL TABLES IN SCHEMA public TO \"{{name}}\";"

vault write pki/roles/service-tls allowed_domains=corp.internal allow_subdomains=true max_ttl=2160h

vault audit enable file file_path=/var/log/vault/audit.log

# Deploy External Secrets Operator, ClusterSecretStore + ExternalSecrets
# Application deployments consume synced K8s Secrets
```

---

## 🧠 Deep Understanding

### How Vault Works Internally

**Request path:** Client sends token → Vault resolves token to identity + policies → checks policy capabilities on path → routes to secret engine → engine processes → data passes through barrier (AES-256-GCM encryption) → barrier writes to storage backend → response returned.

**Barrier:** Every write is encrypted with the master key before reaching storage. Even if the storage backend (raft, consul, S3) is compromised, the data is unreadable without the master key.

### How Database Dynamic Credentials Work

Vault connects to PostgreSQL with admin credentials. On request, it executes `CREATE USER "v-xxx" WITH PASSWORD 'random' VALID UNTIL 'now+TTL'` and `GRANT ...`. The returned credentials have a lease TTL. Vault's revocation mechanism either actively drops the user (`DROP USER`) when the lease expires or the VALID UNTIL clause auto-expires the user as defense-in-depth if Vault is unavailable.

### How PKI Engine Issues Certificates

Vault generates an RSA/ECDSA key pair, constructs an X.509 certificate with the requested CN/SANs, validity period (capped by role's max_ttl), and unique serial. Signs with the CA key. Returns PEM: certificate, private_key, issuing_ca cert, serial_number. Revocation adds the serial to a CRL (Certificate Revocation List) that Vault publishes and distributes.

### How Auto-Unseal Works

Vault stores the master key encrypted by a cloud KMS key in its storage backend. At startup, Vault reads the encrypted master key, sends it to the KMS for decryption, loads the decrypted master key into RAM (never written to disk), and becomes operational. KMS access can be revoked to instantly re-seal Vault.

### How Sealed Secrets Key Management Works

Controller generates RSA 4096-bit key pair on startup. Stores private key in a K8s Secret (`sealed-secrets-key`). kubeseal fetches the public key, then for each secret value: generates a random AES-256 session key → encrypts the secret value with AES-256-GCM → encrypts the session key with RSA-OAEP (public key). The SealedSecret YAML is safe in Git. The controller decrypts using the private RSA key and creates a regular K8s Secret.

---

## 📋 Command Reference

### Vault

| Command | Description |
|---------|-------------|
| `vault server -dev` | Dev server (unsealed, in-memory) |
| `vault server -config=FILE` | Start with config |
| `vault status` | Seal/HA status |
| `vault operator init -key-shares=N -key-threshold=T` | Initialize |
| `vault operator unseal` | Unseal with key share |
| `vault operator seal` | Seal |
| `vault operator raft join http://HOST:8200` | Join raft cluster |
| `vault operator raft list-peers` | List raft members |
| `vault operator raft snapshot save FILE` | Backup |
| `vault operator raft snapshot restore FILE` | Restore |

### KV v2

| Command | Description |
|---------|-------------|
| `vault kv put PATH key=val` | Write |
| `vault kv get PATH [-version=N]` | Read |
| `vault kv metadata get PATH` | Version metadata |
| `vault kv delete PATH` | Soft delete |
| `vault kv undelete -versions=N PATH` | Restore |
| `vault kv destroy -versions=N PATH` | Permanent destroy |
| `vault kv list PATH` | List |

### Auth / Policies / Lease

| Command | Description |
|---------|-------------|
| `vault auth enable TYPE` | Enable auth method |
| `vault auth tune TYPE/ [...]` | Tune auth method |
| `vault write auth/TYPE/...` | Configure auth |
| `vault token create [-policy=NAME]` | Create token |
| `vault token lookup TOKEN` | Inspect token |
| `vault token capabilities TOKEN PATH` | Check permissions |
| `vault policy write NAME @FILE` | Write policy |
| `vault lease renew LEASE_ID` | Renew lease |
| `vault lease revoke LEASE_ID` | Revoke lease |

### Secret Engines

| Command | Description |
|---------|-------------|
| `vault secrets enable [-version=2] kv` | Enable KV v2 |
| `vault secrets enable database` | Enable DB engine |
| `vault write database/config/NAME ...` | Configure DB |
| `vault write database/roles/NAME ...` | Create DB role |
| `vault read database/creds/ROLE` | Get dynamic creds |
| `vault secrets enable pki` | Enable PKI |
| `vault write pki/root/generate/internal ...` | Generate root CA |
| `vault write pki/issue/NAME ...` | Issue certificate |
| `vault write pki/revoke serial_number=X` | Revoke cert |
| `vault secrets enable transit` | Enable transit |
| `vault write -f transit/keys/NAME` | Create encryption key |
| `vault write transit/encrypt/NAME plaintext=...` | Encrypt |

### SOPS

| Command | Description |
|---------|-------------|
| `sops --encrypt FILE` | Encrypt file |
| `sops --decrypt FILE` | Decrypt to stdout |
| `sops FILE` | Edit in $EDITOR |
| `sops --rotate FILE` | Re-encrypt with current keys |
| `sops --encrypt --age PUBKEY FILE` | Encrypt with age |
| `sops --encrypt --kms ARN FILE` | Encrypt with KMS |
| `age-keygen -o PATH` | Generate age key |

### kubeseal

| Command | Description |
|---------|-------------|
| `kubeseal --format yaml < secret.yaml > sealed.yaml` | Seal secret |
| `kubeseal --fetch-cert > cert.pem` | Fetch public key |
| `kubeseal --cert cert.pem < secret.yaml > sealed.yaml` | Offline seal |
| `kubeseal --scope strict` | Strict scope |
| `kubeseal --scope cluster-wide` | Cluster-wide scope |

### External Secrets Operator

| Command | Description |
|---------|-------------|
| `kubectl get secretstores` | List SecretStores |
| `kubectl get externalsecrets` | List ExternalSecrets |
| `kubectl describe externalsecret NAME` | Status details |

### Cloud

| Command | Description |
|---------|-------------|
| `aws secretsmanager create-secret --name N --secret-string V` | Create AWS secret |
| `aws secretsmanager get-secret-value --secret-id N` | Get AWS secret |
| `gcloud secrets create NAME --replication-policy=...` | Create GCP secret |
| `gcloud secrets versions access latest --secret=NAME` | Get GCP secret |
| `az keyvault secret set --vault-name V --name N --value V` | Set Azure secret |
| `az keyvault secret show --vault-name V --name N --query value` | Get Azure secret |

---

## 🚀 What's Coming in Part 59

**Part 59: Site Reliability Engineering (SRE)** — Secrets management is critical to reliability: leaked passwords cause downtime, expired certs cause outages, misconfigured policies cause access failures. Part 59 covers SRE principles — SLIs/SLOs/SLAs, error budgets, incident response, blameless postmortems, toil automation, capacity planning, and chaos engineering. 15 hands-on practices.

---

## 📝 Self-Test

1. What is the difference between static and dynamic secrets? Why are dynamic secrets more secure for database credentials?

2. Describe Vault's seal/unseal mechanism. How does Shamir's Secret Sharing prevent a single person from unsealing Vault?

3. How does Vault auto-unseal with AWS KMS work? Walk through the boot sequence.

4. What are the three components of Vault's AppRole authentication? How does role_id + secret_id differ from traditional username/password?

5. Write a Vault policy that allows an app to read `database/creds/my-app` and read/write `secret/data/my-app/*` but denies access to `secret/data/my-app/admin`.

6. Explain the full flow when an app requests database credentials from Vault. What happens at PostgreSQL? How does TTL-based expiration work?

7. How does Vault's PKI engine issue a certificate? Walk through from role creation to cert delivery and CRL revocation.

8. What is the difference between Vault's transit engine and KV v2? When would you use transit over KV?

9. What problems does Vault Agent solve? How does the agent-sidecar injector work in K8s?

10. How does External Secrets Operator sync secrets from Vault to K8s Secrets? What CRDs are involved?

11. Explain Sealed Secrets encryption: how does kubeseal encrypt and how does the controller decrypt? Why two layers (AES + RSA)?

12. How does SOPS encrypt a YAML file? What is in the `sops` metadata section? How does `.sops.yaml` work?

13. When should you use Vault vs AWS Secrets Manager / GCP Secret Manager / Azure Key Vault? Trade-offs?

14. List five key secrets management best practices and explain why each matters.

15. Design a secrets architecture for multi-cloud K8s (AWS + GCP) needing dynamic DB creds, TLS certs, and audit logging. What components and how do they interact?

**Score:** 12/15 correct = ready for Part 59.

---

*Linux SysAdmin Course | Part 58 of ∞ | Reverse Engineering Approach*
*Previous → Part 57: Modern Linux Networking*
*Next → Part 59: Site Reliability Engineering (SRE)*

[← Previous](part57.md) | [Next →](part59.md)
