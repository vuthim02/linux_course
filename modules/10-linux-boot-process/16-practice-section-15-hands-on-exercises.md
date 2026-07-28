## 💻 PRACTICE SECTION — 15 Hands-On Exercises

### ✅ Level 1: Basic Practices


### ✅ Practice 1: Check Your Boot Mode

```bash
# Are you BIOS or UEFI?
ls /sys/firmware/efi 2>/dev/null && echo "UEFI" || echo "BIOS"

# Check partition table type
sudo fdisk -l /dev/sda 2>/dev/null | head -5
```


### ✅ Practice 2: Explore Kernel Info

```bash
# Kernel version
uname -r
uname -a

# Kernel file
ls -lh /boot/vmlinuz-$(uname -r)

# Initramfs file
ls -lh /boot/initrd.img-$(uname -r) 2>/dev/null || \
ls -lh /boot/initramfs-$(uname -r)* 2>/dev/null

# Kernel modules directory
ls /lib/modules/$(uname -r)/
```


### ✅ Practice 3: View Kernel Parameters

```bash
# Parameters passed to kernel at boot
cat /proc/cmdline

# Each parameter explained:
# BOOT_IMAGE=...  — Which kernel was loaded
# root=...        — Root filesystem device
# ro or rw        — Read-only or read-write mount
# quiet           — Suppress messages
# splash          — Boot splash screen
```


### ✅ Practice 6: Explore systemd Targets

```bash
# Current default target
systemctl get-default

# List all available targets
systemctl list-units --type=target --all

# Current active target
systemctl list-units --type=target --state=active

# Change to multi-user (text mode) temporarily
# sudo systemctl isolate multi-user.target
```


### ✅ Level 2: Intermediary Practices


### ✅ Practice 4: Read Boot Messages

```bash
# All boot messages
dmesg | less

# Boot messages with timestamps
dmesg -T | less

# Filter for your root filesystem
dmesg | grep -i "root\|sda\|ext4"

# Filter for memory info
dmesg | grep -i "memory\|mem"

# Count total boot messages
dmesg | wc -l
```


### ✅ Practice 5: systemd Boot Analysis

```bash
# Overall boot time
systemd-analyze time

# Service startup times
systemd-analyze blame | head -20

# Critical chain (what delayed boot?)
systemd-analyze critical-chain

# All units and their times
systemd-analyze blame
```


### ✅ Practice 7: View /etc/fstab

```bash
# View fstab
cat /etc/fstab

# Find UUID of your partitions
sudo blkid

# Check which partitions are currently mounted
mount | grep "^/dev"

# Compare fstab entries with mounted filesystems
echo "Mounted:"
mount | grep "^/dev" | awk '{print $1, $3}'
echo "In fstab:"
grep -v "^#" /etc/fstab | grep -v "^$" | awk '{print $1, $2}'
```


### ✅ Practice 8: Explore initramfs

```bash
# List contents of initramfs
lsinitramfs /boot/initrd.img-$(uname -r) 2>/dev/null | head -30

# Or manually:
mkdir -p /tmp/initramfs
cd /tmp/initramfs
zcat /boot/initrd.img-$(uname -r) 2>/dev/null | cpio -idm 2>/dev/null || \
xzcat /boot/initrd.img-$(uname -r) 2>/dev/null | cpio -idm 2>/dev/null
ls -la
```


### ✅ Practice 9: Check Boot Logs With journalctl

```bash
# Messages from this boot
journalctl -b --no-pager | tail -30

# Errors from this boot
journalctl -b -p err --no-pager

# Kernel messages from this boot
journalctl -b -k --no-pager | tail -20

# Previous boot (if it crashed)
journalctl -b -1 -p err --no-pager 2>/dev/null || echo "No previous boot logs"
```


### ✅ Practice 10: GRUB Configuration

```bash
# View GRUB config
cat /etc/default/grub

# View generated config (read-only, do not edit)
head -50 /boot/grub/grub.cfg 2>/dev/null || \
head -50 /boot/grub2/grub.cfg 2>/dev/null

# List installed kernels (available at GRUB menu)
ls /boot/vmlinuz-*
```


### ✅ Practice 11: Boot Performance Timeline

```bash
# Generate a timeline
systemd-analyze plot > ~/linux-course/part10/boot_plot.svg 2>/dev/null || \
echo "Boot plot generated"

# Or just print a text timeline
systemd-analyze critical-chain
```


### ✅ Practice 12: Check Startup Services

```bash
# Which services are enabled at boot?
systemctl list-unit-files --type=service --state=enabled | head -30

# Which services failed at boot?
systemctl --failed

# Count enabled services
echo "Enabled services: $(systemctl list-unit-files --type=service --state=enabled --no-legend | wc -l)"

# Count disabled services
echo "Disabled services: $(systemctl list-unit-files --type=service --state=disabled --no-legend | wc -l)"
```


