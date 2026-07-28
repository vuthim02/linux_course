## 9.3 Postscreen (Before-Queue, Built-in)

```bash
# /etc/postfix/main.cf
postscreen_access_list = permit_mynetworks
postscreen_dnsbl_sites = zen.spamhaus.org, bl.mailspike.net
postscreen_greet_action = drop
postscreen_blacklist_action = drop
```

Postscreen checks clients **before** they speak SMTP — reduces load by 80% on busy servers.

### Postscreen Checks

1. **Greeting delay** — penalizes clients that don't wait for the banner
2. **DNSBL lookups** — checks client IP against blacklists
3. **TLS required** — optional enforcement
4. **Non-SMTP commands** — drops clients sending garbage before EHLO

### Actions

| Action | Effect |
|--------|--------|
| `drop` | Disconnect immediately |
| `reject` | Send 4xx/5xx error |
| `permit` | Allow through |
| `ignore` | Don't perform this check |

### Key Takeaway
Postscreen is a "first line of defense" — it eliminates 80% of spam traffic before Postfix even processes it. Essential for any public-facing mail server.


# 10. Rate Limiting and Access Control


[← Previous](30-92-after-queue-filtering-with-amavis.md) | [↑ Index](index.md) | [Next →](32-101-smtp-restriction-system.md)
