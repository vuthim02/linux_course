## 🔍 Section 5: Troubleshooting Kernel Modules

### Checking if a Module Loaded

```bash
# List all modules
lsmod | grep MODULE_NAME

# Check kernel messages for module events
dmesg | grep MODULE_NAME
dmesg | grep "usb\|module\|driver"

# Check if module exists in module tree
modinfo MODULE_NAME
```

### Module Not Loading

```bash
# Debug steps:

# 1. Check if module exists
modinfo MODULE_NAME

# 2. Check kernel messages
dmesg | tail -30

# 3. Try loading with verbose output
sudo modprobe -v MODULE_NAME

# 4. Check if blacklisted
grep -r "blacklist MODULE_NAME" /etc/modprobe.d/

# 5. Check hardware compatibility (lspci / lsusb)
lspci -k | grep -A 3 "VGA\|Ethernet\|Network"
lsusb -t
```

### Hardware-Driver Matching

```bash
# Find which driver handles a PCI device
lspci -k

# Output example:
# 00:1f.2 SATA controller: Intel Corporation 6 Series Chipset Family
#         Subsystem: Dell Device 04a6
#         Kernel driver in use: ahci
#         Kernel modules: ahci

# Find which driver handles a USB device
lsusb -t

# Check loaded modules for a device
udevadm info --query=all --name=/dev/sda | grep -i driver
```

### Resolving Conflicts

```bash
# Two modules cannot use the same hardware
# Scenario: nouveau vs nvidia (both want the GPU)

# Check which is loaded
lsmod | grep -E "nouveau|nvidia"

# Blacklist the one you don't want
echo "blacklist nouveau" | sudo tee /etc/modprobe.d/blacklist-nouveau.conf

# Update initramfs
sudo update-initramfs -u

# Reboot
sudo reboot
```





[← Previous](08-level-3-advanced-building-and.md) | [↑ Index](index.md) | [Next →](10-section-6-building-a-custom.md)
