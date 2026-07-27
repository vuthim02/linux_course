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



---

[← Previous](14-deep-understanding-how-logging-really.md) | [↑ Index](index.md) | [Next →](16-summary-complete-command-reference-for.md)
