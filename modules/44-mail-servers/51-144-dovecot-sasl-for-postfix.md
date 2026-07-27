## 14.4 Dovecot SASL for Postfix

```bash
# /etc/dovecot/conf.d/10-master.conf (already shown above for auth socket)

# /etc/postfix/main.cf
smtpd_sasl_type = dovecot
smtpd_sasl_path = private/auth
smtpd_sasl_auth_enable = yes
```

---

# 15. Hands-On Practices



---

[← Previous](50-143-postfix-dovecot-lmtp-delivery.md) | [↑ Index](index.md) | [Next →](52-level-1-basic-practices.md)
