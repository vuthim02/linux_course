## 10.2 Access Table

```bash
# /etc/postfix/access
# Format: pattern  action
spammer@example.org    REJECT
example.com            OK
192.168.1.             OK
```

```bash
sudo postmap /etc/postfix/access
sudo systemctl reload postfix
```



---

[← Previous](32-101-smtp-restriction-system.md) | [↑ Index](index.md) | [Next →](34-103-anvil-rate-limiting-built-in.md)
