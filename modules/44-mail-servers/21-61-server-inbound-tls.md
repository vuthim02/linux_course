## 6.1 Server (Inbound) TLS

```bash
# /etc/postfix/main.cf
smtpd_tls_cert_file = /etc/letsencrypt/live/mail.example.com/fullchain.pem
smtpd_tls_key_file  = /etc/letsencrypt/live/mail.example.com/privkey.pem
smtpd_tls_security_level = may   # opportunistic: STARTTLS offered
# smtpd_tls_security_level = encrypt   # forced TLS (clients MUST use STARTTLS)

smtpd_tls_protocols = !SSLv2, !SSLv3, !TLSv1, !TLSv1.1
smtpd_tls_mandatory_protocols = !SSLv2, !SSLv3, !TLSv1, !TLSv1.1
smtpd_tls_eecdh_grade = strong
```

### Security Levels Explained

| Level | Behavior |
|-------|----------|
| `may` | Offer STARTTLS, accept plaintext fallback |
| `encrypt` | Require STARTTLS; reject clients that don't negotiate |
| `none` | No TLS (not recommended for any production server) |

### Testing Your TLS Configuration

```bash
# Test STARTTLS support
openssl s_client -connect mail.example.com:25 -starttls smtp

# Check certificate details
echo | openssl s_client -connect mail.example.com:25 -starttls smtp 2>/dev/null | openssl x509 -noout -dates
```

### Key Takeaway
Use `smtpd_tls_security_level = may` for public-facing servers (clients that don't support TLS can still connect). Use `encrypt` for internal servers where all clients support TLS.


[← Previous](20-54-sasl-for-outbound-relaying.md) | [↑ Index](index.md) | [Next →](22-62-client-outbound-tls.md)
