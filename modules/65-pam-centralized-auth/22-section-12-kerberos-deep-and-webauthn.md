## Section 12: Kerberos Deep Dive and WebAuthn/FIDO2

### Kerberos Deep Dive

**Components**: KDC (Key Distribution Center) = AS (Auth Service) + TGS (Ticket Granting Service).

```
1. AS-REQ        → Client sends TGT request (encrypted with password hash)
2. AS-REP        → KDC returns TGT + session key (encrypted with password hash)
3. TGS-REQ       → Client requests service ticket using TGT
4. TGS-REP       → KDC returns service ticket (encrypted with service's key)
5. AP-REQ        → Client presents service ticket to target service
```

```bash
# /etc/krb5.conf
[libdefaults]
  default_realm = EXAMPLE.COM
  dns_lookup_realm = false
  dns_lookup_kdc = false

[realms]
  EXAMPLE.COM = {
    kdc = kdc.example.com
    admin_server = kdc.example.com
  }

# Kerberized services
# SSH: GSSAPIAuthentication yes in sshd_config
# NFS: sec=krb5p mount option
# HTTP: Negotiate auth with mod_auth_kerb
```

### WebAuthn / FIDO2 — Passwordless Authentication

**WebAuthn** (W3C) + **CTAP2** (FIDO) = browser-based hardware token auth.

```bash
# PAM module for FIDO2
sudo apt install libpam-u2f
pamu2fcfg > ~/.config/Yubico/u2f_keys   # Register token

# /etc/pam.d/sshd
# auth sufficient pam_u2f.so
```

| Aspect | Password | TOTP | WebAuthn |
|--------|----------|------|----------|
| Phishing resistant | No | No | Yes |
| Shared secret | Yes (server) | Yes (seed) | No (public key) |
| User experience | Typing | Typing | Touch/BI |
| Deployment cost | Low | Low | Medium |
