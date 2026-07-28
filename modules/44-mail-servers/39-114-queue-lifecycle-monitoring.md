## 11.4 Queue Lifecycle Monitoring

```bash
# Count by queue
for q in incoming active deferred hold maildrop; do
  count=$(sudo find /var/spool/postfix/$q -type f 2>/dev/null | wc -l)
  echo "$q: $count"
done
```

### Monitoring Script

```bash
#!/bin/bash
# Queue watchdog — alert if deferred queue grows
DEFERRED=$(sudo find /var/spool/postfix/deferred -type f 2>/dev/null | wc -l)
if [ "$DEFERRED" -gt 1000 ]; then
    echo "WARNING: Deferred queue has $DEFERRED messages" | mail -s "Postfix Queue Alert" admin@example.com
fi
```

### Key Metrics to Watch

| Queue | Healthy | Warning | Critical |
|-------|---------|---------|----------|
| incoming | < 100 | 100–1000 | > 1000 |
| active | < 50 | 50–200 | > 200 |
| deferred | < 100 | 100–5000 | > 5000 |
| hold | 0 | 1–10 | > 10 |


# 12. Logging


[← Previous](38-113-postsuper-queue-surgery.md) | [↑ Index](index.md) | [Next →](40-121-log-locations.md)
