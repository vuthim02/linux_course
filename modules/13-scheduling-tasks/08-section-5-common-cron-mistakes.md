## 🔍 Section 5: Common Cron Mistakes and Debugging

### Mistake 1: Wrong PATH

```bash
# Symptom: "command not found" in cron output
# Fix: Set PATH at top of crontab
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
```

### Mistake 2: Percent Signs Not Escaped

```bash
# % has special meaning in cron (newline)
# BAD: (the % breaks the command)
0 2 * * * date +%Y-%m-%d > /tmp/date.txt

# GOOD: (escape % with backslash)
0 2 * * * date +\%Y-\%m-\%d > /tmp/date.txt

# BETTER: (use script instead)
0 2 * * * /usr/local/bin/dated-backup.sh
```

### Mistake 3: Script Depends on Terminal

```bash
# BAD: (chron doesn't have a terminal)
0 2 * * * mysql -u root -p

# GOOD: (use non-interactive authentication)
0 2 * * * mysql -u root -pPassword < /tmp/query.sql
# Or use my.cnf with credentials
```

### Mistake 4: Not Using Full Paths

```bash
# BAD:
0 2 * * * mycommand

# GOOD:
0 2 * * * /usr/local/bin/mycommand
```

### Mistake 5: Forgetting the Newline

```bash
# Every crontab MUST end with a blank line!
# Without it, the last entry won't work
```

### Debugging Steps

```bash
# 1. Verify cron is running
systemctl status cron

# 2. Check crontab syntax
crontab -l

# 3. Test the command manually (as the same user)
sudo -u username /usr/local/bin/command

# 4. Add logging to the command
* * * * * /usr/local/bin/command >> /tmp/cron-debug.log 2>&1

# 5. Watch the log in real-time
tail -f /var/log/syslog | grep CRON
```





[← Previous](07-section-4-cron-output-and.md) | [↑ Index](index.md) | [Next →](09-section-6-security-cronallow-and.md)
