## 🔍 Section 2: Loading and Unloading Modules

### Loading Modules — modprobe

`modprobe` is the preferred way to load modules because it handles dependencies.

```bash
# Load a module (with dependencies)
sudo modprobe usb-storage

# Load a module that is already loaded (no error)
sudo modprobe ext4

# Load with parameters
sudo modprobe usb-storage delay_use=5

# Dry run (show what would happen)
sudo modprobe --dry-run usb-storage

# Show module dependencies
sudo modprobe --show-depends usb-storage
```

### Loading Modules — insmod

`insmod` is lower-level. It does NOT handle dependencies.

```bash
# Load a single module (no dependency resolution)
sudo insmod /lib/modules/$(uname -r)/kernel/drivers/usb/storage/usb-storage.ko

# insmod requires full path to .ko file
# insmod will fail if dependencies aren't already loaded

# Always prefer modprobe over insmod
```

### Unloading Modules — modprobe -r

```bash
# Unload a module (removes dependencies if unused)
sudo modprobe -r usb-storage

# Unload multiple modules
sudo modprobe -r ext4 mbcache jbd2
```

### Unloading Modules — rmmod

```bash
# Remove a single module (no dependency check)
sudo rmmod usb-storage

# Force remove (even if in use — DANGEROUS)
sudo rmmod -f usb-storage

# Always prefer modprobe -r over rmmod
```

### Common Errors

```bash
# Error: Module is in use
# rmmod: ERROR: Module xyz is in use by: abc
# Solution: Remove the dependent module first
sudo modprobe -r abc
sudo modprobe -r xyz

# Error: Module not found
# modprobe: FATAL: Module xyz not found in directory
# Solution: Module may not exist or needs to be built

# Error: Operation not permitted
# Insufficient permissions (need root)
```

### Blacklisting Modules

Sometimes you need to prevent a module from loading:

```bash
# Method 1: /etc/modprobe.d/blacklist.conf
echo "blacklist pcspkr" | sudo tee /etc/modprobe.d/blacklist-pcspkr.conf
# (pcspkr is the PC speaker/beep module)

# Method 2: Kernel command line
# Add to GRUB_CMDLINE_LINUX in /etc/default/grub:
# modprobe.blacklist=pcspkr

# Check blacklist
# Module will show as "blacklisted" if you try to load it
sudo modprobe pcspkr
# modprobe: FATAL: Module pcspkr is blacklisted
```

---



---

[← Previous](04-level-2-intermediary-module-management.md) | [↑ Index](index.md) | [Next →](06-section-3-module-dependencies.md)
