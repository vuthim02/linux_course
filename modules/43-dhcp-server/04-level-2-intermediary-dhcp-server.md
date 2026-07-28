## ⭐ Level 2: Intermediary — DHCP Server Configuration and Management

> **Level Goal:** Install and configure ISC DHCP server, manage static reservations, option sets, multiple subnets, and DHCP relay agents.

### What You'll Cover
- Installing and starting `isc-dhcp-server`
- `dhcpd.conf` syntax: declarations, statements, option definitions
- Static reservations (MAC-to-IP mapping)
- DHCP option sets and per-subnet overrides
- Multiple subnet configurations
- DHCP relay agents for跨-router deployments
- Logging and troubleshooting lease issues

At this level you configure a production DHCP server with multiple subnets, static reservations, and relay agents.

At this level you will practice:

- **ISC DHCP installation**: RHEL: `dnf install dhcp-server`. Ubuntu: `apt install isc-dhcp-server`. Configure the listening interface in `/etc/default/isc-dhcp-server` (INTERFACESv4="eth0"). Start with `systemctl enable --now dhcpd`.
- **`dhcpd.conf`**: The main configuration file. `subnet 192.168.1.0 netmask 255.255.255.0 { range 192.168.1.100 192.168.1.200; option routers 192.168.1.1; }` defines a subnet with a dynamic range and default gateway.
- **Static reservations**: `host webserver { hardware ethernet 00:11:22:33:44:55; fixed-address 192.168.1.10; }` always assigns the same IP to a specific MAC address. Essential for servers and printers that need consistent IPs.
- **Multiple subnets**: Define separate `subnet` blocks for each VLAN. Each subnet has its own range, options, and DNS servers. Use `allow` and `deny` statements to control which clients can get addresses.
- **DHCP relay**: When the DHCP server is on a different subnet than the clients, configure `ip helper-address` on the router (Cisco) or `dhcrelay` on a Linux gateway. The relay forwards DORA packets across subnets.


[← Previous](03-section-1-what-is-dhcp.md) | [↑ Index](index.md) | [Next →](05-section-2-isc-dhcp-server.md)
