## 📏 Rules of Thumb

### The Logging Rules

| Rule | Description | Why |
|------|-------------|-----|
| **Check logs first** | Rule #1 of troubleshooting | Find the problem |
| **Use journalctl -f** | Real-time monitoring | See events as they happen |
| **Filter by priority** | `-p err` for errors | Reduce noise |
| **Check rotation** | Prevent disk fill | Maintain space |
| **Export important logs** | Keep copies | Debug later |

### The Log Analysis Rules

| Rule | Description | Why |
|------|-------------|-----|
| **Grep for errors** | `grep -i error` | Find problems |
| **Check timestamps** | Correlate events | Understand sequence |
| **Look for patterns** | Recurring issues | Root cause |
| **Check multiple logs** | Different angles | Complete picture |

### The "Disk Full" Checklist

```bash
# 1. Check which log is large:
du -sh /var/log/*

# 2. Check journal size:
journalctl --disk-usage

# 3. Vacuum journal:
journalctl --vacuum-size=100M

# 4. Force logrotate:
logrotate -f /etc/logrotate.conf

# 5. Remove old compressed logs:
find /var/log -name "*.gz" -mtime +30 -delete
```

### The "Service Failing" Checklist

```bash
# 1. Check service logs:
journalctl -u service -n 100

# 2. Check for errors:
journalctl -u service -p err

# 3. Check system logs:
journalctl -p err --since "1 hour ago"

# 4. Check authentication:
journalctl -u sshd

# 5. Check kernel:
journalctl -k
```

---

**Why these rules matter:** Logging is your first line of defense in troubleshooting. Following these rules helps you find and fix problems faster.

[← Previous](24-level-4-mastery-scenarios.md) | [↑ Index](index.md)
