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





[← Previous](12-level-3-advanced-boot-recovery.md) | [↑ Index](index.md) | [Next →](14-section-9-kernel-panic-and.md)
