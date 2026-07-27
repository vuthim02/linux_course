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



---

[← Previous](13-deep-understanding-kernel-module-internals.md) | [↑ Index](index.md) | [Next →](15-whats-next.md)
