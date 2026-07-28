## 5.1 Why SASL

Without SASL, your server is an open relay or only accepts mail from `mynetworks`. SASL (Simple Authentication and Security Layer) lets remote users **authenticate** before relaying.

### The Problem Without SASL

- Any client on the internet can send mail through your server
- Your server becomes a spam relay (blacklisted within hours)
- No way to distinguish legitimate users from bots

### How SASL Fixes This

```
Client ──EHLO──▶ Postfix
       ◀──250-STARTTLS──
Client ──STARTTLS──▶ (encrypted channel established)
Client ──AUTH PLAIN <credentials>──▶ Postfix verifies via Dovecot
       ◀──235 Authentication successful──
Client ──MAIL FROM:──▶ (now permitted to relay)
```

### SASL Mechanisms

| Mechanism | Security | Notes |
|-----------|----------|-------|
| `PLAIN` | Weak (base64) | Only over TLS |
| `LOGIN` | Weak (base64) | Legacy clients only |
| `CRAM-MD5` | Medium | Challenge-response, no TLS needed |
| `NTLM` | Medium | Microsoft Outlook compatibility |

### Key Takeaway
Always combine SASL with TLS (`smtpd_tls_security_level = may` or `encrypt`). SASL over plaintext sends credentials in the clear.


[← Previous](16-44-minimal-working-configuration.md) | [↑ Index](index.md) | [Next →](18-52-dovecot-sasl-preferred.md)
