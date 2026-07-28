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





[← Previous](07-section-4-stage-3-grub.md) | [↑ Index](index.md) | [Next →](09-section-6-stage-5-systemd.md)
