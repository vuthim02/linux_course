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



---

[← Previous](20-54-sasl-for-outbound-relaying.md) | [↑ Index](index.md) | [Next →](22-62-client-outbound-tls.md)
