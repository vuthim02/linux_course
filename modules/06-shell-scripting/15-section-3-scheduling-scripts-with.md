## 🔍 Section 3: Scheduling Scripts With cron

```bash
# Edit cron jobs
crontab -e

# List cron jobs
crontab -l

# Remove all cron jobs
crontab -r
```

### Crontab Syntax

```
# ┌────────── minute (0-59)
# │ ┌────────── hour (0-23)
# │ │ ┌────────── day of month (1-31)
# │ │ │ ┌────────── month (1-12)
# │ │ │ │ ┌────────── day of week (0-7, 0=Sun, 7=Sun)
# │ │ │ │ │
# * * * * * command_to_run
```

### Examples

```bash
# Every day at 2:30 AM
30 2 * * * /home/alice/scripts/backup.sh

# Every hour
0 * * * * /home/alice/scripts/check_disk.sh

# Every Monday at 3 AM
0 3 * * 1 /home/alice/scripts/weekly_report.sh

# Every 15 minutes
*/15 * * * * /home/alice/scripts/monitor.sh

# Twice a day (6 AM and 6 PM)
0 6,18 * * * /home/alice/scripts/sync.sh

# First day of every month at midnight
0 0 1 * * /home/alice/scripts/monthly_cleanup.sh
```

### Cron Best Practices

```bash
# Always use FULL PATHS in cron scripts
# Cron has a minimal PATH

# Bad:
0 2 * * * backup.sh  # Will fail — command not found

# Good:
0 2 * * * /home/alice/scripts/backup.sh

# Better: set PATH in the script itself
# In script:
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# Redirect output to log
0 2 * * * /home/alice/scripts/backup.sh >> /var/log/backup.log 2>&1

# Use absolute paths for EVERYTHING in cron
```





[← Previous](14-section-2-professional-script-template.md) | [↑ Index](index.md) | [Next →](16-deep-understanding-how-scripts-execute.md)
