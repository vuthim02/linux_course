## 4.1 Identity Parameters

```bash
# /etc/postfix/main.cf

myhostname = mail.example.com
mydomain   = example.com
myorigin   = $myhostname        # or $mydomain — what domain appears in From:
```

- `myhostname` — the FQDN of this mail server
- `mydomain` — the DNS domain
- `myorigin` — domain appended to locally-posted mail (e.g. `myorigin = $mydomain` makes `whoami` → `whoami@example.com`)



---

[← Previous](12-34-maincf-structure.md) | [↑ Index](index.md) | [Next →](14-42-listening-and-delivery.md)