### ✅ Level 3: Advanced Practices


### ✅ Practice 13: Simulate Boot Problem — Missing Root

```bash
# This is informational only — DO NOT change your GRUB config!
echo "If you saw this error at boot:"
echo "  Kernel panic - not syncing: VFS: Unable to mount root fs"
echo ""
echo "It means:"
echo "  1. The root= parameter points to the wrong device"
echo "  2. The initramfs doesn't have the required driver"
echo "  3. The root filesystem is corrupted"
echo ""
echo "Fix: At GRUB, press 'e', find the linux line, check root= parameter"
```


### ✅ Practice 14: Live USB Boot Simulation

```bash
# Create a practice recovery script
mkdir -p ~/linux-course/part10
cd ~/linux-course/part10

cat > recovery_steps.sh << 'EOF'
#!/bin/bash
echo "=== GRUB RECOVERY STEPS ==="
echo ""
echo "When you can't boot, use a Live USB and follow these steps:"
echo ""
echo "Step 1: Identify your partitions"
echo "  sudo fdisk -l"
echo "  sudo blkid"
echo ""
echo "Step 2: Mount root partition"
echo "  sudo mount /dev/sda2 /mnt"
echo ""
echo "Step 3: Mount boot partition (if separate)"
echo "  sudo mount /dev/sda1 /mnt/boot"
echo ""
echo "Step 4: Mount special filesystems"
echo "  for dir in dev proc sys run; do"
echo "    sudo mount --bind /$dir /mnt/$dir"
echo "  done"
echo ""
echo "Step 5: Chroot"
echo "  sudo chroot /mnt"
echo ""
echo "Step 6: Reinstall GRUB"
echo "  # BIOS:"
echo "  grub-install /dev/sda"
echo "  update-grub"
echo ""
echo "  # UEFI:"
echo "  grub-install --target=x86_64-efi --efi-directory=/boot/efi"
echo "  update-grub"
echo ""
echo "Step 7: Exit and reboot"
echo "  exit"
echo "  sudo umount -R /mnt"
echo "  sudo reboot"
EOF

chmod +x recovery_steps.sh
./recovery_steps.sh
```


### ✅ Practice 15: Create a Boot Information Report

```bash
mkdir -p ~/linux-course/part10
cd ~/linux-course/part10

cat > boot_report.sh << 'EOF'
#!/bin/bash
set -euo pipefail

REPORT="boot_report_$(date +%Y%m%d).txt"

{
echo "============================================"
echo "  BOOT INFORMATION REPORT"
echo "  Date: $(date)"
echo "  Hostname: $(hostname)"
echo "============================================"
echo ""

echo "1. FIRMWARE TYPE"
echo "----------------"
if [ -d /sys/firmware/efi ]; then
    echo "Boot mode: UEFI"
else
    echo "Boot mode: BIOS (Legacy)"
fi
echo ""

echo "2. KERNEL"
echo "---------"
echo "Version: $(uname -r)"
echo "Arch:    $(uname -m)"
echo "Kernel:  /boot/vmlinuz-$(uname -r)"
echo "Initrd:  /boot/initrd.img-$(uname -r)"
echo ""

echo "3. KERNEL PARAMETERS"
echo "-------------------"
cat /proc/cmdline
echo ""
echo ""

echo "4. BOOT TIME"
echo "-----------"
systemd-analyze time 2>/dev/null || echo "systemd-analyze not available"
echo ""

echo "5. SLOWEST SERVICES"
echo "------------------"
systemd-analyze blame 2>/dev/null | head -10
echo ""

echo "6. MOUNTED FILESYSTEMS"
echo "---------------------"
mount | grep "^/dev"
echo ""

echo "7. FILESYSTEM TABLE"
echo "------------------"
cat /etc/fstab
echo ""

echo "8. FAILED SERVICES"
echo "-----------------"
systemctl --failed --no-legend 2>/dev/null || echo "None"
echo ""

echo "9. INSTALLED KERNELS"
echo "-------------------"
ls /boot/vmlinuz-* 2>/dev/null
echo ""

echo "10. LAST 20 BOOT MESSAGES"
echo "------------------------"
dmesg | tail -20
echo ""

echo "============================================"
echo "  END OF REPORT"
echo "============================================"

} > "$REPORT"

echo "Report written to $REPORT"
echo "File size: $(wc -c < "$REPORT") bytes"
EOF

chmod +x boot_report.sh
./boot_report.sh
```





[← Previous](15-deep-understanding-the-initramfs-and.md) | [↑ Index](index.md) | [Next →](17-summary-complete-command-reference-for.md)
