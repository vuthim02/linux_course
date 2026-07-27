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


---

[← Previous](17-whats-coming-in-part-59.md) | [↑ Index](index.md)
