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





[← Previous](11-section-7-centralized-logging.md) | [↑ Index](index.md) | [Next →](13-section-9-log-security-and.md)
