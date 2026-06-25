# Internship — Level 3, Week 15-16
## System Health Report Generator

### Real-World Scenario

Management wants a daily server health report emailed every morning at 7 AM. They want to see: is everything running? Are any servers overloaded? Is disk filling up? They don't want to SSH into anything. Build a comprehensive report generator.

### Requirements

Write `/usr/local/bin/health-report.sh` that produces a detailed system health report.

#### Report Sections

**1. Header**
```
╔════════════════════════════════════════════════╗
║     System Health Report                       ║
║     Server: web01.company.com                  ║
║     Date:   2026-06-24 07:00:01 UTC            ║
║     Uptime: 87 days, 4 hours, 12 minutes       ║
╚════════════════════════════════════════════════╝
```

**2. CPU**
```
CPU:
  Model:  Intel Xeon Platinum 8358 @ 2.60GHz (32 cores)
  Load:   1.5 / 3.2 / 2.8  (1/5/15 min)
  Usage:  23.5% user  12.1% sys   0.2% iowait  64.2% idle
  Top 5 by CPU:
   45.2%  postgres: writer process
   12.1%  nginx: worker process
    8.3%  python3 /app/api.py
    5.1%  prometheus
    2.3%  sshd
```

**3. Memory**
```
Memory:
  Total:   62.9 GB
  Used:    41.2 GB (65.5%)
  Buffers:  2.1 GB
  Cache:    8.4 GB
  Available: 21.7 GB (34.5%)
  Swap:     2.0 GB total, 0.3 GB used (15.0%)
```

**4. Disk**
```
Disk:
  Mount     Size  Used  Avail  Use%  Inodes  Type
  /         50G   23G    27G   46%    1.2M   ext4
  /home    500G  412G    88G   82% ★  890K   xfs
  /var     100G   67G    33G   67%    2.1M   xfs
  /mnt/data 2.0T  1.8T  200G   90% ★  340K   xfs

  Highlight: ★ = warning (≥80%), ★★ = critical (≥90%)
```

**5. Network**
```
Network:
  Interface   RX/s     TX/s    Errors  Drops
  eth0       45.2 Mb  12.1 Mb    0      2
  eth1        2.3 Mb   1.1 Mb    0      0

  Listening ports:
    TCP/22    sshd
    TCP/80    nginx
    TCP/443   nginx
    TCP/5432  postgres
    TCP/9090  prometheus
    TCP/3000  grafana

  Established connections: 1,234
  TIME_WAIT: 45, ESTABLISHED: 1,189, CLOSE_WAIT: 0
```

**6. Services**
```
Services:
  sshd          active  enabled    uptime 45d
  nginx         active  enabled    uptime 45d
  postgresql    active  enabled    uptime 12d
  prometheus    active  enabled    uptime 45d
  grafana-server stopped disabled  ⚠ not running
```

**7. Security**
```
Security:
  Last logins (failed): 12 since yesterday
  Last logins (successful): 45 since yesterday
  sudo commands today: 23
  SSH auth failures (last 24h): web01: 3, db01: 145 ★★
  Running as root: 3 processes (check: ntp, cron, sshd)
```

**8. Summary Health Score**
```
Health Score: 84/100
  CPU:    92/100  (load average normal)
  Memory: 85/100  (swap in use)
  Disk:   70/100  ★ 2 mounts over 80%
  Network:95/100  (no errors)
  Services:80/100 ★ grafana-server is not running
  Security:85/100 ★ high SSH failures on db01
```

#### Output Formats

1. **Text report** — sent via email
2. **HTML report** — saved to `/var/www/html/health/` for web viewing
3. **JSON report** — saved to `/var/log/health-reports/` for historical tracking

#### Report Rotation

- Keep 30 days of JSON reports
- Compress reports older than 7 days
- Clean up HTML reports older than 7 days

#### Cron Configuration

```cron
# Daily report at 7:00 AM
0 7 * * * root /usr/local/bin/health-report.sh --email it-team@company.com
# Hourly JSON snapshot (for trending)
0 * * * * root /usr/local/bin/health-report.sh --json-only
```

### Validation

```bash
# Generate report locally
sudo ./health-report.sh --output /tmp/report.txt
cat /tmp/report.txt

# Generate HTML
sudo ./health-report.sh --format html --output /var/www/html/health/report.html

# Test email
sudo ./health-report.sh --email admin@localhost
mail -f /var/mail/root
```

### Deliverables

- `~/internship/health-report.sh`
- `~/internship/health-report.conf` — thresholds, email, mount exclusions
- `~/internship/health-template.html` — HTML template
- `~/internship/sample-report.txt` — generated text report
- `~/internship/sample-report.html` — generated HTML report

### Hints

- `nproc` for CPU count, `lscpu` for model
- `awk '{sum=$1+$2+$3; print $1, $2, $3, sum}' /proc/loadavg` for load
- `free -h | awk '/^Mem:/ {print $2, $3, $4}'` for memory
- `ss -tna | awk 'NR>1 {print $1}' | sort | uniq -c` for connection states
- `lastb | wc -l` for failed logins (requires `lastb` from `sysvinit-utils`)
- `find /proc -maxdepth 2 -name "exe" -readable | xargs -I{} readlink {} | sort | uniq -c | sort -rn | head -10` for root processes
