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



---

[← Previous](13-section-12-best-practices.md) | [↑ Index](index.md) | [Next →](15-deep-understanding.md)
