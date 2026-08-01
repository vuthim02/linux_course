## 👑 Level 4: Mastery — Real-World Scheduling Scenarios

### Scenario 1: Multi-Server Backup Coordination

Design a backup schedule for 3 web servers that must not run simultaneously:

```bash
# Server 1: 01:00 (staggered by 1 hour each)
0 1 * * * /usr/bin/flock -n /tmp/backup.lock /usr/local/bin/backup.sh

# Server 2: 02:00
0 2 * * * /usr/bin/flock -n /tmp/backup.lock /usr/local/bin/backup.sh

# Server 3: 03:00
0 3 * * * /usr/bin/flock -n /tmp/backup.lock /usr/local/bin/backup.sh

# For laptops that may be off: use anacron
# /etc/anacrontab:
1 15 backup-1 /usr/local/bin/backup.sh
```

### Scenario 2: Systemd Timer with RandomizedDelay for Certificate Check

```bash
# Check cert expiry daily, randomize to spread load
# /etc/systemd/system/cert-check.timer
[Unit]
Description=Daily certificate check

[Timer]
OnCalendar=daily
RandomizedDelaySec=6h       # Run anytime between midnight and 6 AM
Persistent=true
FixedRandomDelay=true       # Same offset every day

[Install]
WantedBy=timers.target

# /etc/systemd/system/cert-check.service
[Unit]
Description=Check SSL certificate expiry

[Service]
Type=oneshot
ExecStart=/usr/local/bin/cert-check.sh
```

### Scenario 3: Log Rotation That Never Overlaps

```bash
#!/bin/bash
# /usr/local/bin/safe-logrotate.sh
exec /usr/bin/flock -n /var/lock/logrotate.lock || {
    echo "Previous logrotate still running, skipping"
    exit 1
}

# Run logrotate only if not already running
sudo logrotate -f /etc/logrotate.conf
```

### Scenario 4: anacron + cron Hybrid for Laptop Users

```bash
# /etc/anacrontab: for non-time-critical tasks
1    15    daily-cleanup    /usr/local/bin/clean-tmp.sh
7    20    weekly-update    /usr/local/bin/update-check.sh
30   30    monthly-reports  /usr/local/bin/generate-reports.sh

# User crontab (crontab -e): for time-sensitive tasks
# Run backup at 2 PM — but only if laptop is on
0 14 * * * /usr/local/bin/quick-backup.sh

# Systemd timer: for bounded retry with Persistent=true
[Timer]
OnCalendar=*-*-* 09:00:00
Persistent=true
RandomizedDelaySec=30m
```

### Scenario 5: Cron Job Health Monitoring

```bash
#!/bin/bash
# /usr/local/bin/cron-uptime.sh
# Wrap any cron job to report success/failure

JOB_NAME="$1"
shift
START_TIME=$(date +%s)

"$@"  # Execute the actual job
EXIT_CODE=$?

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

# Log to structured file
echo "$(date +%Y-%m-%dT%H:%M:%S) $JOB_NAME exit=$EXIT_CODE duration=${DURATION}s" \
    >> /var/log/cron-jobs.log

# Alert if failed or too slow
if [ $EXIT_CODE -ne 0 ]; then
    echo "CRON ALERT: $JOB_NAME failed with exit $EXIT_CODE" | \
        mail -s "Cron Failure on $(hostname)" admin@example.com
fi

if [ $DURATION -gt 600 ]; then
    echo "CRON ALERT: $JOB_NAME took too long (${DURATION}s)" | \
        mail -s "Cron Slow Job on $(hostname)" admin@example.com
fi

exit $EXIT_CODE

# Usage in crontab:
# */30 * * * * /usr/local/bin/cron-uptime.sh healthcheck /usr/local/bin/check.sh
```

### Scenario 6: Fleet-Wide Scheduled Task Audit

```bash
#!/bin/bash
# Audit all scheduling system across a server (for compliance)

report_scheduling() {
    echo "=== Cron ==="
    # User crontabs
    for user in $(getent passwd | awk -F: '$3>=1000 {print $1}'); do
        crontab -l -u "$user" 2>/dev/null
    done
    # System crontab
    [ -f /etc/crontab ] && cat /etc/crontab
    # cron.d files
    cat /etc/cron.d/* 2>/dev/null

    echo "=== Systemd Timers ==="
    systemctl list-timers --all --no-legend | awk '{print $NF}'

    echo "=== anacron ==="
    [ -f /etc/anacrontab ] && cat /etc/anacrontab

    echo "=== at Jobs ==="
    atq 2>/dev/null
}

report_scheduling
```



[← Previous](21-section-12-systemd-timer-deep-dive.md) | [↑ Index](index.md) | [Next →](21-rules-of-thumb.md)
