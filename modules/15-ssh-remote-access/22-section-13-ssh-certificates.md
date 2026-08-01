## 🔍 Section 13: SSH Certificates — CA-Signed Keys

SSH certificates scale key management for fleets. A Certificate Authority (CA) signs user public keys, and servers trust the CA rather than maintaining `authorized_keys` on every server.

### Creating a Certificate Authority

```bash
# Generate CA key pair (on a secure admin machine)
ssh-keygen -t ed25519 -C "SSH CA" -f ~/ssh-ca/ca_key
# ca_key          — Private CA key (GUARD THIS)
# ca_key.pub      — Public CA key (distribute to all servers)
```

### Signing User Keys

```bash
# Sign a user's public key
ssh-keygen -s ~/ssh-ca/ca_key \
    -I "alice@example.com" \
    -n alice \
    -V +52w \
    ~/.ssh/id_ed25519.pub

# Output: ~/.ssh/id_ed25519-cert.pub
# Options:
# -I identity    — Who this cert is for (logged in audit trail)
# -n principals  — Usernames allowed (comma-separated)
# -V validity    — Expiry (+52w = 52 weeks)
# -O option      — Restrictions (see below)

# Certificate restrictions
ssh-keygen -s ~/ssh-ca/ca_key \
    -I "bob@example.com" \
    -n bob \
    -V +1d \
    -O force-command=/usr/local/bin/backup.sh \
    -O source-address=10.0.0.0/8 \
    -O no-agent-forwarding \
    ~/.ssh/id_ed25519.pub
```

### Configuring Servers to Trust the CA

```bash
# On every server: tell sshd to trust the CA
# /etc/ssh/sshd_config:
TrustedUserCAKeys /etc/ssh/ca.pub

# Copy the CA public key
sudo cp ~/ssh-ca/ca_key.pub /etc/ssh/
sudo chmod 644 /etc/ssh/ca_key.pub

# Now ANY user with a CA-signed cert can log in
# No need to add their key to authorized_keys!
```

### Using Certificate Authentication

```bash
# Client side — SSH automatically uses the cert if present
# Place id_ed25519-cert.pub next to your private key
# Copy ~/.ssh/id_ed25519-cert.pub to both locations:
cp ~/.ssh/id_ed25519-cert.pub ~/.ssh/

# Connect normally — cert is used automatically
ssh alice@server

# Verify which cert was used
ssh -v alice@server 2>&1 | grep "cert"
```

### Host Certificates

Servers can also have certificates signed by a CA:

```bash
# Sign the host key
ssh-keygen -s ~/ssh-ca/ca_key \
    -I "web01.example.com" \
    -h \
    -V +104w \
    /etc/ssh/ssh_host_ed25519_key.pub

# On the server:
HostCertificate /etc/ssh/ssh_host_ed25519_key-cert.pub

# On clients: trust the CA for host verification
# ~/.ssh/known_hosts:
@cert-authority *.example.com ssh-ed25519 AAAA... (CA public key)
# Now clients trust all servers in *.example.com without host key prompts
```

### Viewing Certificate Contents

```bash
ssh-keygen -L -f ~/.ssh/id_ed25519-cert.pub
# Shows: Type, principal, validity, options, signing CA
```

### Certificate vs Key Comparison

| Feature | Regular Keys | Certificates |
|---------|-------------|--------------|
| Per-server setup | Add key to authorized_keys on each server | Distribute CA pub key once |
| Key rotation | Update authorized_keys everywhere | Re-sign with new CA, servers still trust CA |
| Expiry | Manual revocation only | Built-in `-V` expiry |
| Restrictions | `command=` in authorized_keys | `-O` options at signing time |
| Audit trail | None | `-I` identity embedded in cert |



[← Previous](21-section-12-sftp-chroot-and-restricted-shells.md) | [↑ Index](index.md) | [Next →](24-level-4-mastery-scenarios.md)
