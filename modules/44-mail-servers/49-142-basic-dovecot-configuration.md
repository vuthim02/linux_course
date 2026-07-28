## 14.2 Basic Dovecot Configuration

```bash
# /etc/dovecot/dovecot.conf
!include_try /usr/share/dovecot/protocols.d/*.protocol
listen = *
```

```bash
# /etc/dovecot/conf.d/10-auth.conf
disable_plaintext_auth = yes
auth_username_format = %Ln
auth_mechanisms = plain login
```

```bash
# /etc/dovecot/conf.d/10-mail.conf
mail_location = maildir:/var/mail/vhosts/%d/%n
mail_privileged_group = mail
```

```bash
# /etc/dovecot/conf.d/10-master.conf
service imap-login {
  inet_listener imap {
    port = 0            # disable plain IMAP, force TLS
  }
  inet_listener imaps {
    port = 993
    ssl = yes
  }
}

service lmtp {
  unix_listener /var/spool/postfix/private/dovecot-lmtp {
    mode = 0600
    user = postfix
    group = postfix
  }
}

service auth {
  unix_listener /var/spool/postfix/private/auth {
    mode = 0660
    user = postfix
    group = postfix
  }
}
```

```bash
# /etc/dovecot/conf.d/10-ssl.conf
ssl = required
ssl_cert = </etc/letsencrypt/live/mail.example.com/fullchain.pem
ssl_key  = </etc/letsencrypt/live/mail.example.com/privkey.pem
```




[← Previous](48-141-installing-dovecot.md) | [↑ Index](index.md) | [Next →](50-143-postfix-dovecot-lmtp-delivery.md)
