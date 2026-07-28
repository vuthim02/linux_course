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

### Common Configurations

```bash
# Hosting provider: each customer has their own domain
myhostname = mail.provider.com
mydomain   = provider.com
myorigin   = $mydomain

# Internal corporate mail server
myhostname = mx.internal.corp
mydomain   = internal.corp
myorigin   = $mydomain
```

### Verifying Identity

```bash
# Check what Postfix thinks its identity is
postconf myhostname mydomain myorigin

# Send a test message and check the From: header
echo "test" | sendmail -f root@localhost you@example.com
```


[← Previous](12-34-maincf-structure.md) | [↑ Index](index.md) | [Next →](14-42-listening-and-delivery.md)
