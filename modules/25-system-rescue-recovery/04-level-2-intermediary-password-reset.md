## ⭐ Level 2: Intermediary — Password Reset, Filesystem Repair, and System Recovery

![GRUB Bootloader Screen](https://upload.wikimedia.org/wikipedia/commons/thumb/0/0b/GRUB_screenshot.png/220px-GRUB_screenshot.png)  
*The GRUB bootloader — your gateway to recovery. Image credit: Wikimedia Commons.*

> **Level 2 Goal:** Reset a lost root password, repair corrupted filesystems, recover a broken GRUB installation, use a Live CD/USB environment, and perform chroot-based repairs. Handle common boot failures with confidence.

### What You'll Cover
- Resetting root password via GRUB `rd.break` or `init=/bin/bash`
- Running `fsck` on unmounted filesystems (ext4, XFS)
- Reinstalling GRUB with `grub-install` and `update-grub`
- Booting from a Live USB and mounting the installed system
- Using `chroot` to repair packages, update GRUB, and fix configs

These are the most common recovery scenarios you will face in production. Mastering them means the difference between a five-minute fix and a panicked reinstall.

At this level you will practice:

- **Password reset**: At the GRUB menu, press `e`, append `rd.break` to the kernel line, boot with Ctrl+X. You get an initramfs shell. Remount `/sysroot` read-write with `mount -o remount,rw /sysroot`, then `chroot /sysroot`, run `passwd root`, create `/.autorelabel` for SELinux, and exit twice to reboot.
- **Filesystem repair**: Always unmount or boot to rescue mode first. For ext4: `fsck -y /dev/sda1`. For XFS: `xfs_repair /dev/sda1`. Never run `fsck` on a mounted filesystem — it will destroy data.
- **GRUB reinstall**: Boot from Live USB, `chroot` into your installed system, run `grub-install /dev/sda` and `update-grub` (Debian) or `grub2-mkconfig -o /boot/grub2/grub.cfg` (RHEL).
- **Live USB environment**: Mount your root partition at `/mnt`, mount `/boot` and `/proc`/`sys`/`dev` as needed, then `chroot /mnt` to work inside your installed system as if it had booted normally.


[← Previous](03-section-1-recovery-boot-modes.md) | [↑ Index](index.md) | [Next →](05-section-2-resetting-a-lost.md)
