## 📝 Final Self-Test — Can You Answer These?

1. What are three ways to boot into single-user/rescue mode?
2. How do you reset a lost root password from GRUB?
3. What does fsck do and when should you run it?
4. What is the initramfs emergency shell?
5. How do you reinstall GRUB from a Live USB?
6. What is the purpose of chroot in system recovery?
7. What are the steps to bind-mount virtual filesystems for chroot?
8. How do you check disk health with SMART?
9. What GRUB rescue commands list available drives?
10. What does `systemctl rescue` do vs `systemctl emergency`?
11. How do you force a filesystem check on the next reboot?
12. What is '/forcefsck' used for?
13. What kernel parameter boots directly to a bash shell?
14. How do you check what was in the previous boot's logs?
15. What is the most important thing to have before a system fails?

**Score:** 12/15 correct = you are ready to handle real recovery situations.


## Answer Key

### Q1: What are three ways to boot into single-user/rescue mode?
**Answer:** 1) Add `single` or `rescue` to kernel parameters at GRUB, 2) `systemctl isolate rescue.target`, 3) Hold Shift at boot for GRUB menu.

### Q2: How do you reset a lost root password from GRUB?
**Answer:** Edit GRUB entry, add `rd.break` or `init=/bin/bash` to kernel params, boot, remount root rw, `passwd root`, reboot.

### Q3: What does fsck do and when should you run it?
**Answer:** Checks and repairs filesystem inconsistencies. Run on unmounted filesystems, typically when boot fails or after a crash.

### Q4: What is the initramfs emergency shell?
**Answer:** A minimal shell provided by initramfs when the real rootfs can't be mounted. Allows fixing fstab, LVM, or filesystem issues.

### Q5: How do you reinstall GRUB from a Live USB?
**Answer:** `mount /dev/sda1 /mnt && grub-install --root-directory=/mnt /dev/sda` or use `efibootmgr` for UEFI.

### Q6: What is the purpose of chroot in system recovery?
**Answer:** Changes the apparent root directory, allowing you to work on the damaged system's files from a recovery environment as if it were booted.

### Q7: What are the steps to bind-mount virtual filesystems for chroot?
**Answer:** `mount --bind /dev /mnt/dev && mount --bind /proc /mnt/proc && mount --bind /sys /mnt/sys && chroot /mnt /bin/bash`

### Q8: How do you check disk health with SMART?
**Answer:** `smartctl -a /dev/sda` — shows all SMART attributes. `smartctl -t short` runs a test.

### Q9: What GRUB rescue commands list available drives?
**Answer:** `ls` (lists devices), `ls (hd0,msdos1)/` (lists files on a partition).

### Q10: What does `systemctl rescue` do vs `systemctl emergency`?
**Answer:** `rescue` boots to single-user with most services. `emergency` boots to minimal shell with only rootfs mounted read-only.

### Q11: How do you force a filesystem check on the next reboot?
**Answer:** `sudo touch /forcefsck` (older systems) or `sudo tune2fs -C 5 /dev/sda1` or add `fsck.force=y` to kernel params.

### Q12: What is `/forcefsck` used for?
**Answer:** When present, `fsck` runs on all filesystems at boot regardless of their state. Legacy method (use `tune2fs` for modern systems).

### Q13: What kernel parameter boots directly to a bash shell?
**Answer:** `init=/bin/bash` — bypasses init/systemd entirely, giving a root shell.

### Q14: How do you check what was in the previous boot's logs?
**Answer:** `journalctl -b -1` — shows all journal entries from the previous boot session.

### Q15: What is the most important thing to have before a system fails?
**Answer:** Backups — tested, verified, and ideally offsite. No amount of recovery skill replaces having good backups.


[← Previous](14-summary-complete-command-reference-for.md) | [↑ Index](index.md) | [Next →](16-whats-next-after-part-25.md)
