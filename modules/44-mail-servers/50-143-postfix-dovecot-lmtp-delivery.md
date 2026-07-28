## 14.3 Postfix → Dovecot LMTP Delivery

Instead of the `virtual` delivery agent, tell Postfix to deliver via LMTP to Dovecot:

```bash
# /etc/postfix/main.cf
virtual_transport = lmtp:unix:private/dovecot-lmtp
```

This means Dovecot handles **both** authentication (SASL) and delivery (MDA) — the cleanest architecture.

### Why LMTP Over Local Delivery?

| Feature | `local` transport | LMTP to Dovecot |
|---------|------------------|-----------------|
| Sieve filtering | No | Yes |
| Per-user delivery agent | No | Yes |
| Mailbox format choice | System default | Per-user (Maildir, mboxes) |
| Authentication | Separate (Postfix) | Single (Dovecot) |
| Quota enforcement | No | Yes |

### Dovecot LMTP Configuration

```conf
# /etc/dovecot/conf.d/10-master.conf
service lmtp {
  unix_listener /var/spool/postfix/private/dovecot-lmtp {
    mode = 0600
    user = postfix
    group = postfix
  }
}
```

### Key Takeaway
LMTP is the recommended delivery method. It gives you Dovecot's full feature set (Sieve, quotas, per-user config) without the complexity of `virtual` transport maps.


[← Previous](49-142-basic-dovecot-configuration.md) | [↑ Index](index.md) | [Next →](51-144-dovecot-sasl-for-postfix.md)
