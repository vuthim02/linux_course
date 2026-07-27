## 💻 PRACTICE SECTION — 15 Hands-On Exercises

### ✅ Level 1: Basic Practices

---

### ✅ Practice 1: Explore Your Init System

```bash
mkdir -p ~/linux-course/part12
cd ~/linux-course/part12

# Confirm systemd is your init system
ls -l /sbin/init
cat /proc/1/comm

# Check systemd version
systemctl --version

# How long did boot take?
systemd-analyze
```

---

### ✅ Practice 2: Service Status Deep Dive

```bash
# Pick a running service (sshd, cron, NetworkManager, etc.)
systemctl status cron

# Answer these questions:
# - Is it enabled? (starts at boot?)
# - Is it active? (running right now?)
# - What is the Main PID?
# - How long has it been running?
# - What resources is it using?

# Save the output
systemctl status cron > service_status.txt
```

---

### ✅ Practice 3: Start, Stop, Restart

```bash
# Create a simple test service using cron (safe to experiment with)
sudo systemctl stop cron
systemctl status cron    # Should show inactive

sudo systemctl start cron
systemctl status cron    # Should show active

sudo systemctl restart cron
systemctl status cron    # Should show active again

# Always leave it running
sudo systemctl enable --now cron
```

---

### ✅ Practice 4: Enable and Disable

```bash
# Check if cron is enabled
systemctl is-enabled cron

# Disable it (won't start on next boot)
sudo systemctl disable cron
systemctl is-enabled cron

# Re-enable it
sudo systemctl enable cron
systemctl is-enabled cron
```

---

### ✅ Level 2: Intermediary Practices

---

### ✅ Practice 5: List All Services

```bash
# Count all services
echo "Total service units:"
systemctl list-unit-files --type=service | wc -l

# Count running services
echo "Running services:"
systemctl list-units --type=service --state=running | grep -c running

# Count failed services
echo "Failed services:"
systemctl list-units --type=service --state=failed | grep -c failed

# List all enabled services
systemctl list-unit-files --type=service --state=enabled | head -30
```

---

### ✅ Practice 6: Create a Custom Service

```bash
cd ~/linux-course/part12

# Step 1: Create the script
cat > hello-daemon.sh << 'EOF'
#!/bin/bash
while true; do
    echo "[$(date)] Hello from systemd service"
    sleep 30
done
EOF

chmod +x hello-daemon.sh
sudo cp hello-daemon.sh /usr/local/bin/

# Step 2: Create service file
sudo tee /etc/systemd/system/hello-daemon.service << 'EOF'
[Unit]
Description=Hello Daemon - Learning systemd

[Service]
Type=simple
ExecStart=/usr/local/bin/hello-daemon.sh
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Step 3: Reload systemd
sudo systemctl daemon-reload

# Step 4: Start it
sudo systemctl start hello-daemon
systemctl status hello-daemon

# Step 5: Check the logs
journalctl -u hello-daemon -n 5
```

---

### ✅ Practice 7: Enable/Disable Your Custom Service

```bash
# Enable it to start at boot
sudo systemctl enable hello-daemon
systemctl is-enabled hello-daemon

# Reboot note: Ideally we'd reboot, but for now:
# Just verify it's enabled
systemctl list-unit-files | grep hello
```

---

### ✅ Practice 8: Stop and Remove the Service

```bash
# Stop it
sudo systemctl stop hello-daemon
systemctl status hello-daemon

# Disable it
sudo systemctl disable hello-daemon

# Remove the service file
sudo rm /etc/systemd/system/hello-daemon.service
sudo systemctl daemon-reload

# Remove the script
sudo rm /usr/local/bin/hello-daemon.sh
```

---

### ✅ Practice 9: Explore Targets

```bash
# Current default target
systemctl get-default

# List all targets
systemctl list-units --type=target

# What does multi-user.target require?
systemctl list-dependencies multi-user.target | head -20

# What does graphical.target require?
systemctl list-dependencies graphical.target | head -20

# See the difference (graphical adds display manager)
```

---

### ✅ Practice 10: Journalctl Deep Dive

```bash
# Check journal size and limits
journalctl --disk-usage

# Is journal persistent?
ls -la /var/log/journal/ 2>/dev/null || echo "Journal is NOT persistent"

# Show messages from current boot
journalctl -b --no-pager | wc -l

# Show kernel messages
journalctl -k --no-pager | head -20

# Show messages from the cron service
journalctl -u cron -n 10

# Follow logs for a few seconds
timeout 3 journalctl -f || true
```

---

### ✅ Practice 11: Filter Journal by Time and Priority

