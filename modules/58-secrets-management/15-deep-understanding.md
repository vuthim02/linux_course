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





[← Previous](14-15-hands-on-practices.md) | [↑ Index](index.md) | [Next →](16-command-reference.md)
