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
## Answer Key
### Q1: Static vs dynamic secrets?
**Answer:** Static = fixed values (API keys, passwords). Dynamic = generated on-demand with TTL (DB credentials). Dynamic is more secure: unique per-request, auto-expiring, audit-trailable.
### Q2: Vault's seal/unseal mechanism.
**Answer:** Vault stores data encrypted. Sealed = encrypted, inaccessible. Unseal requires providing unseal keys (Shamir's Secret Sharing). Multiple key holders required (e.g., 3 of 5), preventing single-person access.
### Q3: How does Vault auto-unseal with AWS KMS?
**Answer:** Vault is configured with KMS key ARN. On boot, Vault calls KMS API to decrypt the master key. No manual unsealing needed. IAM role provides auth.
### Q4: Three AppRole components.
**Answer:** `role_id` (fixed, like username), `secret_id` (dynamic, like password, wrapped for security), `bind_secret_id` (optional CIDR restriction). Different from username/password: roles are machine identities, not human.
### Q5: Vault policy for database creds and secret access.
**Answer:**
```hcl
path "database/creds/my-app" { capabilities = ["read"] }
path "secret/data/my-app/*" { capabilities = ["read", "create", "update"] }
path "secret/data/my-app/admin" { capabilities = ["deny"] }
```
### Q6: Database credentials flow from Vault.
**Answer:** App authenticates (AppRole) → requests `database/creds/my-app` → Vault connects to PostgreSQL, creates temporary user with TTL → returns credentials → after TTL, Vault revokes the user.
### Q7: Vault PKI engine flow.
**Answer:** Configure root CA → create role (allowed domains, TTL) → app requests cert (CSR) → Vault signs with CA key → returns cert + key → cert expires or is revoked via CRL/OCSP.
### Q8: Transit engine vs KV v2?
**Answer:** Transit = encryption as a service (encrypt/decrypt without storing data). KV v2 = secret storage with versioning. Transit when you need crypto operations; KV when you need to store secrets.
### Q9: What Vault Agent solves and sidecar injector.
**Answer:** Vault Agent handles auth, token renewal, and secret fetching automatically. In K8s: mutating webhook injects Agent as sidecar, renders secrets to shared volume.
### Q10: External Secrets Operator sync flow.
**Answer:** ExternalSecret CRD defines secret mapping → ESO fetches from Vault/AWS → creates K8s Secret → syncs on `refreshInterval`. CRDs: ExternalSecret, SecretStore/ClusterSecretStore.
### Q11: Sealed Secrets encryption.
**Answer:** `kubeseal` encrypts with controller's public key (RSA-OAEP). Controller watches SealedSecrets, decrypts with private key, creates K8s Secret. Two layers: AES (data) + RSA (AES key).
### Q12: How SOPS encrypts YAML files.
**Answer:** SOPS encrypts values (not keys) using KMS/PGP/AzureKV. `sops` metadata section contains: encrypted key, MAC, version. `.sops.yaml` defines which keys/patterns to encrypt.
### Q13: Vault vs cloud-native secrets managers?
**Answer:** Vault: cloud-agnostic, dynamic secrets, full audit, self-hosted. Cloud managers: managed, simpler, vendor-locked. Use Vault for multi-cloud; cloud manager for single-cloud simplicity.
### Q14: Five secrets management best practices.
**Answer:** 1) Never commit secrets to Git. 2) Use dynamic secrets with short TTL. 3) Audit all access. 4) Encrypt at rest and in transit. 5) Rotate regularly.
### Q15: Multi-cloud K8s secrets architecture.
**Answer:** Vault as central secret store + External Secrets Operator in each cluster + Vault Agent for auth + AWS/GCP auth methods + Vault audit logging to SIEM.
*Linux SysAdmin Course | Part 58 of ∞ | Reverse Engineering Approach*
*Previous → Part 57: Modern Linux Networking*
*Next → Part 59: Site Reliability Engineering (SRE)*
[← Previous](17-whats-coming-in-part-59.md) | [↑ Index](index.md)
