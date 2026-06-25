# 🐧 Linux System Administrator — Complete Course
## Part 25 of ∞: System Rescue and Recovery — When Things Go Wrong

---

> **Reverse Engineering Approach:** Every sysadmin faces the moment — the server won't boot, the root password is lost, a filesystem is corrupt, or GRUB shows a rescue prompt. In that moment, knowing how to recover is what separates a professional from someone who reinstalls. This part teaches you the tools and techniques to bring a broken system back to life.

---

## 🎯 What You Will Achieve in Part 25

| Level | Focus | Skills Gained |
|-------|-------|--------------|
| **⭐ Level 1: Basic** | Rescue Mode Concepts & Boot Options | Understand single-user, rescue, and emergency modes; know the boot process flow |
| **⭐ Level 2: Intermediary** | Recovery Techniques & Tools | Reset lost root passwords, repair filesystems with fsck, fix GRUB, use Live USB and chroot |
| **⭐ Level 3: Advanced** | Boot Internals & Kernel Recovery | Master initramfs mechanics, kernel panic scenarios, boot process debugging, and deep recovery planning |

Complete **15 hands-on practices** across all levels.

---

## ⭐ Level 1: Basic — Understanding Rescue Modes and Boot Concepts

![Linux Rescue Mode](https://upload.wikimedia.org/wikipedia/commons/thumb/3/35/Tux.svg/200px-Tux.svg.png)  
*The Linux penguin — your guide through recovery. Image credit: Wikimedia Commons.*

> **Level 1 Goal:** Understand single-user mode, rescue mode, and emergency mode. Know when and how to boot into each one.

## 🔍 Section 1: Recovery Boot Modes

### Single-User Mode (Rescue Target)

Single-user mode boots with minimal services — just a root shell.

```bash
# Boot into single-user mode:
# Method 1: From GRUB menu
# 1. Reboot
# 2. Press 'e' on the kernel entry in GRUB
# 3. Find the line starting with "linux" or "linux16"
# 4. Add "single" or "1" or "S" to the end of the line
# 5. Press Ctrl+X or F10 to boot

# Method 2: From command line
sudo systemctl rescue

# Method 3: Set default for next boot
sudo systemctl set-default rescue.target
sudo reboot
# Then set back: sudo systemctl set-default multi-user.target
```

### Rescue Target (systemd)

```bash
# Rescue = single-user mode with basic filesystem mounted
sudo systemctl rescue

# This brings you to:
# - Root filesystem mounted (read-write)
# - Basic kernel modules loaded
# - No network services
# - Root shell prompt
```

### Emergency Target

```bash
# Emergency = only a root shell, root fs read-only
sudo systemctl emergency

# Or from GRUB: add "emergency" to kernel command line

# This is the most minimal environment:
# - Root fs mounted read-only
# - Nothing else
# - Only what's built into the kernel works
```

### Differences

| Mode | Root FS | Services | Network | Use Case |
|------|---------|----------|---------|----------|
| Emergency | Read-only | None | No | Last resort, root fs repair |
| Rescue | Read-write | Basic | No | Password reset, config fix |
| Multi-user | Read-write | All non-GUI | Yes | Normal operation |
| Graphical | Read-write | All | Yes | Normal with GUI |

---

## ⭐ Level 2: Intermediary — Password Reset, Filesystem Repair, and System Recovery

![GRUB Bootloader Screen](https://upload.wikimedia.org/wikipedia/commons/thumb/0/0b/GRUB_screenshot.png/220px-GRUB_screenshot.png)  
*The GRUB bootloader — your gateway to recovery. Image credit: Wikimedia Commons.*

> **Level 2 Goal:** Reset a lost root password, repair corrupted filesystems, recover a broken GRUB installation, use a Live CD/USB environment, and perform chroot-based repairs. Handle common boot failures with confidence.

## 🔍 Section 2: Resetting a Lost Root Password

### Method 1: From GRUB (init=/bin/bash)

```bash
# 1. Reboot
# 2. Press 'e' on the kernel in GRUB
# 3. Find the "linux" line
# 4. Change: ro quiet splash
#    To:     rw init=/bin/bash
# 5. Press Ctrl+X to boot
# 6. You get a root shell (no password needed)

# Once booted:
# mount -o remount,rw /
# passwd
# (enter new password)
# exec /sbin/init
# Or: reboot -f
```

### Method 2: From GRUB (single mode with rd.break)

```bash
# For systems with SELinux/AppArmor:
# 1. Press 'e' in GRUB
# 2. Find "linux" line
# 3. Add at the end: rd.break enforcing=0
# 4. Ctrl+X to boot
# 5. Remount filesystem:
#    mount -o remount,rw /sysroot
#    chroot /sysroot
#    passwd
#    touch /.autorelabel
#    exit
#    reboot
```

### Method 3: Using a Live USB

```bash
# 1. Boot from a Live USB (Ubuntu installer, SystemRescue, etc.)
# 2. Open a terminal
# 3. Find the root partition:
#    lsblk
#    fdisk -l
# 4. Mount it:
#    sudo mount /dev/sda1 /mnt
# 5. chroot:
#    sudo chroot /mnt
# 6. Reset password:
#    passwd
# 7. Exit and reboot:
#    exit
#    sudo umount /mnt
#    sudo reboot
```

---

## 🔍 Section 3: Filesystem Repair (fsck)

### When to Use fsck

```bash
# Symptoms of filesystem corruption:
# - System won't boot (dropped to emergency mode)
# - "I/O error" or "Structure needs cleaning" in logs
# - Sudden power loss or improper shutdown
# - Filesystem mounts as read-only automatically
```

### Checking and Repairing Filesystems

```bash
# Check filesystem for errors (DO NOT run on mounted fs)
sudo fsck /dev/sda1

# Force check even if filesystem seems clean
sudo fsck -f /dev/sda1

# Automatically repair without asking
sudo fsck -y /dev/sda1

# Show what would be repaired without doing it
sudo fsck -n /dev/sda1

# Check all filesystems in /etc/fstab
sudo fsck -A

# Skip check on mounted filesystems (use for non-root)
sudo fsck -M /dev/sda1
```

### fsck on the Root Filesystem

```bash
# Root fs cannot be fsck'd while running
# Method 1: Force on next boot
sudo touch /forcefsck
sudo reboot

# Method 2: Add fsck.mode=force to kernel command line in GRUB:
# linux ... fsck.mode=force

# Method 3: Boot from Live USB and check from there
sudo fsck -y /dev/sda1
```

### Understanding fsck Exit Codes

| Code | Meaning |
|------|---------|
| 0 | No errors |
| 1 | Errors corrected |
| 2 | System should be rebooted |
| 4 | Errors left uncorrected |
| 8 | Operational error |
| 16 | Usage/syntax error |
| 32 | fsck interrupted |
| 128 | Shared library error |

### Checking Disk Health (SMART)

```bash
# Check if SMART is available
sudo smartctl -i /dev/sda

# Run a short test
sudo smartctl -t short /dev/sda

# Run a long test (takes hours)
sudo smartctl -t long /dev/sda

# Check test results
sudo smartctl -l selftest /dev/sda

# Overall health
sudo smartctl -H /dev/sda
```

---

## 🔍 Section 4: GRUB Recovery

### The GRUB Rescue Shell

```
When GRUB cannot find its configuration or modules, you get:

    GRUB loading...
    Welcome to GRUB!
    error: no such partition
    Entering rescue mode...
    grub rescue>
```

### GRUB Rescue Commands

```bash
# In the grub rescue shell:

# List available drives
ls

# Look for the boot partition
ls (hd0,msdos1)/
ls (hd0,gpt1)/

# Find the kernel and initrd
ls (hd0,msdos1)/boot/
ls (hd0,msdos1)/boot/grub/

# Set root and prefix
set root=(hd0,msdos1)
set prefix=(hd0,msdos1)/boot/grub

# Load normal module
insmod normal
normal

# Or manually boot:
insmod linux
linux /boot/vmlinuz-6.1.0 root=/dev/sda1
initrd /boot/initrd.img-6.1.0
boot
```

### Reinstalling GRUB

```bash
# From a Live USB:
# 1. Boot from Live USB
# 2. Mount root partition:
sudo mount /dev/sda1 /mnt

# 3. Mount boot partition (if separate):
sudo mount /dev/sda2 /mnt/boot

# 4. Mount virtual filesystems:
sudo mount --bind /dev /mnt/dev
sudo mount --bind /proc /mnt/proc
sudo mount --bind /sys /mnt/sys

# 5. chroot:
sudo chroot /mnt

# 6. Reinstall GRUB (BIOS):
grub-install /dev/sda

# 7. Or for UEFI:
grub-install --target=x86_64-efi --efi-directory=/boot/efi

# 8. Update GRUB config:
update-grub

# 9. Exit and reboot:
exit
sudo umount -R /mnt
sudo reboot
```

### GRUB Configuration Issues

```bash
# If GRUB menu is hidden or wrong:
# Edit /etc/default/grub:

GRUB_TIMEOUT=5           # Show menu for 5 seconds
GRUB_TIMEOUT_STYLE=menu  # Always show menu (not hidden)
GRUB_CMDLINE_LINUX=""    # Kernel parameters

# After editing:
sudo update-grub
```

---

## 🔍 Section 5: Using a Live CD/USB

### Choosing a Rescue Environment

| Tool | Best For |
|------|----------|
| Ubuntu Live USB | General recovery, familiar environment |
| SystemRescue | Advanced recovery tools |
| GParted Live | Partition management |
| Super GRUB Disk | Bootloader repair |
| Hiren's Boot CD | Windows/Linux recovery |

### Essential Live USB Commands

```bash
# After booting Live USB, identify the system:
sudo fdisk -l
lsblk
blkid

# Check what's on a partition:
sudo mount /dev/sda1 /mnt
ls /mnt

# Mount the real root:
sudo mount /dev/sda1 /mnt

# Mount boot (if separate):
sudo mount /dev/sda2 /mnt/boot

# Mount efi (for UEFI):
sudo mount /dev/sda3 /mnt/boot/efi

# Bind virtual filesystems:
for dir in /dev /proc /sys /run; do
    sudo mount --bind "$dir" "/mnt$dir"
done

# chroot into the system:
sudo chroot /mnt
```

### Data Recovery from Live USB

```bash
# Copy important data before attempting repairs:
sudo mount /dev/sda1 /mnt
sudo cp -a /mnt/home /media/usb-backup/

# Or use rsync to network:
sudo rsync -av /mnt/home/ user@server:/backup/

# If filesystem is badly damaged:
sudo ddrescue /dev/sda /dev/sdb /tmp/ddrescue.log
```

---

## 🔍 Section 6: chroot — Repair a System from Inside

### What chroot Does

chroot changes the root directory for a process. It lets you run commands "inside" a broken system from a live environment.

```bash
# chroot changes / to a different directory
# Everything inside sees the "new" root

# Real root: /mnt (where you mounted the broken system)
# chroot /mnt → /mnt becomes /
# Now "passwd" modifies /mnt/etc/shadow, not the live system's
```

### Complete chroot Recovery

```bash
# Step-by-step chroot recovery:

# 1. Boot from Live USB
# 2. Find root partition:
lsblk

# 3. Mount root:
sudo mount /dev/sda1 /mnt

# 4. Mount boot if separate:
sudo mount /dev/sda2 /mnt/boot

# 5. Mount EFI if UEFI:
sudo mount /dev/sda3 /mnt/boot/efi

# 6. Bind virtual filesystems:
sudo mount --bind /dev /mnt/dev
sudo mount --bind /dev/pts /mnt/dev/pts
sudo mount --bind /proc /mnt/proc
sudo mount --bind /sys /mnt/sys
sudo mount --bind /run /mnt/run

# 7. Copy DNS info (for network in chroot):
sudo cp /etc/resolv.conf /mnt/etc/resolv.conf

# 8. chroot:
sudo chroot /mnt /bin/bash

# 9. Now you're INSIDE the broken system:
#    - Reset passwords
#    - Reinstall packages
#    - Fix configuration files
#    - Reinstall GRUB
#    - Run update-grub
#    - etc.

# 10. Exit and clean up:
exit
sudo umount -R /mnt
sudo reboot
```

### What You Can Do From chroot

```bash
# Inside chroot, you can:

# Fix package manager
apt update
apt install -f
apt upgrade

# Reset password
passwd root

# Reinstall bootloader
grub-install /dev/sda
update-grub

# Fix network config
systemctl enable --now NetworkManager

# Rebuild initramfs
update-initramfs -u -k all

# Fix SELinux contexts
touch /.autorelabel

# Remove broken packages
apt remove --purge broken-package

# Fix systemd
systemctl enable essential-services
```

---

## 🔍 Section 7: Specific Recovery Scenarios

### Scenario 1: System Won't Boot (Filesystem Issue)

```bash
# Symptoms:
# - "Kernel panic - not syncing: VFS: Unable to mount root fs"
# - "fsck: /dev/sda1: UNEXPECTED INCONSISTENCY"

# Recovery:
# 1. Boot from Live USB
# 2. Run fsck:
sudo fsck -y /dev/sda1

# 3. If fsck fails, try more aggressive:
sudo fsck -y -c /dev/sda1    # -c = bad blocks scan

# 4. If hardware failure (bad sectors):
sudo ddrescue -d /dev/sda /dev/sdb /tmp/rescue.log
# Then work on the copy
```

### Scenario 2: Kernel Panic

```bash
# Symptoms:
# - "Kernel panic - not syncing: Attempted to kill init!"
# - System halts with kernel error

# Recovery:
# 1. Reboot and select OLD kernel in GRUB (Advanced options)
# 2. If old kernel works:
#    - Check kernel modules
#    - Reinstall current kernel
#    - Check for hardware issues

# 3. If no old kernel available:
#    - Boot from Live USB
#    - chroot
#    - Reinstall kernel:
#      apt install --reinstall linux-image-$(uname -r)
#      update-initramfs -u -k all
#      update-grub
```

### Scenario 3: Missing init or initramfs

```bash
# Symptoms:
# - "ERROR: device '/dev/sda1' not found. Skipping fsck."
# - "Gave up waiting for root device."
# - Dropped to initramfs shell

# Recovery from initramfs shell:
# 1. Check available devices:
ls /dev/sd*
cat /proc/partitions

# 2. Manually mount root:
mount /dev/sda1 /root

# 3. Exit — boot should continue:
exit

# Permanent fix:
# 1. Boot from Live USB
# 2. chroot
# 3. Update initramfs:
sudo update-initramfs -u -k all
# 4. Update GRUB:
sudo update-grub
```

### Scenario 4: "Operating System Not Found"

```bash
# Symptoms:
# - "No bootable device"
# - "Operating system not found"

# Possible causes:
# 1. BIOS boot order changed
# 2. GRUB not installed or corrupted
# 3. Boot partition deleted or corrupted

# Recovery:
# 1. Check BIOS boot order
# 2. Boot from Live USB
# 3. Reinstall GRUB (see Section 4)
# 4. If UEFI:
#    - Check EFI partition: sudo mount /dev/sdaX /mnt/boot/efi
#    - Reinstall GRUB: sudo grub-install --target=x86_64-efi
```

### Scenario 5: Non-Bootable After Update

```bash
# Symptoms:
# - System was working, broke after update
# - Usually: kernel update, GRUB update, or library update

# Recovery:
# 1. Boot old kernel from GRUB (Advanced options)
# 2. If that works:
#    - Check what was updated: grep "Upgrade" /var/log/apt/history.log
#    - Roll back problem package
#    - Or: fix the broken dependency

# 3. If kernel update caused it:
#    - Remove new kernel: apt purge linux-image-NEW
#    - Hold it: apt-mark hold linux-image-NEW

# 4. If GRUB update caused it:
#    - Boot from Super GRUB disk or Live USB
#    - Reinstall GRUB
```

---

## 💻 PRACTICE SECTION — 15 Hands-On Exercises

---

### 📘 Level 1 Practices: Rescue Mode Basics and Boot Inspection

These practices help you explore recovery boot targets, GRUB configuration, and basic filesystem checks without modifying your system.

### ✅ Practice 1: Explore System Rescue Modes

```bash
mkdir -p ~/linux-course/part25
cd ~/linux-course/part25

# Learn about rescue targets
echo "=== Available rescue targets ==="
systemctl list-units --type=target | grep -E "rescue|emergency"

# Check current default target
echo ""
echo "Current default target: $(systemctl get-default)"

# Show rescue service
echo ""
echo "=== Rescue service ==="
systemctl cat rescue.target 2>/dev/null | head -20 || echo "Not available"
```

---

### ✅ Practice 2: Check GRUB Configuration

```bash
cd ~/linux-course/part25

# View GRUB config
echo "=== Kernel command line ==="
grep GRUB_CMDLINE_LINUX /etc/default/grub

# Show timeout
echo ""
echo "=== GRUB timeout ==="
grep GRUB_TIMEOUT /etc/default/grub

# Show all kernel entries in GRUB
echo ""
echo "=== GRUB config ==="
cat /etc/default/grub | grep -v "^#" | grep -v "^$"
```

---

### ✅ Practice 3: Check Filesystem for Errors

```bash
cd ~/linux-course/part25

# Check filesystems (read-only, no repair)
echo "=== Checking root filesystem ==="
sudo tune2fs -l /dev/sda1 2>/dev/null | head -5 || echo "Cannot read /dev/sda1"
sudo dumpe2fs -h /dev/sda1 2>/dev/null | grep -E "Filesystem state|Mount count" || \
  echo "Cannot check filesystem"

# Check mount count (when fsck will run next)
echo ""
echo "=== Root filesystem info ==="
sudo dumpe2fs -h /dev/sda1 2>/dev/null | grep -i "mount\|check\|count\|interval" || \
  echo "Not available"
```

---

### ✅ Practice 4: Force Filesystem Check on Next Boot

```bash
cd ~/linux-course/part25

# Show how to force fsck on next boot
cat << 'EOF'
Forcing filesystem check:

Method 1: Create /forcefsck file
  sudo touch /forcefsck
  sudo reboot
  # After check, the file is deleted automatically

Method 2: Use tune2fs
  sudo tune2fs -c 1 /dev/sda1
  # Forces check every mount (set back with -c 0)

Method 3: From GRUB (add to linux line)
  fsck.mode=force fsck.repair=yes

Method 4: From initramfs shell
  fsck -y /dev/sda1
EOF
```

---

### ✅ Practice 5: SMART Disk Health Check

---

### 📘 Level 2 Practices: GRUB Recovery, chroot, and System Repair

These practices cover intermediate recovery techniques including GRUB rescue, kernel parameter manipulation, chroot operations, and initramfs inspection.

```bash
cd ~/linux-course/part25

# Check if SMART is available
if [ -b /dev/sda ]; then
    echo "=== SMART info for /dev/sda ==="
    sudo smartctl -i /dev/sda 2>/dev/null | grep -E "Model|Serial|Device|Capacity|Protocol" || \
      echo "SMART not available for this device"
    
    echo ""
    echo "=== SMART health ==="
    sudo smartctl -H /dev/sda 2>/dev/null | grep -E "test|PASSED|health" || \
      echo "SMART health check not available"
else
    echo "No /dev/sda device found"
fi
```

---

### ✅ Practice 6: Explore GRUB Rescue Commands (Simulated)

```bash
cd ~/linux-course/part25

# Simulate GRUB rescue commands
cat << 'EOF'
GRUB rescue commands (when you see the "grub rescue>" prompt):

  ls                        — List available drives
  ls (hd0,msdos1)/          — List files on partition
  set root=(hd0,msdos1)     — Set root partition
  set prefix=(hd0,msdos1)/boot/grub  — Set GRUB directory
  insmod normal             — Load normal module
  normal                    — Start normal GRUB menu

  To boot manually:
  insmod linux
  linux /boot/vmlinuz-6.1.0 root=/dev/sda1
  initrd /boot/initrd.img-6.1.0
  boot
EOF
```

---

### ✅ Practice 7: Practice Booting with Kernel Parameters

```bash
cd ~/linux-course/part25

# Show how to add kernel parameters
cat << 'EOF'
Adding kernel parameters at boot:

1. When GRUB menu appears, press 'e' to edit
2. Find the line starting with "linux" or "linux16"
3. Go to the end of that line
4. Add parameters separated by space:

  Useful recovery parameters:
    single         — Boot to single-user mode
    emergency      — Boot to emergency mode
    init=/bin/bash — Start with bash instead of init
    systemd.unit=rescue.target — Boot to rescue target
    fsck.mode=force — Force filesystem check
    3              — Boot to runlevel 3 (multi-user)
    nomodeset      — Don't load graphics driver
    acpi=off       — Disable ACPI (for ACPI problems)
    noapic         — Disable APIC
    nolapic        — Disable local APIC

5. Press Ctrl+X or F10 to boot with these parameters
EOF
```

---

### ✅ Practice 8: chroot Simulation

```bash
cd ~/linux-course/part25

# Show the chroot process
cat << 'EOF' > chroot_guide.txt
Complete chroot recovery process:

1. Boot from Live USB
2. Identify partitions: lsblk
3. Mount root:        sudo mount /dev/sda1 /mnt
4. Mount boot:        sudo mount /dev/sda2 /mnt/boot
5. Mount EFI (UEFI):  sudo mount /dev/sda3 /mnt/boot/efi
6. Bind /dev:         sudo mount --bind /dev /mnt/dev
7. Bind /proc:        sudo mount --bind /proc /mnt/proc
8. Bind /sys:         sudo mount --bind /sys /mnt/sys
9. Bind /run:         sudo mount --bind /run /mnt/run
10. Copy DNS:         sudo cp /etc/resolv.conf /mnt/etc/resolv.conf
11. chroot:           sudo chroot /mnt /bin/bash
12. Clean up:         exit; sudo umount -R /mnt; sudo reboot
EOF

echo "chroot guide written to chroot_guide.txt"
cat chroot_guide.txt
```

---

### ✅ Practice 9: Check Initramfs

```bash
cd ~/linux-course/part25

# List initramfs files
echo "=== Initramfs files ==="
ls /boot/initrd* 2>/dev/null || ls /boot/initramfs* 2>/dev/null

# Show current initramfs
echo ""
echo "=== Current initramfs ==="
uname -r
ls -lh /boot/initrd.img-$(uname -r) 2>/dev/null || \
  ls -lh /boot/initramfs-$(uname -r).img 2>/dev/null || \
  echo "No initramfs found"

# Check contents (without extracting)
echo ""
echo "=== Initramfs contents (brief) ==="
lsinitramfs /boot/initrd.img-$(uname -r) 2>/dev/null | head -20 || \
  lsinitrd /boot/initramfs-$(uname -r).img 2>/dev/null | head -20 || \
  echo "Cannot list initramfs contents"
```

---

### ✅ Practice 10: Check Boot Partition

```bash
cd ~/linux-course/part25

# Check boot files
echo "=== /boot contents ==="
ls -lh /boot/

# Check for ALL kernel versions
echo ""
echo "=== Installed kernels ==="
dpkg -l | grep linux-image 2>/dev/null | awk '{print $2, $3}' || \
  rpm -qa | grep "^kernel-" 2>/dev/null | sort || \
  echo "No kernel packages found"

# Check disk layout
echo ""
echo "=== Disk layout ==="
lsblk 2>/dev/null | grep -E "boot|BOOT" || echo "No separate boot partition"
```

---

### ✅ Practice 11: Simulate Root Password Recovery

```bash
cd ~/linux-course/part25

# Show root password recovery methods
cat << 'EOF'
Root password recovery methods:

METHOD 1: GRUB init=/bin/bash (easiest)
  1. Press 'e' in GRUB on the kernel entry
  2. Find "linux" line, change "ro" to "rw init=/bin/bash"
  3. Ctrl+X to boot
  4. You get root shell
  5. Run: passwd
  6. Run: exec /sbin/init

METHOD 2: Single-user mode
  1. Press 'e' in GRUB
  2. Add "single" to end of "linux" line
  3. Ctrl+X to boot
  4. You get root shell
  5. Run: passwd
  6. Run: reboot

METHOD 3: Live USB + chroot
  1. Boot from Live USB
  2. Mount root partition
  3. chroot
  4. passwd
  5. Reboot
EOF
```

---

### ✅ Practice 12: System Recovery Tools Inventory

---

### 📘 Level 3 Practices: Advanced Boot Analysis and Recovery Planning

These deep-dive practices challenge you to analyze boot logs, create recovery plans, and build system recovery readiness reports.

```bash
cd ~/linux-course/part25

# Check which recovery tools are available
echo "=== Available recovery tools ==="
for tool in fsck smartctl ddrescue grub-install update-grub chroot \
            systemctl blkid lsblk fdisk gdisk testdisk; do
    if command -v $tool &>/dev/null; then
        echo "  ✓ $tool"
    else
        echo "  ✗ $tool (not installed)"
    fi
done
```

---

### ✅ Practice 13: Boot Log Analysis

```bash
cd ~/linux-course/part25

# Check previous boot log
echo "=== Previous boot messages ==="
journalctl -b -1 --no-pager 2>/dev/null | tail -30 || \
  echo "No previous boot log available"

# Check for boot errors
echo ""
echo "=== Boot errors ==="
journalctl -b -p err --no-pager 2>/dev/null | tail -20 || \
  journalctl -p err --no-pager 2>/dev/null | tail -20

# Check kernel boot messages
echo ""
echo "=== Kernel boot messages ==="
dmesg | grep -i "error\|fail\|panic" | tail -10 || echo "No kernel errors"
```

---

### ✅ Practice 14: Create a Boot Recovery USB Plan

```bash
cd ~/linux-course/part25

# Plan for creating a recovery USB
cat << 'EOF' > recovery_usb_plan.txt
RECOVERY USB PREPARATION GUIDE
===============================

Option 1: Ubuntu/Debian Live USB
  1. Download Ubuntu ISO from ubuntu.com
  2. Create bootable USB:
     sudo dd if=ubuntu.iso of=/dev/sdX bs=4M status=progress
     OR use: sudo balena-etcher
  3. Boot from USB (BIOS: F12/F2/DEL to select boot device)

Option 2: SystemRescue
  1. Download from system-rescue.org
  2. Write to USB:
     sudo dd if=systemrescue.iso of=/dev/sdX bs=4M
  3. Contains: fsck, parted, testdisk, ddrescue, networking

Option 3: Super GRUB Disk
  1. Download from supergrubdisk.org
  2. Write to USB
  3. Used specifically for bootloader repair

Option 4: Minimal recovery USB (custom)
  1. Format USB: sudo mkfs.ext4 /dev/sdX
  2. Install GRUB: sudo grub-install --removable /dev/sdX
  3. Copy SystemRescue files to USB

ALWAYS TEST your recovery USB before you need it!
EOF

echo "Recovery USB plan written to recovery_usb_plan.txt"
```

---

### ✅ Practice 15: Real SysAdmin Scenario — Recovery Plan

```bash
cd ~/linux-course/part25

cat > recovery_plan.sh << 'EOF'
#!/bin/bash
set -euo pipefail

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
HOSTNAME=$(hostname)
REPORT="recovery_readiness_report.txt"

echo "============================================" > "$REPORT"
echo "  SYSTEM RECOVERY READINESS REPORT" >> "$REPORT"
echo "  Hostname: $HOSTNAME" >> "$REPORT"
echo "  Date:     $TIMESTAMP" >> "$REPORT"
echo "============================================" >> "$REPORT"
echo "" >> "$REPORT"

# Section 1: Bootloader
echo "1. BOOTLOADER STATUS" >> "$REPORT"
if [ -d /sys/firmware/efi ]; then
    echo "  Firmware: UEFI" >> "$REPORT"
    efibootmgr -v 2>/dev/null | head -5 >> "$REPORT" || echo "  No efibootmgr" >> "$REPORT"
else
    echo "  Firmware: BIOS/Legacy" >> "$REPORT"
fi
echo "  GRUB version: $(grub-install --version 2>/dev/null || echo 'unknown')" >> "$REPORT"
echo "  GRUB config exists: $(test -f /boot/grub/grub.cfg && echo yes || echo no)" >> "$REPORT"
echo "" >> "$REPORT"

# Section 2: Available kernels
echo "2. AVAILABLE KERNELS" >> "$REPORT"
echo "  Running: $(uname -r)" >> "$REPORT"
echo "  Installed:" >> "$REPORT"
ls /boot/vmlinuz-* 2>/dev/null | sed 's/^/    /' >> "$REPORT"
echo "  Total: $(ls /boot/vmlinuz-* 2>/dev/null | wc -l) kernel(s)" >> "$REPORT"
echo "  (Always keep at least 2 kernels)" >> "$REPORT"
echo "" >> "$REPORT"

# Section 3: Filesystem health
echo "3. FILESYSTEM HEALTH" >> "$REPORT"
for fs in $(mount | grep "^/dev" | awk '{print $1}' | sort -u); do
    fstype=$(mount | grep "^$fs " | awk '{print $5}')
    mountpt=$(mount | grep "^$fs " | awk '{print $3}')
    if command -v tune2fs &>/dev/null; then
        state=$(sudo tune2fs -l "$fs" 2>/dev/null | grep "Filesystem state" | awk '{print $3}')
        echo "  $mountpt ($fs, $fstype): $state" >> "$REPORT"
    else
        echo "  $mountpt ($fs, $fstype): cannot check" >> "$REPORT"
    fi
done
echo "" >> "$REPORT"

# Section 4: SMART status
echo "4. DISK HEALTH (SMART)" >> "$REPORT"
for disk in $(lsblk -d -o NAME 2>/dev/null | grep -v NAME | head -3); do
    if [ -b "/dev/$disk" ]; then
        health=$(sudo smartctl -H "/dev/$disk" 2>/dev/null | grep "health" | awk -F: '{print $2}' | xargs)
        echo "  /dev/$disk: ${health:-SMART not available}" >> "$REPORT"
    fi
done
echo "" >> "$REPORT"

# Section 5: Backup status
echo "5. BACKUP STATUS" >> "$REPORT"
echo "  (Verify your backup strategy separately)" >> "$REPORT"
echo "" >> "$REPORT"

# Section 6: Recovery tools
echo "6. RECOVERY TOOLS INSTALLED" >> "$REPORT"
for tool in fsck smartctl dd grub-install gdisk parted testdisk; do
    if command -v $tool &>/dev/null; then
        echo "  ✓ $tool" >> "$REPORT"
    fi
done
echo "" >> "$REPORT"

# Section 7: Recent boot errors
echo "7. RECENT BOOT ERRORS" >> "$REPORT"
journalctl -b -p err --no-pager 2>/dev/null | tail -10 >> "$REPORT" || \
  echo "  Cannot read boot logs" >> "$REPORT"
echo "" >> "$REPORT"

echo "============================================" >> "$REPORT"
echo "  END OF REPORT" >> "$REPORT"
echo "============================================" >> "$REPORT"

cat "$REPORT"
EOF

chmod +x recovery_plan.sh
./recovery_plan.sh
```

---

## ⭐ Level 3: Advanced — Boot Process Internals and Kernel-Level Recovery

![Linux Kernel Boot Process](https://upload.wikimedia.org/wikipedia/commons/thumb/4/45/Linux_kernel_uboot_diagram.svg/220px-Linux_kernel_uboot_diagram.svg.png)  
*The Linux boot process — understanding what happens under the hood. Image credit: Wikimedia Commons.*

> **Level 3 Goal:** Master the internal mechanics of the boot process, initramfs structure, kernel parameters, SELinux recovery, and LVM-based rescue scenarios. Debug boot failures at the kernel level.

## 🧠 Deep Understanding — How System Recovery Really Works

### The Boot Process (Review)

```
1. BIOS/UEFI → Boot device
2. GRUB stage 1 (boot sector) → Finds stage 2
3. GRUB stage 2 (/boot/grub) → Reads config, shows menu
4. Kernel loaded into memory
5. initramfs loaded (temporary root)
6. Kernel mounts initramfs
7. initramfs loads needed drivers
8. initramfs mounts real root filesystem
9. initramfs hands over to init/systemd
10. System boots normally

If any step fails → recovery needed
```

### The initramfs Emergency Shell

```
If the real root cannot be mounted:
  → Kernel drops to a shell inside initramfs

From this shell you can:
  - Check what devices exist: cat /proc/partitions
  - Load drivers: modprobe
  - Mount manually: mount /dev/sda1 /root
  - Check journal: journalctl
  - Exit to continue boot: exit
```

### Why chroot Works

```
chroot changes the "/" for a process:

Before chroot:
  Live USB:   / → USB root
  Broken sys: /mnt → Broken root

After chroot /mnt:
  Process sees: / → Broken root (was /mnt)
  /etc/shadow → /mnt/etc/shadow (real system's shadow)
  /sbin/init  → /mnt/sbin/init

Commands run inside chroot affect the BROKEN system,
not the Live USB. This is how you fix it.
```

### The Golden Rule of Recovery

```
1. DON'T PANIC        — Most problems are fixable
2. DIAGNOSE FIRST     — Understand what failed before acting
3. BACKUP DATA        — Before making changes
4. CHANGE ONE THING   — So you can revert if needed
5. HAVE A RECOVERY USB — Before you need it
6. DOCUMENT           — What you did, so you can repeat or avoid
```

---

## 📋 Summary — Complete Command Reference for Part 25

### ⭐ Level 1 Commands: Basic Rescue Mode Operations

| Command/Action | Purpose |
|----------------|---------|
| `systemctl rescue` | Boot to rescue mode |
| `systemctl emergency` | Boot to emergency mode |
| GRUB: add `single` | Single-user mode |
| GRUB: add `init=/bin/bash` | Root shell without password |
| `sudo touch /forcefsck` | Force fsck on next boot |
| `sudo smartctl -H /dev/sda` | Check disk health |

### ⭐ Level 2 Commands: Intermediate Recovery Techniques

**Filesystem Repair**

| Command | Action |
|---------|--------|
| `sudo fsck -y /dev/sda1` | Repair filesystem (auto-yes) |
| `sudo fsck -f /dev/sda1` | Force check even if clean |
| GRUB: add `fsck.mode=force` | Force filesystem check at boot |

**GRUB Recovery**

| Command | Action |
|---------|--------|
| `grub-install /dev/sda` | Reinstall GRUB (BIOS) |
| `grub-install --target=x86_64-efi` | Reinstall GRUB (UEFI) |
| `update-grub` | Regenerate GRUB config |
| `exit` (from rescue shell) | Continue boot if possible |

**chroot Recovery**

| Command | Action |
|---------|--------|
| `sudo mount /dev/sda1 /mnt` | Mount root |
| `sudo mount --bind /dev /mnt/dev` | Bind /dev |
| `sudo chroot /mnt /bin/bash` | Enter chroot |
| `sudo umount -R /mnt` | Unmount everything |

### ⭐ Level 3 Commands: Advanced Boot Diagnostics

| Command/Action | Purpose |
|----------------|---------|
| `journalctl -b -1` | View previous boot logs |
| `journalctl -b -p err` | Show boot errors only |
| `dmesg \| grep -i "error\|panic"` | Check kernel messages |
| `lsinitramfs /boot/initrd.img-*` | List initramfs contents |

---

## 📝 Final Self-Test — Can You Answer These?

1. What are three ways to boot into single-user/rescue mode?
2. How do you reset a lost root password from GRUB?
3. What does fsck do and when should you run it?
4. What is the initramfs emergency shell?
5. How do you reinstall GRUB from a Live USB?
6. What is the purpose of chroot in system recovery?
7. What are the steps to bind-mount virtual filesystems for chroot?
8. How do you check disk health with SMART?
9. What GRUB rescue commands list available drives?
10. What does `systemctl rescue` do vs `systemctl emergency`?
11. How do you force a filesystem check on the next reboot?
12. What is '/forcefsck' used for?
13. What kernel parameter boots directly to a bash shell?
14. How do you check what was in the previous boot's logs?
15. What is the most important thing to have before a system fails?

**Score:** 12/15 correct = you are ready to handle real recovery situations.

---

## 🚀 What's Next After Part 25

You have completed the Essential Operations (Parts 11-25).

**Next up: Parts 26-40 — Intermediate Administration**

Topics include:
- Networking (IP, routing, DNS, DHCP)
- Advanced storage (RAID, LVM2, encryption)
- Virtualization (KVM, containers)
- Web servers (Nginx, Apache)
- Databases (MySQL/MariaDB, PostgreSQL)
- Backup strategies
- Monitoring and alerting
- Automation with shell scripts
- And much more...

---

*Linux SysAdmin Course | Part 25 of ∞ | Reverse Engineering Approach*
*Previous → Part 24: Kernel Modules and Device Drivers*
*This concludes the Essential Operations section (Parts 11-25)*

[← Previous](part24.md) | [Next →](part26.md)
