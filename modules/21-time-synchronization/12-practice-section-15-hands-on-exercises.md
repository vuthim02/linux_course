## 💻 PRACTICE SECTION — 15 Hands-On Exercises

---

### Level 1 Practices: Time Basics and timedatectl

---

### ✅ Practice 1: Check Your Current Time Settings

```bash
mkdir -p ~/linux-course/part21
cd ~/linux-course/part21

# Full timedatectl output
timedatectl

# Check system clock
echo ""
echo "System time: $(date)"
echo "UTC time:    $(date -u)"
echo "Unix epoch:  $(date +%s)"

# Check hardware clock
echo ""
echo "Hardware clock:"
sudo hwclock --show 2>/dev/null || echo "Cannot access hardware clock"
```

---

### ✅ Practice 2: Check NTP Service

```bash
cd ~/linux-course/part21

# Which NTP implementation is running?
echo "=== NTP Services ==="
systemctl is-active chrony 2>/dev/null && echo "chrony: active" || echo "chrony: inactive"
systemctl is-active systemd-timesyncd 2>/dev/null && echo "timesyncd: active" || echo "timesyncd: inactive"
systemctl is-active ntp 2>/dev/null && echo "ntpd: active" || echo "ntpd: inactive"

# Show the active service
echo ""
echo "=== Active time service ==="
systemctl list-units --type=service --state=running | grep -E "chrony|timesyncd|ntp"
```

---

### ✅ Practice 3: List and Change Timezones

```bash
cd ~/linux-course/part21

# Current timezone
echo "Current timezone: $(timedatectl | grep "Time zone")"

# List some timezones
echo ""
echo "=== Available timezones (Americas) ==="
timedatectl list-timezones | grep -i "america" | head -10

echo ""
echo "=== Available timezones (Europe) ==="
timedatectl list-timezones | grep -i "europe" | head -10

# Try a temporary timezone (as regular user, only affects this shell)
# Set TZ environment variable for this command
TZ='Asia/Tokyo' date
TZ='Europe/London' date
TZ='Australia/Sydney' date
```

---

### ✅ Practice 5: Check Time Synchronization Status

```bash
cd ~/linux-course/part21

# Is the clock synchronized?
echo "=== Synchronization status ==="
timedatectl | grep "synchronized"

# If available, check with chronyc
if command -v chronyc &>/dev/null; then
    echo ""
    echo "=== System time offset ==="
    chronyc tracking | grep "System time"
    
    echo ""
    echo "=== Leap status ==="
    chronyc tracking | grep "Leap status"
fi
```

---

### ✅ Practice 7: Manual Time Setting (Simulated)

```bash
cd ~/linux-course/part21

# Show how to set time manually (without actually doing it)
cat << 'EOF'
Setting time manually (requires disabling NTP first):

  # 1. Disable NTP
  sudo timedatectl set-ntp no
  
  # 2. Set time
  sudo timedatectl set-time "2024-01-15 10:30:00"
  
  # 3. Or set date/time components separately
  sudo timedatectl set-time "10:30:00"        # Time only
  sudo date +%T -s "10:30:00"                # Using date command
  
  # 4. Sync hardware clock
  sudo hwclock -w
  
  # 5. Re-enable NTP
  sudo timedatectl set-ntp yes

WARNING: Never set time manually on a production server if NTP is available.
Manual time setting can break authentication, logging, and scheduled tasks.
EOF
```

---

### ✅ Practice 12: Test Time with curl

```bash
cd ~/linux-course/part21

# Use HTTP headers to see server-side time
echo "=== Server-reported time ==="
curl -sI https://example.com 2>/dev/null | grep -i "date" || \
  curl -sI https://google.com 2>/dev/null | grep -i "date"

# Compare with local time
echo ""
echo "=== Compare with local time ==="
echo "Local:  $(date -u)"
echo "Server: $(curl -sI https://example.com 2>/dev/null | grep -i "date" | cut -d' ' -f2-)"
```

---

### Level 2 Practices: Chrony Configuration and Monitoring

---

### ✅ Practice 4: Explore Chrony (if installed)

