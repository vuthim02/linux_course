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

### Access Table Patterns

| Pattern | Matches |
|---------|---------|
| `user@domain.com` | Exact email address |
| `domain.com` | Any sender from that domain |
| `192.168.1.` | IP prefix (note the trailing dot) |
| `10.0.0.0/24` | CIDR range |

### Actions

| Action | Effect |
|--------|--------|
| `OK` | Allow (bypass restrictions) |
| `REJECT` | Reject with 554 error |
| `DISCARD` | Accept but silently discard |
| `WARN` | Allow but log a warning |

### Key Takeaway
The access table is checked against the **sender** address by default. For recipient-based checks, use `smtpd_recipient_restrictions` with `check_recipient_access`.


[← Previous](32-101-smtp-restriction-system.md) | [↑ Index](index.md) | [Next →](34-103-anvil-rate-limiting-built-in.md)
