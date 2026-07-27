## 🔍 Section 6: Security — cron.allow and cron.deny

```bash
# Who can use cron?
# Controlled by two files:
/etc/cron.allow     # If exists, ONLY listed users can use cron
/etc/cron.deny      # If exists, listed users CANNOT use cron

# If neither exists, only root can use cron (on some systems)
# or all users can (on others)

# Best practice: create cron.allow with specific users
echo "root" > /etc/cron.allow
echo "www-data" >> /etc/cron.allow
echo "backup" >> /etc/cron.allow
```

---



---

[← Previous](08-section-5-common-cron-mistakes.md) | [↑ Index](index.md) | [Next →](10-section-7-at-one-time-scheduling.md)
