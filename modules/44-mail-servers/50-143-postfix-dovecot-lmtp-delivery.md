## 14.3 Postfix → Dovecot LMTP Delivery

Instead of the `virtual` delivery agent, tell Postfix to deliver via LMTP to Dovecot:

```bash
# /etc/postfix/main.cf
virtual_transport = lmtp:unix:private/dovecot-lmtp
```

This means Dovecot handles **both** authentication (SASL) and delivery (MDA) — the cleanest architecture.



---

[← Previous](49-142-basic-dovecot-configuration.md) | [↑ Index](index.md) | [Next →](51-144-dovecot-sasl-for-postfix.md)
