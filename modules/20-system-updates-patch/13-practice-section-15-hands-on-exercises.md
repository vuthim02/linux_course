## 💻 PRACTICE SECTION — 15 Hands-On Exercises

---

### Level 1 Practices: Package Management Basics

---

### ✅ Practice 1: Check Current System State

```bash
mkdir -p ~/linux-course/part20
cd ~/linux-course/part20

# Current kernel
echo "Kernel: $(uname -r)"

# Distribution info
cat /etc/os-release | head -3

# Uptime (how long since last boot = since last kernel update)
echo "Uptime: $(uptime -p)"

# Last update time
echo ""
echo "=== Last apt update ==="
if [ -f /var/log/apt/history.log ]; then
    grep "Start-Date" /var/log/apt/history.log | tail -3
fi
```

---

### ✅ Practice 2: Check Available Updates

```bash
cd ~/linux-course/part20

# Update package list
sudo apt update 2>/dev/null || sudo dnf makecache 2>/dev/null

# List upgradable packages
if command -v apt &>/dev/null; then
    apt list --upgradable 2>/dev/null
elif command -v dnf &>/dev/null; then
    dnf list updates 2>/dev/null
fi

# Count them
echo ""
echo "=== Update count ==="
if command -v apt &>/dev/null; then
    apt list --upgradable 2>/dev/null | grep -v "^Listing" | wc -l | \
      awk '{print $1 " updates available"}'
fi
```

---

### ✅ Practice 3: Check if Reboot Is Required

```bash
cd ~/linux-course/part20

# Check if a reboot is needed (Ubuntu)
if [ -f /var/run/reboot-required ]; then
    echo "REBOOT REQUIRED"
    cat /var/run/reboot-required
else
    echo "No reboot required"
fi

# Alternative: check if new kernel is installed but not booted
INSTALLED_KERNELS=$(ls /boot/vmlinuz-* 2>/dev/null | sort -V | tail -1)
RUNNING_KERNEL="/boot/vmlinuz-$(uname -r)"
if [ "$INSTALLED_KERNELS" != "$RUNNING_KERNEL" ]; then
    echo ""
    echo "Note: Newer kernel installed but not running"
    echo "  Running: $RUNNING_KERNEL"
    echo "  Latest:  $INSTALLED_KERNELS"
    echo "  Reboot to use the new kernel"
fi
```

---

### ✅ Practice 4: Hold and Unhold Packages

```bash
cd ~/linux-course/part20

# Check if any packages are held
echo "=== Currently held packages ==="
apt-mark showhold 2>/dev/null || echo "None held"

# Hold a test package (use a safe one — nano)
echo ""
echo "Holding nano..."
sudo apt-mark hold nano 2>/dev/null
apt-mark showhold

# Unhold
echo ""
echo "Unholding nano..."
sudo apt-mark unhold nano 2>/dev/null
apt-mark showhold
```

---

### ✅ Practice 5: Simulate an Upgrade

```bash
cd ~/linux-course/part20

# Show what WOULD happen without doing it
if command -v apt &>/dev/null; then
    echo "=== Simulated upgrade (apt) ==="
    apt upgrade --dry-run 2>/dev/null | head -30
elif command -v dnf &>/dev/null; then
    echo "=== Simulated upgrade (dnf) ==="
    dnf update --assumeno 2>/dev/null | head -30
fi
```

---

### ✅ Practice 6: Check Update History

```bash
cd ~/linux-course/part20

if [ -f /var/log/apt/history.log ]; then
    echo "=== APT History Log ==="
    echo "Last 5 upgrade events:"
    grep -B1 "End-Date\|Start-Date\|Commandline" /var/log/apt/history.log | \
      grep -v "^--" | tail -15
elif [ -f /var/log/dnf.log ]; then
    echo "=== DNF History ==="
    sudo dnf history | head -10
fi
```

---

### ✅ Practice 8: View Package Changelog

```bash
cd ~/linux-course/part20

# See what changed in a package
echo "=== Changelog for bash ==="
if command -v apt &>/dev/null; then
    apt changelog bash 2>/dev/null | head -30
elif command -v dnf &>/dev/null; then
    dnf changelog bash 2>/dev/null | head -30
fi
```

---

### ✅ Practice 10: Check Disk Space for Updates

```bash
cd ~/linux-course/part20

# Updates require free space (especially kernel updates)
echo "=== Disk space critical areas ==="
df -h / /boot /var

# Check /boot space (critical for kernel updates)
echo ""
echo "=== /boot contents ==="
ls -lh /boot/ | head -10
echo ""
du -sh /boot/

# APT cache size
echo ""
echo "=== APT cache size ==="
du -sh /var/cache/apt/archives/ 2>/dev/null || echo "N/A"
```

