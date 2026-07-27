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



---

[← Previous](15-deep-understanding.md) | [↑ Index](index.md) | [Next →](17-whats-coming-in-part-59.md)
