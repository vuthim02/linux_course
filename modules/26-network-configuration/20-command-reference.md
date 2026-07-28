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





[← Previous](19-deep-understanding-how-linux-networking.md) | [↑ Index](index.md) | [Next →](21-whats-coming-in-part-27.md)