```bash
cd ~/linux-course/part21

if command -v chronyc &>/dev/null; then
    echo "=== Chrony Sources ==="
    chronyc sources -v
    
    echo ""
    echo "=== Chrony Tracking ==="
    chronyc tracking
    
    echo ""
    echo "=== Chrony Activity ==="
    chronyc activity
    
    echo ""
    echo "=== Chrony Configuration ==="
    cat /etc/chrony/chrony.conf 2>/dev/null | grep -v "^#" | grep -v "^$"
else
    echo "Chrony not installed"
fi
```

---

### ✅ Practice 6: Test NTP Server Connectivity

```bash
cd ~/linux-course/part21

# Test basic connectivity to NTP servers
echo "=== Testing NTP server connectivity ==="
for server in pool.ntp.org time.google.com time.apple.com; do
    echo -n "  $server: "
    nc -zuvw2 $server 123 2>/dev/null && echo "OK" || echo "UNREACHABLE"
done

# Query NTP server (requires ntpdate or chrony)
echo ""
echo "=== Query time from pool.ntp.org ==="
if command -v ntpdate &>/dev/null; then
    ntpdate -q pool.ntp.org 2>/dev/null | head -3
elif command -v chronyc &>/dev/null; then
    chronyc sources pool.ntp.org 2>/dev/null | head -5
else
    echo "No NTP query tool available"
fi
```

---

### ✅ Practice 8: Measure Clock Drift

```bash
cd ~/linux-course/part21

# Check chrony's estimate of clock drift
if command -v chronyc &>/dev/null; then
    echo "=== Clock drift ==="
    chronyc tracking | grep -E "Frequency|Skew"
    echo ""
    echo "Frequency = how fast/slow the clock runs (ppm = parts per million)"
    echo "1 ppm = 0.0001% = ~86ms per day = ~31 seconds per year"
fi

# If no chrony, check drift over a shorter period
echo ""
echo "=== Current time vs UTC ==="
echo "System clock: $(date)"
echo "UTC:          $(date -u)"
```

---

### ✅ Practice 9: View Chrony Logs

```bash
cd ~/linux-course/part21

if command -v chronyc &>/dev/null; then
    echo "=== Chrony logs ==="
    journalctl -u chrony -n 30 --no-pager
fi

# Check for time adjustments
echo ""
echo "=== Recent time adjustments ==="
if command -v chronyc &>/dev/null; then
    journalctl -u chrony --no-pager | grep -i "step\|slew\|adjust" | tail -5
fi
```

---

### ✅ Practice 10: Compare Chrony and timesyncd Config

```bash
cd ~/linux-course/part21

# Compare configuration formats
cat << 'EOF'
=== Chrony config (/etc/chrony/chrony.conf) ===
pool 2.debian.pool.ntp.org iburst
makestep 1.0 3
rtcsync

=== timesyncd config (/etc/systemd/timesyncd.conf) ===
[Time]
NTP=0.ubuntu.pool.ntp.org 1.ubuntu.pool.ntp.org
FallbackNTP=ntp.ubuntu.com

=== Which to use? ===
- Chrony: servers, VMs, systems requiring high accuracy
- timesyncd: desktops, laptops, containers, simple setups
EOF
```

---

### ✅ Practice 11: Chrony Server Configuration (Simulated)

```bash
cd ~/linux-course/part21

# Show what a Chrony NTP server config looks like
cat << 'EOF' > chrony_server_example.conf
# Chrony configuration for NTP SERVER
# /etc/chrony/chrony.conf

# Use upstream NTP servers
pool 2.debian.pool.ntp.org iburst
pool 0.pool.ntp.org iburst

# Serve time to local network
allow 192.168.0.0/16
allow 10.0.0.0/8

# Serve time even if upstream is unavailable
local stratum 10

# Sync hardware clock
rtcsync

# Logging
logdir /var/log/chrony
log measurements statistics tracking

# Make initial step if offset > 1 sec (first 3 updates)
makestep 1.0 3

# Client configuration (from /etc/chrony/chrony.conf on client):
# server ntp.internal.example.com iburst
EOF

echo "Example Chrony server config written"
```

---

### ✅ Practice 13: RTC (Hardware Clock) Management

