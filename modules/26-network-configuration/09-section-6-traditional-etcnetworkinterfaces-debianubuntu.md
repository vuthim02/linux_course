## 🔍 Section 6: Traditional /etc/network/interfaces (Debian/Ubuntu Classic)

Before Netplan, Debian and Ubuntu used `/etc/network/interfaces` directly (and still do on systems without Netplan).

### Basic Structure

```bash
cat /etc/network/interfaces
```

```bash
# The loopback interface
auto lo
iface lo inet loopback

# DHCP configuration
auto eth0
iface eth0 inet dhcp

# Static configuration
auto eth1
iface eth1 inet static
    address 192.168.1.100
    netmask 255.255.255.0
    network 192.168.1.0
    broadcast 192.168.1.255
    gateway 192.168.1.1
    dns-nameservers 8.8.8.8 8.8.4.4
    dns-search example.com
```

### Advanced Options

```bash
# Interface with MTU and metric
auto eth0
iface eth0 inet static
    address 192.168.1.100
    netmask 255.255.255.0
    gateway 192.168.1.1
    mtu 9000
    metric 100

# Multiple IP addresses (aliases)
auto eth0:0
iface eth0:0 inet static
    address 192.168.1.200
    netmask 255.255.255.0

auto eth0:1
iface eth0:1 inet static
    address 10.0.0.1
    netmask 255.0.0.0

# Interface bonding
auto bond0
iface bond0 inet static
    address 192.168.1.50
    netmask 255.255.255.0
    gateway 192.168.1.1
    bond-slaves eth0 eth1
    bond-mode active-backup
    bond-miimon 100
    bond-primary eth0

# Bridge
auto br0
iface br0 inet static
    address 192.168.1.200
    netmask 255.255.255.0
    gateway 192.168.1.1
    bridge_ports eth0
    bridge_stp on
    bridge_fd 4

# VLAN (requires vlan package)
auto eth0.100
iface eth0.100 inet static
    address 192.168.100.1
    netmask 255.255.255.0
```

### Interface Management Commands

```bash
# Bring an interface up/down
sudo ifup eth0
sudo ifdown eth0

# Force a restart (down then up)
sudo ifdown eth0 && sudo ifup eth0

# Bring all interfaces defined in the file
sudo ifup -a
sudo ifdown -a

# Quick check of config
sudo ifquery eth0
```

### The interfaces.d Directory

```bash
# Include additional configs from a directory
ls /etc/network/interfaces.d/
```

Main file can source other files:
```bash
source /etc/network/interfaces.d/*.cfg
```

### Pre-up, Post-up, Pre-down, Post-down Hooks

```bash
auto eth0
iface eth0 inet static
    address 192.168.1.100
    netmask 255.255.255.0
    gateway 192.168.1.1
    pre-up /sbin/ethtool -s eth0 speed 1000 duplex full
    post-up /sbin/iptables -A FORWARD -i eth0 -j ACCEPT
    pre-down /sbin/iptables -D FORWARD -i eth0 -j ACCEPT
    post-down /sbin/ip addr flush dev eth0
```

---



---

[← Previous](08-section-5-netplan-modern-ubuntudebian.md) | [↑ Index](index.md) | [Next →](10-section-7-rhelcentosfedora-network-configuration.md)
