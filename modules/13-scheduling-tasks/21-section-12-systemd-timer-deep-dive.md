## 🔍 Section 12: Systemd Timer Deep Dive

### Analyzing Timer Expressions

```bash
# Test what a calendar expression means
systemd-analyze calendar "Mon..Fri 09:00:00"
# Normalized form: Mon..Fri 2025-01-01 09:00:00
# Next elapse: Mon 2025-07-28 09:00:00
# (in UTC): Mon 2025-07-28 09:00:00 UTC

# Multiple iterations
systemd-analyze calendar --iterations=3 "daily"
# Next: 2025-07-29 00:00:00
# Then: 2025-07-30 00:00:00
# Then: 2025-07-31 00:00:00

# Verify a timer's next trigger
systemd-analyze verify /etc/systemd/system/*.timer

# Check timer timing in detail
systemctl show myapp.timer --property=NextElapseUSecRealtime
systemctl show myapp.timer --property=NextElapseUSecMonotonic
```

### Transient Timers (systemd-run)

Create on-the-fly timers without writing unit files:

```bash
# Run a command every 5 minutes for testing
systemd-run --unit=test-timer --on-calendar='*:0/5' \
    /bin/bash -c 'echo "test" | systemd-cat -t test-timer'

# Run once after boot delay
systemd-run --unit=delayed-job --on-boot=10min \
    /usr/local/bin/important-job.sh

# Run 5 min after the service unit becomes active
systemd-run --unit=post-cleanup --on-unit-active=5min \
    /usr/local/bin/cleanup.sh

# List transient timers
systemctl list-timers --all | grep run-
```

### Timer Debugging

```bash
# See when a timer will fire next
systemctl list-timers --all

# Check if timer unit is loaded correctly
systemctl status myapp.timer

# View timer properties
systemctl show myapp.timer | grep -E "Next|Last|Trigger"

# Monitor timer events in real-time
journalctl -f -u myapp.timer -u myapp.service

# View all timer transitions
journalctl -u myapp.timer --no-pager

# Force a timer to fire immediately
sudo systemctl start myapp.service   # Don't start timer manually
# Instead, for testing:
sudo systemctl start myapp.timer     # Start timer, wait for schedule
```

### OnCalendar= Special Shorthands

```bash
# Hourly (at the start of each hour)
OnCalendar=hourly
# Equivalent: *:0:0

# Daily (at midnight)
OnCalendar=daily
# Equivalent: 0:0:0

# Weekly (Monday midnight)
OnCalendar=weekly
# Equivalent: Mon 0:0:0

# Monthly (1st at midnight)
OnCalendar=monthly
# Equivalent: *-*-1 0:0:0

# Quarterly (Jan 1, Apr 1, Jul 1, Oct 1)
OnCalendar=*-01-01,*-04-01,*-07-01,*-10-01 00:00:00

# Every 12 hours
OnCalendar=*:0/12
```

### Monotonic vs Realtime Timers

```bash
# REALTIME — fire at specific wall-clock time
[Timer]
OnCalendar=Mon..Fri 09:00:00

# MONOTONIC — fire relative to system events
[Timer]
OnBootSec=5min             # After system boots
OnStartupSec=5min          # After systemd starts
OnUnitActiveSec=1h         # After the service unit last activated
OnUnitInactiveSec=30m      # After the service unit last deactivated
```

### Timer Unit Dependencies

```bash
# Delay timer until network is up
[Unit]
After=network-online.target
Wants=network-online.target

# Only run when system is on AC power
[Unit]
ConditionACPower=true

# Only run on bare metal (not VM/container)
[Unit]
ConditionVirtualization=no

# Run only during specific hours (using time-set)
[Unit]
After=time-set.target
```



[← Previous](20-section-11-flock-cron-lockfile-patterns.md) | [↑ Index](index.md) | [Next →](22-level-4-mastery-scenarios.md)
