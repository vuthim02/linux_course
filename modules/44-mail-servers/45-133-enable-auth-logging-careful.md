## 13.3 Enable Auth Logging (Careful!)

```bash
# /etc/postfix/main.cf — DO NOT leave on in production (logs passwords!)
smtpd_sasl_authenticated_header = yes
```

This shows the SASL username in `Received:` headers and logs.



---

[← Previous](44-132-smtp-protocol-debugging.md) | [↑ Index](index.md) | [Next →](46-134-common-problems.md)
