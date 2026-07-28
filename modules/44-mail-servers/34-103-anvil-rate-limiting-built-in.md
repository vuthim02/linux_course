## 10.3 Anvil Rate Limiting (Built-in)

```bash
# /etc/postfix/main.cf
# Max concurrent connections from one IP
smtpd_client_connection_count_limit = 10

# Max connections per 60s from one IP
smtpd_client_connection_rate_limit = 30

# Max error rate before dropping
smtpd_client_error_rate_limit = 5

# Max recipients per SMTP session
smtpd_recipient_limit = 100
```

### The Anvil Rate Monitor

Postfix tracks connection statistics using an internal "anvil" process. It monitors:
- Connections per client IP
- Recipients per session
- Auth failures per client

### Setting Limits

| Parameter | Default | Recommended |
|-----------|---------|-------------|
| `smtpd_client_connection_count_limit` | 50 | 10–20 |
| `smtpd_client_connection_rate_limit` | 0 (unlimited) | 30–60 |
| `smtpd_recipient_limit` | 1000 | 50–200 |

### Key Takeaway
Rate limiting is a blunt instrument — it prevents abuse but can also block legitimate bulk senders. Start conservative and tighten based on your traffic patterns.


[← Previous](33-102-access-table.md) | [↑ Index](index.md) | [Next →](35-104-policy-daemon-postfwd-postgrey.md)
