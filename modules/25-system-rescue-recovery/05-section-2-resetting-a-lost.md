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



---

[← Previous](04-level-2-intermediary-password-reset.md) | [↑ Index](index.md) | [Next →](06-section-3-filesystem-repair-fsck.md)
