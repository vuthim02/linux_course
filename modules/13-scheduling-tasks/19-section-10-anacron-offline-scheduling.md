## 🔍 Section 10: anacron — Scheduling for Systems That Aren't Always On

`anacron` runs commands periodically **with a frequency in days**, not at specific times. It's designed for systems that aren't running 24/7 (laptops, desktops, VMs that get suspended).

### How anacron Works

```
1. anacron reads /etc/anacrontab at boot
2. Checks when each job last ran (timestamp files)
3. If more than its period (days) has elapsed, runs the job
4. Updates the timestamp after successful completion
```

### /etc/anacrontab Format

```bash
# /etc/anacrontab
# period delay job-id command
1       5     cron.daily    run-parts /etc/cron.daily
7       10    cron.weekly   run-parts /etc/cron.weekly
30      15    cron.monthly  run-parts /etc/cron.monthly
```

| Field | Meaning | Example |
|-------|---------|---------|
| period | Days between runs | `1` = daily, `7` = weekly |
| delay | Minutes to wait before running (after boot) | `5` = wait 5 minutes |
| job-id | Unique name (used for timestamp file) | `cron.daily` |
| command | Command to execute | `run-parts /etc/cron.daily` |

### Timestamp Files

```bash
# anacron stores timestamps in /var/spool/anacron/
ls -la /var/spool/anacron/
# cron.daily  cron.weekly  cron.monthly

# View last run time
cat /var/spool/anacron/cron.daily
# 20250729
```

### When to Use anacron vs cron

```bash
# cron:   "Run every day at 2 AM" (misses if off)
# anacron: "Run daily" (runs after boot if day changed)

# anacron handles misses automatically
# Good for: log rotation, backup scripts, system updates
# Bad for: time-sensitive jobs (certificate renewal at exact time)
```

### Manual anacron Commands

```bash
sudo anacron -f              # Force all jobs to run now
sudo anacron -u              # Update timestamps without running
sudo anacron -T              # Test /etc/anacrontab syntax
sudo anacron -d              # Debug mode (dry-run + verbose)
```

### How cron and anacron Work Together

Most distros have `/etc/cron.hourly/` managed by cron, and `/etc/cron.daily/`, `weekly`, `monthly` managed by anacron. A systemd timer or cron entry runs `anacron` periodically to trigger these:

```bash
# /etc/cron.d/0anacron (or systemd timer anacron.timer)
# Runs anacron every hour to check for missed jobs
0 * * * * root /usr/sbin/anacron -s
```



[← Previous](18-self-test-can-you-answer-these.md) | [↑ Index](index.md) | [Next →](20-section-11-flock-cron-lockfile-patterns.md)
