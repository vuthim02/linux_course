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


## Answer Key

### Q1: What are the 6 stages of the Linux boot process?
**Answer:** 1. POST (firmware checks hardware), 2. Bootloader (GRUB loads kernel), 3. Kernel loading, 4. initramfs (mounts rootfs), 5. Init/systemd (starts services), 6. Login prompt.

### Q2: What is the difference between BIOS and UEFI?
**Answer:** BIOS is legacy firmware (16-bit, MBR disks, 2TB limit). UEFI is modern (32/64-bit, GPT disks, Secure Boot, faster boot).

### Q3: How do you check if your system boots in UEFI or BIOS mode?
**Answer:** `ls /sys/firmware/efi` — if it exists, you booted in UEFI mode.

### Q4: What does GRUB do during boot?
**Answer:** Loads the kernel and initramfs into memory, passes kernel parameters, and hands control to the kernel.

### Q5: How do you edit kernel parameters temporarily at the GRUB menu?
**Answer:** Press `e` at the GRUB menu to edit the boot entry. Changes are temporary — not saved.

### Q6: What is the initramfs and why is it needed?
**Answer:** A temporary root filesystem loaded into memory that contains drivers needed to mount the real root filesystem (e.g., LVM, RAID, encryption).

### Q7: What command shows boot messages from the kernel?
**Answer:** `dmesg` — displays kernel ring buffer messages including hardware detection and driver loading.

### Q8: What does `systemd-analyze blame` show?
**Answer:** Lists all services sorted by time taken to initialize at boot (slowest first).

### Q9: What is the difference between `journalctl -b` and `journalctl -b -1`?
**Answer:** `-b` shows logs from the current boot. `-b -1` shows logs from the previous boot.

### Q10: How do you change the default systemd target?
**Answer:** `systemctl set-default multi-user.target` (or `graphical.target` for GUI).

### Q11: What is `/etc/fstab` used for?
**Answer:** Defines filesystem mounts — which partitions to mount, where, and with what options. Read at boot for automatic mounts.

### Q12: How do you recover from a GRUB failure using a Live USB?
**Answer:** Boot from Live USB, mount the root partition, `chroot` into it, then run `grub-install` and `update-grub`.

### Q13: What command rebuilds the initramfs on Debian/Ubuntu?
**Answer:** `sudo update-initramfs -u`

### Q14: What does `cat /proc/cmdline` show?
**Answer:** The kernel boot parameters passed by the bootloader (e.g., root device, console settings, quiet).

### Q15: What is a kernel panic and what causes it?
**Answer:** A fatal kernel error where the system halts. Caused by corrupted rootfs, missing initramfs, bad kernel modules, or hardware failures.


*Linux SysAdmin Course | Part 10 of ∞ | Reverse Engineering Approach*
*Previous → Part 9: Process Management — ps, top, kill, and Signals*
*Next → Part 11: Package Management — apt, dnf, yum, snap*

[← Previous](part9.md) | [Next →](part11.md)



[← Previous](18-whats-coming-in-part-11.md) | [↑ Index](index.md)
