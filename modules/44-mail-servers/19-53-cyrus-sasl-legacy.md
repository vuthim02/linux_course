## 5.3 Cyrus SASL (Legacy)

```bash
# /etc/postfix/main.cf
smtpd_sasl_auth_enable = yes
smtpd_sasl_security_options = noanonymous
smtpd_sasl_local_domain = $myhostname
broken_sasl_auth_clients = yes
```

```bash
# /etc/postfix/sasl/smtpd.conf
pwcheck_method: saslauthd
mech_list: PLAIN LOGIN
```

### When to Use Cyrus SASL

- **Legacy systems** that don't have Dovecot installed
- **Minimal setups** where you only need SMTP auth (no IMAP)
- **Compatibility** with older Postfix versions

### Why Dovecot SASL Is Preferred

| Feature | Cyrus SASL | Dovecot SASL |
|---------|-----------|--------------|
| Password formats | Limited | Extensive (MD5-CRYPT, ARGON2I) |
| Active development | No | Yes |
| Shared with IMAP | No | Yes |
| Configuration | Two files | One socket |

### Key Takeaway
Cyrus SASL works but is legacy. Only use it if you have a specific reason not to use Dovecot. New deployments should always use Dovecot SASL.


[← Previous](18-52-dovecot-sasl-preferred.md) | [↑ Index](index.md) | [Next →](20-54-sasl-for-outbound-relaying.md)
