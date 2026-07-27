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



---

[← Previous](08-section-5-using-a-live.md) | [↑ Index](index.md) | [Next →](10-section-7-specific-recovery-scenarios.md)
