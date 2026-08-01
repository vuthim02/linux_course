## 🔍 Section 7: Kernel Updates

Kernel updates are the most impactful type of update.

### Checking Kernel Version

```bash
# Current kernel
uname -r

# Installed kernels
dpkg -l | grep linux-image
# OR
rpm -qa | grep kernel

# Available kernel updates
apt list --upgradable 2>/dev/null | grep "^linux-image"
```

### Kernel Update Process

```bash
# 1. Install new kernel (alongside old one, version will vary)
#    Use 'apt list --upgradable | grep linux-image' to find available version
sudo apt install linux-image-6.2.0-25-generic

# 2. Update GRUB (automatically done)
sudo update-grub

# 3. Reboot
sudo reboot

# 4. Verify new kernel
uname -r
```

### Managing Multiple Kernels

```bash
# List all installed kernels
dpkg -l | grep linux-image | awk '{print $2}'

# Keep at least 2 kernels (current + one fallback)
# Remove old kernels (automatic)
sudo apt autoremove --purge

# Manually remove old kernel
sudo apt purge linux-image-5.15.0-92-generic

# On Fedora/RHEL:
dnf list installed kernel
sudo dnf remove kernel-5.14.0-362
```

### Why Keep Old Kernels?

```bash
# If new kernel fails to boot:
# 1. Reboot
# 2. Hold Shift (BIOS) or Esc (UEFI) during boot
# 3. Select "Advanced options" in GRUB
# 4. Boot the previous kernel
# 5. Remove or hold the broken kernel
```





[← Previous](09-section-6-update-strategies-for.md) | [↑ Index](index.md) | [Next →](11-level-3-advanced-rollback-and.md)
