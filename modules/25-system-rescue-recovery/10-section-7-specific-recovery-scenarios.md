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





[← Previous](09-section-6-chroot-repair-a.md) | [↑ Index](index.md) | [Next →](11-practice-section-15-hands-on-exercises.md)
