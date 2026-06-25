# Internship — Level 2, Week 9-10
## Centralized Log Server

### Real-World Scenario

You have 10 servers generating logs. When something breaks, you have to SSH into each server and search logs individually. There is no centralized log view, no historical retention, no way to correlate events across servers. Build a centralized logging system.

### Requirements

#### Part A: Log Server Setup (log-collector)

Install and configure `rsyslog` as a central log collector:

1. **Install rsyslog** if not already present
2. **Configure `/etc/rsyslog.conf`** on the collector:
   ```bash
   # Enable TCP syslog reception
   module(load="imtcp")
   input(type="imtcp" port="514")
   
   # Template for per-host log files
   template(name="PerHostLog" type="string"
     string="/var/log/remote/%HOSTNAME%/%PROGRAMNAME%.log")
   
   # Apply template to all remote messages
   :source, !isequal, "localhost" -?PerHostLog
   :source, !isequal, "localhost" ~
   ```
3. **Configure firewall** to allow TCP/514 from your subnet
4. **Set up log rotation** in `/etc/logrotate.d/remote-logs`:
   - Daily rotation
   - Keep 30 days
   - Compress with gzip
   - Delay compression
   - Post-rotate script to reload rsyslog

#### Part B: Client Setup

On each client server, configure rsyslog to forward logs:

1. **Edit `/etc/rsyslog.d/50-forward.conf`**:
   ```bash
   *.* @@log-collector.company.com:514  # @@ = TCP
   # Keep local logging too (don't stop local logs)
   ```
2. **Test connectivity:**
   ```bash
   logger "Test log from web01"
   # On collector: tail /var/log/remote/web01/root.log
   ```

#### Part C: Log Search Tool

Write `/usr/local/bin/log-search.sh` that:

1. **Searches across all remote hosts:**
   ```bash
   log-search.sh --host web01 --program sshd --since "1 hour ago" --search "Failed password"
   log-search.sh --all --since yesterday --search "error"
   log-search.sh --host db01 --follow  # tail -f
   ```

2. **Output format:**
   ```
   [web01] 2026-06-24 14:30:01 sshd: Failed password for root from 10.0.0.5 port 22
   [db01]  2026-06-24 14:30:02 postgresql: ERROR: relation "users" does not exist
   ```

3. **Uses:**
   - `grep -r` on `/var/log/remote/`
   - `zgrep` for compressed logs
   - `tail -f` for follow mode (via SSH tail)

#### Part D: Log Summary Report

Write `/usr/local/bin/log-summary.sh` (cron daily):

- Counts log lines per host per severity (error, warning, info)
- Highlights hosts with highest error counts
- Emails summary to it-team@company.com
- Example output:
  ```
  Log Summary — 2026-06-24
  Host      Errors  Warnings  Info
  web01     145     23        1200
  web02     12      8         980
  db01      890     45        450    ← HIGH ERROR RATE
  ```

### Validation

```bash
# On collector: start rsyslog in debug mode to verify reception
rsyslogd -dn | grep "remote"

# On client: send test logs
for i in {1..5}; do logger "test message $i from $(hostname)"; done

# On collector: verify logs arrived
ls /var/log/remote/
tail /var/log/remote/$(hostname)/user.log
```

### Deliverables

- `~/internship/log-server/rsyslog-collector.conf` — collector config
- `~/internship/log-server/logrotate-remote.conf` — rotation config
- `~/internship/log-server/rsyslog-forward.conf` — client config
- `~/internship/log-server/log-search.sh`
- `~/internship/log-server/log-summary.sh`
- `~/internship/log-server/test-results.txt` — verification output

### Hints

- `rsyslog` templates use `%HOSTNAME%` and `%PROGRAMNAME%` variables
- `logrotate` postrotate: `systemctl reload rsyslog`
- `find /var/log/remote -name "*.log" -mmin -5 | xargs grep "error"` for recent searches
- `zcat` or `zgrep` for compressed logs
- Test with `logger -n log-collector -P 514 "test"` from client
