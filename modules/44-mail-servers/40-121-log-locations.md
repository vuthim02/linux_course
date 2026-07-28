## 12.1 Log Locations

```bash
# Primary log
/var/log/mail.log

# Errors only
/var/log/mail.err

# Follow in real time
sudo tail -f /var/log/mail.log
```

### Log Configuration

```bash
# /etc/postfix/main.cf
maillog_file = /var/log/mail.log     # modern: file-based logging
# OR
maillog_command = /usr/bin/logger     # syslog-based (older)
```

### Useful Log Searches

```bash
# Find all messages from a specific sender
grep 'from=<sender@example.com>' /var/log/mail.log

# Find all failed deliveries (bounces)
grep 'status=bounced' /var/log/mail.log

# Find all messages for a specific recipient
grep 'to=<recipient@example.org>' /var/log/mail.log

# Find messages in the last hour
grep "$(date -d '1 hour ago' '+%b %d %H')" /var/log/mail.log
```


[← Previous](39-114-queue-lifecycle-monitoring.md) | [↑ Index](index.md) | [Next →](41-122-interpreting-log-entries.md)
