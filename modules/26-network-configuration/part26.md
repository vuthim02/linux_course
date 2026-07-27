# 🐧 Linux System Administrator — Complete Course
## Part 26 of ∞: Network Configuration — Interfaces, ip, nmcli, netplan

---

> **Reverse Engineering Approach:** A network interface is just a file descriptor. When you `ip link set dev eth0 up`, you are making a system call that tells the kernel to activate a driver that talks to physical hardware — or to a virtual device that lives entirely in software. Every packet that leaves your machine passes through the kernel's network stack, a carefully layered system that shepherds data from user-space sockets all the way down to the wire. Understanding each layer lets you diagnose any networking problem from first principles.

---

## 🎯 What You Will Achieve in Part 26

| Level | Focus | Skills Gained |
|-------|-------|--------------|
| **⭐ Level 1: Basic** | Interface Basics & Network Concepts | Understand interface naming, types, `/etc/hosts`, `/etc/hostname`, and DNS resolution fundamentals |
| **⭐ Level 2: Intermediary** | Configuration & Troubleshooting | Master `ip`, `nmcli`, Netplan; configure bonding, bridging, VLANs; troubleshoot with `ping`, `tcpdump`, `ss` |
| **⭐ Level 3: Advanced** | Performance Tuning & Internals | Tune network with `ethtool`, MTU, offloading, ring buffers; understand kernel network stack internals |

Complete **15 hands-on practices** across all levels.

---

## ⭐ Level 1: Basic — Network Interface Concepts and Hostname Configuration

