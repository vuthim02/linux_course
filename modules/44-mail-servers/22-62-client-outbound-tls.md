## 6.2 Client (Outbound) TLS

```bash
# /etc/postfix/main.cf
smtp_tls_security_level = may           # opportunistic TLS when connecting to others
# smtp_tls_security_level = encrypt     # force TLS for all outbound
smtp_tls_protocols = !SSLv2, !SSLv3, !TLSv1, !TLSv1.1
```



---

[← Previous](21-61-server-inbound-tls.md) | [↑ Index](index.md) | [Next →](23-63-lets-encrypt-automation.md)
