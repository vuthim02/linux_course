## ⭐ Level 3: Advanced — Building and Troubleshooting Kernel Modules

![Simplified structure of the Linux kernel — modules and core](https://upload.wikimedia.org/wikipedia/commons/2/26/Simplified_Structure_of_the_Linux_Kernel.svg)

*Simplified Linux kernel structure showing core components and module boundaries (Wikimedia Commons / public domain)*

> **Level 3 Goal:** Troubleshoot kernel module issues, build custom modules, understand udev for device management, and work with device drivers.

### What You'll Cover
- Troubleshooting: `dmesg`, `journalctl -k`, and module error logs
- Building a custom module: Makefile, `Kbuild`, and kernel headers
- Installing modules with `insmod` and managing version compatibility
- udev rules: matching devices and triggering module loads
- Device driver basics: character, block, and network devices

Building and troubleshooting kernel modules requires understanding how the kernel's build system works and where to look when things go wrong.

At this level you will master:

- **Troubleshooting**: `dmesg | tail -50` shows recent kernel messages including module load failures. `journalctl -k` provides the same via systemd. Look for lines containing `E:` (error) after loading a module. Common errors include version magic mismatches and missing symbols.
- **Building a custom module**: You need kernel headers (`kernel-devel` on RHEL, `linux-headers` on Debian). A minimal Makefile calls the kernel build system with `make -C /lib/modules/$(uname -r)/build M=$(pwd) modules`. The resulting `.ko` file is installed with `insmod`.
- **Version compatibility**: The kernel checks `vermagic` when loading a module. If your module was built against different headers, it will refuse to load. Use `modinfo module.ko | grep vermagic` to check. `insmod -f` forces loading but can cause kernel panics.
- **udev rules**: Define device-to-action mappings in `/etc/udev/rules.d/`. For example, `SUBSYSTEM=="usb", ATTR{idVendor}=="1234", MODE="0666"` makes a USB device accessible to all users. udev triggers module loading automatically when matching hardware appears.


[← Previous](07-section-4-module-parameters.md) | [↑ Index](index.md) | [Next →](09-section-5-troubleshooting-kernel-modules.md)
