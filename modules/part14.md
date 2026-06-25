# 🐧 Linux System Administrator — Complete Course
## Part 14 of ∞: Logging and Journald — System Monitoring and Troubleshooting

---

> **Reverse Engineering Approach:** When a server breaks at 3 AM, logs are your only witness. Every authentication attempt, every service crash, every kernel panic — it's all recorded. The difference between a good sysadmin and a great one is knowing where to look, what to filter, and how to correlate events across thousands of log entries.

---

## 🎯 What You Will Achieve in Part 14

| Level | Focus | What You'll Master |
|-------|-------|-------------------|
| ⭐ **Level 1: Basic** | Logging architecture and syslog | Two logging systems (journald vs rsyslog), syslog protocol, key log files |
| ⭐ **Level 2: Intermediary** | Configuration and log management | rsyslog rules, journalctl queries, journald configuration, logrotate |
| ⭐ **Level 3: Advanced** | Centralized logging and security | Central log servers, log analysis patterns, log security, compliance |

---

## ⭐ Level 1: Basic — Logging Architecture and Syslog

![Syslog Protocol Layers RFC 5424](https://upload.wikimedia.org/wikipedia/commons/c/c3/Syslog_layers_RFC5424.png)
*Syslog protocol layers as defined by RFC 5424. Source: Wikimedia Commons*

> **Level 1 Goal:** Understand the Linux dual logging architecture (journald + rsyslog), learn the syslog protocol with facilities and severities, and know where key log files live.

---

## 🔍 Section 1: The Linux Logging Architecture

Linux has two parallel logging systems:

```
Application (nginx, sshd, mysql...)
    │
    ├──→ systemd-journald (binary, structured, default)
    │       │
    │       ├──→ /run/log/journal/  (volatile, in memory)
    │       └──→ /var/log/journal/  (persistent, on disk)
    │
    └──→ rsyslog (traditional, text-based)
            │
            ├──→ /var/log/syslog     (everything)
            ├──→ /var/log/auth.log   (authentication)
            ├──→ /var/log/kern.log   (kernel messages)
            └──→ /var/log/mail.log   (mail server)
```

### Why Two Systems?

| Aspect | journald | rsyslog |
|--------|----------|---------|
| Format | Binary (structured) | Plain text |
| Storage | Default: memory, Optional: disk | Files on disk |
| Query speed | Very fast (indexed) | grep-based (slower) |
| Field structure | Yes (100+ fields) | No (text only) |
| Reliability | Tamper-evident (signed) | Standard text files |
| Network forwarding | Limited | Primary use case |

In modern Linux, both work together:
1. journald captures everything first
2. rsyslog reads from journald and writes traditional files
3. Most tools still read from `/var/log/` files

---

## 🔍 Section 2: The syslog Protocol

Syslog is the standard for log messages. Every log line has a standard format.

### Syslog Facility and Severity

Each message has a **facility** (what generated it) and a **severity** (how serious).

**Facilities:**

| Code | Keyword | Description |
|------|---------|-------------|
| 0 | kern | Kernel messages |
| 1 | user | User-level messages |
| 2 | mail | Mail system |
| 3 | daemon | System daemons |
| 4 | auth | Authentication (login, su) |
| 5 | syslog | Syslogd itself |
| 6 | lpr | Line printer subsystem |
| 7 | news | Network news subsystem |
| 8 | uucp | UUCP subsystem |
| 9 | cron | Clock daemon (cron/at) |
| 10 | authpriv | Security/authorization |
| 11 | ftp | FTP daemon |
| 16-23 | local0-local7 | Locally defined |

**Severities:**

| Code | Severity | Description |
|------|----------|-------------|
| 0 | emerg | System is unusable |
| 1 | alert | Action must be taken immediately |
| 2 | crit | Critical conditions |
| 3 | err | Error conditions |
| 4 | warning | Warning conditions |
| 5 | notice | Normal but significant |
| 6 | info | Informational |
| 7 | debug | Debug-level messages |

### Standard Log Format

```
Jan 15 10:30:45 server sshd[12345]: Failed password for root from 192.168.1.100 port 22 ssh2
└─────┬────┘ └──┬┘ └──┬┘ └───┬──┘ └─────────────────────────┬────────────────────────┘
 timestamp    host   prog[PID]           message
```

---

## 🔍 Section 4: Key Log Files and What They Contain

### Essential Log Files

| File | Purpose |
|------|---------|
| `/var/log/syslog` | Everything (general system log) |
| `/var/log/auth.log` | Authentication (logins, sudo) |
| `/var/log/kern.log` | Kernel messages |
| `/var/log/dmesg` | Kernel ring buffer (boot messages) |
| `/var/log/boot.log` | System startup messages |
| `/var/log/cron.log` | cron job execution |
| `/var/log/mail.log` | Mail server (postfix, sendmail) |
| `/var/log/apache2/access.log` | Apache web requests |
| `/var/log/apache2/error.log` | Apache errors |
| `/var/log/nginx/access.log` | Nginx web requests |
| `/var/log/nginx/error.log` | Nginx errors |
| `/var/log/mysql/error.log` | MySQL/MariaDB errors |
| `/var/log/faillog` | Failed login attempts |
| `/var/log/lastlog` | Last login for each user |
| `/var/log/wtmp` | Login records (binary) |
| `/var/log/btmp` | Bad login attempts (binary) |

### Reading Binary Logs

```bash
# wtmp, btmp, lastlog are binary — use special commands
last              # Shows logins (reads /var/log/wtmp)
lastb             # Shows failed logins (reads /var/log/btmp)
lastlog           # Shows last login for each user
```

---

## ⭐ Level 2: Intermediary — Configuration and Log Management

![Logging Pipeline: journald to rsyslog](https://upload.wikimedia.org/wikipedia/commons/thumb/9/9f/Linux_kernel_and_Computer_layers.png/1024px-Linux_kernel_and_Computer_layers.png)
*Linux system layers showing how applications, kernel, and logging systems interact. Source: Wikimedia Commons*

> **Level 2 Goal:** Configure rsyslog rules, master journalctl queries and filtering, configure journald persistence, and set up log rotation with logrotate.

---

## 🔍 Section 3: rsyslog Configuration

rsyslog is the workhorse that writes traditional log files.

### Main Configuration

```bash
cat /etc/rsyslog.conf
```

```
#################
# MODULES        #
#################
module(load="imuxsock")    # Local system logging
module(load="imklog")      # Kernel logging
module(load="imjournal")   # Read from journald

###############
# RULES        #
###############
# Format: facility.severity  destination

auth,authpriv.*         /var/log/auth.log
*.*;auth,authpriv.none  -/var/log/syslog
cron.*                  /var/log/cron.log
daemon.*                -/var/log/daemon.log
kern.*                  -/var/log/kern.log
mail.*                  -/var/log/mail.log
user.*                  -/var/log/user.log
```

### Rule Syntax

```
facility.severity     action

Examples:
*.info                /var/log/messages     # All info and above
mail.*                /var/log/maillog      # All mail messages
auth.*                /var/log/authlog      # All auth messages
*.err                 /var/log/errorlog     # All errors
cron.*                @logserver:514        # Forward cron logs to central server
```

### Rule Selectors

```bash
# Single facility
auth.*                    # All auth messages

# Multiple facilities
auth,mail.*               # All auth AND mail messages

# Exclude
*.*;auth.none             # Everything EXCEPT auth

# Severity and above
*.err                     # err and above (err, crit, alert, emerg)
*.=err                    # EXACTLY err (not crit, alert, emerg)

# Multiple selectors (OR)
kern.info;kern.!err       # kern info and above, but NOT err
```

### Configuration Files in rsyslog.d

```bash
# Additional config files
ls /etc/rsyslog.d/

# Example: 50-default.conf
cat /etc/rsyslog.d/50-default.conf
```

### Testing rsyslog Configuration

```bash
# Test the config for syntax errors
sudo rsyslogd -N1

# Restart after changes
sudo systemctl restart rsyslog
```

---

## 🔍 Section 5: Journald Deep Dive

### Journalctl Quick Reference

```bash
# Basic
journalctl                          # All logs (from current boot)
journalctl -b                       # Current boot only
journalctl -b -1                    # Previous boot
journalctl --list-boots             # List all boots

# By unit
journalctl -u nginx                 # Specific service
journalctl -u nginx -u sshd         # Multiple services

# By time
journalctl --since "2 hours ago"
journalctl --since "2024-01-15" --until "2024-01-16"
journalctl --since yesterday

# By priority
journalctl -p err                   # Errors and worse
journalctl -p warning               # Warnings and worse
journalctl -p info                  # Info and worse

# Follow (tail -f equivalent)
journalctl -f

# Last N lines
journalctl -n 50

# By field
journalctl _PID=1234                # Specific process
journalctl _UID=1000                # Specific user
journalctl _SYSTEMD_UNIT=sshd.service

# Output format
journalctl -o json                  # JSON output
journalctl -o verbose               # All fields
journalctl -o short                 # Default format
journalctl -o cat                   # Message only (no metadata)

# No pager
journalctl --no-pager

# Disk usage
journalctl --disk-usage
```

### Journal Fields (Useful for Filtering)

```bash
# List all available fields
journalctl --fields

# Common fields:
# _PID          — Process ID
# _UID          — User ID
# _GID          — Group ID
# _COMM         — Command name
# _EXE          — Executable path
# _CMDLINE      — Full command line
# _SYSTEMD_UNIT — systemd unit name
# _BOOT_ID      — Boot ID (for current boot)
# _MACHINE_ID   — Machine ID
# _HOSTNAME     — Hostname
# PRIORITY      — 0 (emerg) to 7 (debug)
# SYSLOG_FACILITY — Syslog facility code
```

### Advanced journalctl Queries

```bash
# All journal entries from the nginx process itself
journalctl _COMM=nginx

# All errors from the current boot
journalctl -b -p err

# All messages from PID 1234 during a time range
journalctl _PID=1234 --since "10:00" --until "11:00"

# All messages from a specific user's session
journalctl _UID=1000

# Kernel messages
journalctl -k

# Messages from a specific executable
journalctl _EXE=/usr/sbin/sshd

# All failed SSH login attempts
journalctl -u sshd -p info | grep "Failed password"

# Real-time monitoring of specific service
journalctl -u nginx -f
```

### Making Journald Persistent

By default, journald stores logs in memory (`/run/log/journal/`). Logs are lost on reboot.

```bash
# Make journald persistent
sudo mkdir -p /var/log/journal
sudo systemctl restart systemd-journald

# Verify
ls /var/log/journal/
journalctl --disk-usage
```

### Journald Configuration

```bash
cat /etc/systemd/journald.conf
```

```
[Journal]
Storage=auto                 # auto, persistent, volatile, none
Compress=yes                 # Compress old entries (xz)
Seal=yes                     # Enable forward-secure sealing (tamper evidence)
SplitMode=uid               # Separate journal per user
SyncIntervalSec=5m           # Sync to disk interval
RateLimitIntervalSec=30s     # Rate limit interval
RateLimitBurst=1000          # Messages allowed in interval
SystemMaxUse=1G              # Max disk space for journal
SystemKeepFree=500M          # Keep at least 500M free
SystemMaxFileSize=100M       # Max single journal file size
MaxRetentionSec=1month       # How long to keep logs
```

### Forward Journal to Traditional Syslog

```bash
# In /etc/systemd/journald.conf:
ForwardToSyslog=yes

# Then restart:
sudo systemctl restart systemd-journald
```

---

## 🔍 Section 6: Log Rotation with logrotate

Log files grow endlessly. logrotate manages this automatically.

### How logrotate Works

```
1. Runs daily from cron (/etc/cron.daily/logrotate)
2. Reads config from /etc/logrotate.conf and /etc/logrotate.d/*
3. Checks if any log file needs rotation (based on size, age)
4. Renames current log (nginx.log → nginx.log.1)
5. Creates new empty log file
6. Optionally compresses old logs (nginx.log.2.gz)
7. Removes logs older than retention period
8. Sends signal to application to reopen logs
```

### Main Configuration

```bash
cat /etc/logrotate.conf
```

```
# Global settings
weekly                    # Rotate weekly
rotate 4                  # Keep 4 weeks of backups
create                    # Create new file after rotation
dateext                   # Use date as suffix
compress                  # Compress old logs (gzip)

# Include additional config
include /etc/logrotate.d
```

### Per-Service Configuration

```bash
cat /etc/logrotate.d/nginx
```

```
/var/log/nginx/*.log {
    daily
    missingok
    rotate 14
    compress
    delaycompress
    notifempty
    create 640 www-data adm
    sharedscripts
    postrotate
        [ -f /var/run/nginx.pid ] && kill -USR1 $(cat /var/run/nginx.pid)
    endscript
}
```

### Common logrotate Directives

| Directive | Purpose |
|-----------|---------|
| `daily` | Rotate every day |
| `weekly` | Rotate every week |
| `monthly` | Rotate every month |
| `rotate N` | Keep N old logs |
| `size SIZE` | Rotate when file exceeds size (e.g., `size 100M`) |
| `compress` | Compress with gzip |
| `delaycompress` | Skip compression on most recent rotated file |
| `missingok` | Don't error if log file is missing |
| `notifempty` | Don't rotate empty files |
| `create MODE USER GROUP` | Create new file with these permissions |
| `postrotate/endscript` | Run commands after rotation |
| `prerotate/endscript` | Run commands before rotation |
| `sharedscripts` | Run postrotate once for all matching files |
| `dateext` | Use date instead of number suffix |

### Testing logrotate

```bash
# Dry run (shows what WOULD happen)
sudo logrotate -d /etc/logrotate.conf

# Force rotation
sudo logrotate -f /etc/logrotate.conf

# Force rotation of specific config
sudo logrotate -f /etc/logrotate.d/nginx

# Show logrotate status
cat /var/lib/logrotate/status
```

### Custom logrotate Example

```bash
# Create a config for your custom app
sudo tee /etc/logrotate.d/myapp << 'EOF'
/var/log/myapp/*.log {
    weekly
    rotate 4
    compress
    missingok
    notifempty
    create 640 myapp myapp
    sharedscripts
    postrotate
        systemctl reload myapp 2>/dev/null || true
    endscript
}
EOF
```

---

## ⭐ Level 3: Advanced — Centralized Logging and Security

> **Level 3 Goal:** Set up a centralized logging server with rsyslog, master advanced log analysis and troubleshooting patterns, and implement log security measures including integrity protection and compliance.

---

## 🔍 Section 7: Centralized Logging

In production, you send logs from all servers to a central location.

### Rsyslog as a Central Server

**Server side (log receiver):**

```bash
# /etc/rsyslog.conf — enable UDP and/or TCP reception
# Uncomment these lines:
module(load="imudp")
input(type="imudp" port="514")

module(load="imtcp")
input(type="imtcp" port="514")

# Store logs from remote hosts
$template RemoteLogs,"/var/log/remote/%HOSTNAME%/%PROGRAMNAME%.log"
*.* ?RemoteLogs
& ~
```

**Client side (log sender):**

```bash
# /etc/rsyslog.d/50-forward.conf
*.* @logserver.example.com:514   # UDP (single @)
*.* @@logserver.example.com:514  # TCP (double @@)

# Restart
sudo systemctl restart rsyslog
```

### Security Considerations

```bash
# Use firewall to restrict access to port 514
sudo ufw allow from 10.0.0.0/8 to any port 514

# Consider using RELP (Reliable Event Logging Protocol) for TCP
# TLS encryption for logs in transit
# Restrict who can write to log directories
```

---

## 🔍 Section 8: Analyzing Logs for Troubleshooting

### Common Troubleshooting Patterns

```bash
# 1. Find the last error before a crash
journalctl -u myservice -b -p err | tail -20

# 2. Check what happened around a specific time
journalctl --since "10:30" --until "10:35" -u myservice

# 3. Correlate multiple services
journalctl -u nginx -u php-fpm -u mysql --since "5 min ago"

# 4. Check if a cron job ran
journalctl -u cron -n 20

# 5. Find why a service won't start
journalctl -u myservice --since "1 hour ago"

# 6. Check authentication failures
journalctl -u sshd -p info | grep "Failed password"

# 7. Check disk errors
journalctl -k -p err | grep -i "ata\|sd\|i/o error"

# 8. Check OOM (out of memory) kills
journalctl -k | grep -i "oom\|out of memory"

# 9. Check if system was shut down properly
last -x | grep shutdown

# 10. Check systemd unit failures
systemctl --failed
```

### Useful Log Analysis Commands

```bash
# Count occurrences per minute
journalctl -u nginx --since "1 hour ago" -o short | cut -c1-16 | sort | uniq -c | sort -rn | head -10

# Extract IP addresses from access logs
grep -oE "\b[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\b" /var/log/nginx/access.log | sort | uniq -c | sort -rn | head -10

# Find most common error messages
journalctl -p err --since "24 hours ago" -o cat | sort | uniq -c | sort -rn | head -10

# Real-time monitoring
journalctl -f -p err
```

### Using grep with Logs

```bash
# Case-insensitive search
grep -i "error" /var/log/syslog

# Show context (lines before and after)
grep -B 5 -A 5 "OOM" /var/log/syslog

# Search all log files recursively
grep -r "Failed password" /var/log/

# Count matches
grep -c "Failed password" /var/log/auth.log

# Inverted match (everything except)
grep -v "informational" /var/log/syslog | head -20
```

---

## 🔍 Section 9: Log Security and Compliance

### Protecting Log Integrity

```bash
# 1. Restrict log access
sudo chmod 640 /var/log/auth.log
sudo chown root:adm /var/log/auth.log

# 2. Immutable logs (append-only attribute)
sudo chattr +a /var/log/auth.log
# Now even root can only APPEND — no editing or deleting

# 3. Send logs to remote server (can't modify after sending)

# 4. Use journald's forward-secure sealing (Seal=yes)
# This cryptographically signs journal entries
```

### Log Retention Policies

```bash
# Common retention periods:
# - PCI DSS: 1 year
# - HIPAA: 6 years
# - SOX: 7 years
# - GDPR: as needed (right to be forgotten)

# Configure retention in logrotate
# /etc/logrotate.d/rsyslog
rotate 52    # Keep 52 weeks (1 year)
compress
```

### Log Monitoring (Alerting)

```bash
# Simple approach: grep and mail
# In a cron job:
* * * * * grep -c "Failed password" /var/log/auth.log | \
          awk '{if($1>10) system("echo \"SSH attack detected\" | mail -s \"Alert\" admin@example.com")}'

# Better: use a proper monitoring tool
# - fail2ban (brute force detection)
# - logwatch (daily log summary)
# - audispd (real-time audit events)
```

---

## 🧠 Deep Understanding — How Logging Really Works

### The Path of a Log Message

```
Application (e.g., sshd)
    ↓
Calls syslog() or sd_journal_print()
    ↓
journald receives the message
    ↓
Adds metadata: PID, UID, timestamp, boot_id, source file, etc.
    ↓
Stores in /run/log/journal/ (or /var/log/journal/)
    ↓
rsyslog reads from journald (imjournal module)
    ↓
rsyslog applies rules (/etc/rsyslog.conf, /etc/rsyslog.d/)
    ↓
Writes to text files in /var/log/
```

### Forward-Secure Sealing

journald can cryptographically sign journal entries:

```bash
# In journald.conf:
Seal=yes
```

This creates a hash chain where:
- Each entry is linked to the previous entry
- Tampering with any entry breaks the chain
- You can detect if logs were modified after creation

### Log Rate Limiting

journald prevents log flooding:

```bash
# Default: 1000 messages per 30 seconds per service
# After limit: messages are dropped (logged as "suppressed")

# Check if rate limiting is happening:
journalctl -u nginx | grep -i "suppressed\|rate limit"

# Adjust in /etc/systemd/journald.conf:
RateLimitIntervalSec=30s
RateLimitBurst=10000  # Increase burst limit
```

### Why `/var/log/syslog` Still Exists

Many tools and sysadmins still depend on traditional log files:
- grep-based log analysis
- Legacy monitoring tools
- SIEM (Security Information and Event Management) systems
- Compliance requirements (specific file paths)
- Habit and familiarity

---

## 💻 PRACTICE SECTION — 15 Hands-On Exercises

### ✅ Level 1: Basic Practices

---

### ✅ Practice 1: Explore Your Log Files

```bash
mkdir -p ~/linux-course/part14
cd ~/linux-course/part14

# List all log files
ls -la /var/log/
echo "---"

# Count lines in each log
echo "syslog lines: $(wc -l < /var/log/syslog 2>/dev/null || echo N/A)"
echo "auth.log lines: $(wc -l < /var/log/auth.log 2>/dev/null || echo N/A)"
echo "kern.log lines: $(wc -l < /var/log/kern.log 2>/dev/null || echo N/A)"

# Check log file sizes
du -sh /var/log/*.log 2>/dev/null | sort -rn | head -10
```

---

### ✅ Practice 2: Explore journalctl

```bash
cd ~/linux-course/part14

# Check journal disk usage
journalctl --disk-usage

# List all boots
journalctl --list-boots

# Current boot message count
echo "Messages in current boot: $(journalctl -b --no-pager | wc -l)"

# Previous boot message count (if available)
journalctl -b -1 --no-pager 2>/dev/null | wc -l || echo "No previous boot logs"

# Watch journal in real-time (for 3 seconds)
echo "Watch journal for 3 seconds:"
timeout 3 journalctl -f 2>/dev/null || true
```

---

### ✅ Practice 3: Filter by Service

```bash
cd ~/linux-course/part14

# Pick a running service and check its logs
for svc in cron sshd systemd-journald; do
    count=$(journalctl -u $svc -b --no-pager 2>/dev/null | wc -l)
    echo "$svc: $count lines in current boot"
done

# Show last 10 messages from cron
echo ""
echo "=== Last 5 cron messages ==="
journalctl -u cron -n 5 --no-pager
```

---

### ✅ Practice 4: Filter by Time

```bash
cd ~/linux-course/part14

# Logs since last boot (equivalent to -b)
journalctl --since "1 day ago" --no-pager | wc -l

# Logs from today
journalctl --since "today" --no-pager | wc -l

# Logs from a specific hour
journalctl --since "$(date +%Y-%m-%d) 00:00:00" --until "$(date +%Y-%m-%d) 01:00:00" --no-pager | wc -l
```

---

### ✅ Practice 5: Filter by Priority

```bash
cd ~/linux-course/part14

# Count messages by priority in current boot
echo "=== Messages by severity (current boot) ==="
for level in emerg alert crit err warning notice info debug; do
    count=$(journalctl -b -p $level --no-pager 2>/dev/null | wc -l)
    printf "%-10s %d\n" "$level" "$count"
done

# Show actual error messages
echo ""
echo "=== Errors in current boot ==="
journalctl -b -p err -o cat --no-pager | head -20
```

---

### ✅ Level 2: Intermediary Practices

---

### ✅ Practice 6: Kernel Messages

```bash
cd ~/linux-course/part14

# Kernel messages from current boot
echo "=== Kernel messages ==="
journalctl -k --no-pager | tail -20

# Kernel errors
echo ""
echo "=== Kernel errors ==="
journalctl -k -p err --no-pager | tail -10

# Check for hardware errors
echo ""
echo "=== Hardware errors ==="
journalctl -k -p err | grep -i "error\|fail\|warn" | tail -10 || echo "No hardware errors found"
```

---

### ✅ Practice 7: Track Down a Specific Event

```bash
cd ~/linux-course/part14

# Find the last sudo command executed
journalctl -u sudo -n 10 --no-pager || echo "No sudo journal available"

# Alternative: check auth.log
sudo grep "sudo" /var/log/auth.log 2>/dev/null | tail -5

# Find the last login
echo ""
echo "=== Last logins ==="
last | head -10

# Find failed logins
echo ""
echo "=== Failed logins ==="
lastb 2>/dev/null | head -10 || echo "No failed login records"
```

---

### ✅ Practice 8: Log Analysis — Find Patterns

```bash
cd ~/linux-course/part14

# Extract all IP addresses from auth.log
if [ -f /var/log/auth.log ]; then
    echo "=== IP addresses in auth.log ==="
    grep -oE "\b[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\b" /var/log/auth.log 2>/dev/null | \
        sort | uniq -c | sort -rn | head -10
fi

# Count authentication attempts over time
if [ -f /var/log/auth.log ]; then
    echo ""
    echo "=== Auth attempts by hour ==="
    grep "Failed password" /var/log/auth.log 2>/dev/null | \
        awk '{print $1, $2}' | cut -d: -f1-2 | sort | uniq -c | sort -rn | head -10
fi
```

---

### ✅ Practice 9: Watch Logs in Real-Time

```bash
cd ~/linux-course/part14

# Simulate log activity in one terminal
# (Run these commands in separate terminals or use background)

# Terminal 1: Watch journal
echo "Run this in another terminal: journalctl -f"
echo "Or run for 5 seconds:"
timeout 5 journalctl -f 2>/dev/null || true

# Generate some log entries
echo ""
echo "Generating log entries..."
logger "Test message from part14 practice"
sudo systemctl status cron > /dev/null 2>&1
```

---

### ✅ Practice 10: Test logrotate

```bash
cd ~/linux-course/part14

# Check logrotate version
logrotate --version

# View main config
echo "=== logrotate.conf ==="
cat /etc/logrotate.conf | grep -v "^$" | grep -v "^#"

# View a specific config
echo ""
echo "=== rsyslog logrotate config ==="
cat /etc/logrotate.d/rsyslog 2>/dev/null || echo "No rsyslog config"

# Dry run
echo ""
echo "=== Dry run ==="
sudo logrotate -d /etc/logrotate.conf 2>&1 | head -20
```

---

### ✅ Practice 11: Create a logrotate Config

```bash
cd ~/linux-course/part14

# Create a test log file
mkdir -p /tmp/test-logs
for i in $(seq 1 100); do
    echo "Test log entry $i $(date)" >> /tmp/test-logs/test.log
done

# Create a logrotate config for it
sudo tee /etc/logrotate.d/test-logs << 'EOF'
/tmp/test-logs/*.log {
    size 1K
    rotate 3
    compress
    missingok
    notifempty
}
EOF

# Test it
sudo logrotate -d /etc/logrotate.d/test-logs

# Force rotation
sudo logrotate -f /etc/logrotate.d/test-logs

# Check results
ls -la /tmp/test-logs/

# Clean up
sudo rm /etc/logrotate.d/test-logs
rm -rf /tmp/test-logs
```

---

### ✅ Practice 12: Forward Logs to Journal

```bash
cd ~/linux-course/part14

# Use logger to send messages to syslog/journal
logger "This is a test message from the course"

# Check it appears in journal
journalctl -n 1 --no-pager

# Send with different facilities and priorities
logger -p auth.warning "Auth warning test"
logger -p daemon.err "Daemon error test"
logger -t MYAPP "Application message"

# Check them
echo ""
echo "=== MYAPP messages ==="
journalctl -t MYAPP -n 5 --no-pager
```

---

### ✅ Level 3: Advanced Practices

---

### ✅ Practice 13: Check Boot Performance

```bash
cd ~/linux-course/part14

# Boot time
systemd-analyze

# Kernel messages at boot
echo ""
echo "=== Kernel boot messages ==="
journalctl -k -b --no-pager | head -20

# Boot chart (if systemd-analyze is available)
systemd-analyze plot > /tmp/boot-plot.svg 2>/dev/null
echo "Boot plot saved to /tmp/boot-plot.svg"
```

---

### ✅ Practice 14: Find Large Log Files

```bash
cd ~/linux-course/part14

# Find all log files larger than 10MB
echo "=== Large log files (>10MB) ==="
find /var/log -name "*.log" -type f -size +10M -exec ls -lh {} \; 2>/dev/null | sort -k5 -rh

# Check journal size
echo ""
echo "=== Journal disk usage ==="
journalctl --disk-usage

# Show total log size
echo ""
echo "=== Total log directory size ==="
du -sh /var/log/ 2>/dev/null
```

---

### ✅ Practice 15: Real SysAdmin Scenario — Log Analysis Report

```bash
cd ~/linux-course/part14

cat > log_analysis_report.sh << 'EOF'
#!/bin/bash
set -euo pipefail

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
HOSTNAME=$(hostname)
REPORT="log_analysis_report.txt"

echo "============================================" > "$REPORT"
echo "  LOG ANALYSIS REPORT" >> "$REPORT"
echo "  Hostname: $HOSTNAME" >> "$REPORT"
echo "  Date:     $TIMESTAMP" >> "$REPORT"
echo "============================================" >> "$REPORT"
echo "" >> "$REPORT"

# Section 1: System Uptime and Boot
echo "1. SYSTEM UPTIME & BOOT" >> "$REPORT"
uptime >> "$REPORT"
echo "" >> "$REPORT"

# Section 2: Failed Services
echo "2. FAILED SERVICES" >> "$REPORT"
if systemctl --failed --no-legend 2>/dev/null | grep -q .; then
    systemctl --failed >> "$REPORT"
else
    echo "  No failed services. ✓" >> "$REPORT"
fi
echo "" >> "$REPORT"

# Section 3: Authentication Issues
echo "3. AUTHENTICATION ISSUES" >> "$REPORT"
echo "  Last 5 failed logins:" >> "$REPORT"
lastb 2>/dev/null | head -5 >> "$REPORT"

echo "" >> "$REPORT"
echo "  Failed sudo attempts:" >> "$REPORT"
journalctl -u sudo -p warning --since "7 days ago" --no-pager 2>/dev/null | head -10 >> "$REPORT" || echo "  No sudo logs found" >> "$REPORT"
echo "" >> "$REPORT"

# Section 4: Disk Space
echo "4. DISK SPACE" >> "$REPORT"
df -h / >> "$REPORT"
echo "" >> "$REPORT"

# Section 5: Log Volume by Service
echo "5. TOP LOG PRODUCERS (by journal lines)" >> "$REPORT"
for unit in $(journalctl -b --no-pager -o json 2>/dev/null | head -1 | wc -l); do true; done
# Simpler approach:
for svc in sshd cron nginx apache2 NetworkManager kernel; do
    count=$(journalctl -u $svc -b --no-pager 2>/dev/null | wc -l)
    if [ "$count" -gt 0 ]; then
        printf "  %-20s %d lines\n" "$svc" "$count" >> "$REPORT"
    fi
done
echo "" >> "$REPORT"

# Section 6: Journal Health
echo "6. JOURNAL HEALTH" >> "$REPORT"
journalctl --verify 2>&1 | tail -3 >> "$REPORT"
echo "" >> "$REPORT"

# Section 7: Recent Errors
echo "7. RECENT SYSTEM ERRORS (last 24h)" >> "$REPORT"
journalctl -p err --since "24 hours ago" --no-pager -o cat 2>/dev/null | sort | uniq -c | sort -rn | head -10 >> "$REPORT"
echo "" >> "$REPORT"

echo "============================================" >> "$REPORT"
echo "  END OF REPORT" >> "$REPORT"
echo "============================================" >> "$REPORT"

cat "$REPORT"
EOF

chmod +x log_analysis_report.sh
./log_analysis_report.sh
```

---

## 📋 Summary — Complete Command Reference for Part 14

### Level 1: Basic Commands — journalctl and Log Files

**journalctl**

| Command | Action |
|---------|--------|
| `journalctl` | All logs (current boot) |
| `journalctl -b` | Current boot |
| `journalctl -b -1` | Previous boot |
| `journalctl --list-boots` | List all boots |
| `journalctl -u NAME` | Specific service |
| `journalctl -f` | Follow (tail -f) |
| `journalctl -n N` | Last N lines |
| `journalctl --since TIME` | Filter by start time |
| `journalctl --until TIME` | Filter by end time |
| `journalctl -p PRIORITY` | Filter by priority |
| `journalctl -k` | Kernel messages |
| `journalctl --disk-usage` | Show disk usage |
| `journalctl --verify` | Verify journal integrity |

**Log Files**

| File | Purpose |
|------|---------|
| `/var/log/syslog` | General system log |
| `/var/log/auth.log` | Authentication log |
| `/var/log/kern.log` | Kernel log |
| `/var/log/dmesg` | Kernel ring buffer |

### Level 2: Intermediary Commands — rsyslog and logrotate

**rsyslog**

| Command | Action |
|---------|--------|
| `cat /etc/rsyslog.conf` | View configuration |
| `sudo systemctl restart rsyslog` | Restart rsyslog |
| `sudo rsyslogd -N1` | Test config syntax |

**logrotate**

| Command | Action |
|---------|--------|
| `cat /etc/logrotate.conf` | View global config |
| `ls /etc/logrotate.d/` | List per-service configs |
| `sudo logrotate -d FILE` | Dry run |
| `sudo logrotate -f FILE` | Force rotation |

### Level 3: Advanced Commands (See troubleshooting and centralized logging sections above — no additional commands)

---

## 🚀 What's Coming in Part 15

**Part 15: SSH and Remote Access — Secure Remote Administration**

You will learn:
- SSH server configuration (sshd_config)
- SSH key-based authentication (passwordless login)
- SCP, rsync, and SFTP for file transfers
- SSH tunneling and port forwarding
- SSH config file for client-side shortcuts
- Hardening SSH against attacks
- 15 hands-on practices

---

## 📝 Self-Test — Can You Answer These?

1. What are the two main logging systems on modern Linux?
2. How do you view logs for a specific systemd service?
3. What command shows logs from the previous boot?
4. What is the difference between `journalctl -u nginx -p err` and `journalctl -u nginx | grep -i error`?
5. What facility and severity would you use to log an auth failure?
6. What is the purpose of logrotate?
7. What does `rotate 4` mean in logrotate.conf?
8. How do you make journald logs persistent across reboots?
9. What does `postrotate` in a logrotate config do?
10. How do you test a logrotate configuration without actually rotating?
11. What format argument makes journalctl output JSON?
12. What is the path to the authentication log file?
13. How do you send a test message to syslog/journal?
14. What is forward-secure sealing in journald?
15. How do you forward logs from one server to another?

**Score:** 12/15 correct = ready for Part 15.

---

*Linux SysAdmin Course | Part 14 of ∞ | Reverse Engineering Approach*
*Previous → Part 13: Scheduling Tasks — cron, at, systemd timers*
*Next → Part 15: SSH and Remote Access*

[← Previous](part13.md) | [Next →](part15.md)
