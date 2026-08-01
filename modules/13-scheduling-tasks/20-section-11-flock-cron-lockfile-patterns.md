## 🔍 Section 11: flock — Preventing Cron Job Overlaps

Long-running cron jobs can overlap if the previous instance hasn't finished. `flock` provides file-based locking to prevent this.

### Basic flock Usage

```bash
# /usr/bin/flock <lockfile> <command>

# Example: run backup only if not already running
0 2 * * * /usr/bin/flock -n /tmp/backup.lock /usr/local/bin/backup.sh
# -n = non-block: fail immediately if lock is held
```

### flock Patterns for Cron

```bash
# Pattern 1: Non-blocking (skip if running)
*/5 * * * * /usr/bin/flock -n /tmp/healthcheck.lock \
    /usr/local/bin/healthcheck.sh

# Pattern 2: Wait for previous to finish
0 3 * * * /usr/bin/flock -w 3600 /tmp/backup.lock \
    /usr/local/bin/backup.sh
# -w 3600 = wait up to 1 hour for lock

# Pattern 3: Within a script (more robust)
cat > /usr/local/bin/safe-backup.sh << 'SCRIPT'
#!/bin/bash
exec /usr/bin/flock -n /var/lock/backup.lock || exit 1
# Only one instance runs at a time
rsync -av /data/ /backup/
SCRIPT
```

### flock Tips

```bash
# Verify lock is held
flock /tmp/mylock true         # Returns 0 if lock acquired
flock -n /tmp/mylock true      # Returns 1 if lock held by another

# List held locks
lslocks                         # Lists all file locks
lsof /tmp/mylock                # Which process holds the lock

# Common lockfile locations
/var/lock/          # Standard for system locks
/tmp/               # Simple but less secure
/run/               # Runtime directory (best for system services)
```

### Additional Cron Hardening

```bash
# 1. Timeout wrapper — kill jobs that run too long
0 2 * * * timeout 300 /usr/local/bin/backup.sh

# 2. Nice + ionice — don't starve the system
0 3 * * * nice -n 19 ionice -c 3 /usr/local/bin/backup.sh

# 3. Output handling — capture everything with timestamps
0 * * * * /usr/local/bin/check.sh >> /var/log/cron-check.log 2>&1

# 4. Load check — skip if system is busy
0 * * * * [ "$(awk '{print $1}' /proc/loadavg | cut -d. -f1)" -lt 2 ] \
    && /usr/local/bin/backup.sh

# 5. Email on failure only
0 2 * * * /usr/local/bin/job.sh > /dev/null 2>&1 || \
    echo "Job failed at $(date)" | mail -s "CRON FAILURE" admin@example.com
```



[← Previous](19-section-10-anacron-offline-scheduling.md) | [↑ Index](index.md) | [Next →](21-section-12-systemd-timer-deep-dive.md)
