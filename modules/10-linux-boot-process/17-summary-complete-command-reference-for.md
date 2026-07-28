## 📋 Summary — Complete Command Reference for Part 10

### Level 1: Basic Commands — Boot Information and Mode

| Command | Action |
|---------|--------|
| `uname -r` | Kernel version |
| `uname -a` | All system info |
| `cat /proc/cmdline` | Kernel boot parameters |
| `ls /sys/firmware/efi` | Check UEFI (exists = UEFI) |
| `sudo fdisk -l /dev/sda` | Check partition table type |

### Level 2: Intermediary Commands — GRUB, systemd, Filesystem

| Command | Action |
|---------|--------|
| `dmesg` | Kernel ring buffer (boot messages) |
| `dmesg -T` | Boot messages with timestamps |
| `cat /etc/default/grub` | GRUB configuration |
| `sudo update-grub` | Regenerate GRUB config (Debian) |
| `sudo grub2-mkconfig -o /boot/grub2/grub.cfg` | Regenerate (Fedora/RHEL) |
| `grub-install /dev/sda` | Install GRUB to MBR |
| `systemd-analyze time` | Total boot time |
| `systemd-analyze blame` | Per-service boot times |
| `systemd-analyze critical-chain` | Boot bottleneck |
| `systemd-analyze plot` | Generate boot chart |
| `systemctl get-default` | Current default target |
| `systemctl set-default target` | Change default target |
| `systemctl isolate target` | Switch to target now |
| `systemctl --failed` | List failed services |
| `journalctl -b` | All logs from current boot |
| `journalctl -b -k` | Kernel logs from current boot |
| `journalctl -b -p err` | Errors from current boot |
| `journalctl -b -1` | Logs from previous boot |
| `cat /etc/fstab` | Filesystem table |
| `sudo blkid` | List UUIDs of all partitions |
| `mount` | Show mounted filesystems |

### Level 3: Advanced Commands — Initramfs

| Command | Action |
|---------|--------|
| `lsinitramfs /boot/initrd.img-*` | List initramfs contents |
| `sudo update-initramfs -u` | Rebuild initramfs (Debian) |
| `sudo dracut --force` | Rebuild initramfs (Fedora/RHEL) |





[← Previous](16-practice-section-15-hands-on-exercises.md) | [↑ Index](index.md) | [Next →](18-whats-coming-in-part-11.md)
