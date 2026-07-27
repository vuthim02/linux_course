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



---

[← Previous](13-section-9-log-security-and.md) | [↑ Index](index.md) | [Next →](15-practice-section-15-hands-on-exercises.md)
