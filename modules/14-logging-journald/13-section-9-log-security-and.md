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



---

[← Previous](12-section-8-analyzing-logs-for.md) | [↑ Index](index.md) | [Next →](14-deep-understanding-how-logging-really.md)
