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



---

[← Previous](07-section-3-rsyslog-configuration.md) | [↑ Index](index.md) | [Next →](09-section-6-log-rotation-with.md)
