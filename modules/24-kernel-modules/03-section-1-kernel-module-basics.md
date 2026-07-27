## 🔍 Section 1: Kernel Module Basics

### What Are Kernel Modules?

Kernel modules are pieces of code that can be loaded into or removed from the running kernel without rebooting. They extend kernel functionality:

- **Device drivers**: Hardware support (network cards, storage, USB)
- **Filesystem drivers**: ext4, XFS, NTFS, etc.
- **Network protocols**: Netfilter, IPsec, tunneling
- **Security modules**: SELinux, AppArmor
- **Miscellaneous**: Crypto modules, hardware monitoring

### Why Modules Instead of Built-in?

```
Built-in (compiled into kernel image):
  ✓ Always available (no loading needed)
  ✓ No risk of missing module at boot
  ✗ Larger kernel image
  ✗ Wastes memory if unused
  ✗ Requires kernel recompile to change

Modules (separate .ko files):
  ✓ Smaller kernel image
  ✓ Memory saved when not in use
  ✓ Can be loaded/unloaded dynamically
  ✓ No recompile needed for different hardware
  ✗ Need to be available at load time
  ✗ Can fail to load (dependencies, conflicts)
```

### Module Files

```bash
# Where kernel modules live
ls /lib/modules/$(uname -r)/
ls /lib/modules/$(uname -r)/kernel/

# Module files have .ko (kernel object) extension
ls /lib/modules/$(uname -r)/kernel/drivers/

# Common module categories
ls /lib/modules/$(uname -r)/kernel/drivers/net/     # Network drivers
ls /lib/modules/$(uname -r)/kernel/drivers/usb/     # USB drivers
ls /lib/modules/$(uname -r)/kernel/fs/              # Filesystem modules
```

### Listing Loaded Modules — lsmod

```bash
# List all loaded kernel modules
lsmod

# Output format:
# Module           Size   Used by
# nf_conntrack    139264  8 nf_nat,xt_conntrack,nf_conntrack_netlink
# xt_state         16384  2
# xt_conntrack     16384  4
# ext4            720896  3
# usb_storage      77824  0

# Columns:
# Module:   Name of the module
# Size:     Memory used (bytes)
# Used by:  Count + list of dependent modules
```

### Module Information — modinfo

```bash
# Get detailed info about a module
modinfo ext4

# Output:
# filename:       /lib/modules/6.2.0/kernel/fs/ext4/ext4.ko
# license:        GPL
# description:    Fourth Extended Filesystem
# author:         Remy Card, Stephen Tweedie, et al.
# version:        1.00
# depends:        mbcache,jbd2
# intree:         Y
# firmware:       
# parm:           max_batch_time:Maximum amount of time for ext4 to...
# parm:           mb_stream_req:...
# parm:           errors:...

# Get module info for a specific parameter
modinfo -p ext4    # Show parameters only

# Find which module provides a specific alias
modinfo -F alias usb-storage
```

### Viewing Module Parameters

```bash
# Module parameters can be viewed after loading
cat /sys/module/EXT4/parameters/errors
# OR (module name varies in /sys):
ls /sys/module/ | grep ext4
cat /sys/module/ext4/parameters/errors
```

---



---

[← Previous](02-level-1-basic-kernel-module.md) | [↑ Index](index.md) | [Next →](04-level-2-intermediary-module-management.md)
