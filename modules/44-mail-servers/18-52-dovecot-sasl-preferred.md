## 5.2 Dovecot SASL (Preferred)

Modern setups delegate SASL to Dovecot:

```bash
# /etc/postfix/main.cf
smtpd_sasl_type = dovecot
smtpd_sasl_path = private/auth          # Dovecot's auth socket
smtpd_sasl_auth_enable = yes
broken_sasl_auth_clients = yes
smtpd_relay_restrictions = permit_mynetworks, permit_sasl_authenticated, defer_unauth_destination
```

On the Dovecot side (`/etc/dovecot/conf.d/10-master.conf`):

```bash
# Dovecot auth socket for Postfix
unix_listener /var/spool/postfix/private/auth {
  mode = 0660
  user = postfix
  group = postfix
}
```




[← Previous](17-51-why-sasl.md) | [↑ Index](index.md) | [Next →](19-53-cyrus-sasl-legacy.md)
