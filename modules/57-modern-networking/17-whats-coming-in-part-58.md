## 🚀 What's Coming in Part 58

**Part 58: Secrets Management — Vault, SOPS, Sealed Secrets**

Modern networking needs secrets for everything: TLS certificates, database passwords, API keys, and WireGuard private keys. In Part 58 you will learn how to manage secrets in production using HashiCorp Vault (for dynamic secrets and encryption-as-a-service), SOPS (for Git-encrypted configuration files), and Sealed Secrets (for Kubernetes-native secret encryption at rest). You will also understand how Cilium's integration with Vault can automate TLS certificate distribution and WireGuard key rotation across your cluster.

### Topics Covered

- Secrets management philosophy — encryption at rest vs in transit vs in use
- HashiCorp Vault architecture — seal/unseal, secret engines, auth methods
- Vault dynamic secrets for databases and cloud IAM
- SOPS — encrypted files in Git with AWS/GCP/Azure KMS or age
- Sealed Secrets — encrypting Kubernetes Secrets for safe storage in Git
- Cilium integration with Vault for automated certificate management
- WireGuard key rotation with Vault PKI
- Best practices: least privilege, rotation schedules, audit logging
- 15 hands-on practices including a real-world multi-platform integration

### Why This Matters After Networking

Part 57 showed you how WireGuard tunnels and Cilium network policies secure your network. But network security is useless if secrets are exposed. A leaked Vault token or a hardcoded database password can bypass every firewall and network policy you've built. Secrets management is the final layer of defense-in-depth.





[← Previous](16-command-reference.md) | [↑ Index](index.md) | [Next →](18-self-test-can-you-answer-these.md)
