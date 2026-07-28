## 🔍 Section 2: Where Crontabs Live

### System Crontab vs User Crontabs

There are two types:

1. **System crontab** (`/etc/crontab`) — has an extra field for user
2. **User crontabs** (`/var/spool/cron/crontabs/username`) — run as that user

### System Crontab Example

```bash
cat /etc/crontab
```

```
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

# Example of job definition:
# .---------------- minute (0-59)
# |  .------------- hour (0-23)
# |  |  .---------- day of month (1-31)
# |  |  |  .------- month (1-12)
# |  |  |  |  .---- day of week (0-6)
# |  |  |  |  |
# *  *  *  *  * user command
```

Notice: System crontab has a **user** column (6th field). User crontabs do NOT have this.

### The cron.d Directory

```bash
# Packages install their cron jobs here
ls /etc/cron.d/

# Example: /etc/cron.d/php
cat /etc/cron.d/php
```

```
# /etc/cron.d/php
* * * * * root /usr/lib/php/sessionclean
```

### The cron.hourly/daily/weekly/monthly Directories

```bash
# Scripts placed here run automatically
ls /etc/cron.hourly/
ls /etc/cron.daily/
ls /etc/cron.weekly/
ls /etc/cron.monthly/

# Example: add a backup script
sudo cp /usr/local/bin/daily-backup.sh /etc/cron.daily/
sudo chmod +x /etc/cron.daily/daily-backup.sh
```

These are managed by `run-parts` — a utility that runs all scripts in a directory.





[← Previous](03-section-1-cron-the-classic.md) | [↑ Index](index.md) | [Next →](05-level-2-intermediary-scheduling-workflows.md)
