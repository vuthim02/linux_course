## 👑 Level 4: Mastery — Real-World Logging Scenarios

### Scenario 1: Security Incident Investigation

```bash
# You detect unusual SSH activity. Investigate with journal + auditd.

# Step 1: Check recent SSH logins
journalctl -u sshd --since "24 hours ago" | grep "Accepted"

# Step 2: Investigate a specific user
journalctl -u sshd | grep "bob" | grep "Accepted"
ausearch -ui bob -ts yesterday -i | grep ssh

# Step 3: Track what the user did after login
ausearch -ua 1001 -sc execve -ts today | grep -o 'exe="[^"]*"' | sort | uniq -c

# Step 4: Check for privilege escalation
ausearch -sc setuid -ts today -i

# Step 5: Generate a report
aureport --login --summary -i
ausearch -m USER_LOGIN --failed -ts this-week | aureport -f -i
```

### Scenario 2: Centralized Log Server with TLS

```bash
# SERVER (log receiver)
# /etc/rsyslog.conf — enable TCP with TLS
module(load="imtcp")
module(load="imtls")
input(type="imtls" port="6514" TLS="on")
# TLS certs in /etc/rsyslog.d/tls/
# Server cert, key, and CA

$template RemoteLogs,"/var/log/remote/%HOSTNAME%/%PROGRAMNAME%.log"
*.* ?RemoteLogs

# CLIENT (log forwarder)
# /etc/rsyslog.d/tls-forward.conf
$DefaultNetstreamDriver gtls
$DefaultNetstreamDriverCAFile /etc/rsyslog.d/tls/ca.pem
$DefaultNetstreamDriverCertFile /etc/rsyslog.d/tls/cert.pem
$DefaultNetstreamDriverKeyFile /etc/rsyslog.d/tls/key.pem
*.* @@logserver.example.com:6514

# Test the connection
logger -n logserver.example.com -P 6514 "TLS test message"
```

### Scenario 3: Production Log Management

```bash
# Goal: manage 3 web servers with centralized logging, rotation, and alerting.

# Step 1: Configure journald for production
# /etc/systemd/journald.conf
[Journal]
Storage=persistent
SystemMaxUse=5G
SystemKeepFree=1G
MaxRetentionSec=3month
ForwardToSyslog=yes

# Step 2: logrotate config for custom app
# /etc/logrotate.d/mywebapp
/var/log/mywebapp/*.log {
    daily
    rotate 30
    compress
    delaycompress
    maxage 60
    size 100M
    missingok
    notifempty
    create 640 www-data adm
    sharedscripts
    postrotate
        systemctl reload mywebapp 2>/dev/null || true
    endscript
}

# Step 3: Send structured logs from the app
#!/bin/bash
# /usr/local/bin/log-request.sh
logger --journald <<EOF
MESSAGE=Request completed
PRIORITY=6
MYAPP_STATUS=200
MYAPP_PATH=/api/users
MYAPP_DURATION_MS=45
EOF

# Step 4: Alert on 5xx errors
journalctl -u mywebapp --since "5 min ago" | grep '"status":5[0-9][0-9]'
```

### Scenario 4: Automated Log Analysis

```bash
#!/bin/bash
# /usr/local/bin/log-audit-daily.sh — run daily via cron/systemd timer

REPORT="/tmp/daily-log-report-$(date +%Y%m%d).txt"
{
    echo "=== Daily Log Report: $(date) ==="
    echo ""
    echo "--- Failed SSH Attempts ---"
    journalctl -u sshd --since "24 hours ago" | grep -c "Failed password"
    
    echo ""
    echo "--- Sudo Usage ---"
    journalctl -u sudo --since "24 hours ago" --no-pager | \
        grep -oP 'USER=\K\S+' | sort | uniq -c
    
    echo ""
    echo "--- Disk Space Alert ---"
    df -h /var/log | awk 'NR>1 {print $5, $4}'
    
    echo ""
    echo "--- Last 10 auditd Alerts ---"
    ausearch -ts today -i 2>/dev/null | tail -20
    
    echo ""
    echo "--- journald Disk Usage ---"
    journalctl --disk-usage
    
    echo ""
    echo "--- Core Dumps ---"
    coredumpctl list --since "24 hours ago" 2>/dev/null || echo "None"
} > "$REPORT"

mail -s "Daily Log Report: $(hostname)" admin@example.com < "$REPORT"
logger -t log-audit "Daily report generated: $REPORT"
```

### Scenario 5: Debugging a Crashing Service

```bash
# Step 1: Check journal for crash
journalctl -u myapp.service --since "1 hour ago" -p err

# Step 2: Enable core dumps
ulimit -c unlimited
# Also set in /etc/security/limits.d/core.conf:
# * soft core unlimited

# Step 3: Restart and trigger the crash
sudo systemctl restart myapp.service
# (wait for crash)

# Step 4: Find and analyze the dump
coredumpctl list | grep myapp
coredumpctl info /usr/bin/myapp
coredumpctl gdb /usr/bin/myapp
# (gdb) bt
# (gdb) frame 5
# (gdb) info locals

# Step 5: Extract for developer
coredumpctl dump /usr/bin/myapp > myapp-crash.core
gzip myapp-crash.core
# Send myapp-crash.core.gz + myapp binary + debug symbols
```



[← Previous](23-section-13-coredumpctl-crash-analysis.md) | [↑ Index](index.md) | [Next →](20-rules-of-thumb.md)
