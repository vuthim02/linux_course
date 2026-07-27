## 🔍 Section 7: Journald — systemd's Logging System

journald is the logging component of systemd. It replaces syslog with a structured, binary log format.

### Basic journalctl Usage

```bash
# View all logs (from most recent boot)
journalctl

# Follow new log entries (like tail -f)
journalctl -f

# Show last N lines
journalctl -n 50

# Logs from current boot only
journalctl -b

# Logs from previous boot
journalctl -b -1

# Logs from a specific service
journalctl -u nginx

# Logs from multiple services
journalctl -u nginx -u sshd

# Logs since a specific time
journalctl --since "2024-01-15 10:00:00"
journalctl --since "1 hour ago"
journalctl --since yesterday

# Logs until a time
journalctl --until "2024-01-15 12:00:00"
```

### Filtering by Priority

```bash
# Emergency (0) through Debug (7)
journalctl -p err          # Errors and worse
journalctl -p warning      # Warnings and worse
journalctl -p info         # Info and worse (default)

# Only errors from nginx
journalctl -u nginx -p err
```

### Output Formats

```bash
# JSON output
journalctl -u nginx -o json

# Short (default, one line per entry)
journalctl -u nginx -o short

# Verbose (all fields)
journalctl -u nginx -o verbose

# With no pager (pipe to file)
journalctl -u nginx --no-pager
```

### Journal Size and Persistence

```bash
# Check journal disk usage
journalctl --disk-usage

# Show journal settings
systemctl show systemd-journald

# Limit journal size (in /etc/systemd/journald.conf):
# SystemMaxUse=500M
# MaxRetentionSec=1month
```

By default, journald stores logs in memory (`/run/log/journal`). To make logs persistent:

```bash
sudo mkdir -p /var/log/journal
sudo systemctl restart systemd-journald
```

---



---

[← Previous](09-section-6-targets-the-modern.md) | [↑ Index](index.md) | [Next →](11-section-8-analyzing-boot-performance.md)