```bash
cd ~/linux-course/part21

# Check RTC
echo "=== RTC settings ==="
timedatectl | grep RTC

# Show RTC time
echo ""
echo "Hardware clock:"
sudo hwclock --show 2>/dev/null || echo "Cannot read hardware clock"

# Compare system and hardware time
echo ""
echo "System time:  $(date)"
echo "Hardware RTC: $(sudo hwclock --show 2>/dev/null || echo 'N/A')"
```

---

### ✅ Practice 14: Chrony Source Statistics

```bash
cd ~/linux-course/part21

if command -v chronyc &>/dev/null; then
    echo "=== Source statistics ==="
    chronyc sourcestats -v
    
    echo ""
    echo "=== NTP reachability ==="
    # The Reach column shows if server is responding
    # 377 = all 8 probes received (perfect)
    # 0 = no response in last 8 polls
    chronyc sources | awk 'NR>2 {print $1, $6}'
fi
```

---

### Level 3 Practices: Advanced Troubleshooting and Auditing

---

### ✅ Practice 15: Real SysAdmin Scenario — Time Audit Report

```bash
cd ~/linux-course/part21

cat > time_audit.sh << 'EOF'
#!/bin/bash
set -euo pipefail

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
HOSTNAME=$(hostname)
REPORT="time_audit_report.txt"

echo "============================================" > "$REPORT"
echo "  TIME SYNCHRONIZATION AUDIT REPORT" >> "$REPORT"
echo "  Hostname: $HOSTNAME" >> "$REPORT"
echo "  Date:     $TIMESTAMP" >> "$REPORT"
echo "============================================" >> "$REPORT"
echo "" >> "$REPORT"

# Section 1: Current time
echo "1. CURRENT TIME" >> "$REPORT"
echo "  Local: $(date)" >> "$REPORT"
echo "  UTC:   $(date -u)" >> "$REPORT"
echo "  Epoch: $(date +%s)" >> "$REPORT"
echo "" >> "$REPORT"

# Section 2: timedatectl output
echo "2. TIMEDATECTL STATUS" >> "$REPORT"
timedatectl | sed 's/^/  /' >> "$REPORT"
echo "" >> "$REPORT"

# Section 3: NTP service status
echo "3. NTP SERVICE" >> "$REPORT"
for svc in chrony systemd-timesyncd ntp; do
    status=$(systemctl is-active "$svc" 2>/dev/null || echo "not-found")
    echo "  $svc: $status" >> "$REPORT"
done
echo "" >> "$REPORT"

# Section 4: Chrony info (if available)
echo "4. CHRONY STATUS" >> "$REPORT"
if command -v chronyc &>/dev/null; then
    echo "  Sources:" >> "$REPORT"
    chronyc sources -v 2>/dev/null | sed 's/^/    /' >> "$REPORT"
    echo "" >> "$REPORT"
    echo "  Tracking:" >> "$REPORT"
    chronyc tracking 2>/dev/null | sed 's/^/    /' >> "$REPORT"
else
    echo "  Not installed" >> "$REPORT"
fi
echo "" >> "$REPORT"

# Section 5: Timezone
echo "5. TIMEZONE" >> "$REPORT"
echo "  $(timedatectl | grep "Time zone")" >> "$REPORT"
echo "" >> "$REPORT"

# Section 6: RTC
echo "6. HARDWARE CLOCK" >> "$REPORT"
sudo hwclock --show 2>/dev/null | sed 's/^/  /' >> "$REPORT" || echo "  Cannot read" >> "$REPORT"
echo "" >> "$REPORT"

# Section 7: Time drift
echo "7. TIME DRIFT ESTIMATE" >> "$REPORT"
if command -v chronyc &>/dev/null; then
    chronyc tracking 2>/dev/null | grep "Frequency" | sed 's/^/  /' >> "$REPORT"
    echo "  (ppm = microseconds per second)" >> "$REPORT"
fi
echo "" >> "$REPORT"

echo "============================================" >> "$REPORT"
echo "  END OF REPORT" >> "$REPORT"
echo "============================================" >> "$REPORT"

cat "$REPORT"
EOF

chmod +x time_audit.sh
./time_audit.sh
```

---



---

[← Previous](11-section-7-troubleshooting-time-sync.md) | [↑ Index](index.md) | [Next →](13-deep-understanding-how-ntp-really.md)
