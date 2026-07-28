## Schedule

A backup schedule must balance data protection against system impact. The frequency of backups depends on how much data you can afford to lose (RPO).

### Recommended Schedule

| Backup Type | Frequency | Time Window | Notes |
|-------------|-----------|-------------|-------|
| **Databases** | Daily | 03:00 | Off-peak hours; minimal impact on production |
| **Incremental files** | Daily | 02:00 | Fast, low I/O — only changed blocks |
| **Full file backup** | Weekly (Sunday) | 01:00 | Complete baseline for restore |
| **System config** | After any change | Immediate | Capture `/etc/`, cron, systemd units |
| **Offsite sync** | Daily after incremental | 04:00 | Ensure offsite copy within 24 hours |

### Automating with Cron

```bash
# /etc/crontab example
0 2 * * *  root  /usr/local/bin/backup-incremental.sh
0 1 * * 0  root  /usr/local/bin/backup-full.sh
0 3 * * *  root  /usr/local/bin/backup-database.sh
0 4 * * *  root  /usr/local/bin/sync-offsite.sh
```

### Automating with systemd Timers

```ini
# /etc/systemd/system/backup-incremental.timer
[Unit]
Description=Daily incremental backup

[Timer]
OnCalendar=*-*-* 02:00:00
Persistent=true

[Install]
WantedBy=timers.target
```


[← Previous](20-section-13-disaster-recovery-planning.md) | [↑ Index](index.md) | [Next →](22-retention.md)
