# Internship — Level 1, Week 5-6
## Disk Usage Alerting System

### Real-World Scenario

Users store large files in their home directories. The shared `/projects` volume fills up weekly. IT doesn't know until someone complains. Build a disk monitoring and alerting system that gives early warning.

### Requirements

Write a script `/usr/local/bin/disk-alert.sh` that:

1. **Checks all mounted filesystems:**
   ```bash
   df -h --exclude-type=tmpfs --exclude-type=devtmpfs
   ```

2. **Thresholds:**
   - **Warning (80-89%):** Log it, optional notification
   - **Critical (90-94%):** Log it, find top offenders, send alert
   - **Emergency (95%+):** Log it, find top offenders, send urgent alert, attempt cleanup

3. **On critical/emergency, find top disk users:**
   - Scan `/home/` — top 10 directories by size
   - Scan `/var/` — top 10 directories by size
   - Output: `du -sh /home/* | sort -rh | head -10`

4. **Emergency auto-cleanup:**
   - Remove old logs: `find /var/log -name "*.gz" -mtime +30 -delete`
   - Remove old journal logs: `journalctl --vacuum-time=7d`
   - Empty apt cache: `apt-get clean`
   - Remove old kernels: `apt-get autoremove --purge`
   - Report how much space was freed

5. **Weekly report:**
   - Every Monday at 9 AM, generate and email a disk usage report
   - Format:
     ```
     Weekly Disk Report — 2026-06-24
     Filesystem      Size  Used Avail Use% Mounted on
     /dev/sda1        98G   82G   16G  84% /
     /dev/sdb1       500G  475G   25G  95% /home  *** EMERGENCY ***
     
     Top 5 by size in /home:
     245G  /home/jdoe/projects
     120G  /home/asmith/datasets
      ...
     
     Cleanup actions taken:
     - Freed 2.3G from apt cache
     - Freed 500M from old logs
     ```

6. **Configuration file:**
   - `/etc/disk-alert.conf`:
     ```ini
     WARN_THRESHOLD=80
     CRIT_THRESHOLD=90
     EMERG_THRESHOLD=95
     ALERT_EMAIL=it-team@company.com
     EXCLUDE_MOUNTS=/boot,/snap
     ```

### Cron Setup

```cron
# Check every hour during business hours
0 * * * 1-5 root /usr/local/bin/disk-alert.sh --check
# Weekly report every Monday
0 9 * * 1 root /usr/local/bin/disk-alert.sh --report
```

### Validation

```bash
# Test with a specific threshold
sudo ./disk-alert.sh --check --fake-usage /home=95

# Verify email delivery
mail -f /var/mail/root
```

### Deliverables

- `~/internship/disk-alert.sh`
- `~/internship/disk-alert.conf`
- `~/internship/sample-report.txt` — a sample weekly report (generated, not real)

### Hints

- `df -P` gives parseable output (no line wrapping)
- `awk '$5 ~ /%$/ { print $1, $5, $6 }'` to extract mount point and usage
- `mail -s "$SUBJECT" "$ALERT_EMAIL" < "$TMPFILE"`
- Use a PID file to prevent concurrent runs: `/var/run/disk-alert.pid`
- `trap "rm -f /var/run/disk-alert.pid; exit" EXIT INT TERM`
