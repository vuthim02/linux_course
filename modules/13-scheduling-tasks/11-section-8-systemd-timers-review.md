## 🔍 Section 8: Systemd Timers (Review from Part 12)

systemd timers are the modern replacement for cron. They offer more features.

### Recap — Basic Timer Structure

```ini
# /etc/systemd/system/weekly-cleanup.timer
[Unit]
Description=Weekly cleanup timer

[Timer]
OnCalendar=weekly
Persistent=true

[Install]
WantedBy=timers.target
```

```ini
# /etc/systemd/system/weekly-cleanup.service
[Unit]
Description=Weekly cleanup

[Service]
Type=oneshot
ExecStart=/usr/local/bin/cleanup.sh
```

### Systemd Timer Schedule Syntax (More Detail)

```bash
# Format: DayOfWeek Year-Month-Day Hour:Minute:Second
# * means "every"

OnCalendar=*-*-* *:*:*              # Every minute (like */1 * * *)
OnCalendar=*-*-* *:00:00            # Every hour
OnCalendar=*-*-* 00:00:00           # Daily at midnight
OnCalendar=Mon *-*-* 00:00:00       # Every Monday
OnCalendar=*-*-01 00:00:00          # First of every month
OnCalendar=*-*-01/7 00:00:00        # Every 7 days starting day 1
OnCalendar=*-01-01 00:00:00         # January 1 every year
OnCalendar=Sat,Tue *-*-* 03:00:00   # Every Saturday and Tuesday at 3 AM

# Multiple schedules
OnCalendar=Mon..Fri 09:00:00
OnCalendar=Mon..Fri 17:00:00
```

### Monotonic Timers (Relative to Events)

```ini
[Timer]
OnBootSec=5min              # 5 minutes after boot
OnUnitActiveSec=1h          # 1 hour after the service last ran
OnUnitInactiveSec=30m       # 30 minutes after the service stops
OnStartupSec=10min          # 10 minutes after systemd starts
```

### Timer Features cron Doesn't Have

```bash
# 1. Persistent=true — catch up after downtime
# If the system was off at 2 AM, run immediately on boot
[Timer]
OnCalendar=daily
Persistent=true

# 2. RandomizedDelay — avoid thundering herd
[Timer]
OnCalendar=daily
RandomizedDelaySec=1h    # Run at a random time between midnight and 1 AM

# 3. AccuracySec — power saving
[Timer]
OnCalendar=hourly
AccuracySec=1h           # Allow up to 1 hour of delay (saves wake-ups)

# 4. FixedRandomDelay — same random offset each time
[Timer]
OnCalendar=daily
FixedRandomDelay=true
RandomizedDelaySec=30m   # Always +15 minutes (5000/10000 * 30m for example)
```

### When to Use Systemd Timers vs Cron

**Use systemd timers when:**
- You need persistent (catch-up) behavior
- You want randomized delays
- You need dependency management (run after network.target)
- You want unified logging via journald
- The task is closely related to a systemd service

**Use cron when:**
- You need simple, portable scheduling
- Multiple admins need to view/edit easily
- You're on a non-systemd system (rare these days)
- You need user crontabs (non-root scheduled tasks)
- You want the `@reboot` syntax (which systemd handles differently)

---



---

[← Previous](10-section-7-at-one-time-scheduling.md) | [↑ Index](index.md) | [Next →](12-level-3-advanced-real-world-patterns.md)
