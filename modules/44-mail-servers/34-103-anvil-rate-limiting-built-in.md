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



---

[← Previous](33-102-access-table.md) | [↑ Index](index.md) | [Next →](35-104-policy-daemon-postfwd-postgrey.md)
