## 6.2 Client (Outbound) TLS

```bash
# /etc/postfix/main.cf
smtp_tls_security_level = may           # opportunistic TLS when connecting to others
# smtp_tls_security_level = encrypt     # force TLS for all outbound
smtp_tls_protocols = !SSLv2, !SSLv3, !TLSv1, !TLSv1.1
```

### Outbound TLS Levels

| Level | Behavior |
|-------|----------|
| `none` | No TLS ever (not recommended) |
| `may` | Try STARTTLS, fall back to plaintext |
| `encrypt` | Require TLS; fail if remote doesn't support it |
| `dane` | Use DANE/TLSA records for verified TLS |

### Checking If Remote Servers Support TLS

```bash
# Check STARTTLS support
openssl s_client -connect mx.example.com:25 -starttls smtp 2>&1 | grep "Verify return code"

# Or with telnet
telnet mx.example.com 25
EHLO test
# Look for 250-STARTTLS in the response
```

### Key Takeaway
Use `smtp_tls_security_level = may` as the baseline. Switch to `encrypt` only when you know all your recipients support TLS (e.g., internal relay to another server you control).


[← Previous](21-61-server-inbound-tls.md) | [↑ Index](index.md) | [Next →](23-63-lets-encrypt-automation.md)