---

### ✅ Practice 14: Compare Installed vs Available Versions

```bash
cd ~/linux-course/part20

# Show current and available versions of key packages
echo "=== Package version comparison ==="
for pkg in bash openssl nginx sshd; do
    installed=""
    available=""
    
    if command -v apt &>/dev/null; then
        installed=$(dpkg -l $pkg 2>/dev/null | awk '/^ii/ {print $3}')
        available=$(apt list --upgradable 2>/dev/null | grep "^$pkg/" | awk -F' ' '{print $2}')
    elif command -v rpm &>/dev/null; then
        installed=$(rpm -q $pkg 2>/dev/null)
        available=$(dnf list updates $pkg 2>/dev/null | grep "$pkg" | awk '{print $2}')
    fi
    
    if [ -n "$installed" ]; then
        if [ -n "$available" ]; then
            echo "  $pkg: installed=$installed → available=$available"
        else
            echo "  $pkg: installed=$installed (up to date)"
        fi
    fi
done
```

---

### Level 2 Practices: Automation and Strategy

---

### ✅ Practice 7: Check Kernel Update Status

```bash
cd ~/linux-course/part20

# List installed kernels
echo "=== Installed kernels ==="
if command -v dpkg &>/dev/null; then
    dpkg -l | grep linux-image | awk '{print $2, $3}'
elif command -v rpm &>/dev/null; then
    rpm -qa | grep "^kernel-" | sort
fi

# Check available kernel updates
echo ""
echo "=== Available kernel updates ==="
if command -v apt &>/dev/null; then
    apt list --upgradable 2>/dev/null | grep "^linux-image" || echo "None"
elif command -v dnf &>/dev/null; then
    dnf list updates kernel 2>/dev/null || echo "None"
fi
```

---

### ✅ Practice 9: Configure Unattended-Upgrades (Simulated)

```bash
cd ~/linux-course/part20

# Check if unattended-upgrades is installed
if command -v unattended-upgrades &>/dev/null; then
    echo "unattended-upgrades is installed"
    echo "Config file: /etc/apt/apt.conf.d/50unattended-upgrades"
    echo ""
    echo "=== Current config ==="
    sudo cat /etc/apt/apt.conf.d/50unattended-upgrades 2>/dev/null | \
      grep -v "^//" | grep -v "^$" | head -20
else
    echo "unattended-upgrades is NOT installed"
    echo ""
    echo "Would install with:"
    echo "  sudo apt install unattended-upgrades"
    echo ""
    echo "Would edit:"
    echo "  sudo dpkg-reconfigure unattended-upgrades"
fi
```

---

### ✅ Practice 12: Understand Package Pinning

```bash
cd ~/linux-course/part20

# Show APT pinning
cat << 'EOF'
APT pinning allows you to:
- Prefer packages from one repo over another
- Hold packages at specific versions
- Mix repos with different versions

Example: Prefer backports for specific packages:
  # /etc/apt/preferences.d/backports
  Package: *
  Pin: release n=jammy-backports
  Pin-Priority: 100

  # Give high priority to specific packages from backports
  Package: linux-image-generic
  Pin: release n=jammy-backports
  Pin-Priority: 500

Check current pinning:
  apt-cache policy package_name
EOF
```

---

### ✅ Practice 13: Plan a Maintenance Window

```bash
cd ~/linux-course/part20

# Create a maintenance plan template
cat > maintenance_plan_template.txt << 'EOF'
========================================
  SYSTEM UPDATE MAINTENANCE PLAN
========================================

Date: YYYY-MM-DD
Time: 02:00 - 04:00 (off-peak)
System: [HOSTNAME]
Type: [Security | Routine | Major]

PRE-UPDATE:
  [ ] Verify backups
  [ ] Take VM snapshot / LVM snapshot
  [ ] Check disk space (df -h)
  [ ] Check running services
  [ ] Review available updates (apt list --upgradable)
  [ ] Notify stakeholders

UPDATE:
  [ ] sudo apt update
  [ ] sudo apt upgrade
  [ ] Check for kernel update
  [ ] Reboot if needed

POST-UPDATE:
  [ ] Verify services (systemctl --failed)
  [ ] Check logs (journalctl -p err)
  [ ] Run application tests
  [ ] Verify from user perspective
  [ ] Document what was updated

ROLLBACK PLAN:
  [ ] Reboot to old kernel (if kernel issue)
  [ ] Restore VM snapshot
  [ ] Reinstall previous package versions
EOF

echo "Maintenance plan template created"
```

