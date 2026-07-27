# 🐧 Linux System Administrator — Complete Course
## Part 10 of ∞: The Linux Boot Process — From Power On to Login

---

> **Reverse Engineering Approach:** When you press the power button, a chain of events unfolds that transforms an inert collection of silicon into a running Linux system. Most users never see this process — it just works. But when it breaks, you need to know every step. We will trace the boot process from the electrical signal to the login prompt, understanding what each component does and how to fix it when it fails.

---

## 🎯 What You Will Achieve in Part 10

| Level | Focus | What You'll Master |
|-------|-------|-------------------|
| ⭐ **Level 1: Basic** | Boot foundations and concepts | 6 boot stages, BIOS vs UEFI, firmware role, hardware initialization |
| ⭐ **Level 2: Intermediary** | Boot configuration and tools | GRUB configuration, kernel/initramfs, systemd targets, boot logs, /etc/fstab |
| ⭐ **Level 3: Advanced** | Recovery and deep internals | GRUB rescue, kernel panic recovery, initramfs internals, Live USB repair |

---

## ⭐ Level 1: Basic — Foundations of the Boot Process

![Linux Boot Process Diagram](https://upload.wikimedia.org/wikipedia/commons/8/83/Linux_Boot.png)
*Linux boot process stages from power-on to login prompt. Source: Wikimedia Commons*

> **Level 1 Goal:** Understand the 6-stage boot sequence, the difference between BIOS and UEFI, and what happens at the hardware and firmware levels before Linux even starts.

---

## 🔍 Section 1: The Boot Process Overview

The Linux boot process has 6 stages:

```
┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐
│ POWER ON │───►│  BIOS/   │───►│  GRUB    │───►│  KERNEL  │───►│   INIT   │───►│  LOGIN   │
│          │    │  UEFI    │    │  BOOT    │    │          │    │ (SYSTEMD)│    │  PROMPT  │
└──────────┘    └──────────┘    └──────────┘    └──────────┘    └──────────┘    └──────────┘
 Stage 1         Stage 2         Stage 3         Stage 4         Stage 5         Stage 6
 Hardware        Firmware        Bootloader      OS Kernel      Userspace       Ready
```

| Stage | Duration | What Happens |
|-------|----------|-------------|
| 1. Power On | < 1s | Power supply stabilizes, CPU resets, starts firmware |
| 2. BIOS/UEFI | 1-5s | POST, hardware detection, boot device selection |
| 3. GRUB | 1-3s | Loads kernel and initramfs into memory |
| 4. Kernel | 2-10s | Initializes hardware, mounts root filesystem |
| 5. systemd | 5-30s | Starts services, reaches target (multi-user/graphical) |
| 6. Login | — | Display manager or console login prompt |

---

## 🔍 Section 2: Stage 1 — Power On

When you press the power button:

```bash
1. Power supply sends POWER_GOOD signal to motherboard
2. CPU resets and loads the firmware (BIOS/UEFI) from ROM
3. CPU starts executing the firmware code
4. Firmware initializes essential hardware:
   - CPU and memory controllers
   - System clock
   - Interrupt controllers
   - Basic I/O (keyboard, display)
```

At this point, nothing Linux-specific has happened. The firmware doesn't know or care about Linux.

---

## 🔍 Section 3: Stage 2 — BIOS vs UEFI

### BIOS (Legacy)

```bash
# BIOS = Basic Input/Output System
# - 16-bit mode
# - Runs in real mode (no memory protection)
# - Reads the Master Boot Record (MBR) from the boot device
# - MBR is 512 bytes, stored in the FIRST sector of the disk
# - MBR contains bootloader code (stage 1) and partition table

# MBR layout:
# Bytes 0-445:   Bootloader code (stage 1)
# Bytes 446-509: Partition table (4 entries, 16 bytes each)
# Bytes 510-511: Boot signature (0x55 0xAA)

# BIOS limitation: MBR can only address disks up to 2TB
```

### UEFI (Modern)

```bash
# UEFI = Unified Extensible Firmware Interface
# - 32-bit or 64-bit mode
# - Can run in protected mode with memory protection
# - Reads EFI System Partition (ESP) — FAT32 formatted
# - ESP contains .efi bootloader files
# - Supports Secure Boot (cryptographic signature verification)

# ESP location:
# - Usually /boot/efi or /boot/EFI
# - Contains: /EFI/ubuntu/grubx64.efi, /EFI/BOOT/bootx64.efi

# UEFI advantages:
# - Faster boot
# - GUI configuration
# - Mouse support
# - Network boot
# - GPT partition tables (supports > 2TB disks)
```

### Checking Your System

```bash
# Check if booting in BIOS or UEFI mode
ls /sys/firmware/efi
# If directory exists = UEFI
# If directory does not exist = BIOS

# Or check kernel boot messages
dmesg | grep -i "efi\|bios"

# Check partition table type
sudo fdisk -l /dev/sda | grep "Disklabel"
# "gpt" = GPT (usually UEFI)
# "dos" = MBR (usually BIOS)
```

---

## ⭐ Level 2: Intermediary — Boot Configuration and Management

<!-- ![Linux Startup Process](https://i.pinimg.com/1200x/d8/59/c2/d859c212d41306cd2f05a23f0ea9b436.jpg) -->
<img src="https://i.pinimg.com/1200x/d8/59/c2/d859c212d41306cd2f05a23f0ea9b436.jpg" style="max-width:600px;">
*Detailed Linux startup process flow. Source: Wikimedia Commons*

> **Level 2 Goal:** Configure GRUB boot parameters, understand kernel initialization and initramfs, manage systemd targets, read boot logs, and manage filesystem mounting at boot.

---

## 🔍 Section 4: Stage 3 — GRUB Bootloader

GRUB (GRand Unified Bootloader) is the most common Linux bootloader.

### What GRUB Does

```bash
1. BIOS/UEFI loads GRUB stage 1 (or EFI file)
2. GRUB loads its configuration from /boot/grub/grub.cfg
3. GRUB loads the Linux kernel and initramfs into memory
4. GRUB transfers control to the kernel
```

### GRUB Configuration

```bash
# Main config file (DO NOT edit directly — generated by update-grub)
/boot/grub/grub.cfg

# User-editable config
/etc/default/grub

# Additional configs in
/etc/default/grub.d/
```

### /etc/default/grub Key Options

```bash
# Default boot entry (0 = first entry)
GRUB_DEFAULT=0

# Timeout in seconds before auto-boot
GRUB_TIMEOUT=5

# Kernel command-line parameters (EXTREMELY IMPORTANT)
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"
GRUB_CMDLINE_LINUX=""

# Common kernel parameters:
# quiet           — Suppress boot messages
# splash          — Show splash screen
# nomodeset       — Don't load graphics drivers (fix boot issues)
# single          — Boot to single-user mode (maintenance)
# 3               — Boot to runlevel 3 (multi-user, no GUI)
# 5               — Boot to runlevel 5 (graphical)
# net.ifnames=0   — Use eth0 instead of predictable names
# crashkernel=auto — Reserve memory for crash dumps
```

### Applying GRUB Changes

```bash
# After editing /etc/default/grub, regenerate grub.cfg:
# Debian/Ubuntu:
sudo update-grub

# Fedora/RHEL:
sudo grub2-mkconfig -o /boot/grub2/grub.cfg
# If UEFI:
sudo grub2-mkconfig -o /boot/efi/EFI/fedora/grub.cfg
```

### Booting Into Recovery Mode

```bash
# At GRUB menu:
# 1. Select the boot entry you want
# 2. Press 'e' to edit
# 3. Find the line starting with "linux"
# 4. Add 'single' or 'init=/bin/bash' at the end
# 5. Press Ctrl+X or F10 to boot

# Recovery mode kernel parameters:
# single           — Single-user mode
# init=/bin/bash   — Start directly to a root shell (no password)
# rw               — Mount root filesystem read-write
```

### Viewing GRUB Version

```bash
grub-install --version
```

---

## 🔍 Section 5: Stage 4 — Kernel Initialization

GRUB loads two things into memory: the **kernel** and the **initramfs**.

### The Kernel

```bash
# Kernel file location
ls /boot/vmlinuz-*
# /boot/vmlinuz-6.1.0-21-amd64

# The kernel is a compressed ELF binary (vmlinuz = "virtual memory LINUx Zip")

# Check current kernel version
uname -r
```

### The initramfs (Initial RAM Filesystem)

The **initramfs** is a temporary root filesystem loaded before the real root. It contains:

```bash
# Essential kernel modules (disk drivers, filesystem drivers)
# Hardware detection tools
# The init system (usually a script or systemd)

# Location:
ls /boot/initrd.img-*  # Debian/Ubuntu
ls /boot/initramfs-*   # Fedora/RHEL

# What's inside (view it):
# It's a gzip-compressed cpio archive
zcat /boot/initrd.img-$(uname -r) | cpio -t 2>/dev/null | head -20

# Or:
lsinitramfs /boot/initrd.img-$(uname -r) | head -20
```

### What the Kernel Does During Boot

```bash
1. Decompresses itself (the kernel is self-extracting)
2. Sets up memory management (page tables)
3. Initializes the CPU (detects features, sets up interrupts)
4. Initializes the console (early printk messages appear)
5. Detects hardware (PCI, USB, ACPI)
6. Loads the initramfs from memory
7. Mounts the initramfs as root filesystem
8. Starts the first userspace process (/init or systemd)
```

### Kernel Boot Parameters

```bash
# View kernel boot parameters of the current boot
cat /proc/cmdline
# Example: BOOT_IMAGE=/vmlinuz-6.1.0-21-amd64 root=/dev/sda2 ro quiet

# Common parameters:
# root=/dev/sda2       — Which partition is the root filesystem
# ro                   — Mount root read-only initially
# rw                   — Mount root read-write
# quiet                — Suppress kernel messages
# splash               — Show splash screen
# init=/bin/bash       — Override init with bash (emergency)
# systemd.unit=rescue.target  — Boot to rescue mode
# systemd.unit=emergency.target — Boot to emergency mode
```

---

## 🔍 Section 6: Stage 5 — systemd Initialization

After the kernel finishes, it starts the first userspace process: **systemd** (PID 1).

### What systemd Does

```bash
1. Mounts filesystems listed in /etc/fstab
2. Starts udev (device manager — creates /dev entries)
3. Loads kernel modules
4. Sets up networking
5. Starts system services (SSH, cron, web server...)
6. Reaches the default target (multi-user or graphical)
```

### systemd Targets

```bash
# Targets are like runlevels in the old SysV init
# They represent different system states

# Common targets:
poweroff.target        # System is powered off
rescue.target          # Single-user mode, basic system
emergency.target       # Emergency shell, only root filesystem
multi-user.target      # Normal multi-user, no GUI (text mode)
graphical.target       # Multi-user with GUI
reboot.target          # Reboot

# Check current target
systemctl get-default

# Set default target
sudo systemctl set-default multi-user.target

# Switch to a target right now
sudo systemctl isolate rescue.target
```

### Analyzing Boot Performance

```bash
# Show how long each service took to start
systemd-analyze blame

# Show critical chain (what was the bottleneck)
systemd-analyze critical-chain

# Show overall boot time
systemd-analyze time

# Plot boot chart (generates SVG)
systemd-analyze plot > boot_plot.svg
```

### Viewing Boot Logs

```bash
# All messages from this boot
journalctl -b

# Kernel messages only
journalctl -b -k

# Errors and warnings only
journalctl -b -p err

# Messages sorted by priority
journalctl -b -p warning..emerg

# Previous boot messages (if boot failed)
journalctl -b -1
```

---

## 🔍 Section 7: The Boot Process in Detail — Kernel Messages

Watch the actual boot process:

```bash
# View kernel ring buffer (boot messages)
dmesg

# Follow live boot messages (if you have a serial console)
dmesg -w

# Filter for specific hardware
dmesg | grep -i "usb"
dmesg | grep -i "ata\|sda"
dmesg | grep -i "memory"

# Show boot time stamps
dmesg -T | tail -20

# Check what was detected during boot
dmesg | grep -E "Detected|Found|initialized"
```

### Key dmesg Output to Understand

```bash
# Memory detected
[    0.000000] Memory: 8182384K/8380416K available

# CPU detected
[    0.000000] smpboot: CPU0: Intel(R) Core(TM) i7-8700K

# Root filesystem mounted
[    3.452819] EXT4-fs (sda2): mounted filesystem with ordered data mode

# Network interface
[    4.123456] e1000: eth0 NIC Link is Up 1000 Mbps

# First userspace process
[    4.567890] Run /init as init process
```

---

## 🔍 Section 10: Understanding /etc/fstab

The `/etc/fstab` file controls which filesystems are mounted at boot.

```bash
cat /etc/fstab
```

```
# <file system>    <mount point>  <type>  <options>         <dump> <pass>
UUID=abc123-...    /              ext4    defaults,errors=remount-ro 0 1
UUID=def456-...    /boot          ext4    defaults          0 2
UUID=ghi789-...    /home          ext4    defaults          0 2
UUID=xxx-...       swap           swap    sw                0 0
/dev/sr0           /media/cdrom   auto    ro,user,noauto    0 0
```

| Field | Meaning |
|-------|---------|
| File system | Device or UUID to mount |
| Mount point | Where to attach it in the tree |
| Type | Filesystem type (ext4, xfs, swap...) |
| Options | Mount options (comma-separated) |
| Dump | Backup flag (0=don't dump, 1=dump) |
| Pass | fsck order (0=skip, 1=root, 2=other) |

### Critical fstab Options

```bash
# defaults         — rw, suid, dev, exec, auto, nouser, async
# noauto           — Don't mount at boot (manual mount only)
# user             — Allow any user to mount
# ro               — Read-only mount
# errors=remount-ro — Remount read-only on error (for root fs)
# noexec           — Cannot execute binaries from this partition
# nosuid           — Ignore SUID bits on this partition
# discard          — Enable TRIM for SSDs
```

### Using UUID Instead of Device Names

```bash
# Device names like /dev/sda1 can change between boots
# UUIDs are permanent (based on the filesystem)

# Find UUID of a partition
blkid /dev/sda1

# Or list all
sudo blkid

# UUID format: UUID="abc12345-6789-def0-1234-56789abcdef0"
```

---

## ⭐ Level 3: Advanced — Boot Recovery and Internals

![Linux Kernel Boot Messages](https://upload.wikimedia.org/wikipedia/commons/5/56/Linux_boot_screen_compact.png)
*Linux kernel boot messages displayed during the boot process. Source: Wikimedia Commons*

> **Level 3 Goal:** Recover from GRUB failures and kernel panics, repair the bootloader from a Live USB environment, and understand the initramfs internals and why it exists.

---

## 🔍 Section 8: GRUB Rescue and Recovery

When GRUB itself cannot load (missing config, corrupted MBR), you get the GRUB rescue prompt:

```
grub rescue>
```

### Common Causes

```bash
# - /boot partition deleted or corrupted
# - GRUB configuration file missing
# - MBR overwritten (by Windows dual-boot)
# - Disk reordered (BIOS tries different disk)
# - Filesystem errors on /boot
```

### GRUB Rescue Commands

```bash
# At the grub rescue> prompt, you need to load modules manually:

# 1. Find which partition has /boot
ls                    # List available partitions
# (hd0,msdos1) (hd0,msdos2)

# 2. Set the root partition
set root=(hd0,msdos1)

# 3. Load necessary modules
insmod ext2
insmod normal

# 4. Load normal mode
normal

# 5. From GRUB menu, boot Linux, then run:
sudo update-grub
sudo grub-install /dev/sda
```

### Reinstalling GRUB From Live USB

```bash
# Boot from a Live USB, then:

# 1. Identify your root partition
sudo fdisk -l

# 2. Mount the root partition
sudo mount /dev/sda2 /mnt
sudo mount /dev/sda1 /mnt/boot   # If separate boot partition

# 3. Mount special filesystems
sudo mount --bind /dev /mnt/dev
sudo mount --bind /proc /mnt/proc
sudo mount --bind /sys /mnt/sys
sudo mount --bind /run /mnt/run   # For UEFI

# 4. Chroot into your system
sudo chroot /mnt

# 5. Reinstall GRUB
# For BIOS:
grub-install /dev/sda
update-grub

# For UEFI:
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=Ubuntu
update-grub

# 6. Exit and reboot
exit
sudo umount -R /mnt
sudo reboot
```

---

## 🔍 Section 9: Kernel Panic and System Recovery

### Kernel Panic

A **kernel panic** is the kernel's way of saying "I cannot recover from this error." It stops everything.

```bash
# What you see:
# Kernel panic - not syncing: VFS: Unable to mount root fs on unknown-block(0,0)
# or:
# Kernel panic - not syncing: Attempted to kill init!
```

### Common Causes of Kernel Panic

```bash
# 1. Missing or wrong root filesystem
#    - Wrong root= parameter in GRUB
#    - initramfs missing required drivers
#    - Filesystem corruption

# 2. Hardware failure
#    - Bad RAM (run memtest86)
#    - Failing disk

# 3. Kernel bug or incompatible driver
#    - Try booting an older kernel from GRUB

# 4. Out of memory (OOM)
#    - System ran out of memory and killed a critical process
```

### Recovery Methods

```bash
# Method 1: Boot an older kernel
# At GRUB menu → Advanced options → Select previous kernel

# Method 2: Boot to recovery mode
# At GRUB menu → Advanced options → Recovery mode

# Method 3: Edit kernel parameters at GRUB
# Press 'e' at GRUB, add 'single' or 'init=/bin/bash'

# Method 4: Use Live USB
# Boot from USB, mount root, chroot, fix the problem
```

---

## 🧠 Deep Understanding — The initramfs and Why It Exists

### The Chicken-and-Egg Problem

```
The kernel needs to read the root filesystem to start systemd.
But the root filesystem driver might be a kernel module.
Kernel modules live ON the root filesystem.

Solution: initramfs
- initramfs is a small root filesystem embedded in the kernel image
- Contains the essential drivers needed to mount the real root
- Once the real root is mounted, systemd switches to it (pivot_root)
```

### What initramfs Contains

```bash
# Typical initramfs contents:
# - /init or /lib/systemd/systemd — First process
# - Kernel modules for storage (ahci, nvme, ext4, xfs)
# - Device mapper tools (for LVM, encryption)
# - mdadm (for RAID)
# - cryptsetup (for LUKS encryption)
# - fsck (filesystem check tools)

# The init process:
# 1. Loads necessary kernel modules
# 2. Detects hardware (via udev)
# 3. Assembles RAID arrays
# 4. Unlocks encrypted disks
# 5. Mounts the real root filesystem
# 6. Transitions to the real root (pivot_root or switch_root)
```

### Why You Might Need to Rebuild initramfs

```bash
# After changing storage hardware
# After installing a new kernel
# After changing filesystem type
# After enabling LUKS encryption
# After moving /boot to a different filesystem

# Rebuild initramfs:
# Debian/Ubuntu:
sudo update-initramfs -u

# Fedora/RHEL:
sudo dracut --force
```

---

## 💻 PRACTICE SECTION — 15 Hands-On Exercises

### ✅ Level 1: Basic Practices

---

### ✅ Practice 1: Check Your Boot Mode

```bash
# Are you BIOS or UEFI?
ls /sys/firmware/efi 2>/dev/null && echo "UEFI" || echo "BIOS"

# Check partition table type
sudo fdisk -l /dev/sda 2>/dev/null | head -5
```

---

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

---

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

---

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

---

### ✅ Level 2: Intermediary Practices

---

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

---

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

---

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

---

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

---

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

---

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

---

### ✅ Practice 11: Boot Performance Timeline

```bash
# Generate a timeline
systemd-analyze plot > ~/linux-course/part10/boot_plot.svg 2>/dev/null || \
echo "Boot plot generated"

# Or just print a text timeline
systemd-analyze critical-chain
```

---

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

---

### ✅ Level 3: Advanced Practices

---

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

---

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

---

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

---

## 📋 Summary — Complete Command Reference for Part 10

### Level 1: Basic Commands — Boot Information and Mode

| Command | Action |
|---------|--------|
| `uname -r` | Kernel version |
| `uname -a` | All system info |
| `cat /proc/cmdline` | Kernel boot parameters |
| `ls /sys/firmware/efi` | Check UEFI (exists = UEFI) |
| `sudo fdisk -l /dev/sda` | Check partition table type |

### Level 2: Intermediary Commands — GRUB, systemd, Filesystem

| Command | Action |
|---------|--------|
| `dmesg` | Kernel ring buffer (boot messages) |
| `dmesg -T` | Boot messages with timestamps |
| `cat /etc/default/grub` | GRUB configuration |
| `sudo update-grub` | Regenerate GRUB config (Debian) |
| `sudo grub2-mkconfig -o /boot/grub2/grub.cfg` | Regenerate (Fedora/RHEL) |
| `grub-install /dev/sda` | Install GRUB to MBR |
| `systemd-analyze time` | Total boot time |
| `systemd-analyze blame` | Per-service boot times |
| `systemd-analyze critical-chain` | Boot bottleneck |
| `systemd-analyze plot` | Generate boot chart |
| `systemctl get-default` | Current default target |
| `systemctl set-default target` | Change default target |
| `systemctl isolate target` | Switch to target now |
| `systemctl --failed` | List failed services |
| `journalctl -b` | All logs from current boot |
| `journalctl -b -k` | Kernel logs from current boot |
| `journalctl -b -p err` | Errors from current boot |
| `journalctl -b -1` | Logs from previous boot |
| `cat /etc/fstab` | Filesystem table |
| `sudo blkid` | List UUIDs of all partitions |
| `mount` | Show mounted filesystems |

### Level 3: Advanced Commands — Initramfs

| Command | Action |
|---------|--------|
| `lsinitramfs /boot/initrd.img-*` | List initramfs contents |
| `sudo update-initramfs -u` | Rebuild initramfs (Debian) |
| `sudo dracut --force` | Rebuild initramfs (Fedora/RHEL) |

---

## 🚀 What's Coming in Part 11

**Part 11: Package Management — apt, dnf, yum, snap**

You will learn:
- How package managers work (deb vs rpm)
- apt — managing packages on Debian/Ubuntu
- dpkg — low-level Debian package tool
- dnf/yum — managing packages on Fedora/RHEL
- rpm — low-level Red Hat package tool
- snap and flatpak — universal package formats
- Adding repositories and PPAs
- 15 hands-on practices

---

## 📝 Self-Test — Can You Answer These?

1. What are the 6 stages of the Linux boot process?
2. What is the difference between BIOS and UEFI?
3. How do you check if your system boots in UEFI or BIOS mode?
4. What does GRUB do during boot?
5. How do you edit kernel parameters temporarily at the GRUB menu?
6. What is the initramfs and why is it needed?
7. What command shows boot messages from the kernel?
8. What does `systemd-analyze blame` show?
9. What is the difference between `journalctl -b` and `journalctl -b -1`?
10. How do you change the default systemd target?
11. What is `/etc/fstab` used for?
12. How do you recover from a GRUB failure using a Live USB?
13. What command rebuilds the initramfs on Debian/Ubuntu?
14. What does `cat /proc/cmdline` show?
15. What is a kernel panic and what causes it?

**Score:** 12/15 correct = ready for Part 11.

---

*Linux SysAdmin Course | Part 10 of ∞ | Reverse Engineering Approach*
*Previous → Part 9: Process Management — ps, top, kill, and Signals*
*Next → Part 11: Package Management — apt, dnf, yum, snap*

[← Previous](part9.md) | [Next →](part11.md)
