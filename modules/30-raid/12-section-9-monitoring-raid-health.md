## 🔍 Section 9: Monitoring RAID Health

### /proc/mdstat — Real-Time Health

The simplest and most useful monitoring tool. Parse it in scripts:

```bash
#!/bin/bash
# Quick RAID health check

if grep -q "\[.*_.*\]" /proc/mdstat; then
    echo "ALERT: RAID array has a failed device!"
    mdadm --detail /dev/md0
    exit 1
fi

if grep -q "resync\|recovery\|reshape" /proc/mdstat; then
    echo "INFO: RAID array is syncing"
    cat /proc/mdstat
else
    echo "OK: All arrays healthy"
fi
```

### mdadm --monitor Mode

mdadm can run as a daemon and watch for events:

```bash
# Run in foreground (for testing)
mdadm --monitor --scan --test

# Run as daemon
mdadm --monitor --scan --daemonise --syslog

# With email alerts
mdadm --monitor --scan --mail=root@localhost
```

Events monitored:
- `Fail`: A device has failed
- `FailSpare`: A spare has failed
- `SpareActive`: A spare was activated (started rebuild)
- `NewArray`: A new array was detected
- `RebuildStarted/RebuildFinished/RebuildNN`

### Email Alerts Configuration

In `/etc/mdadm/mdadm.conf`:

```
MAILADDR admin@example.com
MAILFROM mdadm@server.example.com
PROGRAM /usr/local/bin/raid_notify.sh
```

The `MAILADDR` directive tells mdadm where to send alerts. The `PROGRAM` directive specifies a script to run on events (useful for Slack/PagerDuty integration).

### Integrating with systemd

mdadm provides a systemd service for monitoring:

```bash
systemctl enable mdmonitor.service
systemctl start mdmonitor.service

# Check status
systemctl status mdmonitor.service
```

The service reads `/etc/mdadm/mdadm.conf` and starts mdadm in monitor mode.

### smartctl — Predictive Failure Detection

SMART (Self-Monitoring, Analysis and Reporting Technology) can predict drive failures before they happen:

```bash
# Check SMART health
smartctl -H /dev/sda

# Comprehensive status
smartctl -a /dev/sda | grep -E "Reallocated|Pending|Offline|UDMA|Current_Pending"

# Key SMART attributes to watch:
#   5   Reallocated_Sector_Ct    — sectors remapped (should be 0)
# 197   Current_Pending_Sector   — sectors waiting to be remapped (should be 0)
# 198   Offline_Uncorrectable    — uncorrectable errors (should be 0)
# 196   Reallocated_Event_Count  — reallocation events (should be 0)
```

### Monitoring Script Example

```bash
#!/bin/bash
# /usr/local/bin/raid_health.sh
# Run from cron every 5 minutes

ALERT_EMAIL="admin@example.com"
TMPFILE=$(mktemp)

cat /proc/mdstat > "$TMPFILE"

# Check for failed devices
if grep -q "\[.*_.*\]" /proc/mdstat; then
    mail -s "RAID FAILURE on $(hostname)" "$ALERT_EMAIL" < "$TMPFILE"
fi

# Check for degraded arrays (should show [UU] not [U_] etc.)
if grep -qE "\[.*_.*" /proc/mdstat; then
    mail -s "RAID DEGRADED on $(hostname)" "$ALERT_EMAIL" < "$TMPFILE"
fi

rm -f "$TMPFILE"
```





[← Previous](11-section-8-raid-failure-simulation.md) | [↑ Index](index.md) | [Next →](13-section-10-raid-and-lvm.md)
