## 7.1 Email Aliases

System-wide aliases redirect mail for local Unix accounts:

```bash
# /etc/aliases
root:           admin@example.com
postmaster:     root
abuse:          root
webmaster:      alice@example.com
```

After editing:

```bash
sudo newaliases      # rebuilds /etc/aliases.db
```

The lookup table is used by the `local` delivery agent.




[← Previous](23-63-lets-encrypt-automation.md) | [↑ Index](index.md) | [Next →](25-72-virtual-alias-domains.md)
