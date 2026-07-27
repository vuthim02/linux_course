## 7.2 Virtual Alias Domains

Virtual aliases let you host multiple domains where **all** mail is forwarded elsewhere (no local mailboxes):

```bash
# /etc/postfix/main.cf
virtual_alias_domains = example.org, example.net, example.info
virtual_alias_maps    = hash:/etc/postfix/virtual
```

```bash
# /etc/postfix/virtual
# Forward mail for entire domains
@example.org          alice@example.com
@example.net          bob@example.com

# Per-user forwarding
info@example.info     help@example.com
sales@example.org     alice@example.com
```

```bash
sudo postmap /etc/postfix/virtual
sudo systemctl reload postfix
```

When both `virtual_alias_maps` and `mydestination` match a domain, virtual aliases take precedence.

---

# 8. Virtual Mailbox Domains



---

[← Previous](24-71-email-aliases.md) | [↑ Index](index.md) | [Next →](26-81-concept.md)
