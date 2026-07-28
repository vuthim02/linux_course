## 3.2 Reconfiguring Postfix

```bash
sudo dpkg-reconfigure postfix
```

This rewrites `/etc/postfix/main.cf` with interactive prompts. Useful for fast prototyping.

### What dpkg-reconfigure Asks

1. **General type**: Internet Site, Satellite, Local Only, No Configuration
2. **System mail name**: your FQDN (e.g., `mail.example.com`)
3. **Root and postmaster mail recipient**: forwarding target
4. **Other destinations**: domains this server accepts mail for
5. **Relay domain**: smarthost for outbound mail
6. **Outbound relay limit**: not usually needed
7. **Local networks**: trusted networks (default: `127.0.0.0/8`)
8. **Mailbox size limit**: 0 = unlimited
9. **Local address extension character**: `+`
10. **Internet protocols**: all, ipv4, ipv6

### Key Takeaway
`dpkg-reconfigure` is great for initial setup but **never use it in production** — it overwrites your customized `main.cf`. Always edit `main.cf` directly with `postconf -e`.


[← Previous](09-31-installing-postfix.md) | [↑ Index](index.md) | [Next →](11-33-examining-configuration.md)
