## 🔍 Section 7: Device Drivers and udev

### What is udev?

udev is the device manager for the Linux kernel. It:
- Creates device nodes in `/dev`
- Handles device naming
- Runs rules when devices are added/removed
- Manages persistent device naming

### udev Rules

```bash
# udev rule location
/etc/udev/rules.d/           # Custom rules
/usr/lib/udev/rules.d/       # System rules

# Rule format:
# ACTION=="add", SUBSYSTEM=="usb", ATTR{product}=="MyDevice", SYMLINK+="mydriver"

# Example: Create persistent name for a USB drive
# /etc/udev/rules.d/99-usb-drive.rules
# ACTION=="add", SUBSYSTEM=="block", KERNEL=="sd*", ATTRS{serial}=="ABCD1234", SYMLINK+="backup_drive"
```

### Viewing udev Information

```bash
# Get info about a device
udevadm info --query=all --name=/dev/sda

# Monitor udev events (for debugging)
sudo udevadm monitor

# Trigger udev rules manually
sudo udevadm trigger

# Reload udev rules
sudo udevadm control --reload
```

### Persistent Device Naming

```bash
# Network interfaces (systemd's predictable naming)
# Instead of eth0, you get names like:
#   enp0s3     (Ethernet, PCI bus 0, slot 3)
#   ens33      (Ethernet, slot 33)
#   wlp2s0     (WiFi, PCI bus 2, slot 0)

# Override with udev rule (if needed)
# /etc/systemd/network/10-rename.link
```

---



---

[← Previous](10-section-6-building-a-custom.md) | [↑ Index](index.md) | [Next →](12-practice-section-15-hands-on-exercises.md)
