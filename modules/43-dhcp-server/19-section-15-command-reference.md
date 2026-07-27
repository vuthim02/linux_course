## 📋 Section 15: Command Reference

### ⭐ Level 1: Basic Commands

#### 15.1 ISC DHCP Server Commands

| Command | Description |
|---------|-------------|
| `sudo dhcpd -t` | Test config syntax |
| `sudo dhcpd -f -d` | Run in foreground debug mode |
| `sudo dhcpd -cf /etc/dhcp/dhcpd.conf` | Specify config file |
| `sudo dhclient eth0` | DHCP client |
| `sudo dhclient -r eth0` | Release lease |
| `sudo dhclient -v eth0` | Verbose client |

#### 15.2 DHCP Option Codes Quick Reference

| Code | Name | Type |
|------|------|------|
| 1 | Subnet Mask | IP |
| 3 | Router | IP list |
| 6 | Domain Name Server | IP list |
| 12 | Host Name | String |
| 15 | Domain Name | String |
| 28 | Broadcast Address | IP |
| 42 | NTP Servers | IP list |
| 51 | IP Address Lease Time | uint32 (s) |
| 53 | DHCP Message Type | byte |
| 54 | Server Identifier | IP |
| 58 | Renewal Time (T1) | uint32 |
| 59 | Rebinding Time (T2) | uint32 |
| 60 | Vendor Class Identifier | String |
| 66 | TFTP Server Name | String |
| 67 | Bootfile Name | String |
| 252 | WPAD URL | String |

### ⭐ Level 2: Intermediary Commands

#### 15.3 Relay and Diagnostic Commands

| Command | Description |
|---------|-------------|
| `sudo dhcrelay 192.168.1.10` | Start relay agent |
| `sudo dhcrelay -d 192.168.1.10` | Relay debug mode |
| `sudo dhcpd -6 -cf /etc/dhcp/dhcpd6.conf` | Run DHCPv6 server |
| `sudo ss -tulpn \| grep :67` | Check DHCP server is listening |
| `sudo tcpdump -i eth0 port 67 or port 68 -n -v` | Capture DHCP packets |
| `sudo tcpdump -i eth0 port 67 or port 68 -w file.pcap` | Save capture to file |
| `sudo tail -f /var/log/syslog \| grep dhcpd` | Monitor DHCP logs |
| `sudo grep DHCPACK /var/log/syslog` | Find successful assignments |
| `sudo grep DHCPNAK /var/log/syslog` | Find denials |
| `dhcping -s 192.168.1.10 -c 192.168.1.100` | Test DHCP server reply |
| `dhcping -s 192.168.1.10 -g 192.168.2.1` | Test relay via giaddr |
| `nmcli dev show eth0` | Check client IP |
| `cat /var/lib/dhcp/dhcpd.leases` | View all leases |

#### 15.4 Wireshark DHCP Filters

| Filter | Purpose |
|--------|---------|
| `bootp` | All DHCP/BOOTP traffic |
| `bootp.type == 1` | DISCOVER only |
| `bootp.type == 2` | OFFER only |
| `bootp.type == 3` | REQUEST only |
| `bootp.type == 5` | ACK only |
| `bootp.option.dhcp == 66` | Option 66 (TFTP) |
| `bootp.option.dhcp == 67` | Option 67 (bootfile) |
| `bootp.giaddr != 0.0.0.0` | Relayed packets |

### ⭐ Level 3: Advanced Commands

#### 15.5 Failover and Kea Commands

| Command | Description |
|---------|-------------|
| `sudo dhcpd -T` | Test failover config |
| `kea-dhcp4 -t /etc/kea/kea-dhcp4.conf` | Test Kea DHCPv4 config |
| `kea-dhcp6 -t /etc/kea/kea-dhcp6.conf` | Test Kea DHCPv6 config |
| `kea-ctrl-agent -t /etc/kea/kea-ctrl-agent.conf` | Test control agent |
| `kea-admin db-init mysql -u kea -p pass -n kea` | Init MySQL DB |
| `kea-shell --host localhost --port 8000 command config-get` | CLI to control agent |

---



---

[← Previous](18-section-14-deep-understanding.md) | [↑ Index](index.md) | [Next →](20-section-16-whats-coming-in.md)
