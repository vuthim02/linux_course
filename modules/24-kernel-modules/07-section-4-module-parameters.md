## 🔍 Section 4: Module Parameters

### Passing Parameters to Modules

```bash
# Method 1: Command line when loading
sudo modprobe usb-storage delay_use=5

# Method 2: /etc/modprobe.d/ config file
echo "options usb-storage delay_use=5" | sudo tee /etc/modprobe.d/usb-storage.conf

# Method 3: Kernel command line (for built-in drivers)
# Add to GRUB_CMDLINE_LINUX:
# usb-storage.delay_use=5
```

### Viewing Module Parameters

```bash
# Show available parameters
modinfo -p usb-storage

# Show current parameter values
# Method 1: /sys/module/
cat /sys/module/usb_storage/parameters/delay_use

# Method 2: modinfo with -F
modinfo -F parm usb-storage

# Common parameter examples:
# - max_batch_time (ext4): Maximum time to wait for IO
# - nr_requests (block): Number of IO requests to queue
# - delay_use (usb-storage): Delay before using USB storage
```

---



---

[← Previous](06-section-3-module-dependencies.md) | [↑ Index](index.md) | [Next →](08-level-3-advanced-building-and.md)
