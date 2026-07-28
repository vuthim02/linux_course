## 🔍 Section 7: The Boot Process in Detail — Kernel Messages

Watch the actual boot process:

```bash
# View kernel ring buffer (boot messages)
dmesg

# Follow live boot messages (if you have a serial console)
dmesg -w

# Filter for specific hardware
dmesg | grep -i "usb"
dmesg | grep -i "ata\|sda"
dmesg | grep -i "memory"

# Show boot time stamps
dmesg -T | tail -20

# Check what was detected during boot
dmesg | grep -E "Detected|Found|initialized"
```

### Key dmesg Output to Understand

```bash
# Memory detected
[    0.000000] Memory: 8182384K/8380416K available

# CPU detected
[    0.000000] smpboot: CPU0: Intel(R) Core(TM) i7-8700K

# Root filesystem mounted
[    3.452819] EXT4-fs (sda2): mounted filesystem with ordered data mode

# Network interface
[    4.123456] e1000: eth0 NIC Link is Up 1000 Mbps

# First userspace process
[    4.567890] Run /init as init process
```





[← Previous](09-section-6-stage-5-systemd.md) | [↑ Index](index.md) | [Next →](11-section-10-understanding-etcfstab.md)
