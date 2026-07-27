# 🐧 Linux System Administrator — Complete Course
## Part 20 of ∞: System Updates and Patch Management

---

> **Reverse Engineering Approach:** Keeping a system updated is the single most important security practice. But updates are also the most common cause of production outages — a kernel update might break a driver, a library update might break an application. Understanding the update lifecycle, how to stage and test updates, and how to roll back when things go wrong is what separates a professional sysadmin from someone who just runs `apt upgrade` and hopes for the best.

---

## 🎯 What You Will Achieve in Part 20

This module is organized into three progressive levels:

| Level | Focus | What You'll Master |
|-------|-------|--------------------|
| ⭐ Level 1: Basic | Package Management Fundamentals | Update lifecycle, checking/applying updates, LTS vs rolling release |
| ⭐ Level 2: Intermediary | Automation and Strategy | Unattended-upgrades, production strategies, kernel updates |
| ⭐ Level 3: Advanced | Rollback and Internals | Rollback strategies, APT transactions, library compatibility |

---

## ⭐ Level 1: Basic — Package Management Fundamentals

![Linux software stack that updates affect at every layer](https://upload.wikimedia.org/wikipedia/commons/3/30/IO_stack_of_the_Linux_kernel.svg)

*Linux software stack showing the layers that updates touch (Fischer & Schönberger / Wikimedia Commons / CC-BY-SA-4.0)*

> **Level 1 Goal:** Understand where updates come from, how to check for them, how to apply them safely, and how to choose between LTS and rolling release distributions.

## 🔍 Section 1: The Update Lifecycle

### Where Updates Come From

```
Upstream Developer (e.g., Nginx team)
    └── Releases new version 1.24.0
              │
              ▼
Distribution Packager (e.g., Debian/Ubuntu maintainer)
    └── Packages it for the distribution
        └── Tests with distribution libraries
        └── Applies distribution-specific patches
        └── Signs with distribution GPG key
              │
              ▼
Distribution Repository
    └── Released to -proposed (testing)
    └── Promoted to -updates (stable)
    └── Security fixes → -security (urgent)
              │
              ▼
Your System (apt update / apt upgrade)
```

### Update Channels

| Channel | Content | Urgency |
|---------|---------|---------|
| `-security` | Critical security fixes | Install ASAP |
| `-updates` | Bug fixes, non-security improvements | Install on schedule |
| `-backports` | Newer versions from later releases | Optional |
| `-proposed` | Pre-release testing | DO NOT use in production |

### Types of Updates

| Type | Example | Risk |
|------|---------|------|
| Security patch | Fix for CVE in OpenSSL | Low (minimal code change) |
| Bug fix | Fix crash in NFS driver | Low |
| Minor version | 1.2.3 → 1.2.4 | Low |
| Major version | 1.x → 2.x | HIGH (breaking changes) |
| Kernel update | 6.1 → 6.2 | Medium (requires reboot) |
| Library update | libssl 1.1 → 3.0 | HIGH (may break apps) |

---

## 🔍 Section 2: Checking for Updates

### APT (Debian/Ubuntu)

```bash
# Update the package index
sudo apt update

# List upgradable packages
apt list --upgradable

# Count available updates
apt list --upgradable 2>/dev/null | grep -v "^Listing" | wc -l

# Show upgradable packages with more detail
apt list --upgradable 2>/dev/null

# Check if there are security updates specifically
apt list --upgradable 2>/dev/null | grep -i security || echo "No security updates"

# Show package changelog before updating
apt changelog nginx
```

### DNF (Fedora/RHEL)

```bash
# Check for updates (does NOT download them)
dnf check-update

# List available updates
dnf list updates

# Count updates
dnf check-update 2>/dev/null | wc -l

# Check for security updates
dnf updateinfo list

# Check for security updates only
dnf updateinfo list --security
```

### Keeping Track of Update History

```bash
# Debian/Ubuntu: update history
less /var/log/apt/history.log

# Fedora/RHEL
less /var/log/dnf.log

# Last update time
grep "Start-Date" /var/log/apt/history.log | tail -1
```

---

## 🔍 Section 3: Applying Updates

### Safe Update Practices

```bash
# NEVER run upgrade without first running update
sudo apt update && sudo apt upgrade -y

# ALWAYS review what will be upgraded before confirming
sudo apt upgrade
# Review the list, then type 'y' or 'n'

# For non-interactive scripts:
sudo apt update && sudo apt upgrade -y

# Full-upgrade (handles dependency changes)
sudo apt full-upgrade
# May REMOVE packages if needed to satisfy dependencies
```

### DNF Update Commands

```bash
# Update all packages
sudo dnf update

# Update specific package
sudo dnf update nginx

# Security updates only
sudo dnf update --security

# Download packages but don't install
sudo dnf update --downloadonly

# Skip broken packages
sudo dnf update --skip-broken
```

### Partial Upgrades

```bash
# Update a single package
sudo apt install --only-upgrade nginx

# Hold a package at current version
sudo apt-mark hold nginx

# Show held packages
apt-mark showhold

# Unhold
sudo apt-mark unhold nginx
```

---

## 🔍 Section 5: LTS vs Rolling Release

### LTS (Long Term Support)

| Aspect | LTS |
|--------|-----|
| Release cycle | Every 2 years (Ubuntu), 3-4 years (Debian) |
| Support period | 5-10 years |
| Package versions | Frozen at release (with backports) |
| Stability | Very high |
| New features | Rarely (mostly security + bug fixes) |
| Upgrade | Major upgrade every 2+ years |

**Examples:** Ubuntu 22.04 LTS, Debian 12, RHEL 9, Rocky 9

### Rolling Release

| Aspect | Rolling |
|--------|---------|
| Release cycle | Continuous |
| Support period | Always current |
| Package versions | Always latest |
| Stability | Lower (bleeding edge) |
| New features | Constantly |
| Upgrade | Never (always up to date) |

**Examples:** Arch Linux, openSUSE Tumbleweed

### Which to Choose?

| Use Case | Recommendation |
|----------|---------------|
| Production servers | LTS |
| Desktop (stable) | LTS |
| Desktop (latest hardware) | Rolling |
| Development/Testing | Either |
| Embedded/IoT | LTS |
| Containers | LTS |

### The Hybrid Approach

```bash
# Use LTS base, but pull specific packages from backports
# Example: Install newer kernel on Ubuntu LTS
sudo apt install -t jammy-backports linux-image-6.2

# Or enable specific PPAs for newer versions of specific software
sudo add-apt-repository ppa:deadsnakes/ppa
sudo apt install python3.12
```

---

## ⭐ Level 2: Intermediary — Automation and Strategy

![Simplified Linux kernel structure — update automation affects every subsystem](https://upload.wikimedia.org/wikipedia/commons/2/26/Simplified_Structure_of_the_Linux_Kernel.svg)

*Simplified Linux kernel structure showing subsystems affected by automated updates (ScotXW / Wikimedia Commons / CC-BY-SA-4.0)*

> **Level 2 Goal:** Configure unattended-upgrades for automatic security patching, implement production update strategies, and manage kernel updates safely.

## 🔍 Section 4: Unattended-Upgrades

Automatic security updates for Debian/Ubuntu.

### Installation and Configuration

```bash
# Install
sudo apt install unattended-upgrades apt-listchanges

# Configuration file
sudo dpkg-reconfigure --priority=low unattended-upgrades

# Or edit the config directly:
sudo cat /etc/apt/apt.conf.d/50unattended-upgrades
```

### Configuration Options

```
// Enable security updates
Unattended-Upgrade::Allowed-Origins {
    "${distro_id}:${distro_codename}-security";
//  "${distro_id}:${distro_codename}-updates";
//  "${distro_id}:${distro_codename}-proposed";
};

// Auto-fix broken packages
Unattended-Upgrade::AutoFixInterruptedDpkg "true";

// Clean unused dependencies
Unattended-Upgrade::Remove-Unused-Dependencies "true";

// Automatically reboot if needed (for kernel updates)
Unattended-Upgrade::Automatic-Reboot "true";
Unattended-Upgrade::Automatic-Reboot-Time "03:00";

// Send email on errors
Unattended-Upgrade::Mail "admin@example.com";
```

### Checking Unattended-Upgrade Status

```bash
# Check the log
less /var/log/unattended-upgrades/unattended-upgrades.log

# Simulate a run (dry-run)
sudo unattended-upgrades --dry-run --debug

# Check if it's running
systemctl status unattended-upgrades
```

### DNF Automatic (Fedora/RHEL)

```bash
# Install
sudo dnf install dnf-automatic

# Configure
sudo cat /etc/dnf/automatic.conf

# Enable timer
sudo systemctl enable --now dnf-automatic.timer

# Check status
systemctl status dnf-automatic.timer
```

---

## 🔍 Section 6: Update Strategies for Production

### Staged Rollout

```
Development Server
    ↓ (test updates)
Staging Server
    ↓ (validate with real workloads)
Production Server 1 (canary)
    ↓ (monitor for 24h)
Production Server 2-10
    ↓ (monitor for 48h)
All remaining servers
```

### Maintenance Windows

```bash
# Standard practice:
# - Schedule updates during low-traffic periods
# - 2 AM Sunday is common
# - Communicate with stakeholders
# - Have a rollback plan BEFORE starting

# For critical infrastructure:
# - Blue/green deployment (switch traffic to updated server)
# - Canary deployment (5% traffic to updated server)
# - Full deployment after validation
```

### Pre-Update Checklist

```bash
# 1. Check what will be updated
apt list --upgradable > pre-update-inventory.txt

# 2. Check if reboot is needed (kernel update)
# Check if kernel will be updated
apt list --upgradable 2>/dev/null | grep "^linux-image"

# 3. Check disk space
df -h

# 4. Take a snapshot (VM) or backup critical data

# 5. Have a rollback plan
```

### Post-Update Checklist

```bash
# 1. Verify services are running
systemctl --failed

# 2. Check for errors in logs
journalctl -p err --since "10 minutes ago"

# 3. Run critical application tests

# 4. If rebooted, verify system comes up clean
systemd-analyze
systemctl --failed

# 5. Document what was updated and why
```

---

## 🔍 Section 7: Kernel Updates

Kernel updates are the most impactful type of update.

### Checking Kernel Version

```bash
# Current kernel
uname -r

# Installed kernels
dpkg -l | grep linux-image
# OR
rpm -qa | grep kernel

# Available kernel updates
apt list --upgradable 2>/dev/null | grep "^linux-image"
```

### Kernel Update Process

```bash
# 1. Install new kernel (alongside old one)
sudo apt install linux-image-6.2.0-25-generic

# 2. Update GRUB (automatically done)
sudo update-grub

# 3. Reboot
sudo reboot

# 4. Verify new kernel
uname -r
```

### Managing Multiple Kernels

```bash
# List all installed kernels
dpkg -l | grep linux-image | awk '{print $2}'

# Keep at least 2 kernels (current + one fallback)
# Remove old kernels (automatic)
sudo apt autoremove --purge

# Manually remove old kernel
sudo apt purge linux-image-5.15.0-92-generic

# On Fedora/RHEL:
dnf list installed kernel
sudo dnf remove kernel-5.14.0-362
```

### Why Keep Old Kernels?

```bash
# If new kernel fails to boot:
# 1. Reboot
# 2. Hold Shift (BIOS) or Esc (UEFI) during boot
# 3. Select "Advanced options" in GRUB
# 4. Boot the previous kernel
# 5. Remove or hold the broken kernel
```

---

## ⭐ Level 3: Advanced — Rollback and Internals

![Linux kernel map — understanding the deep internals of updates](https://upload.wikimedia.org/wikipedia/commons/1/1c/Linux_kernel_diagram.svg)

*Linux kernel architecture diagram — the foundation that updates modify (Kuzux / Wikimedia Commons / CC-BY-SA-2.5)*

> **Level 3 Goal:** Master rollback strategies for failed updates, understand APT and DNF transaction internals, and manage filesystem-level snapshots for recovery.

## 🔍 Section 8: Rollback Strategies

### APT Rollback

```bash
# APT does NOT have a built-in rollback command
# Strategies:

# 1. Reinstall previous version from cache
ls /var/cache/apt/archives/nginx*.deb
sudo dpkg -i /var/cache/apt/archives/nginx_1.18.0-0ubuntu1_amd64.deb

# 2. Use apt log to see previous versions
grep "Upgrade" /var/log/apt/history.log | tail -5

# 3. Pin a package to a specific version
sudo apt-mark hold nginx
sudo apt install nginx=1.18.0-0ubuntu1

# 4. Use snapshot/backup (if available)
# VM snapshot restore
```

### DNF Rollback

```bash
# DNF has better rollback support

# View transaction history
dnf history

# Rollback a specific transaction
sudo dnf history undo 42

# Rollback to a specific date
sudo dnf history rollback 2024-01-15

# View what a rollback would do
dnf history undo 42 --dry-run

# Example:
# dnf history
# ID  Command line                    Date/time       Action
# 42  update nginx                    2024-01-15 14:22 Install/Upgrade
# 41  install httpd                   2024-01-14 10:00 Install

# Rollback transaction 42
sudo dnf history undo 42
# This removes the upgraded nginx and reinstalls the previous version
```

### Kernel Rollback

```bash
# 1. Reboot and select old kernel in GRUB

# 2. Once booted, remove the new kernel
sudo apt purge linux-image-6.2.0-25-generic
sudo update-grub

# 3. Hold kernel to prevent re-installation
sudo apt-mark hold linux-image-6.2.0-25-generic

# 4. Reboot again to verify
```

### Filesystem Snapshots (Advanced)

```bash
# Using LVM snapshots:
# Before update:
sudo lvcreate -L 5G -s -n root_snap /dev/vg/root

# If update fails:
sudo lvconvert --merge /dev/vg/root_snap
sudo reboot

# Using ZFS/btrfs snapshots:
# ZFS:
zfs snapshot -r rpool/ROOT@pre-update-2024-01-15
# Rollback:
zfs rollback -r rpool/ROOT@pre-update-2024-01-15
```

---

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

## 🧠 Deep Understanding — How Updates Work

### The APT Transaction

```
apt upgrade (or apt-get upgrade):
1. Reads /var/lib/dpkg/status (installed packages database)
2. Downloads new Packages.gz from repositories
3. Compares versions
4. Builds list of packages to upgrade
5. Calculates dependency changes
6. Downloads .deb files to /var/cache/apt/archives/
7. Verifies checksums and GPG signatures
8. Runs dpkg on each .deb in dependency order
9. Runs post-installation scripts
10. Updates /var/lib/dpkg/status
```

### Why Reboot After Kernel Update?

```
Old kernel loaded in memory:
  ┌────────────────────┐
  │ Running kernel 6.1 │  ← Active, can't be replaced while running
  └────────────────────┘

New kernel installed to disk:
  /boot/vmlinuz-6.2     ← Available on disk

GRUB configured to boot new kernel:
  /boot/grub/grub.cfg  ← Updated to include both kernels

On reboot:
  GRUB menu → select kernel 6.2 → loads new kernel
  Old kernel still available as fallback
```

### Library Compatibility

```
APR (Application Binary Interface):
When a shared library (libssl.so.3) is updated:
- Old programs linked against libssl.so.1.1 continue to work
- New programs use the new library

SONAME (Shared Object Name):
libssl.so.3  (major version 3)
libssl.so.1.1  (major version 1.1)

Breaking change: when major version changes (1.1 → 3)
  - Old programs may need recompilation
  - Both versions can be installed simultaneously
  - Each program uses the version it was linked against
```

---

## 📋 Summary — Complete Command Reference for Part 20

### Level 1: Basic Commands — Checking and Applying Updates

| Command | Action |
|---------|--------|
| `sudo apt update` | Update package index |
| `apt list --upgradable` | List upgradable packages |
| `dnf check-update` | Check for updates |
| `dnf updateinfo list --security` | List security updates |
| `sudo apt upgrade` | Upgrade all packages |
| `sudo apt full-upgrade` | Upgrade with dep changes |
| `sudo dnf update` | Update all packages |
| `sudo apt install --only-upgrade PKG` | Upgrade single package |

### Level 2: Intermediary Commands — Holds, Pins, and Automation

| Command | Action |
|---------|--------|
| `sudo apt-mark hold PKG` | Prevent upgrade |
| `sudo apt-mark unhold PKG` | Allow upgrade |
| `apt-mark showhold` | Show held packages |
| `apt-cache policy PKG` | Show version info |
| `less /var/log/unattended-upgrades/` | Auto-update logs |

### Level 3: Advanced Commands — History and Rollback

| Command | Action |
|---------|--------|
| `less /var/log/apt/history.log` | APT history |
| `dnf history` | DNF transaction history |
| `sudo dnf history undo ID` | Rollback transaction |

---

## 🚀 What's Coming in Part 21

**Part 21: Time Synchronization — NTP and Chrony**

You will learn:
- Why accurate time is critical for servers
- The NTP protocol and how it works
- Chrony — the modern NTP implementation
- Setting up NTP clients and servers
- Troubleshooting time synchronization issues
- 15 hands-on practices

---

## 📝 Self-Test — Can You Answer These?

1. What is the difference between `apt update` and `apt upgrade`?
2. What is the purpose of `unattended-upgrades`?
3. What does `apt-mark hold nginx` do?
4. Why should you always check what will be upgraded before confirming?
5. What three update channels does Ubuntu provide?
6. Why are kernel updates especially impactful?
7. How do you check if a reboot is required after updates?
8. How does DNF's rollback (`dnf history undo`) work?
9. What is the difference between LTS and rolling release?
10. How do you see what changed in a package before upgrading?
11. What is the purpose of `full-upgrade` vs `upgrade`?
12. Why should you always keep at least one old kernel?
13. How do you check disk space before an update?
14. What is package pinning and when would you use it?
15. How do security updates reach your system from upstream developers?

**Score:** 12/15 correct = ready for Part 21.

---

*Linux SysAdmin Course | Part 20 of ∞ | Reverse Engineering Approach*
*Previous → Part 19: Software Repositories and PPAs*
*Next → Part 21: Time Synchronization — NTP and Chrony*

[← Previous](part19.md) | [Next →](part21.md)
