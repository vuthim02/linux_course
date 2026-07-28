## ⭐ Level 3: Advanced — Boot Process Internals and Kernel-Level Recovery

![Linux Kernel Boot Process](https://upload.wikimedia.org/wikipedia/commons/thumb/4/45/Linux_kernel_uboot_diagram.svg/220px-Linux_kernel_uboot_diagram.svg.png)  
*The Linux boot process — understanding what happens under the hood. Image credit: Wikimedia Commons.*

> **Level 3 Goal:** Master the internal mechanics of the boot process, initramfs structure, kernel parameters, SELinux recovery, and LVM-based rescue scenarios. Debug boot failures at the kernel level.

### What You'll Cover
- GRUB2 configuration: `/etc/default/grub` and `grub.cfg`
- initramfs anatomy: unpacking with `lsinitramfs` and `dracut`
- Kernel parameters for debugging: `debug`, `rd.break`, `systemd.log_level`
- LVM recovery: activating volumes and assembling RAID arrays
- Kernel panic analysis: reading crash dumps and serial console output

Understanding the boot process at the kernel level lets you diagnose failures that no amount of `fsck` or password resets can fix.

At this level you will master:

- **GRUB2 configuration**: `/etc/default/grub` controls timeout, default kernel, and console settings. Edit it and run `grub2-mkconfig` to regenerate `/boot/grub2/grub.cfg`. Never edit `grub.cfg` directly — it is regenerated on kernel updates.
- **initramfs anatomy**: The initramfs is a compressed cpio archive loaded into RAM by GRUB. Use `lsinitramfs /boot/initrd.img-$(uname -r)` (Debian) or `lsinitrd` (RHEL) to list its contents. It contains the kernel modules needed to mount the real root filesystem (LVM, RAID, crypto).
- **Debugging kernel parameters**: `debug` enables verbose initramfs output. `rd.break` stops at initramfs before switching root. `systemd.log_level=debug` enables verbose systemd logging. `rd.shell` drops to a shell on initramfs failure.
- **LVM recovery**: If the VG is not activated, use `vgchange -ay` to activate it. For RAID, `mdadm --assemble --scan` attempts to reassemble all known arrays. These are common after disk failures.
- **Kernel panic**: The panic message appears on screen and in `/var/crash/` if kdump is configured. Read the stack trace to identify the failing module or function. Serial console output is essential when the screen is not visible.


[← Previous](11-practice-section-15-hands-on-exercises.md) | [↑ Index](index.md) | [Next →](13-deep-understanding-how-system-recovery.md)
