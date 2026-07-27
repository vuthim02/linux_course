## 🔍 Section 9: Systemd Timers — Modern Cron

systemd timers are the modern replacement for cron. They offer calendar-based and monotonic scheduling.

### Timer Unit Structure

A timer needs two files:

1. **Timer file** (`.timer`) — defines the schedule
2. **Service file** (`.service`) — defines what to run

### Calendar Timer Example

```ini
# /etc/systemd/system/daily-backup.timer
[Unit]
Description=Daily backup timer

[Timer]
OnCalendar=daily
Persistent=true

[Install]
WantedBy=timers.target
```

```ini
# /etc/systemd/system/daily-backup.service
[Unit]
Description=Daily backup

[Service]
Type=oneshot
ExecStart=/usr/local/bin/backup.sh
```

### Monotonic Timer Example

```ini
[Timer]
OnBootSec=5min       # Run 5 minutes after boot
OnUnitActiveSec=1h   # Run 1 hour after last activation

# Other options:
# OnStartupSec=     — after systemd starts
# OnActiveSec=      — after timer unit becomes active
# OnUnitInactiveSec — after service becomes inactive
```

### Timer Schedule Syntax

```bash
# OnCalendar= syntax:
OnCalendar=*-*-*                      # Every day
OnCalendar=*-*-* 00:00:00            # Daily at midnight
OnCalendar=Mon *-*-* 09:00:00        # Every Monday at 9 AM
OnCalendar=*-*-1..7 04:00:00         # First week of month at 4 AM
OnCalendar=hourly                    # Every hour
OnCalendar=daily                     # Every day
OnCalendar=weekly                    # Every week
OnCalendar=monthly                   # Every month
```

### Managing Timers

```bash
# List all timers
systemctl list-timers

# List all timers (including inactive)
systemctl list-timers --all

# Start/enable a timer
sudo systemctl enable --now daily-backup.timer

# Check timer status
systemctl status daily-backup.timer

# View timer information
systemctl show daily-backup.timer
```

### Systemd Timer vs Cron

| Feature | cron | systemd timer |
|---------|------|---------------|
| Schedule | Fixed minute/hour/day/month | Calendar or relative (monotonic) |
| Dependencies | None | Full systemd dependency system |
| Logging | Mail or syslog | Journald (automatic) |
| Random delay | No | RandomizedDelaySec= |
| Persistent | No | Persistent=yes (catch up after downtime) |
| Missed runs | Lost | Can catch up (Persistent=true) |
| Environment | Limited | Full environment control |

### Add Random Delay

```ini
[Timer]
OnCalendar=daily
RandomizedDelaySec=1h    # Run at a random time within the hour
```

This prevents all daily tasks from running at exactly midnight.

---



---

[← Previous](11-section-8-analyzing-boot-performance.md) | [↑ Index](index.md) | [Next →](13-level-3-advanced-debugging-and.md)
