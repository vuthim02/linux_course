## 11.4 Queue Lifecycle Monitoring

```bash
# Count by queue
for q in incoming active deferred hold maildrop; do
  count=$(sudo find /var/spool/postfix/$q -type f 2>/dev/null | wc -l)
  echo "$q: $count"
done
```

---

# 12. Logging



---

[← Previous](38-113-postsuper-queue-surgery.md) | [↑ Index](index.md) | [Next →](40-121-log-locations.md)
