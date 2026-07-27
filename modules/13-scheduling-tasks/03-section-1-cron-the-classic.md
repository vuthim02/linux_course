## 🔍 Section 1: cron — The Classic Scheduler

cron is a daemon (`crond`) that reads configuration files called "crontabs" and executes commands at specified times.

### How cron Works

```
cron daemon (crond)        ← starts at boot, runs forever
    ↓
Reads crontab files        ← /etc/crontab, /var/spool/cron/crontabs/*
    ↓
Checks every minute        ← looks at current time
    ↓
Matches against schedule   ← compares with each crontab line
    ↓
Executes command           ← runs as the crontab owner
    ↓
Sleeps 60 seconds          ← checks again
```

### The crontab Command

```bash
# Edit your crontab (opens in default editor)
crontab -e

# List your crontab entries
crontab -l

# List another user's crontab (root only)
sudo crontab -l -u www-data

# Remove your crontab
crontab -r

# Edit another user's crontab
sudo crontab -e -u www-data
```

### Crontab Syntax (The Five Stars)

```
* * * * * command_to_execute
│ │ │ │ │
│ │ │ │ └── Day of week (0-7)  [0=Sunday, 7=Sunday]
│ │ │ └──── Month (1-12)
│ │ └────── Day of month (1-31)
│ └──────── Hour (0-23)
└────────── Minute (0-59)
```

### Common Schedule Examples

```bash
# Every minute
* * * * * command

# Every hour at minute 0
0 * * * * command

# Every day at midnight
0 0 * * * command

# Every day at 2:30 AM
30 2 * * * command

# Every Monday at 8 AM
0 8 * * 1 command

# First day of every month at midnight
0 0 1 * * command

# Every 15 minutes
*/15 * * * * command

# Every 6 hours (at minute 0)
0 */6 * * * command

# Every weekday (Mon-Fri) at 9:30 AM
30 9 * * 1-5 command

# Multiple times: 8 AM, 12 PM, and 4 PM every day
0 8,12,16 * * * command

# First and fifteenth of each month
0 0 1,15 * * command
```

### Special @-Times

```bash
# These are aliases for common schedules:
@reboot        On system boot (once)
@yearly        0 0 1 1 *     (once a year)
@annually      0 0 1 1 *     (once a year)
@monthly       0 0 1 * *     (once a month)
@weekly        0 0 * * 0     (once a week)
@daily         0 0 * * *     (once a day)
@hourly        0 * * * *     (once an hour)

# Examples
@daily    /usr/local/bin/rotate-logs.sh
@reboot   /usr/local/bin/check-disks.sh
```

---



---

[← Previous](02-level-1-basic-cron-fundamentals.md) | [↑ Index](index.md) | [Next →](04-section-2-where-crontabs-live.md)
