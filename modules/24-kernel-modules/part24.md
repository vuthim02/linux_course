# 🐧 Linux System Administrator — Complete Course
## Part 24 of ∞: Kernel Modules and Device Drivers

---

> **Reverse Engineering Approach:** The Linux kernel is a monolith — but a modular one. Every piece of hardware you plug in, every filesystem you mount, every network protocol you use, is likely a kernel module. When a device doesn't work, you need to figure out which module drives it, whether it's loaded, and what parameters it needs. Understanding kernel modules is the difference between "Linux doesn't support my hardware" and "let me load the right driver."

---

## 🎯 What You Will Achieve in Part 24

This module is organized into three progressive levels:

| Level | Focus | What You'll Master |
|-------|-------|--------------------|
| ⭐ Level 1: Basic | Kernel Module Basics | Understanding kernel modules, `lsmod`, `modinfo`, exploring loaded modules |
| ⭐ Level 2: Intermediary | Module Management | Loading/unloading modules (`modprobe`, `insmod`, `rmmod`), dependencies, parameters |
| ⭐ Level 3: Advanced | Building and Troubleshooting | Building custom modules, troubleshooting driver issues, udev, and module internals |

---

## ⭐ Level 1: Basic — Kernel Module Basics

![Linux kernel architecture — subsystems and module interfaces](https://upload.wikimedia.org/wikipedia/commons/1/1c/Linux_kernel_diagram.svg)

*Linux kernel architecture showing subsystem layout (Wikimedia Commons / public domain)*

> **Level 1 Goal:** Understand what kernel modules are, how to list loaded modules, and how to get detailed information about specific modules.

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

## ⭐ Level 2: Intermediary — Module Management

![Linux kernel IO stack — device driver layers](https://upload.wikimedia.org/wikipedia/commons/3/30/IO_stack_of_the_Linux_kernel.svg)

*Linux kernel IO stack — layers from application to hardware device (Wikimedia Commons / public domain)*

> **Level 2 Goal:** Load and unload kernel modules manually, manage module dependencies, pass parameters to modules, and understand automatic module loading.

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

## 🔍 Section 3: Module Dependencies

### Module Dependency Tree

```bash
# Show dependencies of a module
modinfo ext4 | grep depends
# depends:        mbcache,jbd2

# Show entire dependency tree
modprobe --show-depends ext4

# Display dependency graph (human readable)
lsmod | grep ext4
```

### Module Loading Order

```
When you load a module, modprobe:
1. Checks if module exists
2. Checks dependencies
3. Loads dependencies in order (if not already loaded)
4. Loads the requested module

When you unload:
1. Checks if other modules depend on this one
2. If dependencies exist, refuses to unload
3. If no dependencies, unloads the module
4. Optionally unloads unused dependencies (-r flag)
```

### modules.dep

```bash
# The dependency database
cat /lib/modules/$(uname -r)/modules.dep | grep ext4

# Format: module.ko: dependency1.ko dependency2.ko
# Example:
# kernel/fs/ext4/ext4.ko: kernel/fs/mbcache/mbcache.ko kernel/fs/jbd2/jbd2.ko

# Rebuild dependency database
sudo depmod -a
```

---

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

## ⭐ Level 3: Advanced — Building and Troubleshooting Kernel Modules

![Simplified structure of the Linux kernel — modules and core](https://upload.wikimedia.org/wikipedia/commons/2/26/Simplified_Structure_of_the_Linux_Kernel.svg)

*Simplified Linux kernel structure showing core components and module boundaries (Wikimedia Commons / public domain)*

> **Level 3 Goal:** Troubleshoot kernel module issues, build custom modules, understand udev for device management, and work with device drivers.

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

---

## 🔍 Section 6: Building a Custom Kernel Module

### Prerequisites

```bash
# Install kernel headers and build tools
# Debian/Ubuntu
sudo apt install linux-headers-$(uname -r) build-essential

# Fedora/RHEL
sudo dnf install kernel-devel kernel-headers gcc make

# Verify headers are installed
ls /lib/modules/$(uname -r)/build/
```

### Simple "Hello World" Module

```bash
cd ~/linux-course/part24
mkdir -p hello_module
cd hello_module
```

```c
// hello.c — Simple kernel module
#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/init.h>

static int __init hello_init(void)
{
    printk(KERN_INFO "Hello, kernel module loaded!\n");
    return 0;
}

static void __exit hello_exit(void)
{
    printk(KERN_INFO "Goodbye, kernel module unloaded!\n");
}

module_init(hello_init);
module_exit(hello_exit);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Linux Course");
MODULE_DESCRIPTION("A simple hello world module");
```

```makefile
# Makefile for the hello module
obj-m += hello.o

all:
    make -C /lib/modules/$(shell uname -r)/build M=$(PWD) modules

clean:
    make -C /lib/modules/$(shell uname -r)/build M=$(PWD) clean
```

```bash
# Build the module
make

# Load the module
sudo insmod hello.ko

# Check kernel messages
dmesg | tail -5
# Should see: Hello, kernel module loaded!

# Check if loaded
lsmod | grep hello

# Unload
sudo rmmod hello

# Check kernel messages again
dmesg | tail -5
# Should see: Goodbye, kernel module unloaded!
```

---

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

## 💻 PRACTICE SECTION — 15 Hands-On Exercises

---

### Level 1 Practices: Kernel Module Basics

---

### ✅ Practice 1: List All Loaded Modules

```bash
mkdir -p ~/linux-course/part24
cd ~/linux-course/part24

echo "=== Loaded Kernel Modules ==="
lsmod

echo ""
echo "Total modules loaded: $(lsmod | wc -l)"
echo "Total memory used by modules: $(lsmod | awk 'NR>1 {sum+=$2} END {print sum}') bytes"
```

---

### ✅ Practice 2: Get Detailed Info on a Module

```bash
cd ~/linux-course/part24

# Pick the first module from lsmod and get its info
FIRST_MOD=$(lsmod | awk 'NR==2{print $1}')
echo "=== Module info for: $FIRST_MOD ==="
modinfo $FIRST_MOD

echo ""
echo "=== All parameters for this module ==="
modinfo -p $FIRST_MOD 2>/dev/null || echo "No parameters"
```

---

### ✅ Practice 3: Explore Module Directories

```bash
cd ~/linux-course/part24

echo "=== Kernel Module Tree ==="
echo "Kernel version: $(uname -r)"
echo ""

# Count modules
echo "Total module files:"
find /lib/modules/$(uname -r) -name "*.ko" 2>/dev/null | wc -l

echo ""
echo "=== Module categories ==="
ls /lib/modules/$(uname -r)/kernel/

echo ""
echo "=== Network drivers ==="
ls /lib/modules/$(uname -r)/kernel/drivers/net/ | head -10

echo ""
echo "=== Filesystem modules ==="
ls /lib/modules/$(uname -r)/kernel/fs/
```

---

### ✅ Practice 5: Find Module for a Hardware Device

```bash
cd ~/linux-course/part24

echo "=== Hardware and their drivers ==="

# PCI devices
echo "--- PCI devices ---"
lspci -k 2>/dev/null | grep -E "Kernel driver|Kernel modules" | head -10

# USB devices
echo ""
echo "--- USB devices ---"
lsusb -t 2>/dev/null | head -10

# Check network interfaces
echo ""
echo "--- Network interfaces ---"
for iface in /sys/class/net/*/device/driver; do
    if [ -f "$iface" ]; then
        echo "  $(basename $(dirname $(dirname $iface))): $(basename $(readlink $iface))"
    fi
done 2>/dev/null || echo "Cannot read driver info"
```

---

### ✅ Practice 7: Show Module Dependencies

```bash
cd ~/linux-course/part24

# Pick a complex module and show its dependencies
echo "=== Module dependencies ==="
lsmod | awk 'NR>1 {print $1}' | head -20 | while read mod; do
    DEPS=$(modinfo -F depends "$mod" 2>/dev/null)
    if [ -n "$DEPS" ]; then
        echo "  $mod depends on: $DEPS"
    fi
done

echo ""
echo "=== Dependency tree example: ext4 ==="
modprobe --show-depends ext4 2>/dev/null | head -10
```

---

### Level 2 Practices: Module Management

---

### ✅ Practice 4: Test Loading and Unloading a Module

```bash
cd ~/linux-course/part24

echo "=== Safe module test ==="

# Find a module that is safe to load/unload (not in use)
lsmod | tail -10

# Let's test with a module that's likely removable
# Try the pcspkr module (PC speaker) — safe to test
echo "Testing module load/unload..."
echo ""

# Check if pcspkr exists
if modinfo pcspkr &>/dev/null; then
    echo "pcspkr module exists"
    if ! lsmod | grep -q pcspkr; then
        echo "Loading pcspkr..."
        sudo modprobe -v pcspkr 2>&1 || echo "Failed to load (may be blacklisted)"
    fi
    
    echo ""
    echo "Checking if loaded:"
    lsmod | grep pcspkr || echo "Not loaded"
    
    # Try to unload
    echo ""
    echo "Unloading pcspkr..."
    sudo modprobe -r pcspkr 2>&1 || echo "Failed to unload"
else
    echo "pcspkr not available on this system"
    echo ""
    echo "=== Modprobe dry-run example ==="
    sudo modprobe --dry-run -v ext4 2>/dev/null
fi
```

---

### ✅ Practice 6: Blacklist a Module (Simulated)

```bash
cd ~/linux-course/part24

# Create a simulation of blacklisting
cat << 'EOF' > blacklist_sim.txt
=== Module Blacklisting Simulation ===

1. Create a blacklist file:
   echo "blacklist pcspkr" | sudo tee /etc/modprobe.d/blacklist-pcspkr.conf

2. Verify it's in effect:
   sudo modprobe pcspkr
   # Output: modprobe: FATAL: Module pcspkr is blacklisted

3. To remove the blacklist:
   sudo rm /etc/modprobe.d/blacklist-pcspkr.conf

4. Alternative: soft block via install directive
   echo "install pcspkr /bin/true" | sudo tee /etc/modprobe.d/nopcspkr.conf
   # This replaces the module with /bin/true (does nothing)

=== When to blacklist ===

- Conflicting drivers (nouveau vs nvidia)
- Buggy modules that cause crashes
- Security concerns (unused modules)
- Hardware that should use a different driver
EOF

cat blacklist_sim.txt
```

---

### ✅ Practice 8: View and Modify Module Parameters

```bash
cd ~/linux-course/part24

# Show module parameters via sysfs
echo "=== Module Parameters (via sysfs) ==="
for mod in /sys/module/*/parameters/; do
    MODNAME=$(basename $(dirname $mod))
    PARAMS=$(ls "$mod" 2>/dev/null | head -5)
    if [ -n "$PARAMS" ]; then
        echo "  $MODNAME:"
        for param in $PARAMS; do
            val=$(cat "${mod}${param}" 2>/dev/null)
            echo "    $param = $val"
        done
    fi
done | head -30

echo ""
echo "=== Setting parameters ==="
echo "Parameters can be set:"
echo "  1. At load time: sudo modprobe MODULE param=value"
echo "  2. In config file: /etc/modprobe.d/*.conf"
echo "  3. Via sysfs (if writable): echo value > /sys/module/MODULE/parameters/param"
```

---

### ✅ Practice 9: Module Configuration Files

```bash
cd ~/linux-course/part24

# Show existing modprobe configs
echo "=== Existing modprobe configuration ==="
for conf in /etc/modprobe.d/*.conf; do
    if [ -f "$conf" ]; then
        echo "--- $conf ---"
        cat "$conf"
        echo ""
    fi
done

# Create a sample config file
echo ""
echo "=== Creating sample config ==="
cat << 'EOF' | sudo tee /etc/modprobe.d/course-example.conf 2>/dev/null || echo "(no sudo — just showing the format)"
# Example modprobe configuration

# Blacklist unused modules
blacklist pcspkr
blacklist floppy

# Set default parameters
options usb-storage delay_use=5
options intel_idle max_cstate=4
EOF

# Cleanup
sudo rm -f /etc/modprobe.d/course-example.conf 2>/dev/null || true
```

---

### ✅ Practice 10: Module Autoload Configuration

```bash
cd ~/linux-course/part24

cat << 'EOF' > autoload_simulation.txt
=== Automatic Module Loading ===

Modules can be loaded automatically:

1. By udev (when hardware is detected)
2. By kernel (built-in alias matching)
3. By /etc/modules (legacy)
4. By /etc/modules-load.d/*.conf (modern)

=== /etc/modules-load.d/ ===

Files in /etc/modules-load.d/*.conf list modules to load at boot:
   # /etc/modules-load.d/my-modules.conf
   # Load these modules at boot
   ip_tables
   nf_conntrack

=== Currently loaded auto-load modules ===
EOF

ls /etc/modules-load.d/*.conf 2>/dev/null | while read f; do
    echo "--- $(basename $f) ---"
    cat "$f" | grep -v "^#" | grep -v "^$"
done

echo ""
echo "=== Legacy /etc/modules ==="
cat /etc/modules 2>/dev/null || echo "(not present on this system)"
```

---

### ✅ Practice 11: Module Dependency Map

```bash
cd ~/linux-course/part24

# Show the dependency map file
echo "=== Module dependency file ==="
echo "File: /lib/modules/$(uname -r)/modules.dep"
echo ""
echo "First 20 entries:"
head -20 /lib/modules/$(uname -r)/modules.dep 2>/dev/null || echo "Cannot read"

echo ""
echo "=== Check if modules.dep is up to date ==="
echo "To rebuild: sudo depmod -a"
```

---

### ✅ Practice 13: Find Module by Device

```bash
cd ~/linux-course/part24

# Use udevadm to find module for a device
echo "=== Device to Module Mapping ==="

# Check block devices
echo "--- Block devices ---"
for dev in /dev/sd?; do
    if [ -b "$dev" ]; then
        MOD=$(udevadm info --query=all --name="$dev" 2>/dev/null | grep "ID_BUS\|ID_MODEL\|DRIVER" | head -3)
        if [ -n "$MOD" ]; then
            echo "  $dev:"
            echo "$MOD" | sed 's/^/    /'
        fi
    fi
done 2>/dev/null

echo ""
echo "--- Driver mapping ---"
# Check all PCI devices with drivers
lspci -k 2>/dev/null | grep -B1 "Kernel driver in use" | grep -v "^--$"
```

---

### Level 3 Practices: Building and Troubleshooting

---

### ✅ Practice 12: Build a Simple Kernel Module (if build tools available)

```bash
cd ~/linux-course/part24

echo "=== Kernel Module Build Test ==="

# Check if build prerequisites are available
if [ -d "/lib/modules/$(uname -r)/build" ]; then
    echo "✓ Kernel build headers found"
else
    echo "✗ Kernel build headers not found"
    echo "  Install: sudo apt install linux-headers-$(uname -r)"
fi

if command -v gcc &>/dev/null; then
    echo "✓ GCC installed: $(gcc --version | head -1)"
else
    echo "✗ GCC not installed"
    echo "  Install: sudo apt install build-essential"
fi

if command -v make &>/dev/null; then
    echo "✓ Make installed"
else
    echo "✗ Make not installed"
fi

echo ""
echo "=== Source code for hello module ==="

# Create and show the module source
mkdir -p hello_module
cat > hello_module/hello.c << 'EOF'
#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/init.h>

static int __init hello_init(void)
{
    printk(KERN_INFO "Hello, kernel module loaded!\n");
    return 0;
}

static void __exit hello_exit(void)
{
    printk(KERN_INFO "Goodbye, kernel module unloaded!\n");
}

module_init(hello_init);
module_exit(hello_exit);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Linux Course");
MODULE_DESCRIPTION("A simple hello world module");
EOF

cat > hello_module/Makefile << 'EOF'
obj-m += hello.o

KDIR := /lib/modules/$(shell uname -r)/build
PWD := $(shell pwd)

all:
    $(MAKE) -C $(KDIR) M=$(PWD) modules

clean:
    $(MAKE) -C $(KDIR) M=$(PWD) clean
EOF

echo ""
echo "Module source and Makefile created in hello_module/"
echo "To build: cd hello_module && make"
echo "To load:  sudo insmod hello.ko"
echo "To view:  dmesg | tail"
echo "To unload: sudo rmmod hello"
```

---

### ✅ Practice 14: Module Troubleshooting Simulation

```bash
cd ~/linux-course/part24

cat << 'EOF' > troubleshoot_scenario.txt
=== KERNEL MODULE TROUBLESHOOTING SCENARIO ===

Scenario: You plug in a USB WiFi adapter, but it doesn't work.

Step 1: Is the device detected?
  lsusb
  # Look for your device in the list
  
Step 2: Is there a driver loaded?
  lsusb -t
  # Check if the device has a driver attached
  # If "driver=unknown" or "unbound" — driver is missing

Step 3: Check kernel messages for clues
  dmesg | tail -30
  dmesg | grep -i usb
  # Look for: "new USB device found", "usbcore: registered new interface driver"

Step 4: Find the right module
  ls /lib/modules/$(uname -r)/kernel/drivers/net/wireless/
  # Look for drivers matching your chipset

Step 5: Try different drivers
  sudo modprobe DRIVER_NAME
  # Common WiFi drivers: iwlwifi, ath9k, rtl8xxxu, rtl8192cu

Step 6: Check if it works now
  ip link show
  # Look for a new interface (wlan0, wlp2s0, etc.)
  
Step 7: Still not working? Check firmware
  dmesg | grep -i firmware
  # Some drivers need firmware files
  ls /lib/firmware/
  # Firmware may be missing and need to be installed separately
EOF

cat troubleshoot_scenario.txt
```

---

### ✅ Practice 15: Comprehensive Kernel Audit

```bash
cd ~/linux-course/part24

cat > kernel_audit.sh << 'EOF'
#!/bin/bash
set -euo pipefail

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
HOSTNAME=$(hostname)
REPORT="kernel_audit_report.txt"

echo "============================================" > "$REPORT"
echo "  KERNEL MODULES AUDIT REPORT" >> "$REPORT"
echo "  Hostname: $HOSTNAME" >> "$REPORT"
echo "  Date:     $TIMESTAMP" >> "$REPORT"
echo "============================================" >> "$REPORT"
echo "" >> "$REPORT"

# Section 1: Kernel version
echo "1. KERNEL VERSION" >> "$REPORT"
echo "  $(uname -a)" >> "$REPORT"
echo "" >> "$REPORT"

# Section 2: Loaded modules
echo "2. LOADED MODULES" >> "$REPORT"
echo "  Total: $(lsmod | wc -l)" >> "$REPORT"
echo "  Top 10 by memory usage:" >> "$REPORT"
lsmod | sort -k2 -rn | head -10 | awk '{printf "    %-20s %8d bytes\n", $1, $2}' >> "$REPORT"
echo "" >> "$REPORT"

# Section 3: Module categories
echo "3. MODULE CATEGORIES" >> "$REPORT"
echo "  Filesystem modules: $(ls /lib/modules/$(uname -r)/kernel/fs/ 2>/dev/null | wc -l)" >> "$REPORT"
echo "  Network drivers: $(ls /lib/modules/$(uname -r)/kernel/drivers/net/ 2>/dev/null | wc -l)" >> "$REPORT"
echo "  USB drivers: $(ls /lib/modules/$(uname -r)/kernel/drivers/usb/ 2>/dev/null | wc -l)" >> "$REPORT"
echo "  Sound drivers: $(ls /lib/modules/$(uname -r)/kernel/sound/ 2>/dev/null | wc -l)" >> "$REPORT"
echo "" >> "$REPORT"

# Section 4: Hardware and drivers
echo "4. HARDWARE DRIVERS" >> "$REPORT"
lspci -k 2>/dev/null | grep -E "Kernel driver" | sed 's/^/  /' >> "$REPORT"
echo "" >> "$REPORT"

# Section 5: Module config
echo "5. MODULE CONFIGURATION" >> "$REPORT"
echo "  Files in /etc/modprobe.d/: $(ls /etc/modprobe.d/ 2>/dev/null | wc -l)" >> "$REPORT"
echo "  Files in /etc/modules-load.d/: $(ls /etc/modules-load.d/ 2>/dev/null | wc -l)" >> "$REPORT"
echo "" >> "$REPORT"

# Section 6: Module dependencies
echo "6. MODULE DEPENDENCIES" >> "$REPORT"
echo "  Dependencies file: /lib/modules/$(uname -r)/modules.dep" >> "$REPORT"
echo "  Total entries: $(wc -l < /lib/modules/$(uname -r)/modules.dep 2>/dev/null)" >> "$REPORT"
echo "" >> "$REPORT"

echo "============================================" >> "$REPORT"
echo "  END OF AUDIT" >> "$REPORT"
echo "============================================" >> "$REPORT"

cat "$REPORT"
EOF

chmod +x kernel_audit.sh
./kernel_audit.sh
```

---

## 🧠 Deep Understanding — Kernel Module Internals

### How Modules Fit Into the Kernel

```
User space
    │
    ├── Application
    │       │
    │       ▼
    ├── System call interface
    │       │
    │       ▼
Kernel space
    │
    ├── VFS (Virtual File System)
    │       │
    │       ▼
    ├── ext4.ko  ←  Module  (loaded from disk)
    │       │
    │       ▼
    ├── Block layer
    │       │
    │       ▼
    ├── ahci.ko  ←  Module  (loaded from disk)
    │       │
    │       ▼
    ├── Hardware (SSD)
```

### Module Lifecycle

```
1. Module file (.ko) stored in /lib/modules/$(uname -r)/
2. modprobe reads modules.dep to find dependencies
3. Kernel allocates memory for module
4. Module is linked into kernel space
5. module_init() function runs (initialization)
6. Module is now active and registered
7. When unloaded, module_exit() runs (cleanup)
8. Memory is freed
```

### Module Versioning

```bash
# Modules are tied to exact kernel version
# A module built for kernel 6.2.0-22-generic
# will NOT load on kernel 6.2.0-23-generic

# Check module version magic
modinfo ext4 | grep vermagic

# Output:
# vermagic:       6.2.0-22-generic SMP mod_unload modversions

# If vermagic doesn't match, you get:
# modprobe: ERROR: could not insert 'xyz': Exec format error
# dmesg: module xyz: module version magic mismatch
```

### Module Utilities Summary

```
┌─────────────┬──────────────────────────────────────┐
│ Command     │ Purpose                              │
├─────────────┼──────────────────────────────────────┤
│ lsmod       │ List loaded modules                  │
│ modinfo     │ Show module information               │
│ modprobe    │ Load/unload modules (with deps)       │
│ insmod      │ Load single module (no deps)          │
│ rmmod       │ Remove single module (no deps)        │
│ depmod      │ Build module dependency database       │
│ modprobe -r │ Remove module with unused deps        │
└─────────────┴──────────────────────────────────────┘
```

---

## 📋 Summary — Complete Command Reference for Part 24

### Level 1: Basic Commands — Module Information

| Command | Action |
|---------|--------|
| `lsmod` | List loaded kernel modules |
| `modinfo MODULE` | Show module information |
| `modinfo -p MODULE` | Show module parameters |
| `ls /lib/modules/$(uname -r)` | List available module files |

### Level 2: Intermediary Commands — Module Management

| Command | Action |
|---------|--------|
| `sudo modprobe MODULE` | Load module with dependencies |
| `sudo modprobe -r MODULE` | Unload module with unused deps |
| `sudo insmod FILE` | Load single module (no deps) |
| `sudo rmmod MODULE` | Remove single module (no deps) |
| `sudo depmod -a` | Rebuild dependency database |
| `sudo modprobe -v MODULE` | Verbose module loading |

### Level 3: Advanced Commands — Building and Debugging

| Command | Action |
|---------|--------|
| `dmesg \| grep MODULE` | Check kernel messages for module |
| `lspci -k` | Show PCI device drivers |
| `lsusb -t` | Show USB device drivers |
| `udevadm info --name=DEV` | Show udev device info |
| `sudo udevadm monitor` | Monitor udev events |
| `make -C /lib/modules/...` | Build kernel modules |

---

## 🚀 What's Next?

**Congratulations! You've completed all 24 parts of the Linux System Administrator course.**

You now have:
- Foundation in Linux system administration
- Skills in package management, time sync, networking, and more
- Hands-on experience with 360+ practices (15 per module × 24 modules)
- Troubleshooting methodology for real-world problems

**Suggested next steps:**
- Linux Security (SELinux, AppArmor, auditd)
- Advanced Storage (LVM, RAID, Stratis)
- Containerization (Docker, Podman)
- Orchestration (Kubernetes basics)
- Configuration Management (Ansible, Puppet)

---

## 📝 Self-Test — Can You Answer These?

1. What is a kernel module and why is it used instead of building everything into the kernel?
2. How do you list all currently loaded kernel modules?
3. What does `modinfo` show about a module?
4. What is the difference between `modprobe` and `insmod`?
5. How do you unload a kernel module?
6. What does `depmod -a` do and when should you run it?
7. How do you pass parameters to a kernel module?
8. What is module blacklisting and how do you do it?
9. How do you check which kernel module is driving a PCI device?
10. What is udev and what does it do?
11. What does `vermagic` mean in a kernel module?
12. How do you build a custom kernel module?
13. What does `module_init()` and `module_exit()` do?
14. What happens when a module dependency is missing?
15. How do you troubleshoot a device that isn't working?

**Score:** 12/15 correct = congratulations, you've mastered Part 24!

---

*Linux SysAdmin Course | Part 24 of ∞ | Reverse Engineering Approach*
*Previous → Part 23: Virtual Terminals and Console Management*


[← Previous](part23.md)
