## 14.4 Dovecot SASL for Postfix

```bash
# /etc/dovecot/conf.d/10-master.conf (already shown above for auth socket)

# /etc/postfix/main.cf
smtpd_sasl_type = dovecot
smtpd_sasl_path = private/auth
smtpd_sasl_auth_enable = yes
```

### Why Dovecot SASL Over Cyrus SASL?

- **Unified authentication** — same password database for IMAP and SMTP
- **Password formats** — Dovecot supports more formats (MD5-CRYPT, BLF-CRYPT, ARGON2I)
- **Active development** — Cyrus SASL is effectively unmaintained
- **Simpler config** — one socket, one config file

### Verifying SASL Works

```bash
# Test authentication
perl -MMIME::Base64 -e 'print encode_base64("\0user\@example.com\0password")' | \
  openssl s_client -connect mail.example.com:587 -starttls smtp 2>/dev/null | \
  openssl s_client -connect mail.example.com:587 -starttls smtp

# Or use swaks
swaks --to user@example.com --server mail.example.com:587 --auth LOGIN --auth-user user@example.com
```


# 15. Hands-On Practices


[← Previous](50-143-postfix-dovecot-lmtp-delivery.md) | [↑ Index](index.md) | [Next →](52-level-1-basic-practices.md)
