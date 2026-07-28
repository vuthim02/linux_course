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





[← Previous](09-section-6-traditional-etcnetworkinterfaces-debianubuntu.md) | [↑ Index](index.md) | [Next →](11-section-8-etchosts-and-etchostname.md)
