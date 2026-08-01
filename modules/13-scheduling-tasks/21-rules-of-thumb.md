## 📏 Rules of Thumb

### The Cron Rules

| Rule | Description | Why |
|------|-------------|-----|
| **Always redirect output** | Save logs for debugging | Know what happened |
| **Use full paths** | cron has minimal PATH | Prevent "command not found" |
| **Test with echo first** | Verify command works | Prevent accidents |
| **Use lockfiles** | Prevent overlapping runs | Resource management |
| **Document in comments** | Explain what job does | Maintainability |

### The systemd Timer Rules

| Rule | Description | Why |
|------|-------------|-----|
| **Use Persistent=true** | Run missed jobs | Catch up on downtime |
| **Use OnCalendar** | More flexible than cron | Better precision |
| **Check with list-timers** | See what's scheduled | Visibility |
| **Use override files** | Don't edit package units | Maintainability |

### The "Job Didn't Run" Checklist

```bash
# 1. Check cron service:
systemctl status cron

# 2. Check cron logs:
grep CRON /var/log/syslog

# 3. Check crontab:
crontab -l

# 4. Check permissions:
ls -la /path/to/script.sh

# 5. Check PATH:
echo $PATH

# 6. Check disk space:
df -h
```

### The "Job Overlapping" Prevention

```bash
# Use lockfile:
#!/bin/bash
LOCKFILE="/tmp/script.lock"

if [ -e "$LOCKFILE" ] && kill -0 "$(cat "$LOCKFILE")"; then
    echo "Already running"
    exit 1
fi

echo $$ > "$LOCKFILE"
trap "rm -f $LOCKFILE" EXIT

# Your script here
```

---

**Why these rules matter:** Following these rules ensures your scheduled tasks run reliably and don't cause problems.

[← Previous](22-level-4-mastery-scenarios.md) | [↑ Index](index.md)
