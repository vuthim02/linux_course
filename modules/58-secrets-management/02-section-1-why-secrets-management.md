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





[← Previous](01-what-you-will-achieve.md) | [↑ Index](index.md) | [Next →](03-section-2-hashicorp-vault-architecture.md)
