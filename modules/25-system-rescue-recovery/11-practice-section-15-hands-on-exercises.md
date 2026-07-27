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



---

[← Previous](10-section-7-specific-recovery-scenarios.md) | [↑ Index](index.md) | [Next →](12-level-3-advanced-boot-process.md)
