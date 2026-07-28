## ⭐ Level 2: Intermediary — Network Configuration, Management, and Troubleshooting

![ip command output](https://upload.wikimedia.org/wikipedia/commons/thumb/2/2c/Linux_command_output_screenshot.png/220px-Linux_command_output_screenshot.png)  
*Command-line network management on Linux. Image credit: Wikimedia Commons.*

> **Level 2 Goal:** Master the `ip` command, configure interfaces with NetworkManager and Netplan, set up bonding/bridging/VLANs, and troubleshoot connectivity using `ping`, `traceroute`, `mtr`, `tcpdump`, and `ss`.

### What You'll Cover
- The `ip` command: `ip addr`, `ip link`, `ip route`, `ip neigh`
- NetworkManager: `nmcli` and `nmtui` for day-to-day configuration
- Netplan: YAML-based network config for Ubuntu
- Bonding (LACP) and bridging for link aggregation
- VLAN tagging with `ip link add link ... name ... type vlan`

The `ip` command is the modern replacement for `ifconfig`, `route`, and `arp`. It is faster, more feature-rich, and actively maintained. Mastering it is non-negotiable for Linux network administration.

At this level you will practice:

- **`ip addr`**: Add an IP: `ip addr add 192.168.1.10/24 dev enp0s3`. Show all: `ip -br addr` (brief mode). The `-4` and `-6` flags filter by protocol version.
- **`ip route`**: Add a default route: `ip route add default via 192.168.1.1`. Show routes: `ip route show`. The kernel's routing table determines where packets are sent.
- **NetworkManager**: `nmcli con show` lists connections. `nmcli con modify "Wired" ipv4.addresses 192.168.1.10/24` sets an IP. `nmtui` provides a text UI for interactive configuration.
- **Bonding**: Combine multiple NICs for redundancy or throughput. `ip link add bond0 type bond mode 802.3ad` creates an LACP bond. `ip link set enp0s3 master bond0` enslaves a NIC to the bond.
- **VLANs**: `ip link add link enp0s3 name enp0s3.100 type vlan id 100` creates a VLAN sub-interface. This is essential for separating traffic on switches that carry multiple VLANs.


[← Previous](03-section-1-network-interfaces-overview.md) | [↑ Index](index.md) | [Next →](05-section-2-the-ip-command.md)