```bash
# Errors from today
journalctl --since "00:00:00" -p err --no-pager | head -20

# Warnings from last hour
journalctl --since "1 hour ago" -p warning --no-pager | head -20

# All journal entries for a specific PID
# (pick a PID from systemctl status cron)
systemctl status cron | grep "Main PID"
PID=$(systemctl status cron | grep "Main PID" | awk '{print $3}')
journalctl _PID=$PID -n 10 --no-pager
```

---

### ✅ Practice 12: Boot Analysis

```bash
# Time breakdown
systemd-analyze

# Which services take longest?
systemd-analyze blame | head -15

# Critical chain (dependency path)
systemd-analyze critical-chain

# Generate a plot (if you have a display)
systemd-analyze plot > boot_plot.svg 2>/dev/null
ls -la boot_plot.svg
```

---

### ✅ Practice 13: Create a systemd Timer

```bash
cd ~/linux-course/part12

# Step 1: Create the service (what to run)
sudo tee /etc/systemd/system/hello-timer.service << 'EOF'
[Unit]
Description=Hello Timer Service

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'echo "Timer ran at $(date)" | systemd-cat -t hello-timer'
EOF

# Step 2: Create the timer (when to run)
sudo tee /etc/systemd/system/hello-timer.timer << 'EOF'
[Unit]
Description=Run hello every minute

[Timer]
OnCalendar=*-*-* *:*:00
Persistent=true

[Install]
WantedBy=timers.target
EOF

# Step 3: Enable and start
sudo systemctl daemon-reload
sudo systemctl enable --now hello-timer.timer

# Step 4: Check it
systemctl list-timers --all | grep hello
sleep 70

# Step 5: Check the log
journalctl -t hello-timer -n 5

# Step 6: Disable and remove
sudo systemctl disable --now hello-timer.timer
sudo rm /etc/systemd/system/hello-timer.*
sudo systemctl daemon-reload
```

---

### ✅ Level 3: Advanced Practices

---

### ✅ Practice 14: Investigate Service Dependencies

```bash
# What does NetworkManager depend on?
systemctl list-dependencies NetworkManager

# What depends on network.target?
systemctl list-dependencies --reverse network.target

# What depends on multi-user.target?
systemctl list-dependencies --reverse multi-user.target | head -20
```

---

### ✅ Practice 15: Real SysAdmin Scenario — Service Health Check

```bash
cd ~/linux-course/part12

cat > service_health_check.sh << 'EOF'
#!/bin/bash
set -euo pipefail

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
HOSTNAME=$(hostname)
REPORT="service_health_report.txt"

echo "============================================" > "$REPORT"
echo "  SERVICE HEALTH CHECK REPORT" >> "$REPORT"
echo "  Hostname: $HOSTNAME" >> "$REPORT"
echo "  Date:     $TIMESTAMP" >> "$REPORT"
echo "============================================" >> "$REPORT"
echo "" >> "$REPORT"

# Check failed services
echo "[*] Checking for failed services..." >> "$REPORT"
FAILED=$(systemctl --failed --no-legend 2>/dev/null | wc -l)
if [ "$FAILED" -eq 0 ]; then
    echo "  No failed services found. ✓" >> "$REPORT"
else
    echo "  WARNING: $FAILED failed service(s) found!" >> "$REPORT"
    systemctl --failed --no-legend >> "$REPORT"
fi
echo "" >> "$REPORT"

# List critical services and their status
echo "[*] Critical service status:" >> "$REPORT"
for svc in sshd cron nginx apache2 httpd NetworkManager systemd-journald; do
    STATUS=$(systemctl is-active "$svc" 2>/dev/null || echo "not-found")
    ENABLED=$(systemctl is-enabled "$svc" 2>/dev/null || echo "not-found")
    printf "  %-35s Active: %-12s Enabled: %s\n" "$svc" "$STATUS" "$ENABLED" >> "$REPORT"
done
echo "" >> "$REPORT"

# Boot time
echo "[*] Boot performance:" >> "$REPORT"
systemd-analyze 2>/dev/null >> "$REPORT"
echo "" >> "$REPORT"

# Slowest services
echo "[*] Slowest services at boot:" >> "$REPORT"
systemd-analyze blame 2>/dev/null | head -10 >> "$REPORT"
echo "" >> "$REPORT"

# Journal disk usage
echo "[*] Journal disk usage:" >> "$REPORT"
journalctl --disk-usage 2>/dev/null >> "$REPORT"
echo "" >> "$REPORT"

echo "============================================" >> "$REPORT"
echo "  END OF REPORT" >> "$REPORT"
echo "============================================" >> "$REPORT"

cat "$REPORT"
EOF

chmod +x service_health_check.sh
./service_health_check.sh
```

---



---

[← Previous](17-deep-understanding-how-systemd-really.md) | [↑ Index](index.md) | [Next →](19-summary-complete-command-reference-for.md)
