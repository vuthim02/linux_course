## 📚 Quick Reference Cards

### DORA Flow
```
Client                          Server
  │ DISCOVER (BC, 0.0.0.0:68)    │
  │──────────────────────────────>│
  │ OFFER (BC, yiaddr=IP)         │
  │<──────────────────────────────│
  │ REQUEST (BC, server ID)       │
  │──────────────────────────────>│
  │ ACK (BC, options + lease)     │
  │<──────────────────────────────│
```

### Config Cheat Sheet
```bash
# Global
option domain-name "example.com";
option domain-name-servers 8.8.8.8;
default-lease-time 86400; max-lease-time 172800;
authoritative;
log-facility local7;

# Subnet
subnet 192.168.1.0 netmask 255.255.255.0 {
    range 192.168.1.100 192.168.1.200;
    option routers 192.168.1.1;
}

# Reservation
host printer {
    hardware ethernet 00:11:22:33:44:55;
    fixed-address 192.168.1.10;
}

# Failover
failover peer "dhcp-failover" { primary; address 10.0.0.1; port 647; ... }
pool { failover peer "dhcp-failover"; range 10.0.0.100 10.0.0.200; }

# PXE
option tftp-server-name "192.168.1.5";
option bootfile-name "pxelinux.0";
```

### Troubleshooting Flowchart
```
Client gets 169.254.x.x?
  ├─ Same subnet as DHCP server?
  │   ├─ Yes → Check dhcpd: systemctl status isc-dhcp-server
  │   └─ No  → Relay configured? → Check dhcrelay, ip helper-address
  ├─ Free IPs? → Check leases: cat /var/lib/dhcp/dhcpd.leases
  └─ DHCP errors? → sudo tail -f /var/log/syslog | grep dhcpd
```

### Port Reference
| Port | Protocol | Service |
|------|----------|---------|
| 67/udp | DHCP | DHCP Server |
| 68/udp | DHCP | DHCP Client |
| 69/udp | TFTP | PXE boot file transfer |
| 546/udp | DHCPv6 | DHCPv6 Client |
| 547/udp | DHCPv6 | DHCPv6 Server |
| 647/tcp | DHCP Failover | Failover peer |

---

*Previous → Part 42: DNS Server Administration (BIND)*
*Next → Part 44: Mail Servers — Postfix*

[← Previous](part42.md) | [Next →](part44.md)


---

[← Previous](21-section-17-self-test.md) | [↑ Index](index.md)
