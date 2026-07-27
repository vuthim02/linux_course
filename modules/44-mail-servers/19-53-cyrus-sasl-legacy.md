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



---

[← Previous](18-52-dovecot-sasl-preferred.md) | [↑ Index](index.md) | [Next →](20-54-sasl-for-outbound-relaying.md)
