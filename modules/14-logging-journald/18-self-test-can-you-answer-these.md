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


## Answer Key

### Q1: What are the two main logging systems on modern Linux?
**Answer:** syslog/rsyslog (traditional file-based logging) and journald/systemd-journald (structured binary journal).

### Q2: How do you view logs for a specific systemd service?
**Answer:** `journalctl -u service-name` — filters logs by unit name.

### Q3: What command shows logs from the previous boot?
**Answer:** `journalctl -b -1` — shows journal entries from the previous boot.

### Q4: What is the difference between `journalctl -u nginx -p err` and `grep -i error`?
**Answer:** `-p err` uses journald's priority filter (efficient, indexed). `grep` does text matching on all output (slower, less precise).

### Q5: What facility and severity would you use to log an auth failure?
**Answer:** Facility `auth` (or `authpriv`), severity `warning` or `crit`. E.g., `auth.warning` or `auth.crit`.

### Q6: What is the purpose of logrotate?
**Answer:** Automatically rotates, compresses, and cleans up old log files to prevent disk space exhaustion.

### Q7: What does `rotate 4` mean in logrotate.conf?
**Answer:** Keep 4 rotated (archived) log files before deleting the oldest one.

### Q8: How do you make journald logs persistent across reboots?
**Answer:** Create `/var/log/journal/` directory and ensure `Storage=persistent` is set in `/etc/systemd/journald.conf`, then restart journald.

### Q9: What does `postrotate` in a logrotate config do?
**Answer:** A script section that runs after log rotation — typically used to restart or signal the service to reopen its log files.

### Q10: How do you test a logrotate configuration without actually rotating?
**Answer:** `logrotate -d /etc/logrotate.d/config` — performs a dry run showing what would happen.

### Q11: What format argument makes journalctl output JSON?
**Answer:** `journalctl -o json` or `journalctl -o json-pretty` — outputs each entry as a JSON object.

### Q12: What is the path to the authentication log file?
**Answer:** `/var/log/auth.log` (Debian/Ubuntu) or `/var/log/secure` (RHEL/CentOS).

### Q13: How do you send a test message to syslog/journal?
**Answer:** `logger "test message"` — writes to syslog/journald. Check with `journalctl -t test`.

### Q14: What is forward-secure sealing in journald?
**Answer:** A feature that cryptographically signs journal files periodically, preventing tampering. If an attacker gets access, they can't modify past sealed entries.

### Q15: How do you forward logs from one server to another?
**Answer:** Configure rsyslog with `action(type="omfwd" target="remote-server")` or use `RemoteSyslog` in journald.conf to forward to a central log server.


[← Previous](17-whats-coming-in-part-15.md) | [↑ Index](index.md) | [Next →](19-section-10-logwatch-and-syslog-ng.md)
