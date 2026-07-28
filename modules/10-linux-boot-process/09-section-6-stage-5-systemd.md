## 🔍 Section 6: Stage 5 — systemd Initialization

After the kernel finishes, it starts the first userspace process: **systemd** (PID 1).

### What systemd Does

```bash
1. Mounts filesystems listed in /etc/fstab
2. Starts udev (device manager — creates /dev entries)
3. Loads kernel modules
4. Sets up networking
5. Starts system services (SSH, cron, web server...)
6. Reaches the default target (multi-user or graphical)
```

### systemd Targets

```bash
# Targets are like runlevels in the old SysV init
# They represent different system states

# Common targets:
poweroff.target        # System is powered off
rescue.target          # Single-user mode, basic system
emergency.target       # Emergency shell, only root filesystem
multi-user.target      # Normal multi-user, no GUI (text mode)
graphical.target       # Multi-user with GUI
reboot.target          # Reboot

# Check current target
systemctl get-default

# Set default target
sudo systemctl set-default multi-user.target

# Switch to a target right now
sudo systemctl isolate rescue.target
```

### Analyzing Boot Performance

```bash
# Show how long each service took to start
systemd-analyze blame

# Show critical chain (what was the bottleneck)
systemd-analyze critical-chain

# Show overall boot time
systemd-analyze time

# Plot boot chart (generates SVG)
systemd-analyze plot > boot_plot.svg
```

### Viewing Boot Logs

```bash
# All messages from this boot
journalctl -b

# Kernel messages only
journalctl -b -k

# Errors and warnings only
journalctl -b -p err

# Messages sorted by priority
journalctl -b -p warning..emerg

# Previous boot messages (if boot failed)
journalctl -b -1
```





[← Previous](08-section-5-stage-4-kernel.md) | [↑ Index](index.md) | [Next →](10-section-7-the-boot-process.md)
