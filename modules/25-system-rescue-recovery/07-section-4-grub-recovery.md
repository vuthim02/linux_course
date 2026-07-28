## 🔍 Section 4: GRUB Recovery

### The GRUB Rescue Shell

```
When GRUB cannot find its configuration or modules, you get:

    GRUB loading...
    Welcome to GRUB!
    error: no such partition
    Entering rescue mode...
    grub rescue>
```

### GRUB Rescue Commands

```bash
# In the grub rescue shell:

# List available drives
ls

# Look for the boot partition
ls (hd0,msdos1)/
ls (hd0,gpt1)/

# Find the kernel and initrd
ls (hd0,msdos1)/boot/
ls (hd0,msdos1)/boot/grub/

# Set root and prefix
set root=(hd0,msdos1)
set prefix=(hd0,msdos1)/boot/grub

# Load normal module
insmod normal
normal

# Or manually boot:
insmod linux
linux /boot/vmlinuz-6.1.0 root=/dev/sda1
initrd /boot/initrd.img-6.1.0
boot
```

### Reinstalling GRUB

```bash
# From a Live USB:
# 1. Boot from Live USB
# 2. Mount root partition:
sudo mount /dev/sda1 /mnt

# 3. Mount boot partition (if separate):
sudo mount /dev/sda2 /mnt/boot

# 4. Mount virtual filesystems:
sudo mount --bind /dev /mnt/dev
sudo mount --bind /proc /mnt/proc
sudo mount --bind /sys /mnt/sys

# 5. chroot:
sudo chroot /mnt

# 6. Reinstall GRUB (BIOS):
grub-install /dev/sda

# 7. Or for UEFI:
grub-install --target=x86_64-efi --efi-directory=/boot/efi

# 8. Update GRUB config:
update-grub

# 9. Exit and reboot:
exit
sudo umount -R /mnt
sudo reboot
```

### GRUB Configuration Issues

```bash
# If GRUB menu is hidden or wrong:
# Edit /etc/default/grub:

GRUB_TIMEOUT=5           # Show menu for 5 seconds
GRUB_TIMEOUT_STYLE=menu  # Always show menu (not hidden)
GRUB_CMDLINE_LINUX=""    # Kernel parameters

# After editing:
sudo update-grub
```





[← Previous](06-section-3-filesystem-repair-fsck.md) | [↑ Index](index.md) | [Next →](08-section-5-using-a-live.md)
