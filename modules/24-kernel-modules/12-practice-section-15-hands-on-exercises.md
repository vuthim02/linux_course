## 💻 PRACTICE SECTION — 15 Hands-On Exercises


### Level 1 Practices: Kernel Module Basics


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


### Level 2 Practices: Module Management


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


### Level 3 Practices: Building and Troubleshooting


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





[← Previous](11-section-7-device-drivers-and.md) | [↑ Index](index.md) | [Next →](13-deep-understanding-kernel-module-internals.md)
