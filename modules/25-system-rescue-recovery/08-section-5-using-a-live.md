## 🔍 Section 5: Using a Live CD/USB

### Choosing a Rescue Environment

| Tool | Best For |
|------|----------|
| Ubuntu Live USB | General recovery, familiar environment |
| SystemRescue | Advanced recovery tools |
| GParted Live | Partition management |
| Super GRUB Disk | Bootloader repair |
| Hiren's Boot CD | Windows/Linux recovery |

### Essential Live USB Commands

```bash
# After booting Live USB, identify the system:
sudo fdisk -l
lsblk
blkid

# Check what's on a partition:
sudo mount /dev/sda1 /mnt
ls /mnt

# Mount the real root:
sudo mount /dev/sda1 /mnt

# Mount boot (if separate):
sudo mount /dev/sda2 /mnt/boot

# Mount efi (for UEFI):
sudo mount /dev/sda3 /mnt/boot/efi

# Bind virtual filesystems:
for dir in /dev /proc /sys /run; do
    sudo mount --bind "$dir" "/mnt$dir"
done

# chroot into the system:
sudo chroot /mnt
```

### Data Recovery from Live USB

```bash
# Copy important data before attempting repairs:
sudo mount /dev/sda1 /mnt
sudo cp -a /mnt/home /media/usb-backup/

# Or use rsync to network:
sudo rsync -av /mnt/home/ user@server:/backup/

# If filesystem is badly damaged:
sudo ddrescue /dev/sda /dev/sdb /tmp/ddrescue.log
```

---



---

[← Previous](07-section-4-grub-recovery.md) | [↑ Index](index.md) | [Next →](09-section-6-chroot-repair-a.md)
