## 🔍 Section 4: Cron Output and Logging

### Where Cron Output Goes

```bash
# By default, cron MAILS output to the user
# If mail is not configured, it may be lost

# To redirect output (SUPPRESS mailing):
0 2 * * * /usr/local/bin/backup.sh > /dev/null 2>&1

# To LOG output to a file:
0 2 * * * /usr/local/bin/backup.sh >> /var/log/backup.log 2>&1

# To log with timestamp:
0 2 * * * echo "[$(date)] Running backup" >> /var/log/backup.log; \
            /usr/local/bin/backup.sh >> /var/log/backup.log 2>&1
```

### Cron Logging

```bash
# cron logs to syslog, which goes to journald
journalctl -u cron -n 20

# Or check syslog directly
grep CRON /var/log/syslog | tail -20

# Sample log entry:
# Jan 15 02:00:01 server CRON[12345]: (root) CMD (/usr/local/bin/backup.sh)
```

### Checking If cron Ran

```bash
# 1. Check syslog
sudo grep "$(date +%b%e)" /var/log/syslog | grep CRON

# 2. Check journal
journalctl -u cron --since "1 hour ago"

# 3. Check your mail
mail
```





[← Previous](06-section-3-crontab-environment.md) | [↑ Index](index.md) | [Next →](08-section-5-common-cron-mistakes.md)
