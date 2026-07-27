## 9.3 Postscreen (Before-Queue, Built-in)

```bash
# /etc/postfix/main.cf
postscreen_access_list = permit_mynetworks
postscreen_dnsbl_sites = zen.spamhaus.org, bl.mailspike.net
postscreen_greet_action = drop
postscreen_blacklist_action = drop
```

Postscreen checks clients **before** they speak SMTP — reduces load by 80% on busy servers.

---

# 10. Rate Limiting and Access Control



---

[← Previous](30-92-after-queue-filtering-with-amavis.md) | [↑ Index](index.md) | [Next →](32-101-smtp-restriction-system.md)