![Network Interfaces](https://upload.wikimedia.org/wikipedia/commons/thumb/c/c9/Ethernet_Connection.svg/220px-Ethernet_Connection.svg.png)  
*Ethernet connection — the foundation of Linux networking. Image credit: Wikimedia Commons.*

> **Level 1 Goal:** Understand network interface naming conventions and types. Configure hostnames via `/etc/hostname` and `/etc/hosts`. Grasp basic DNS resolution through `/etc/resolv.conf`.

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

---

## ⭐ Level 2: Intermediary — Network Configuration, Management, and Troubleshooting

![ip command output](https://upload.wikimedia.org/wikipedia/commons/thumb/2/2c/Linux_command_output_screenshot.png/220px-Linux_command_output_screenshot.png)  
*Command-line network management on Linux. Image credit: Wikimedia Commons.*

> **Level 2 Goal:** Master the `ip` command, configure interfaces with NetworkManager and Netplan, set up bonding/bridging/VLANs, and troubleshoot connectivity using `ping`, `traceroute`, `mtr`, `tcpdump`, and `ss`.

## 🔍 Section 2: The `ip` Command — Modern Network Swiss Army Knife

The `ip` command from the `iproute2` package is the modern replacement for `ifconfig`, `route`, `arp`, and `netstat`. It communicates with the kernel via **Netlink sockets**, a more powerful and extensible mechanism than the old `ioctl` system calls.

### ip addr — Address Management

```bash
# Show all addresses
ip addr

# Show addresses for a specific interface
ip addr show enp0s3

# Show only IPv4 addresses
ip -4 addr

# Show only IPv6 addresses
ip -6 addr

# Add an IP address
sudo ip addr add 192.168.1.100/24 dev enp0s3

# Remove an IP address
sudo ip addr del 192.168.1.100/24 dev enp0s3

# Flush all IPs from an interface
sudo ip addr flush dev enp0s3
```

### ip link — Interface Control

```bash
# List all interfaces
ip link show

# Show a specific interface
ip link show enp0s3

# Bring an interface up/down
sudo ip link set enp0s3 up
sudo ip link set enp0s3 down

# Set MAC address
sudo ip link set enp0s3 address 00:11:22:33:44:55

# Set MTU
sudo ip link set enp0s3 mtu 9000

# Set interface alias (visible in ip link)
sudo ip link set enp0s3 alias "Primary uplink"
```

### ip route — Routing Table

```bash
# Show routing table
ip route

# Show routing table for a specific protocol
ip route show proto static
ip route show proto kernel

# Add a default gateway
sudo ip route add default via 192.168.1.1

# Add a static route
sudo ip route add 10.0.0.0/8 via 192.168.1.1

# Add a route via an interface (no gateway)
sudo ip route add 10.0.0.0/8 dev enp0s3

# Delete a route
sudo ip route del 10.0.0.0/8

# Replace a route (atomically update)
sudo ip route replace 10.0.0.0/8 via 192.168.1.100

# Show route cache (deprecated, but some kernels support it)
ip route show cache
```

### ip neigh — Neighbor Table (ARP/NDISC)

```bash
# Show ARP table (IPv4 neighbors)
ip neigh

# Show IPv6 neighbors
ip -6 neigh

# Add a static ARP entry
sudo ip neigh add 192.168.1.1 lladdr 00:11:22:33:44:55 dev enp0s3

# Delete a neighbor entry
sudo ip neigh del 192.168.1.1 dev enp0s3

# Flush all neighbor entries
sudo ip neigh flush all
```

### ip netns — Network Namespaces

```bash
# List network namespaces
ip netns list

# Create a namespace
sudo ip netns add testns

# Run a command in a namespace
sudo ip netns exec testns ip addr

# Add a veth pair to connect namespaces
sudo ip link add veth0 type veth peer name veth1
sudo ip link set veth1 netns testns
```

### The `ip` command is Scriptable

```bash
# JSON output for programmatic use
ip -j addr show
ip -j -p link show  # Pretty-printed JSON

# Batch mode (read commands from file)
cat << 'EOF' | sudo ip -batch -
addr add 192.168.2.10/24 dev enp0s3
link set enp0s3 up
route add default via 192.168.2.1
EOF
```

### Why `ip` Replaced `ifconfig`

| Feature | `ip` | `ifconfig` |
|---------|------|------------|
| Multiple IPs per interface | Native | Alias interfaces (eth0:0) |
| IPv6 | Full support | Limited |
| Netlink protocol | Yes | ioctl (older) |
| Network namespaces | Yes | No |
| JSON output | Yes | No |
| Batch mode | Yes | No |
| VRF, bridge, VLAN | Integrated | Separate tools |

---

## 🔍 Section 3: Legacy ifconfig and route — Still in the Wild

Despite being deprecated, `ifconfig` and `route` are still installed on many systems and are essential knowledge for maintaining older servers (RHEL 6, CentOS 6, Ubuntu 14.04).

### ifconfig

```bash
# Install ifconfig (net-tools package)
sudo apt install net-tools   # Debian/Ubuntu
sudo yum install net-tools   # RHEL/CentOS

# Show all interfaces (including down)
ifconfig -a

# Show active interfaces only
ifconfig

# Show a specific interface
ifconfig enp0s3

# Set an IP address
sudo ifconfig enp0s3 192.168.1.100 netmask 255.255.255.0

# Bring interface up/down
sudo ifconfig enp0s3 up
sudo ifconfig enp0s3 down

# Set MTU
sudo ifconfig enp0s3 mtu 9000

# Add an alias (secondary IP)
sudo ifconfig enp0s3:0 192.168.1.200 netmask 255.255.255.0

# Add an alias with broadcast
sudo ifconfig enp0s3:1 10.0.0.1 netmask 255.0.0.0 broadcast 10.255.255.255
```

### route

```bash
# Show routing table
route -n   # -n shows numeric IPs (no DNS lookup)

# Add a default gateway
sudo route add default gw 192.168.1.1

# Add a static route
sudo route add -net 10.0.0.0 netmask 255.0.0.0 gw 192.168.1.1

# Add a route via an interface
sudo route add -net 10.0.0.0 netmask 255.0.0.0 dev enp0s3

# Delete a route
sudo route del -net 10.0.0.0 netmask 255.0.0.0

# Reject a route (blackhole)
sudo route add -net 10.0.0.0 netmask 255.0.0.0 reject
```

### arp (Address Resolution Protocol)

```bash
# Show ARP cache
arp -n

# Add static ARP entry
sudo arp -s 192.168.1.1 00:11:22:33:44:55

# Delete ARP entry
sudo arp -d 192.168.1.1

# Show interface ARP statistics
arp -i enp0s3 -n
```

### netstat (Deprecated, Use ss Instead)

```bash
# Show all listening ports
netstat -tuln

# Show routing table
netstat -rn

# Show network statistics
netstat -s

# Show active connections
netstat -an | grep ESTABLISHED

# Show process using each socket
netstat -tulnp
```

### Why These Are Legacy

- `ifconfig` cannot show detailed stats (dropped packets, errors, speed)
- `ifconfig` reports inconsistent output for multi-address interfaces
- `route` cannot handle advanced routing (policy routing, multipath)
- `netstat` is slow on systems with many connections
- All use the older `ioctl` system call instead of Netlink sockets

---

## 🔍 Section 4: NetworkManager, nmcli, nmtui

NetworkManager is the default network management service on most modern Linux distributions. It abstracts hardware, configuration files, and connectivity in a unified D-Bus service.

### The NetworkManager Architecture

```
┌──────────────────────────────────────────┐
│           NetworkManager daemon          │
│  (systemd service: NetworkManager.service) │
├──────────────────────────────────────────┤
│  D-Bus API ─┬─ nmcli (command line)      │
│              ├─ nmtui (text UI)          │
│              ├─ GNOME Settings (GUI)     │
│              └─ nm-connection-editor     │
├──────────────────────────────────────────┤
│  Backends: netplan, ifupdown,            │
│            /etc/sysconfig/network-scripts│
└──────────────────────────────────────────┘
```

```bash
# Check if NetworkManager is running
systemctl status NetworkManager

# Or
nmcli general status
```

### nmcli — The Command-Line Tool

#### General Status and Control

```bash
# Show overall status
nmcli general status

# Show hostname and networking state
nmcli general hostname
nmcli networking connectivity check
nmcli networking on
nmcli networking off

# Show permissions
nmcli general permissions

# Show version
nmcli --version
```

#### Device Management

```bash
# Show all network devices
nmcli device status

# Show device details
nmcli device show enp0s3

# Show device capabilities (speed, duplex, etc.)
nmcli device show enp0s3 | grep -E 'SPEED|DUPLEX|AUTONEG'

# Connect a Wi-Fi network
nmcli device wifi connect "MyWiFi" password "secret123"

# List available Wi-Fi networks
nmcli device wifi list

# Disconnect and reconnect a device
nmcli device disconnect enp0s3
nmcli device connect enp0s3

# Monitor device changes
nmcli device monitor enp0s3
```

#### Connection Management

```bash
# List all connections
nmcli connection show

# List only active connections
nmcli connection show --active

# Show connection details
nmcli connection show "Wired connection 1"

# Create a new static IP connection
nmcli connection add \
    type ethernet \
    con-name "static-eth0" \
    ifname enp0s3 \
    ipv4.method manual \
    ipv4.addresses 192.168.1.100/24 \
    ipv4.gateway 192.168.1.1 \
    ipv4.dns 8.8.8.8,8.8.4.4

# Create a DHCP connection
nmcli connection add \
    type ethernet \
    con-name "dhcp-eth0" \
    ifname enp0s3 \
    ipv4.method auto

# Modify an existing connection
nmcli connection modify "static-eth0" \
    ipv4.addresses 192.168.1.200/24 \
    ipv4.dns "1.1.1.1"

# Activate a connection
nmcli connection up "static-eth0"

# Deactivate a connection
nmcli connection down "static-eth0"

# Delete a connection
nmcli connection delete "static-eth0"

# Clone a connection
nmcli connection clone "static-eth0" "backup-eth0"
```

#### Wi-Fi from Command Line

```bash
# Scan for Wi-Fi
nmcli device wifi list

# Connect to an open network
nmcli device wifi connect "CoffeeShop"

# Connect to a WPA2 network
nmcli device wifi connect "WorkWiFi" password "s3cr3t"

# Connect using WPA2 Enterprise (EAP)
nmcli device wifi connect "University" \
    password "student123" \
    wep-key-type key \
    --ask

# Save a Wi-Fi network but don't connect
nmcli device wifi connect "KnownNetwork" password "pass" --hidden yes

# Turn Wi-Fi on/off
nmcli radio wifi off
nmcli radio wifi on
```

### nmtui — The Text User Interface

`nmtui` is a curses-based UI that runs in any terminal.

```bash
# Start the text UI
nmtui
```

Menu structure:
```
┌───────────── NetworkManager TUI ─────────────┐
│                                               │
│  Edit a connection                            │
│  Activate a connection                        │
│  Set system hostname                          │
│  Quit                                         │
│                                               │
└───────────────────────────────────────────────┘
```

Use arrow keys to navigate, Enter to select, Tab to switch fields.

### NetworkManager Configuration Files

Connections are stored in `/etc/NetworkManager/system-connections/`:

```bash
# List all connection files
ls /etc/NetworkManager/system-connections/

# View a connection file (INI format)
sudo cat /etc/NetworkManager/system-connections/static-eth0.nmconnection
```

Example connection file:
```ini
[connection]
id=static-eth0
uuid=abc12345-6789-def0-1234-56789abcdef0
type=ethernet
interface-name=enp0s3

[ipv4]
method=manual
addresses=192.168.1.100/24
gateway=192.168.1.1
dns=8.8.8.8;8.8.4.4;

[ipv6]
method=disabled
```

### Managing NetworkManager via systemd

```bash
# Restart NetworkManager
sudo systemctl restart NetworkManager

# Reload configuration without restarting
sudo nmcli connection reload

# View NetworkManager logs
journalctl -u NetworkManager -n 50 -f
```

---

## 🔍 Section 5: Netplan — Modern Ubuntu/Debian Network Configuration

Netplan is a YAML-based network configuration utility introduced in Ubuntu 17.10. It reads configuration from `/etc/netplan/` and generates backend configuration for either NetworkManager or systemd-networkd.

### Netplan Configuration Files

```bash
# Location of Netplan configs
ls /etc/netplan/

# Typical file: /etc/netplan/01-netcfg.yaml or 00-installer-config.yaml
```

### Basic Netplan Syntax

```yaml
# /etc/netplan/01-netcfg.yaml
network:
  version: 2
  renderer: networkd   # or NetworkManager
  ethernets:
    enp0s3:
      dhcp4: true
```

### DHCP Configuration

```yaml
# /etc/netplan/01-dhcp.yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    enp0s3:
      dhcp4: true
      dhcp6: false
      dhcp-identifier: mac   # Use MAC-based DHCP ID
```

### Static IP Configuration

```yaml
# /etc/netplan/01-static.yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    enp0s3:
      dhcp4: false
      addresses:
        - 192.168.1.100/24
        - 10.0.0.1/24      # Secondary IP
      routes:
        - to: default
          via: 192.168.1.1
      nameservers:
        addresses:
          - 8.8.8.8
          - 8.8.4.4
        search:
          - example.com
      optional: true       # Don't wait for this interface at boot
```

### Multiple Interfaces

```yaml
# /etc/netplan/02-multi-interface.yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    enp0s3:
      dhcp4: true
    enp0s8:
      addresses:
        - 192.168.100.10/24
      routes:
        - to: 10.0.0.0/8
          via: 192.168.100.1
```

### Apply Netplan Configuration

```bash
# Test the configuration (dry run)
sudo netplan try

# This shows the diff and asks for confirmation (auto-reverts in 120 seconds)

# Apply the configuration
sudo netplan apply

# Generate backend configs without applying
sudo netplan generate

# Debug/show current config
sudo netplan get
sudo netplan status
sudo netplan status --diff
```

### Netplan Backend: systemd-networkd

Under the hood, Netplan generates configuration for systemd-networkd:

```bash
# See the generated configs
ls /run/systemd/network/
cat /run/systemd/network/*.network
```

Generated file example:
```ini
# /run/systemd/network/10-netplan-enp0s3.network
[Match]
Name=enp0s3

[Network]
DHCP=ipv4
DNS=8.8.8.8
DNS=8.8.4.4
Domains=example.com

[DHCP]
RouteMetric=100
UseDNS=false
```

### Netplan with NetworkManager as Renderer

```yaml
# /etc/netplan/01-nm.yaml
network:
  version: 2
  renderer: NetworkManager
  ethernets:
    enp0s3:
      dhcp4: true
```

This makes NetworkManager manage the interface, and you can still use `nmcli` for additional configuration.

### Network Bonding with Netplan

```yaml
# /etc/netplan/03-bond.yaml
network:
  version: 2
  renderer: networkd
  bonds:
    bond0:
      interfaces:
        - enp0s3
        - enp0s8
      parameters:
        mode: active-backup
        mii-monitor-interval: 100
        primary: enp0s3
      addresses:
        - 192.168.1.50/24
      routes:
        - to: default
          via: 192.168.1.1
```

### Bridging with Netplan

```yaml
# /etc/netplan/04-bridge.yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    enp0s3:
      dhcp4: false
  bridges:
    br0:
      interfaces:
        - enp0s3
      addresses:
        - 192.168.1.200/24
      routes:
        - to: default
          via: 192.168.1.1
      parameters:
        stp: true
        forward-delay: 4
```

### VLAN with Netplan

```yaml
# /etc/netplan/05-vlan.yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    enp0s3:
      dhcp4: false
  vlans:
    vlan100:
      id: 100
      link: enp0s3
      addresses:
        - 192.168.100.1/24
    vlan200:
      id: 200
      link: enp0s3
      addresses:
        - 192.168.200.1/24
```

---

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

## 🔍 Section 7: RHEL/CentOS/Fedora Network Configuration

Red Hat-based distributions (RHEL, CentOS, Fedora, AlmaLinux, Rocky Linux) use interface scripts in `/etc/sysconfig/network-scripts/`.

### The Main Network Configuration

```bash
cat /etc/sysconfig/network
```

```bash
# Created by anaconda
NETWORKING=yes
HOSTNAME=server01.example.com
GATEWAY=192.168.1.1
NETWORKING_IPV6=no
IPV6_AUTOCONF=no
```

### Interface Configuration File

```bash
# These are named by interface
ls /etc/sysconfig/network-scripts/ifcfg-*
```

#### DHCP Configuration

```bash
# /etc/sysconfig/network-scripts/ifcfg-eth0
TYPE=Ethernet
BOOTPROTO=dhcp
DEFROUTE=yes
PEERDNS=yes
PEERROUTES=yes
IPV4_FAILURE_FATAL=no
IPV6INIT=yes
IPV6_AUTOCONF=yes
IPV6_DEFROUTE=yes
IPV6_PEERDNS=yes
IPV6_PEERROUTES=yes
NAME=eth0
UUID=abc12345-6789-def0-1234-56789abcdef0
DEVICE=eth0
ONBOOT=yes
```

#### Static IP Configuration

```bash
# /etc/sysconfig/network-scripts/ifcfg-eth0
TYPE=Ethernet
BOOTPROTO=static
DEFROUTE=yes
IPADDR=192.168.1.100
NETMASK=255.255.255.0
GATEWAY=192.168.1.1
DNS1=8.8.8.8
DNS2=8.8.4.4
DOMAIN=example.com
IPV6INIT=no
NAME=eth0
DEVICE=eth0
ONBOOT=yes
USERCTL=no
```

### Key Directives Explained

| Directive | Purpose |
|-----------|---------|
| `TYPE=Ethernet` | Interface type (Ethernet, Bridge, Bond, Vlan) |
| `BOOTPROTO=dhcp` | Use DHCP (`static`, `dhcp`, `none`) |
| `ONBOOT=yes` | Activate at boot |
| `DEFROUTE=yes` | Use as default route |
| `PEERDNS=yes` | Accept DNS from DHCP |
| `IPADDR` | Static IP address |
| `NETMASK` | Subnet mask |
| `GATEWAY` | Default gateway |
| `DNS1`, `DNS2` | DNS servers |
| `USERCTL=no` | Allow non-root users to control |
| `NM_CONTROLLED=yes` | Managed by NetworkManager |
| `MTU` | Set MTU size |
| `HWADDR` | MAC address (for binding config to hardware) |
| `MACADDR` | Override MAC address |

### Multiple IP Addresses

```bash
# /etc/sysconfig/network-scripts/ifcfg-eth0:0 (alias)
DEVICE=eth0:0
BOOTPROTO=static
IPADDR=192.168.1.200
NETMASK=255.255.255.0
ONBOOT=yes
```

Modern method (multiple addresses in one file):
```bash
# /etc/sysconfig/network-scripts/ifcfg-eth0
IPADDR0=192.168.1.100
NETMASK0=255.255.255.0
IPADDR1=192.168.1.200
NETMASK1=255.255.255.0
```

### Route Configuration

```bash
# /etc/sysconfig/network-scripts/route-eth0
# Static routes for eth0
10.0.0.0/8 via 192.168.1.254
172.16.0.0/12 via 192.168.1.254
```

Alternative format:
```bash
ADDRESS0=10.0.0.0
NETMASK0=255.0.0.0
GATEWAY0=192.168.1.254

ADDRESS1=172.16.0.0
NETMASK1=255.240.0.0
GATEWAY1=192.168.1.254
```

### Interface Control Commands (RHEL style)

```bash
# Bring an interface up/down
sudo ifup eth0
sudo ifdown eth0

# Restart all networking (legacy)
sudo service network restart

# Using systemd
sudo systemctl restart network

# Show interface status
sudo ifconfig eth0

# Or with modern tools
ip addr show eth0
```

### Bonding in RHEL Style

```bash
# /etc/sysconfig/network-scripts/ifcfg-bond0
DEVICE=bond0
TYPE=Bond
BONDING_MASTER=yes
BOOTPROTO=static
IPADDR=192.168.1.50
NETMASK=255.255.255.0
GATEWAY=192.168.1.1
ONBOOT=yes
BONDING_OPTS="mode=active-backup miimon=100 primary=eth0"
```

```bash
# /etc/sysconfig/network-scripts/ifcfg-eth0
DEVICE=eth0
TYPE=Ethernet
BOOTPROTO=none
ONBOOT=yes
MASTER=bond0
SLAVE=yes
```

```bash
# /etc/sysconfig/network-scripts/ifcfg-eth1
DEVICE=eth1
TYPE=Ethernet
BOOTPROTO=none
ONBOOT=yes
MASTER=bond0
SLAVE=yes
```

### Bridging in RHEL Style

```bash
# /etc/sysconfig/network-scripts/ifcfg-br0
DEVICE=br0
TYPE=Bridge
BOOTPROTO=static
IPADDR=192.168.1.200
NETMASK=255.255.255.0
GATEWAY=192.168.1.1
ONBOOT=yes
DELAY=4
STP=yes
```

```bash
# /etc/sysconfig/network-scripts/ifcfg-eth0
DEVICE=eth0
TYPE=Ethernet
BOOTPROTO=none
ONBOOT=yes
BRIDGE=br0
```

### VLAN in RHEL Style

```bash
# /etc/sysconfig/network-scripts/ifcfg-eth0.100
DEVICE=eth0.100
BOOTPROTO=static
IPADDR=192.168.100.1
NETMASK=255.255.255.0
ONBOOT=yes
VLAN=yes
```

---

## 🔍 Section 8: /etc/hosts and /etc/hostname — Hostname Configuration

### /etc/hostname

This file contains the system's hostname — a single line.

```bash
# View current hostname
cat /etc/hostname

# Set hostname temporarily (immediate, lost on reboot)
sudo hostname server01.example.com

# Set hostname permanently (survives reboot)
sudo hostnamectl set-hostname server01.example.com

# Or directly edit the file
echo "server01.example.com" | sudo tee /etc/hostname

# Set pretty hostname (for desktops)
sudo hostnamectl set-hostname "My Server" --pretty

# Set all three: static, pretty, transient
sudo hostnamectl set-hostname server01.example.com --static
```

### Viewing Hostname Information

```bash
# Display hostname in various forms
hostname
hostname -f   # FQDN
hostname -s   # Short name (first component)
hostname -d   # Domain name
hostname -i   # IP address from /etc/hosts
hostname -A   # All FQDNs

# With hostnamectl
hostnamectl
```

Output of `hostnamectl`:
```
   Static hostname: server01.example.com
   Pretty hostname: My Server
         Icon name: computer-vm
           Chassis: vm
        Machine ID: abc1234567890def1234567890abcdef
           Boot ID: def1234567890abcdef1234567890abcd
  Operating System: Ubuntu 22.04 LTS
            Kernel: Linux 6.2.0-26-generic
      Architecture: x86-64
```

### /etc/hosts — Local DNS Resolution

This file maps IP addresses to hostnames, bypassing DNS. It is checked BEFORE DNS (unless configured otherwise in `/etc/nsswitch.conf`).

```bash
cat /etc/hosts
```

```
127.0.0.1       localhost
127.0.1.1       server01.example.com server01
192.168.1.100   server01 server01.example.com

# The following lines are desirable for IPv6 capable hosts
::1             ip6-localhost ip6-loopback
fe00::0         ip6-localnet
ff00::0         ip6-mcastprefix
ff02::1         ip6-allnodes
ff02::2         ip6-allrouters
```

### /etc/nsswitch.conf — Name Service Switch

Controls the order of name resolution:

```bash
cat /etc/nsswitch.conf | grep hosts
```

```
hosts:          files dns myhostname
```

This means:
1. `files` → check `/etc/hosts` first
2. `dns` → check DNS next
3. `myhostname` → check own hostname last

### Practical Uses for /etc/hosts

```bash
# Block a website (redirect to localhost)
echo "127.0.0.1   ads.example.com" | sudo tee -a /etc/hosts

# Override DNS for testing (point domain to staging server)
echo "10.0.0.50   production.example.com" | sudo tee -a /etc/hosts

# Add entries for local development
echo "127.0.0.1   myapp.local" | sudo tee -a /etc/hosts

# Verify resolution
getent hosts production.example.com
```

### How Hostname Resolution Works

```
Application calls gethostbyname("example.com")
    ↓
nsswitch.conf says: files → dns
    ↓
Check /etc/hosts for match
    ↓ (if not found)
DNS resolver queries /etc/resolv.conf for nameservers
    ↓ (if not found)
Return error or fall back to myhostname
```

---

## 🔍 Section 9: /etc/resolv.conf and DNS

`/etc/resolv.conf` is THE DNS resolver configuration file on Linux. However, on modern systems it's often managed dynamically.

### Classic /etc/resolv.conf

```bash
cat /etc/resolv.conf
```

```
# Generated by NetworkManager
nameserver 127.0.0.53
nameserver 8.8.8.8
nameserver 8.8.4.4
search example.com localdomain
options timeout:2 attempts:3 rotate
```

### Directives

| Directive | Purpose |
|-----------|---------|
| `nameserver` | DNS server IP (up to 3, tried in order) |
| `search` | Domain suffixes to try before absolute lookup |
| `domain` | Local domain name (overrides search if set) |
| `options` | Tuning parameters (timeout, attempts, rotate, ndots) |

```bash
# Manual resolv.conf example
cat /etc/resolv.conf
```

```
search example.com
nameserver 1.1.1.1
nameserver 1.0.0.1
options timeout:2 attempts:2 rotate
```

### How DNS Resolution Flows

```
Application: ping example.com
    ↓
1. Check /etc/hosts → match? Return IP.
2. Check DNS cache (nscd/systemd-resolved) → cached? Return IP.
3. Check /etc/resolv.conf → query nameserver 1.1.1.1
4. Nameserver returns 93.184.216.34
5. Application gets the IP.
```

### systemd-resolved and Stub Resolvers

Modern Ubuntu systems (17.10+) run `systemd-resolved`, which listens on `127.0.0.53`:

```bash
# Check if systemd-resolved is running
systemctl status systemd-resolved

# /etc/resolv.conf points to stub resolver
cat /etc/resolv.conf
# → nameserver 127.0.0.53

# systemd-resolved forwards to real DNS servers
resolvectl status
```

Output of `resolvectl status`:
```
Global
       Protocols: -LLMNR -mDNS -DNSOverTLS DNSSEC=no/unsupported
resolv.conf mode: stub

Link 2 (enp0s3)
    Current Scopes: DNS
         Protocols: +DefaultRoute +LLMNR -mDNS -DNSOverTLS DNSSEC=no/unsupported
Current DNS Server: 192.168.1.1
       DNS Servers: 192.168.1.1 8.8.8.8
        DNS Domain: example.com
```

### Using resolvectl

```bash
# Show DNS configuration
resolvectl

# Query a domain
resolvectl query example.com

# Query with specific type
resolvectl query -t MX example.com

# Query an IP (reverse lookup)
resolvectl query 93.184.216.34

# Flush DNS cache
sudo resolvectl flush-caches

# Show cache statistics
resolvectl statistics

# Set DNS server for a specific interface
sudo resolvectl dns enp0s3 8.8.8.8 1.1.1.1

# Set DNS domain for an interface
sudo resolvectl domain enp0s3 "example.com"
```

### DNS Troubleshooting

```bash
# Classic tools
host example.com
dig example.com
nslookup example.com

# Query a specific nameserver
dig @8.8.8.8 example.com

# Trace the DNS resolution path
dig +trace example.com

# Check if system resolver works
getent hosts example.com

# Test with shorter timeout
timeout 2 getent hosts example.com

# Check for DNS leaks
dig whoami.akamai.net @resolver1.opendns.com
```

### The Hosts vs DNS Priority

```bash
# Test the order: which answer wins?
echo "127.0.0.1   google.com" | sudo tee -a /etc/hosts
ping -c 1 google.com   # Will ping 127.0.0.1, not the real Google

# Clean up
sudo sed -i '/google.com/d' /etc/hosts
```

---

## 🔍 Section 10: Bonding and Bridging

### Interface Bonding (Link Aggregation)

Bonding combines multiple physical interfaces into one logical interface for redundancy and/or increased throughput.

#### Bonding Modes

| Mode | Name | Description |
|------|------|-------------|
| 0 | balance-rr | Round-robin: packets alternate across interfaces |
| 1 | active-backup | One active, one standby (failover) |
| 2 | balance-xor | XOR of MAC addresses selects interface |
| 3 | broadcast | All packets sent on all interfaces |
| 4 | 802.3ad | IEEE 802.3ad dynamic link aggregation (LACP) |
| 5 | balance-tlb | Adaptive transmit load balancing |
| 6 | balance-alb | Adaptive load balancing (tx + rx) |

```bash
# Load the bonding kernel module
sudo modprobe bonding

# Check available modes
cat /sys/class/net/bonding_masters 2>/dev/null || echo "No bonds exist"
```

#### Create a Bond from Command Line

```bash
# 1. Create the bond interface
sudo ip link add bond0 type bond mode 802.3ad

# 2. Set bond parameters
sudo ip link set bond0 type bond miimon 100
sudo ip link set bond0 type bond xmit_hash_policy layer3+4

# 3. Add slave interfaces
sudo ip link set eth0 master bond0
sudo ip link set eth1 master bond0

# 4. Bring bond up with an IP
sudo ip addr add 192.168.1.50/24 dev bond0
sudo ip link set bond0 up
```

#### Check Bond Status

```bash
# Bond status in /proc
cat /proc/net/bonding/bond0

# Bond details with ip
ip link show bond0
ip link show master bond0  # Shows slaves

# Check which interface is active (active-backup mode)
cat /proc/net/bonding/bond0 | grep -E "Active Slave|Currently Active Slave"
```

#### Kernel Module Parameters

```bash
# Show bonding module parameters
modinfo bonding

# Load with specific parameters
sudo modprobe bonding mode=1 miimon=100 max_bonds=2

# Load at boot: /etc/modules or /etc/modprobe.d/bonding.conf
echo "bonding" | sudo tee /etc/modules-load.d/bonding.conf
echo "options bonding mode=1 miimon=100" | sudo tee /etc/modprobe.d/bonding.conf
```

### Linux Bridge

A Linux bridge is a virtual switch. It connects interfaces (physical or virtual) as if they were plugged into the same switch.

```bash
# Install bridge utilities
sudo apt install bridge-utils    # Debian/Ubuntu
sudo yum install bridge-utils    # RHEL/CentOS
```

#### Create a Bridge

```bash
# Method 1: Using ip (modern)
sudo ip link add br0 type bridge
sudo ip link set br0 up

# Method 2: Using brctl (legacy)
sudo brctl addbr br0
sudo brctl addif br0 eth0
sudo brctl addif br0 tap0  # Virtual interface for a VM
sudo ifconfig br0 192.168.1.200/24 up
```

#### Bridge Management

```bash
# Show bridges
brctl show

# Show bridge details (STP, forwarding)
bridge link show
bridge fdb show          # Forwarding database (MAC table)

# STP (Spanning Tree Protocol) control
sudo brctl stp br0 on    # Enable Spanning Tree
sudo brctl stp br0 off   # Disable Spanning Tree

# Set bridge priority
sudo brctl setbridgeprio br0 4096

# Ageing time (how long before learned MACs expire)
sudo brctl setageing br0 300
```

#### Bridge + Netplan

```yaml
network:
  version: 2
  renderer: networkd
  bridges:
    br0:
      interfaces: [enp0s3, enp0s8]
      addresses: [192.168.1.200/24]
      routes:
        - to: default
          via: 192.168.1.1
      parameters:
        stp: true
        forward-delay: 4
        ageing-time: 300
        priority: 32768
```

### Bridge for VMs (Docker/Libvirt Style)

When you install Docker or libvirt, they create bridges:

```bash
# Docker bridge
ip link show docker0
brctl show docker0

# libvirt default bridge
ip link show virbr0
brctl show virbr0

# Check which interfaces are bridged
bridge link show master virbr0
```

---

## 🔍 Section 11: VLAN Tagging — 802.1Q

VLANs (Virtual LANs) allow you to segment a single physical network into multiple logical networks using 802.1Q tags.

### How 802.1Q Works

```
┌──────────────┬────────┬──────────────┬───────────────┬──────┐
│ Destination  │ Source │ 802.1Q Tag   │ EtherType     │ Payload │
│ MAC (6B)     │ MAC(6B)│ (4B)         │ (2B)          │       │
└──────────────┴────────┴──────────────┴───────────────┴──────┘
                         ├─ Priority (3 bits)
                         ├─ DEI (1 bit)
                         ├─ VID (12 bits) → 1-4094
                         └─ EtherType 0x8100
```

### Creating VLAN Interfaces

```bash
# Load the 8021q kernel module
sudo modprobe 8021q

# Check if loaded
lsmod | grep 8021q

# Create a VLAN interface
sudo ip link add link enp0s3 name enp0s3.100 type vlan id 100

# Bring it up and assign IP
sudo ip addr add 192.168.100.1/24 dev enp0s3.100
sudo ip link set enp0s3.100 up

# Alternative naming (vlan100)
sudo ip link add link enp0s3 name vlan100 type vlan id 100
```

### Using vconfig (Legacy)

```bash
# Install vlan package
sudo apt install vlan    # Debian/Ubuntu

# Create VLAN
sudo vconfig add enp0s3 100

# Set VLAN flags
sudo vconfig set_flag enp0s3 1  # Enable VLAN reorder header
sudo vconfig set_egress_map enp0s3 0 7  # Set priority

# Remove VLAN
sudo vconfig rem enp0s3.100
```

### VLAN Management

```bash
# Show VLAN interfaces
ip link show type vlan

# Show VLAN details
cat /proc/net/vlan/enp0s3.100

# Output:
# enp0s3.100  VID: 100      REORDER_HDR: 1  dev->priv_flags: 1
# total frames received:         0
# total bytes received:          0
# total frames transmitted:      0
# total bytes transmitted:       0
# ...

# Remove a VLAN interface
sudo ip link delete enp0s3.100
```

### VLAN in /etc/network/interfaces

```bash
auto enp0s3.100
iface enp0s3.100 inet static
    address 192.168.100.1
    netmask 255.255.255.0
    vlan-raw-device enp0s3
```

### VLAN with NetworkManager

```bash
# Create a VLAN connection
nmcli connection add type vlan \
    con-name vlan-100 \
    dev enp0s3 \
    id 100 \
    ipv4.method manual \
    ipv4.addresses 192.168.100.1/24

# Or using raw device
nmcli connection add type vlan \
    con-name vlan-200 \
    ifname enp0s3.200 \
    vlan.parent enp0s3 \
    vlan.id 200 \
    ipv4.addresses 192.168.200.1/24
```

### Practical VLAN Scenario

A router/firewall with one physical interface connected to a trunk port:

```bash
# Physical interface (no IP)
sudo ip link set enp0s3 up

# Management VLAN 10
sudo ip link add link enp0s3 name vlan10 type vlan id 10
sudo ip addr add 10.0.10.1/24 dev vlan10
sudo ip link set vlan10 up

# Client VLAN 20
sudo ip link add link enp0s3 name vlan20 type vlan id 20
sudo ip addr add 10.0.20.1/24 dev vlan20
sudo ip link set vlan20 up

# Server VLAN 30
sudo ip link add link enp0s3 name vlan30 type vlan id 30
sudo ip addr add 10.0.30.1/24 dev vlan30
sudo ip link set vlan30 up

# Enable routing between VLANs
sudo sysctl -w net.ipv4.ip_forward=1

# Make persistent
echo "net.ipv4.ip_forward=1" | sudo tee /etc/sysctl.d/99-router.conf
```

---

## ⭐ Level 3: Advanced — Performance Tuning and Kernel Network Internals

![Network Performance Tuning](https://upload.wikimedia.org/wikipedia/commons/thumb/e/e6/Network_Stack.svg/220px-Network_Stack.svg.png)  
*The Linux network stack — understanding the path from application to wire. Image credit: Wikimedia Commons.*

> **Level 3 Goal:** Tune network interface performance with ethtool, configure MTU and offloading, adjust ring buffer sizes, and understand how the kernel network stack processes packets from arrival to delivery.

## 🔍 Section 12: Tuning — ethtool, MTU, Offloading, Ring Buffers

### ethtool — Query and Control Network Devices

```bash
# Install ethtool
sudo apt install ethtool

# Basic information
sudo ethtool enp0s3

# Show driver info
sudo ethtool -i enp0s3
# Output:
# driver: e1000
# version: 7.3.21-k8-NAPI
# firmware-version: 0.3-0
# bus-info: 0000:00:03.0

# Show link status and speed
sudo ethtool enp0s3 | grep -E "Speed|Duplex|Link detected"

# Show NIC capabilities
sudo ethtool -k enp0s3  # Offloading features
sudo ethtool -c enp0s3  # Coalescing settings
sudo ethtool -g enp0s3  # Ring buffer sizes
sudo ethtool -a enp0s3  # Pause parameteres
```

### Changing Settings with ethtool

```bash
# Set speed and duplex
sudo ethtool -s enp0s3 speed 1000 duplex full autoneg on

# Set ring buffer sizes
sudo ethtool -G enp0s3 rx 4096 tx 4096

# Set coalescing (interrupt moderation)
sudo ethtool -C enp0s3 rx-usecs 100 tx-usecs 100

# Set pause frames
sudo ethtool -A enp0s3 rx on tx on

# Wake-on-LAN settings
sudo ethtool -s enp0s3 wol g  # Magic packet
sudo ethtool enp0s3 | grep "Wake-on"
```

### MTU (Maximum Transmission Unit)

MTU is the largest packet size a network interface can transmit without fragmentation.

```bash
# Check current MTU
ip link show enp0s3 | grep mtu

# Set MTU to 1500 (standard Ethernet)
sudo ip link set enp0s3 mtu 1500

# Set MTU to 9000 (jumbo frames — for data centers)
sudo ip link set enp0s3 mtu 9000

# Test MTU with ping
ping -M do -s 1472 -c 3 192.168.1.1   # 1472 + 28 = 1500
ping -M do -s 8972 -c 3 192.168.1.1   # 8972 + 28 = 9000

# -M do = Don't Fragment (probe MTU)
# -s = payload size (ICMP header is 8 bytes, IP header 20)
```

### Path MTU Discovery

```bash
# Find the smallest MTU along a path
tracepath 8.8.8.8

# Use tracepath -n for faster results (no DNS)
tracepath -n 8.8.8.8 | head -10
```

### TCP Offloading

Modern NICs can offload TCP processing from the CPU:

```bash
# Show offload settings
sudo ethtool -k enp0s3

# Common offload features:
# tx-checksumming: Checksum offload for transmit
# rx-checksumming: Checksum offload for receive
# tcp-segmentation-offload (TSO): NIC splits large TCP segments
# generic-segmentation-offload (GSO): Software version of TSO
# generic-receive-offload (GRO): Merge incoming packets
# large-receive-offload (LRO): Merge incoming packets (coarse)
# rx-vlan-offload: VLAN tag stripping on receive
# tx-vlan-offload: VLAN tag insertion on transmit
```

Disable offloading for troubleshooting or specific workloads:

```bash
# Disable TSO and GSO
sudo ethtool -K enp0s3 tso off gso off

# Disable checksum offloading
sudo ethtool -K enp0s3 tx off rx off

# Disable LRO/GRO
sudo ethtool -K enp0s3 lro off gro off

# Re-enable
sudo ethtool -K enp0s3 tso on gso on tx on rx on
```

### Ring Buffer Sizes

Ring buffers hold received packets waiting for the kernel to process them:

```bash
# Show current ring buffer
sudo ethtool -g enp0s3

# Output:
# Ring parameters for enp0s3:
# Pre-set maximums:
# RX:             4096
# TX:             4096
# Current hardware settings:
# RX:             256
# TX:             256

# Increase ring buffer (reduces drops at high packet rates)
sudo ethtool -G enp0s3 rx 4096 tx 4096
```

### Persistent Tuning with systemd Link Files

```bash
# /etc/systemd/network/10-enp0s3.link
[Match]
MACAddress=08:00:27:ab:cd:ef

[Link]
MTUBytes=9000
WakeOnLan=magic
```

Or with udev rules:

```bash
# /etc/udev/rules.d/70-persistent-net.rules
ACTION=="add", SUBSYSTEM=="net", KERNEL=="enp0s3", \
    RUN+="/sbin/ethtool -s $name speed 1000 duplex full"
```

### Network Performance Monitoring

```bash
# Interface statistics (packets, errors, drops)
ip -s link show enp0s3

# Live monitoring with watch
watch -n 1 'ip -s link show enp0s3'

# Per-protocol statistics
netstat -s

# Socket statistics
ss -s
```

---

## 🔍 Section 13: Troubleshooting — ping, traceroute, mtr, tcpdump, ss

### ping — Basic Connectivity Test

```bash
# Basic ping
ping 8.8.8.8

# Ping with count
ping -c 4 8.8.8.8

# Ping with interval
ping -i 0.2 -c 10 8.8.8.8   # Every 200ms

# Ping with flood (root only)
sudo ping -f -c 1000 8.8.8.8

# Check MTU with ping (Don't Fragment)
ping -M do -s 1472 -c 3 192.168.1.1

# Ping a hostname
ping -c 2 google.com
```

Interpretation:
```
64 bytes from 8.8.8.8: icmp_seq=1 ttl=118 time=12.3 ms
```
- `ttl=118` → started at 128, has traversed ~10 hops
- `time=12.3ms` → round-trip latency
- `icmp_seq=1` → sequence number (gaps mean packet loss)

### traceroute — Path Discovery

```bash
# Basic traceroute
traceroute 8.8.8.8

# Faster (no DNS lookups)
traceroute -n 8.8.8.8

# Set max hops
traceroute -m 30 -n 8.8.8.8

# Use TCP instead of UDP (for firewalls)
traceroute -T -p 80 8.8.8.8

# Use ICMP
traceroute -I 8.8.8.8

# Set source interface
traceroute -i enp0s3 -n 8.8.8.8
```

Output example:
```
traceroute to 8.8.8.8 (8.8.8.8), 30 hops max, 60 byte packets
 1  192.168.1.1  0.523 ms  0.430 ms  0.437 ms
 2  10.0.0.1    1.234 ms  1.567 ms  1.234 ms
 3  * * *
 4  72.14.215.123  12.345 ms  15.678 ms  14.567 ms
 5  216.239.43.45  18.901 ms  19.234 ms  20.123 ms
 6  8.8.8.8     21.456 ms  21.567 ms  22.123 ms
```

`* * *` means no response (firewall or silent router).

### mtr — Continuous Traceroute + Ping

`mtr` combines traceroute and ping into a single, continuously updating display.

```bash
# Install mtr
sudo apt install mtr  # Debian/Ubuntu
sudo yum install mtr  # RHEL/CentOS

# Run mtr
mtr 8.8.8.8

# Text-only output (no ncurses)
mtr -r 8.8.8.8

# Generate a report (10 cycles)
mtr -r -c 10 8.8.8.8

# No DNS
mtr -n 8.8.8.8

# Show both IPv4 and IPv6
mtr -4 8.8.8.8
```

Output:
```
                            My traceroute  [v0.95]
server01 (192.168.1.100) -> 8.8.8.8                       Tue Jan 15 10:23:45 2024
Keys:  Help   Display mode   Restart statistics   Order of fields   quit
                                       Packets               Pings
 Host                                Loss%   Snt   Last   Avg  Best  Wrst StDev
 1. 192.168.1.1                      0.0%    10    0.4   0.5   0.3   0.8   0.1
 2. 10.0.0.1                        0.0%    10    1.2   1.3   1.0   2.1   0.3
 3. 72.14.215.123                   0.0%    10   12.3  13.4  12.1  18.9   1.8
 4. 216.239.43.45                   0.0%    10   18.9  19.2  18.1  22.3   1.2
 5. 8.8.8.8                         0.0%    10   21.4  21.8  20.9  23.1   0.7
```

### tcpdump — Packet Capture

`tcpdump` is the Swiss Army knife of packet analysis.

#### Basic Usage

```bash
# Capture all traffic on an interface
sudo tcpdump -i enp0s3

# Capture N packets then stop
sudo tcpdump -i enp0s3 -c 100

# Don't resolve hostnames or ports
sudo tcpdump -i enp0s3 -nn

# Save to file (pcap format, readable by Wireshark)
sudo tcpdump -i enp0s3 -w capture.pcap -c 1000

# Read a capture file
sudo tcpdump -r capture.pcap -nn
```

#### Filter Expressions

```bash
# Host filter
sudo tcpdump -i enp0s3 host 192.168.1.1

# Port filter
sudo tcpdump -i enp0s3 port 80
sudo tcpdump -i enp0s3 port 22

# Protocol filter
sudo tcpdump -i enp0s3 icmp
sudo tcpdump -i enp0s3 tcp
sudo tcpdump -i enp0s3 udp
sudo tcpdump -i enp0s3 arp

# Complex expressions (and/or/not)
sudo tcpdump -i enp0s3 host 192.168.1.100 and port 443
sudo tcpdump -i enp0s3 not port 22
sudo tcpdump -i enp0s3 src 10.0.0.1 and dst port 53

# Subnet
sudo tcpdump -i enp0s3 net 192.168.1.0/24
```

#### Practical tcpdump Examples

```bash
# Watch DHCP traffic (bootp/dhcp uses ports 67/68)
sudo tcpdump -i enp0s3 -nn port 67 or port 68

# Watch DNS queries
sudo tcpdump -i enp0s3 -nn port 53

# Watch TCP handshake (SYN packets only)
sudo tcpdump -i enp0s3 'tcp[tcpflags] & tcp-syn != 0'

# Watch HTTP requests and responses
sudo tcpdump -i enp0s3 -A port 80   # -A = ASCII output
sudo tcpdump -i enp0s3 -X port 80   # -X = hex+ASCII

# Watch traffic for a specific MAC
sudo tcpdump -i enp0s3 ether host 08:00:27:ab:cd:ef

# Watch VLAN traffic
sudo tcpdump -i enp0s3 vlan

# Verbose output (more packet details)
sudo tcpdump -i enp0s3 -v
sudo tcpdump -i enp0s3 -vv
sudo tcpdump -i enp0s3 -vvv
```

#### tcpdump One-Liners

```bash
# Show top talkers by packet count
sudo tcpdump -i enp0s3 -nn -c 1000 | awk '{print $3}' | cut -d. -f1-4 | sort | uniq -c | sort -rn | head -10

# Capture HTTP requests only
sudo tcpdump -i enp0s3 -A -s 0 'tcp port 80 and (((ip[2:2] - ((ip[0]&0xf)<<2)) - ((tcp[12]&0xf0)>>2)) != 0)'

# Show non-TCP traffic (just UDP and others)
sudo tcpdump -i enp0s3 not tcp

# Capture during a specific window (background, stop later)
sudo tcpdump -i enp0s3 -w overnight.pcap &
# ... let it run ...
pkill -SIGINT tcpdump  # Stop gracefully
```

### ss — Socket Statistics (Modern netstat)

`ss` is the modern replacement for `netstat`, also using Netlink sockets.

```bash
# Show all sockets
ss -a

# Show all listening sockets
ss -l

# Show TCP sockets
ss -t

# Show UDP sockets
ss -u

# Show process using each socket
ss -tup

# Numeric (no DNS/service resolution)
ss -tulpn

# Show socket statistics summary
ss -s

# Show sockets in a specific state
ss -t state established
ss -t state listening
ss -t state time-wait
ss state fin-wait-1

# Show sockets for a specific port
ss -t sport = :22
ss -t dport = :80
ss -t '( sport = :22 or dport = :22 )'

# Show all connections to a specific host
ss -t dst 192.168.1.1

# Show timer info
ss -t -o

# Show memory usage per socket
ss -t -m
```

### Troubleshooting Methodology

#### Step-by-Step Network Problem Diagnosis

```bash
# Step 1: Is the interface up?
ip link show enp0s3 | grep "state UP"

# Step 2: Do we have an IP?
ip addr show enp0s3 | grep "inet "

# Step 3: Can we reach the gateway?
ping -c 2 $(ip route | grep default | awk '{print $3}')

# Step 4: Can we reach the internet?
ping -c 2 8.8.8.8

# Step 5: Does DNS work?
host google.com

# Step 6: Is the remote service reachable?
nc -zv 192.168.1.100 80

# Step 7: Check for packet loss
mtr -rn 8.8.8.8

# Step 8: Capture traffic for deep inspection
sudo tcpdump -i enp0s3 -c 100 -nn host 192.168.1.100
```

#### Common Problems and Solutions

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| Interface is DOWN | Cable unplugged | Check cable, `ip link set dev up` |
| No IP address | DHCP failure | `dhclient`, check DHCP server |
| Can't ping gateway | Wrong default route | `ip route add default via ...` |
| Can ping IP but not hostname | DNS misconfigured | Check `/etc/resolv.conf` |
| Slow connection | Duplex mismatch | `ethtool -s speed 1000 duplex full` |
| Dropped packets | Ring buffer full | `ethtool -G rx 4096` |
| High latency | Bufferbloat | Check for full buffers with `ss -t -m` |
| Port not responding | Firewall | `sudo iptables -L`, `sudo ufw status` |

---

## 🛠️ 15 Hands-On Practices

---

### 📘 Level 1 Practices: Interface Basics and Hostname Configuration

Explore your network interfaces, understand naming conventions, and configure hostname and DNS resolution settings.

### ✅ Practice 1: Explore Your Network Interfaces

```bash
mkdir -p ~/linux-course/part26
cd ~/linux-course/part26

# List all interfaces and their details
ip link show

# Save the output
ip link show > interfaces.txt

# Identify each interface type:
# - Which is the loopback?
# - Which is Ethernet?
# - Any wireless interfaces?

# Check interface speeds (if ethtool is available)
for iface in $(ip -o link show | awk -F': ' '{print $2}'); do
    echo "=== $iface ==="
    sudo ethtool "$iface" 2>/dev/null | grep -E "Speed|Duplex|Link detected" || echo "No ethtool info"
done

# Count total interfaces
echo "Total interfaces: $(ip -o link show | wc -l)"
```

---

### 📘 Level 2 Practices: Configuration, Management, and Troubleshooting

Master the `ip` command, configure interfaces with Netplan and nmcli, set up bonding/bridging/VLANs, and practice troubleshooting with mtr, tcpdump, and ss.

### ✅ Practice 2: Master the `ip` Command

```bash
cd ~/linux-course/part26

# 1. Show all IP addresses
ip addr > ip_addresses.txt

# 2. Show routing table
ip route > routing_table.txt

# 3. Show neighbor table (ARP)
ip neigh > arp_cache.txt

# 4. Show only IPv6 addresses
ip -6 addr > ipv6_addresses.txt

# 5. JSON output (programmatic)
ip -j -p addr show > ip_json.json

# Compare the output of each file
cat ip_addresses.txt
cat routing_table.txt
cat arp_cache.txt
```

---

### ✅ Practice 3: Compare `ip` vs `ifconfig` Output

```bash
cd ~/linux-course/part26

# Install net-tools if not present
which ifconfig || sudo apt install -y net-tools

# Compare outputs for the same interface
INTERFACE=$(ip -o link show | grep -v lo | head -1 | awk -F': ' '{print $2}')

echo "=== ip addr show $INTERFACE ==="
ip addr show $INTERFACE

echo ""
echo "=== ifconfig $INTERFACE ==="
ifconfig $INTERFACE

echo ""
echo "=== ip route ==="
ip route

echo ""
echo "=== route -n ==="
route -n

# Note the differences:
# - ifconfig shows less information (no statistics, no secondary IPs)
# - route shows less routing information
```

---

### ✅ Practice 4: Set a Static IP with Netplan

```bash
cd ~/linux-course/part26

# Back up existing config
sudo cp /etc/netplan/*.yaml /etc/netplan/backup.yaml 2>/dev/null || echo "No existing config to backup"

# Create a static IP configuration
sudo tee /etc/netplan/01-static-practice.yaml << 'EOF'
network:
  version: 2
  renderer: networkd
  ethernets:
    enp0s3:
      dhcp4: false
      addresses:
        - 192.168.50.10/24
      routes:
        - to: default
          via: 192.168.50.1
      nameservers:
        addresses:
          - 1.1.1.1
          - 8.8.8.8
EOF

# Test the configuration (auto-reverts in 120 seconds if not confirmed)
sudo netplan try

# Apply if confirmed
# sudo netplan apply

# Verify
# ip addr show enp0s3

# Restore DHCP
sudo tee /etc/netplan/01-static-practice.yaml << 'EOF'
network:
  version: 2
  renderer: networkd
  ethernets:
    enp0s3:
      dhcp4: true
EOF

# Re-apply
# sudo netplan apply
```

---

### ✅ Practice 5: Use nmcli to Configure a Connection

```bash
cd ~/linux-course/part26

# List all connections
nmcli connection show

# Create a new DHCP connection via nmcli
nmcli connection add \
    type ethernet \
    con-name "practice-dhcp" \
    ifname enp0s3 \
    ipv4.method auto

# Modify to static
nmcli connection modify "practice-dhcp" \
    ipv4.method manual \
    ipv4.addresses 192.168.50.20/24 \
    ipv4.gateway 192.168.50.1

# Show the connection file
echo "=== Connection file ==="
sudo cat /etc/NetworkManager/system-connections/practice-dhcp.nmconnection

# Delete the test connection
nmcli connection delete "practice-dhcp"
```

---

### ✅ Practice 6: Configure Hostname and /etc/hosts

```bash
cd ~/linux-course/part26

# Current hostname
echo "Current hostname: $(hostname)"
echo "FQDN: $(hostname -f)"

# Set a temporary hostname
sudo hostname practice-vm-01

# Confirm
hostname

# Add entries to /etc/hosts
echo "192.168.1.100   db-server db-server.example.com" | sudo tee -a /etc/hosts
echo "192.168.1.101   web-server web-server.example.com" | sudo tee -a /etc/hosts

# Test resolution
getent hosts db-server
getent hosts web-server
ping -c 1 db-server

# Remove entries
sudo sed -i '/db-server/d' /etc/hosts
sudo sed -i '/web-server/d' /etc/hosts

# Restore hostname
sudo hostname $(cat /etc/hostname)
```

---

### ✅ Practice 7: DNS Resolution Deep Dive

```bash
cd ~/linux-course/part26

# 1. Show resolver config
echo "=== /etc/resolv.conf ==="
cat /etc/resolv.conf

echo ""
echo "=== resolvectl status ==="
resolvectl status 2>/dev/null || systemd-resolve --status 2>/dev/null || echo "Not available"

# 2. Resolve a hostname
echo ""
echo "=== dig google.com ==="
dig +short google.com

# 3. Trace the resolution path
echo ""
echo "=== Resolution trace ==="
getent hosts google.com

# 4. Check nsswitch order
echo ""
echo "=== nsswitch hosts line ==="
grep hosts /etc/nsswitch.conf

# 5. Test DNS server resolution
echo ""
echo "=== Query specific DNS server ==="
dig @1.1.1.1 google.com +short

# 6. SRV record query
dig _http._tcp.google.com SRV +short 2>/dev/null || echo "No SRV record"
```

---

### ✅ Practice 8: Diagnose the Network with mtr and traceroute

```bash
cd ~/linux-course/part26

# 1. Basic connectivity
echo "=== Step 1: Local loopback ==="
ping -c 2 127.0.0.1

echo ""
echo "=== Step 2: Gateway ==="
GATEWAY=$(ip route | grep default | awk '{print $3}')
ping -c 2 "$GATEWAY"

echo ""
echo "=== Step 3: External IP ==="
ping -c 2 8.8.8.8

echo ""
echo "=== Step 4: DNS resolution ==="
host google.com 2>/dev/null || nslookup google.com 2>/dev/null

# 2. Traceroute
echo ""
echo "=== Traceroute to 8.8.8.8 ==="
traceroute -n 8.8.8.8 2>/dev/null || echo "traceroute not available"

# 3. mtr if available
if which mtr >/dev/null 2>&1; then
    echo ""
    echo "=== MTR report (5 cycles) ==="
    mtr -r -c 5 -n 8.8.8.8
fi

# Save results
traceroute -n 8.8.8.8 > traceroute_result.txt 2>/dev/null
echo "Saved traceroute result."
```

---

### ✅ Practice 9: Run tcpdump and Analyze Traffic

```bash
cd ~/linux-course/part26

# Capture 20 packets to a file
sudo tcpdump -i enp0s3 -c 20 -nn -w capture.pcap

# Read the capture
echo "=== Packet summary ==="
sudo tcpdump -r capture.pcap -nn -c 10

# Show hex dump of first 5 packets
echo ""
echo "=== Hex dump ==="
sudo tcpdump -r capture.pcap -nn -X -c 5

# Show packet statistics
echo ""
echo "=== Packet statistics ==="
capinfos capture.pcap 2>/dev/null || echo "capinfos not installed (try 'sudo apt install wireshark-common')"

# Count protocols
echo ""
echo "=== Protocol distribution ==="
sudo tcpdump -r capture.pcap -nn 2>/dev/null | awk '{print $3}' | cut -d. -f1 | sort | uniq -c | sort -rn

# Generate traffic while capturing in another terminal
# In a second terminal:
# ping -c 10 8.8.8.8
# curl http://example.com
```

---

### ✅ Practice 10: Manage Interface Bonding

```bash
cd ~/linux-course/part26

# This practice creates a virtual bond using dummy interfaces
# (since you may not have two physical NICs)

# Load bonding and dummy kernel modules
sudo modprobe bonding
sudo modprobe dummy

# Create two dummy interfaces to simulate physical NICs
sudo ip link add dummy0 type dummy
sudo ip link add dummy1 type dummy

# Create a bond interface
sudo ip link add bond0 type bond

# Configure bond mode (active-backup)
sudo ip link set bond0 type bond mode 1 miimon 100

# Add dummy interfaces as slaves
sudo ip link set dummy0 master bond0
sudo ip link set dummy1 master bond0

# Assign IP to bond
sudo ip addr add 192.168.200.50/24 dev bond0

# Bring everything up
sudo ip link set dummy0 up
sudo ip link set dummy1 up
sudo ip link set bond0 up

# Check bond status
echo "=== Bond status ==="
cat /proc/net/bonding/bond0

# Test failover
echo ""
echo "=== Active slave before ==="
cat /proc/net/bonding/bond0 | grep "Active Slave"

# Take down the active slave
ACTIVE=$(cat /proc/net/bonding/bond0 | grep "Active Slave" | awk '{print $4}')
echo "Taking down $ACTIVE..."
sudo ip link set "$ACTIVE" down

echo ""
echo "=== Active slave after failover ==="
sleep 1
cat /proc/net/bonding/bond0 | grep "Active Slave"

# Clean up
sudo ip link set bond0 down
sudo ip link delete bond0
sudo ip link delete dummy0
sudo ip link delete dummy1
```

---

### ✅ Practice 11: Create a Linux Bridge

```bash
cd ~/linux-course/part26

# Create a bridge
sudo ip link add br-practice type bridge

# Create two veth pairs (virtual Ethernet cables)
sudo ip link add veth-a type veth peer name veth-a-br
sudo ip link add veth-b type veth peer name veth-b-br

# Connect one end of each to the bridge
sudo ip link set veth-a-br master br-practice
sudo ip link set veth-b-br master br-practice

# Assign IPs to the free ends
sudo ip addr add 10.0.100.1/24 dev veth-a
sudo ip addr add 10.0.100.2/24 dev veth-b

# Bring everything up
sudo ip link set br-practice up
sudo ip link set veth-a up
sudo ip link set veth-b up
sudo ip link set veth-a-br up
sudo ip link set veth-b-br up

# Verify bridge
echo "=== Bridge status ==="
bridge link show master br-practice

# Test connectivity through the bridge
echo ""
echo "=== Ping through bridge ==="
ping -c 2 -I veth-a 10.0.100.2

# Show FDB (forwarding database)
echo ""
echo "=== MAC table ==="
bridge fdb show br br-practice

# Clean up
sudo ip link delete br-practice
sudo ip link delete veth-a
sudo ip link delete veth-b
```

---

### ✅ Practice 12: Configure a VLAN Interface

```bash
cd ~/linux-course/part26

# Load 8021q kernel module
sudo modprobe 8021q

# Create a VLAN interface on top of a dummy interface
sudo ip link add dummy-vlan type dummy
sudo ip link set dummy-vlan up

# Create VLAN 100 and VLAN 200
sudo ip link add link dummy-vlan name dummy-vlan.100 type vlan id 100
sudo ip link add link dummy-vlan name dummy-vlan.200 type vlan id 200

# Assign IPs
sudo ip addr add 10.0.100.1/24 dev dummy-vlan.100
sudo ip addr add 10.0.200.1/24 dev dummy-vlan.200

# Bring them up
sudo ip link set dummy-vlan.100 up
sudo ip link set dummy-vlan.200 up

# Show VLAN interfaces
echo "=== VLAN interfaces ==="
ip link show type vlan

# Show VLAN details
echo ""
echo "=== VLAN 100 details ==="
cat /proc/net/vlan/dummy-vlan.100

# Enable routing between VLANs (router-on-a-stick)
sudo sysctl -w net.ipv4.ip_forward=1

# Show IPs on each VLAN
echo ""
echo "=== IPs ==="
ip addr show dummy-vlan.100
ip addr show dummy-vlan.200

# Clean up
sudo ip link delete dummy-vlan
```

---

### 📘 Level 3 Practices: Performance Tuning and Advanced Diagnostics

Tune network interfaces with ethtool, analyze socket states with ss, and apply your skills in a multi-segment network mini-project.

### ✅ Practice 13: Tune Network with ethtool

```bash
cd ~/linux-course/part26

# Pick the first non-loopback interface
IFACE=$(ip -o link show | grep -v lo | head -1 | awk -F': ' '{print $2}')

echo "=== Interface: $IFACE ==="

# Basic info
echo "=== ethtool $IFACE ==="
sudo ethtool "$IFACE" 2>/dev/null

# Driver info
echo ""
echo "=== Driver info ==="
sudo ethtool -i "$IFACE" 2>/dev/null

# Offload settings
echo ""
echo "=== Offload settings ==="
sudo ethtool -k "$IFACE" 2>/dev/null | head -20

# Ring buffer
echo ""
echo "=== Ring buffers ==="
sudo ethtool -g "$IFACE" 2>/dev/null

# Coalescing settings
echo ""
echo "=== Coalescing ==="
sudo ethtool -c "$IFACE" 2>/dev/null

# Current speed and duplex
echo ""
echo "=== Current link ==="
sudo ethtool "$IFACE" 2>/dev/null | grep -E "Speed|Duplex|Auto-negotiation|Link detected"

# Check if WOL is enabled
echo ""
echo "=== Wake-on-LAN ==="
sudo ethtool "$IFACE" 2>/dev/null | grep "Wake-on"

# Interface statistics
echo ""
echo "=== Interface stats ==="
ip -s link show "$IFACE"
```

---

### ✅ Practice 14: Deep Troubleshooting with ss and Socket Analysis

```bash
cd ~/linux-course/part26

# 1. Socket statistics summary
echo "=== Socket summary ==="
ss -s

# 2. All listening ports
echo ""
echo "=== Listening ports ==="
ss -tulpn

# 3. Established TCP connections
echo ""
echo "=== Established connections ==="
ss -t state established

# 4. Services with the most connections
echo ""
echo "=== Top services by connection count ==="
ss -t | awk '{print $4}' | cut -d: -f1 | sort | uniq -c | sort -rn | head -10

# 5. Connection states distribution
echo ""
echo "=== TCP state distribution ==="
ss -t | awk '{print $1}' | sort | uniq -c | sort -rn

# 6. Time-wait connections (high count = performance issue)
echo ""
echo "=== TIME-WAIT connections ==="
ss -t state time-wait | wc -l

# 7. Process owning each socket
echo ""
echo "=== Socket to process mapping ==="
ss -tupn | head -20

# 8. Memory usage per socket
echo ""
echo "=== Socket memory (top 5) ==="
ss -t -m | grep -oP 'skmem\([^)]+\)' | head -10
```

---

### ✅ Practice 15: Real-World Integration — Multi-Segment Network Mini-Project

```bash
cd ~/linux-course/part26

# This practice builds a small multi-segment network with:
# - A bridge (switch)
# - Two VLANs
# - A bonding interface
# - Routing between segments
# - All virtual, running on a single machine

cat > network-lab.sh << 'EOF'
#!/bin/bash
set -euo pipefail

echo "============================================"
echo "  Multi-Segment Network Lab"
echo "============================================"

# Load modules
sudo modprobe bonding
sudo modprobe 8021q
sudo modprobe dummy

# Create the "physical" interfaces (simulated)
sudo ip link add phys0 type dummy
sudo ip link add phys1 type dummy
sudo ip link add phys2 type dummy

# 1. Create a bond from phys0 and phys1 (redundant trunk)
echo "[1] Creating bond0 (active-backup)..."
sudo ip link add bond0 type bond mode 1 miimon 100
sudo ip link set phys0 master bond0
sudo ip link set phys1 master bond0
sudo ip link set bond0 up
sudo ip link set phys0 up
sudo ip link set phys1 up
echo "  Bond status:"
cat /proc/net/bonding/bond0 | grep -E "Bonding Mode|Active Slave"

# 2. Create VLANs on the bond (trunk ports)
echo ""
echo "[2] Creating VLANs on bond0..."
sudo ip link add link bond0 name bond0.10 type vlan id 10
sudo ip link add link bond0 name bond0.20 type vlan id 20
sudo ip link set bond0.10 up
sudo ip link set bond0.20 up

# 3. Create a bridge for VLAN 10
echo ""
echo "[3] Creating bridge br10 for VLAN 10..."
sudo ip link add br10 type bridge
sudo ip link set bond0.10 master br10
sudo ip addr add 10.0.10.1/24 dev br10
sudo ip link set br10 up

# 4. Create a bridge for VLAN 20
echo ""
echo "[4] Creating bridge br20 for VLAN 20..."
sudo ip link add br20 type bridge
sudo ip link set bond0.20 master br20
sudo ip addr add 10.0.20.1/24 dev br20
sudo ip link set br20 up

# 5. Connect a "client" to each VLAN via veth pairs
echo ""
echo "[5] Connecting simulated clients..."
# Client A on VLAN 10
sudo ip link add client-a type veth peer name client-a-br
sudo ip link set client-a-br master br10
sudo ip addr add 10.0.10.100/24 dev client-a
sudo ip link set client-a up
sudo ip link set client-a-br up

# Client B on VLAN 20
sudo ip link add client-b type veth peer name client-b-br
sudo ip link set client-b-br master br20
sudo ip addr add 10.0.20.100/24 dev client-b
sudo ip link set client-b up
sudo ip link set client-b-br up

# 6. Connect the router to phys2
echo ""
echo "[6] Setting up external connectivity..."
sudo ip addr add 10.0.0.1/24 dev phys2
sudo ip link set phys2 up

# 7. Enable IP forwarding (router)
echo ""
echo "[7] Enabling routing..."
sudo sysctl -w net.ipv4.ip_forward=1

# 8. Verify everything
echo ""
echo "============================================"
echo "  Network Lab — Verification"
echo "============================================"

echo ""
echo "=== Interfaces ==="
ip link show | grep -E "bond|br|client|phys" | awk '{print $2, $9}'

echo ""
echo "=== VLANs ==="
ip link show type vlan

echo ""
echo "=== Bridges ==="
bridge link show | head -10

echo ""
echo "=== Bond status ==="
cat /proc/net/bonding/bond0 | grep -E "Bonding Mode|Active Slave|MII Status"

echo ""
echo "=== IP assignments ==="
ip addr show | grep "inet " | grep -E "10\.0\."

echo ""
echo "=== Connectivity tests ==="
echo -n "Client A → Gateway (VLAN 10): "
ping -c 1 -W 1 -I client-a 10.0.10.1 >/dev/null 2>&1 && echo "OK" || echo "FAIL"

echo -n "Client B → Gateway (VLAN 20): "
ping -c 1 -W 1 -I client-b 10.0.20.1 >/dev/null 2>&1 && echo "OK" || echo "FAIL"

echo -n "Client A → Client B (inter-VLAN): "
ping -c 1 -W 1 -I client-a 10.0.20.100 >/dev/null 2>&1 && echo "OK (routed)" || echo "FAIL (no route, needs firewall rules)"

echo ""
echo "============================================"
echo "  Lab complete! Run './network-cleanup.sh' to tear down."
echo "============================================"
EOF

chmod +x network-lab.sh

cat > network-cleanup.sh << 'EOF'
#!/bin/bash
set -euo pipefail

echo "Tearing down network lab..."
sudo ip link delete br10 2>/dev/null || true
sudo ip link delete br20 2>/dev/null || true
sudo ip link delete bond0 2>/dev/null || true
sudo ip link delete phys0 2>/dev/null || true
sudo ip link delete phys1 2>/dev/null || true
sudo ip link delete phys2 2>/dev/null || true
sudo ip link delete client-a 2>/dev/null || true
sudo ip link delete client-b 2>/dev/null || true
echo "Cleanup complete."
EOF

chmod +x network-cleanup.sh

echo "Network lab scripts created!"
echo ""
echo "Run the lab:"
echo "  sudo ./network-lab.sh"
echo ""
echo "Clean up:"
echo "  sudo ./network-cleanup.sh"
```

---

## 🧠 Deep Understanding — How Linux Networking Really Works

### The Network Stack (OSI Model in Linux)

Linux implements the network stack in kernel space. Here is how the layers map:

```
Layer 7 (Application)     ─┐
    HTTP, SSH, DNS         │  User space
Layer 4 (Transport)        │  (socket interface)
    TCP, UDP               │
                           │
Layer 3 (Network)         ─┤  Kernel space
    IP, ICMP, ARP          │  Network stack
                           │
Layer 2 (Data Link)       ─┤
    Ethernet, Bridge       │  Device drivers
                           │
Layer 1 (Physical)        ─┤  Hardware
    Cable, Radio           │
```

### How a Packet Flows: Sending

```
Application: send(sockfd, "Hello", 5, 0);
    ↓
1. User space → Kernel boundary (syscall)
    ↓
2. Socket layer — buffers the data, determines protocol (TCP/UDP)
    ↓
3. TCP layer — segments the data, adds sequence numbers, computes checksum
    ↓
4. IP layer — wraps in IP packet, determines routing (fib_lookup → routing table)
    ↓
5. Neighbor layer — resolves next-hop MAC via ARP (or finds cached entry)
    ↓
6. Device driver — enqueues packet on TX ring buffer
    ↓
7. NIC — transmits bits on the wire (DMA from memory to cable)
    ↓
8. Interrupt fires when transmission completes → driver frees the buffer
```

### How a Packet Flows: Receiving

```
NIC receives bits on the wire
    ↓
1. DMA — NIC writes packet data directly to memory (no CPU involvement)
    ↓
2. Interrupt — NIC raises IRQ → kernel runs interrupt handler
    ↓
3. NAPI — modern drivers use polling to avoid interrupt storm
    ↓
4. GRO — Generic Receive Offload merges smaller packets
    ↓
5. Netfilter — hooks for iptables/nftables
    ↓
6. IP layer — reassembles fragments, routes lookup (is it for us? forward?)
    ↓
7. TCP layer — checksums, orders segments (if the local socket)
    ↓
8. Socket receive queue — data is available for recv()
    ↓
9. Application reads data via syscall (recvfrom, read)
```

### Netlink Sockets — How `ip` Talks to the Kernel

The `ip` command (and `ss`, `bridge`, `devlink`) communicates with the kernel via **Netlink sockets**. Netlink is a socket-based IPC mechanism specifically for kernel-to-user and user-to-kernel networking control.

```bash
# Netlink socket types used by iproute2:
# NETLINK_ROUTE — routing, links, addresses, neighbors
# NETLINK_SOCK_DIAG — socket diagnostics (ss)
# NETLINK_NEIGHBOR — neighbor discovery
# NETLINK_FIB_LOOKUP — forwarding information base

# See Netlink sockets on your system
ss -f netlink

# strace the ip command to see Netlink in action
strace -e socket,sendmsg,recvmsg ip addr show 2>&1 | head -20
```

Output of strace:
```
socket(AF_NETLINK, SOCK_RAW|SOCK_CLOEXEC, NETLINK_ROUTE) = 3
sendmsg(3, {msg_name={...}, msg_iov=[...]}, 0) = 40
recvmsg(3, {msg_name={...}, msg_iov=[...]}, 0) = 4096
```

This is why `ip` is more powerful than `ifconfig` — Netlink supports adding new message types without changing the kernel ABI, while `ioctl` requires new ioctl numbers for every feature.

### The Role of udev in Interface Naming

When the kernel discovers a new network device, it:

1. Creates a `net` device in sysfs (`/sys/class/net/<name>/`)
2. Sends a `uevent` to udev
3. udev looks at its rules in `/lib/udev/rules.d/`
4. Rules check for `ID_NET_NAME_ONBOARD`, `ID_NET_NAME_SLOT`, `ID_NET_NAME_MAC`
5. udev renames the interface using `ip link set dev <old> name <new>`
6. The new name is assigned based on the best available identifier

```bash
# Trace udev events for a new device
sudo udevadm monitor --property | grep -E "INTERFACE|ACTION|ID_NET"

# Simulate a new device event
sudo udevadm trigger --verbose --subsystem-match=net
```

### Network Namespaces — Lightweight Virtual Networking

A network namespace is a separate copy of the network stack with its own interfaces, routes, firewall rules, and sockets. Containers use this heavily.

```bash
# Create a network namespace
sudo ip netns add blue
sudo ip netns add red

# Create a veth pair connecting them
sudo ip link add veth-blue type veth peer name veth-red

# Move each end into its namespace
sudo ip link set veth-blue netns blue
sudo ip link set veth-red netns red

# Configure in the blue namespace
sudo ip netns exec blue ip addr add 10.0.0.1/24 dev veth-blue
sudo ip netns exec blue ip link set veth-blue up
sudo ip netns exec blue ip link set lo up

# Configure in the red namespace
sudo ip netns exec red ip addr add 10.0.0.2/24 dev veth-red
sudo ip netns exec red ip link set veth-red up
sudo ip netns exec red ip link set lo up

# Ping from blue to red
sudo ip netns exec blue ping -c 2 10.0.0.2

# Check processes in each namespace
sudo ip netns exec blue ps aux

# Each namespace has its own:
# - Interfaces (lo is separate)
# - Routing table
# - ARP table
# - iptables rules
# - /proc/net/*
# - Sockets (port 80 can be used in both)
```

```bash
# List all namespaces
ip netns list

# Show routes in a namespace
sudo ip netns exec blue ip route

# Run a shell in a namespace
sudo ip netns exec blue bash
# Now you're in the "blue" network stack!
```

### The Socket Buffer (sk_buff)

Every packet in the kernel travels inside an `sk_buff` structure. This is the fundamental data structure of the network stack:

```
┌──────────────────────────────────┐
│  sk_buff                         │
├──────────────────────────────────┤
│  dev         ← incoming/outgoing │
│  sk          ← owning socket     │
│  protocol   ← EtherType          │
│  priority   ← QoS                │
│  len        ← total length       │
│  data       ← pointer to payload │
│  mac_header ← L2 header          │
│  nh         ← L3 header (IP)     │
│  h          ← L4 header (TCP)    │
│  cb         ← control block      │
│  tstamp     ← packet timestamp   │
│  mark       ← netfilter mark     │
└──────────────────────────────────┘
```

The `sk_buff` is passed through the stack, and each layer moves the `data` pointer forward as it strips headers:

```
Arriving:  [Eth hdr][IP hdr][TCP hdr][Payload]
            ↑
            data pointer

After L2:   [Eth hdr][IP hdr][TCP hdr][Payload]
                     ↑
                     data pointer (eth stripped)

After L3:   [Eth hdr][IP hdr][TCP hdr][Payload]
                              ↑
                              data pointer (IP stripped)
```

### Interrupt Coalescing and NAPI

Without coalescing, every packet generates an interrupt, overwhelming the CPU at high packet rates.

```
High packet rate (bad):
Packet 1 ─→ IRQ ─→ handler ─→ process
Packet 2 ─→ IRQ ─→ handler ─→ process  ← CPU saturated with interrupts
Packet 3 ─→ IRQ ─→ handler ─→ process
...

With NAPI (good):
Packet 1 ─→ IRQ ─→ handler disables interrupts, starts polling
Packet 2 ─→ ─────→ poll() collects all packets in batch
Packet 3 ─→ ─────→ poll() collects all packets in batch
    ...               ...
                  → handler re-enables interrupts when no more packets
```

```bash
# Check if NAPI is active on an interface
cat /sys/class/net/enp0s3/gro_flush_timeout
cat /sys/class/net/enp0s3/napi_defer_hard_irqs

# Check GRO (Generic Receive Offload) stats
ethtool -S enp0s3 | grep -i gro
```

### tc — Traffic Control

The Linux traffic control system (`tc`) manages queuing disciplines:

```bash
# Show current qdisc (queue discipline)
tc qdisc show dev enp0s3

# Default qdisc: pfifo_fast (three-band priority queue)
# Alternative: fq_codel (fair queuing with controlled delay)

# Set fq_codel for better latency under load
sudo tc qdisc replace dev enp0s3 root fq_codel
```

### Key Takeaway

Every layer of the Linux network stack is modular and replaceable:
- **Driver** handles hardware specifics
- **Qdisc** manages packet queuing
- **Netfilter** provides firewall hooks
- **Neighbor subsystem** tracks L2↔L3 mappings
- **Routing tables** decide next hops
- **Network namespaces** isolate entire stacks

Understanding this stack is what separates a sysadmin who blindly copies commands from one who truly knows how Linux networks work.

---

## 📚 Command Reference

### ⭐ Level 1 Commands: Interface Basics and Hostname

| Command | Description |
|---------|-------------|
| `hostnamectl set-hostname NAME` | Set system hostname |
| `hostname` | Show current hostname |
| `hostname -f` | Show FQDN |
| `getent hosts NAME` | Query system host resolution |
| `ip link show` | List all network interfaces |
| `ip addr show` | Show all IP addresses |
| `ip -6 addr` | Show only IPv6 addresses |
| `ip -j -p addr show` | JSON output (programmatic) |
| `ifconfig eth0 up/down` | Legacy: bring interface up/down |

### ⭐ Level 2 Commands: Configuration and Troubleshooting

**The `ip` Command**

| Command | Description |
|---------|-------------|
| `ip addr add 10.0.0.1/24 dev eth0` | Add IP to interface |
| `ip addr del 10.0.0.1/24 dev eth0` | Remove IP from interface |
| `ip link set eth0 up/down` | Bring interface up or down |
| `ip link set eth0 mtu 9000` | Set MTU |
| `ip route` | Show routing table |
| `ip route add default via 10.0.0.1` | Add default gateway |
| `ip route add 10.0.0.0/8 via 10.0.0.1` | Add static route |
| `ip route del 10.0.0.0/8` | Delete route |
| `ip neigh` | Show ARP/neighbor table |

**Legacy Commands**

| Command | Description |
|---------|-------------|
| `ifconfig eth0 10.0.0.1 netmask 255.255.255.0` | Legacy: set IP |
| `route -n` | Legacy: show routing table |
| `route add default gw 10.0.0.1` | Legacy: add default gateway |
| `arp -n` | Legacy: show ARP table |

**NetworkManager**

| Command | Description |
|---------|-------------|
| `nmcli device status` | List network devices |
| `nmcli connection show` | List connections |
| `nmcli connection add type ethernet ...` | Create connection |
| `nmcli connection modify NAME ...` | Change connection settings |
| `nmcli connection up NAME` | Activate connection |
| `nmcli connection down NAME` | Deactivate connection |
| `nmcli device wifi list` | Scan Wi-Fi networks |
| `nmcli device wifi connect SSID password PASS` | Connect to Wi-Fi |
| `nmtui` | Text-based NetworkManager UI |

**Netplan**

| Command | Description |
|---------|-------------|
| `netplan apply` | Apply current configuration |
| `netplan try` | Test configuration (auto-revert) |
| `netplan generate` | Generate backend configs |
| `netplan get` | Show current config |
| `netplan status` | Show status of all interfaces |
| `netplan status --diff` | Show diff between config and current |

**DNS**

| Command | Description |
|---------|-------------|
| `dig example.com` | DNS query (detailed) |
| `dig +short example.com` | DNS query (short answer) |
| `host example.com` | Simple DNS lookup |
| `nslookup example.com` | Classic DNS lookup |
| `resolvectl query example.com` | systemd-resolved query |
| `resolvectl status` | Show resolver configuration |

**Bonding and Bridging**

| Command | Description |
|---------|-------------|
| `ip link add bond0 type bond mode 1` | Create bond interface |
| `ip link set eth0 master bond0` | Add slave to bond |
| `cat /proc/net/bonding/bond0` | Show bond status |
| `ip link add br0 type bridge` | Create bridge |
| `ip link set eth0 master br0` | Add port to bridge |
| `bridge link show` | Show bridge ports |
| `bridge fdb show` | Show MAC forwarding table |
| `brctl show` | Legacy: show bridges |

**VLAN**

| Command | Description |
|---------|-------------|
| `ip link add link eth0 name eth0.100 type vlan id 100` | Create VLAN interface |
| `ip -d link show type vlan` | Show all VLANs |
| `cat /proc/net/vlan/eth0.100` | Show VLAN details |

**Troubleshooting**

| Command | Description |
|---------|-------------|
| `ping -c 4 host` | Test connectivity |
| `traceroute -n host` | Trace route to host |
| `mtr -rn host` | Continuous traceroute + ping |
| `tcpdump -i eth0 -nn` | Capture packets |
| `tcpdump -i eth0 -w file.pcap` | Save capture to file |
| `ss -tulpn` | Show listening sockets with processes |
| `ss -t state established` | Show established connections |
| `ss -s` | Socket statistics summary |

### ⭐ Level 3 Commands: Performance Tuning

| Command | Description |
|---------|-------------|
| `ethtool eth0` | Show interface capabilities and settings |
| `ethtool -i eth0` | Show driver info |
| `ethtool -k eth0` | Show offload features |
| `ethtool -g eth0` | Show ring buffer sizes |
| `ethtool -S eth0` | Show NIC statistics |
| `ethtool -s eth0 speed 1000 duplex full` | Set speed and duplex |

---

## 🚀 What's Coming in Part 27

**Part 27: DNS and Name Resolution** — You have seen how `/etc/resolv.conf`, `systemd-resolved`, and `dig` work. In Part 27 you will dive deep into the Domain Name System itself: how recursive and authoritative resolvers differ, how to run your own BIND or Unbound DNS server, how DNSSEC protects against cache poisoning, and how to troubleshoot complex DNS issues. You will also learn about mDNS, LLMNR, and split-horizon DNS for enterprise environments.

Topics covered:
- DNS hierarchy — root servers, TLDs, authoritative nameservers
- Resource record types: A, AAAA, CNAME, MX, TXT, NS, SOA, SRV
- Running BIND9 as a caching resolver
- Running Unbound as a local DNS server
- DNSSEC validation and key management
- Split-horizon DNS with views (BIND)
- mDNS and Avahi for local network discovery
- DNS troubleshooting with dig, nslookup, delv, and tcpdump
- 15 hands-on practices

---

## 📝 Self-Test — Can You Answer These?

1. What are the three main predictable network interface naming schemes (enp0s3, ens33, eno1)? What determines which one is used?
2. What kernel mechanism does the `ip` command use to communicate with the kernel (as opposed to `ifconfig`'s mechanism)?
3. How do you add a secondary IP address using `ip addr`? How was this done with `ifconfig`?
4. What is the difference between `netplan try` and `netplan apply`?
5. What file does a Debian/Ubuntu system use for network configuration before Netplan was introduced?
6. In RHEL/CentOS, what is the purpose of the `ifcfg-eth0` file and where is it located?
7. How does `/etc/nsswitch.conf` control the order of name resolution?
8. What is the difference between systemd-resolved's stub resolver (`127.0.0.53`) and a traditional `/etc/resolv.conf`?
9. What are the six bonding modes? Which mode provides LACP (802.3ad) aggregation?
10. How does a Linux bridge differ from a switch? What is STP and why is it needed?
11. What happens to a packet when it is received by a VLAN interface with a matching VID?
12. How do you use `ethtool -k` to check and disable TCP segmentation offload?
13. What does the `-M do` flag in `ping` test? How does `tracepath` use this?
14. What is the difference between `ss -t` and `ss -t state established`?
15. What kernel data structure carries every packet through the Linux network stack, and what does each layer's processing do to its `data` pointer?

**Score:** 12/15 correct = ready for Part 27.

---

*Linux SysAdmin Course | Part 26 of ∞ | Reverse Engineering Approach*
*Previous → Part 25: System Rescue and Recovery*
*Next → Part 27: DNS and Name Resolution*

[← Previous](part25.md) | [Next →](part27.md)
