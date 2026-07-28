## 🔍 Section 8: Rollback Strategies

### APT Rollback

```bash
# APT does NOT have a built-in rollback command
# Strategies:

# 1. Reinstall previous version from cache
ls /var/cache/apt/archives/nginx*.deb
sudo dpkg -i /var/cache/apt/archives/nginx_1.18.0-0ubuntu1_amd64.deb

# 2. Use apt log to see previous versions
grep "Upgrade" /var/log/apt/history.log | tail -5

# 3. Pin a package to a specific version
sudo apt-mark hold nginx
sudo apt install nginx=1.18.0-0ubuntu1

# 4. Use snapshot/backup (if available)
# VM snapshot restore
```

### DNF Rollback

```bash
# DNF has better rollback support

# View transaction history
dnf history

# Rollback a specific transaction
sudo dnf history undo 42

# Rollback to a specific date
sudo dnf history rollback 2024-01-15

# View what a rollback would do
dnf history undo 42 --dry-run

# Example:
# dnf history
# ID  Command line                    Date/time       Action
# 42  update nginx                    2024-01-15 14:22 Install/Upgrade
# 41  install httpd                   2024-01-14 10:00 Install

# Rollback transaction 42
sudo dnf history undo 42
# This removes the upgraded nginx and reinstalls the previous version
```

### Kernel Rollback

```bash
# 1. Reboot and select old kernel in GRUB

# 2. Once booted, remove the new kernel
sudo apt purge linux-image-6.2.0-25-generic
sudo update-grub

# 3. Hold kernel to prevent re-installation
sudo apt-mark hold linux-image-6.2.0-25-generic

# 4. Reboot again to verify
```

### Filesystem Snapshots (Advanced)

```bash
# Using LVM snapshots:
# Before update:
sudo lvcreate -L 5G -s -n root_snap /dev/vg/root

# If update fails:
sudo lvconvert --merge /dev/vg/root_snap
sudo reboot

# Using ZFS/btrfs snapshots:
# ZFS:
zfs snapshot -r rpool/ROOT@pre-update-2024-01-15
# Rollback:
zfs rollback -r rpool/ROOT@pre-update-2024-01-15
```





[← Previous](11-level-3-advanced-rollback-and.md) | [↑ Index](index.md) | [Next →](13-practice-section-15-hands-on-exercises.md)
