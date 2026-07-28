## ⭐ Level 2: Intermediary — Module Management

![Linux kernel IO stack — device driver layers](https://upload.wikimedia.org/wikipedia/commons/3/30/IO_stack_of_the_Linux_kernel.svg)

*Linux kernel IO stack — layers from application to hardware device (Wikimedia Commons / public domain)*

> **Level 2 Goal:** Load and unload kernel modules manually, manage module dependencies, pass parameters to modules, and understand automatic module loading.

### What You'll Cover
- Loading modules with `insmod` vs `modprobe` (dependency handling)
- Unloading modules with `rmmod` and checking if in use
- Setting module parameters at load time and via `/etc/modprobe.d/`
- Blacklisting modules to prevent auto-loading
- Using `depmod` to rebuild the module dependency database

The key distinction at this level is between `insmod` and `modprobe`. `insmod` loads a single `.ko` file but does not resolve dependencies — if the module needs another module loaded first, it will fail. `modprobe` reads `modules.dep` and loads all required modules in the correct order.

At this level you will master:

- **Module parameters**: Pass options at load time with `modprobe module param=value`, or persist them in `/etc/modprobe.d/myconfig.conf` using `options module param=value`. Common examples include `options bonding mode=4` or `options ip_tables hashsize=131072`.
- **Blacklisting**: Create `/etc/modprobe.d/blacklist-custom.conf` with `blacklist module_name` to prevent auto-loading. This is essential for suppressing problematic drivers (e.g., `blacklist nouveau` for NVIDIA proprietary drivers).
- **`rmmod`**: Removes a module only if its reference count is zero. Use `lsmod | grep module_name` to check dependencies first. `modprobe -r` removes a module and its unused dependents.
- **`depmod`**: Rebuilds the `/lib/modules/$(uname -r)/modules.dep` file after installing new modules. Usually runs automatically during kernel package installation.


[← Previous](03-section-1-kernel-module-basics.md) | [↑ Index](index.md) | [Next →](05-section-2-loading-and-unloading.md)
