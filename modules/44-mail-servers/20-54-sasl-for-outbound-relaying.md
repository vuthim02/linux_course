## 5.4 SASL for Outbound Relaying

If you relay through a provider (e.g. Amazon SES, Mailgun, your ISP):

```bash
# /etc/postfix/main.cf
relayhost = [smtp.example.com]:587
smtp_sasl_auth_enable = yes
smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd
smtp_sasl_security_options = noanonymous
```

```bash
# /etc/postfix/sasl_passwd
# Format: destination  username:password
[smtp.example.com]:587    myuser@example.com:MySecretPass
```

```bash
# Build the hash database
sudo postmap /etc/postfix/sasl_passwd
sudo chmod 600 /etc/postfix/sasl_passwd /etc/postfix/sasl_passwd.db
```


# 6. TLS/SSL




[← Previous](19-53-cyrus-sasl-legacy.md) | [↑ Index](index.md) | [Next →](21-61-server-inbound-tls.md)