---

### ✅ Practice 15: Real SysAdmin Scenario — Update Report

```bash
cd ~/linux-course/part20

cat > update_report.sh << 'EOF'
#!/bin/bash
set -euo pipefail

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
HOSTNAME=$(hostname)
REPORT="update_report.txt"

echo "============================================" > "$REPORT"
echo "  SYSTEM UPDATE STATUS REPORT" >> "$REPORT"
echo "  Hostname: $HOSTNAME" >> "$REPORT"
echo "  Date:     $TIMESTAMP" >> "$REPORT"
echo "============================================" >> "$REPORT"
echo "" >> "$REPORT"

# Section 1: System info
echo "1. SYSTEM INFORMATION" >> "$REPORT"
echo "  Kernel: $(uname -r)" >> "$REPORT"
echo "  Uptime: $(uptime -p)" >> "$REPORT"
cat /etc/os-release | head -3 >> "$REPORT"
echo "" >> "$REPORT"

# Section 2: Available updates
echo "2. AVAILABLE UPDATES" >> "$REPORT"
if command -v apt &>/dev/null; then
    count=$(apt list --upgradable 2>/dev/null | grep -v "^Listing" | wc -l)
    echo "  Total updates available: $count" >> "$REPORT"
    echo "" >> "$REPORT"
    echo "  Security updates:" >> "$REPORT"
    apt list --upgradable 2>/dev/null | grep -i security | head -10 >> "$REPORT" || echo "  None" >> "$REPORT"
    echo "" >> "$REPORT"
    echo "  Kernel updates:" >> "$REPORT"
    apt list --upgradable 2>/dev/null | grep "^linux-image" >> "$REPORT" || echo "  None" >> "$REPORT"
fi
echo "" >> "$REPORT"

# Section 3: Reboot status
echo "3. REBOOT STATUS" >> "$REPORT"
if [ -f /var/run/reboot-required ]; then
    echo "  REBOOT REQUIRED" >> "$REPORT"
    cat /var/run/reboot-required >> "$REPORT"
else
    echo "  No reboot required" >> "$REPORT"
fi
echo "" >> "$REPORT"

# Section 4: Held packages
echo "4. HELD PACKAGES" >> "$REPORT"
held=$(apt-mark showhold 2>/dev/null)
if [ -n "$held" ]; then
    echo "$held" | sed 's/^/  /' >> "$REPORT"
else
    echo "  None" >> "$REPORT"
fi
echo "" >> "$REPORT"

# Section 5: Last update
echo "5. LAST UPDATE" >> "$REPORT"
if [ -f /var/log/apt/history.log ]; then
    tail -5 /var/log/apt/history.log >> "$REPORT"
fi
echo "" >> "$REPORT"

# Section 6: Available disk space
echo "6. DISK SPACE FOR UPDATES" >> "$REPORT"
df -h / /boot /var | awk 'NR>1 {printf "  %s: %s free\n", $1, $4}' >> "$REPORT"
echo "" >> "$REPORT"

# Section 7: Failed services
echo "7. SERVICE HEALTH" >> "$REPORT"
failed=$(systemctl --failed --no-legend 2>/dev/null | wc -l)
echo "  Failed services: $failed" >> "$REPORT"
echo "" >> "$REPORT"

echo "============================================" >> "$REPORT"
echo "  END OF REPORT" >> "$REPORT"
echo "============================================" >> "$REPORT"

cat "$REPORT"
EOF

chmod +x update_report.sh
./update_report.sh
```

---

### Level 3 Practices: Rollback and Recovery

---

### ✅ Practice 11: Learn DNF History Rollback

```bash
cd ~/linux-course/part20

# Only on DNF systems
if command -v dnf &>/dev/null; then
    echo "=== DNF transaction history ==="
    sudo dnf history | head -10
    
    echo ""
    echo "To rollback transaction 42:"
    echo "  sudo dnf history undo 42"
    echo ""
    echo "To rollback to a specific state:"
    echo "  sudo dnf history rollback TRANSACTION_ID"
else
    echo "DNF not available — but here's how rollback works:"
    cat << 'EOF'
DNF keeps a transaction log:
  /var/lib/dnf/history.sqlite

Each transaction has an ID.
You can undo any transaction:
  sudo dnf history undo 42

This reverses the changes of transaction 42.
It will install the previous version of any upgraded packages.
EOF
fi
```

---



---

[← Previous](12-section-8-rollback-strategies.md) | [↑ Index](index.md) | [Next →](14-deep-understanding-how-updates-work.md)
