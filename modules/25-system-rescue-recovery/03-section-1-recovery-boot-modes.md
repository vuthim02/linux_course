## 🔍 Section 1: Recovery Boot Modes

### Single-User Mode (Rescue Target)

Single-user mode boots with minimal services — just a root shell.

```bash
# Boot into single-user mode:
# Method 1: From GRUB menu
# 1. Reboot
# 2. Press 'e' on the kernel entry in GRUB
# 3. Find the line starting with "linux" or "linux16"
# 4. Add "single" or "1" or "S" to the end of the line
# 5. Press Ctrl+X or F10 to boot

# Method 2: From command line
sudo systemctl rescue

# Method 3: Set default for next boot
sudo systemctl set-default rescue.target
sudo reboot
# Then set back: sudo systemctl set-default multi-user.target
```

### Rescue Target (systemd)

```bash
# Rescue = single-user mode with basic filesystem mounted
sudo systemctl rescue

# This brings you to:
# - Root filesystem mounted (read-write)
# - Basic kernel modules loaded
# - No network services
# - Root shell prompt
```

### Emergency Target

```bash
# Emergency = only a root shell, root fs read-only
sudo systemctl emergency

# Or from GRUB: add "emergency" to kernel command line

# This is the most minimal environment:
# - Root fs mounted read-only
# - Nothing else
# - Only what's built into the kernel works
```

### Differences

| Mode | Root FS | Services | Network | Use Case |
|------|---------|----------|---------|----------|
| Emergency | Read-only | None | No | Last resort, root fs repair |
| Rescue | Read-write | Basic | No | Password reset, config fix |
| Multi-user | Read-write | All non-GUI | Yes | Normal operation |
| Graphical | Read-write | All | Yes | Normal with GUI |





[← Previous](02-level-1-basic-understanding-rescue.md) | [↑ Index](index.md) | [Next →](04-level-2-intermediary-password-reset.md)
