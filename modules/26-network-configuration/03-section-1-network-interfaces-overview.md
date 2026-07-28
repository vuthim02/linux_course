## 🔍 Section 1: Network Interfaces Overview

### What Is a Network Interface?

A network interface is the kernel's representation of a network device. It can be physical (a PCI Ethernet card), virtual (a loopback, bridge, VLAN, or tunnel), or logical (a bond master).

```bash
# List all network interfaces on the system
ip link show

# Or with the legacy command
ifconfig -a
```

Output example:
```
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN mode DEFAULT group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
2: enp0s3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP mode DEFAULT group default qlen 1000
    link/ether 08:00:27:ab:cd:ef brd ff:ff:ff:ff:ff:ff
3: wlp2s0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP mode DORMANT group default qlen 1000
    link/ether 7c:76:3f:12:34:56 brd ff:ff:ff:ff:ff:ff
```

### Interface Types

| Type | Name Pattern | Purpose |
|------|-------------|---------|
| Loopback | `lo` | Internal communication (127.0.0.1) |
| Ethernet | `eth0`, `enp0s3`, `ens33` | Wired network |
| Wireless | `wlan0`, `wlp2s0` | Wi-Fi |
| Bridge | `br0`, `br-int` | Software switch |
| Bond | `bond0` | Link aggregation |
| VLAN | `eth0.10`, `vlan10` | 802.1Q tagging |
| Tunnel | `tun0`, `tap0` | VPN/tunneling |

### The Loopback Interface

`lo` is a virtual interface that always exists and is always up. It routes traffic to `127.0.0.1` (localhost).

```bash
# Loopback details
ip addr show lo
```

Output:
```
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host noprefixroute
       valid_lft forever preferred_lft forever
```

### Interface Naming Conventions

Historically, Linux used `eth0`, `eth1`, etc. This was unpredictable because the kernel assigned names based on driver probe order. Modern systems use **predictable naming**:

| Name | Scheme | Example |
|------|--------|---------|
| `enp0s3` | en(ethernet) + p(bus 0) + s(slot 3) | PCI slot-based |
| `ens33` | en + s(slot 33) | Firmware/BIOS slot |
| `enx78e7d1ea46da` | en + x + MAC address | MAC-based |
| `eno1` | en + o(onboard index 1) | Firmware index |
| `wlp2s0` | wl(wireless) + p2 + s0 | Wi-Fi PCI slot |

```bash
# See how udev names your interfaces
udevadm info -e | grep -E '^P:|ID_NET_NAME'

# Check the udev rule file that controls naming
cat /lib/udev/rules.d/80-net-name-slot.rules 2>/dev/null || echo "Not present"
```

### How udev Names Interfaces

When the kernel detects a network device, udev runs rules in `/lib/udev/rules.d/`. The `80-net-setup-link.rules` and `75-net-description.rules` files assign names based on firmware, PCI topology, or MAC address.

```bash
# View udev database for a specific interface
udevadm info /sys/class/net/enp0s3

# See the kernel device tree for PCI network devices
lspci | grep -i ethernet

# Look at the sysfs interface
ls -la /sys/class/net/enp0s3/
```

### Disabling Predictable Naming (Back to eth0)

If you prefer the old `eth0` naming:

```bash
# 1. Add to kernel command line in /etc/default/grub
GRUB_CMDLINE_LINUX="net.ifnames=0 biosdevname=0"

# 2. Update grub
sudo update-grub

# 3. Reboot
sudo reboot
```





[← Previous](02-level-1-basic-network-interface.md) | [↑ Index](index.md) | [Next →](04-level-2-intermediary-network-configuration.md)
