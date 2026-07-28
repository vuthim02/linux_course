## 🔁 Section 9: ISC DHCP Failover

### 9.1 Why Failover?

A single DHCP server is a single point of failure. Failover allows two servers (primary/secondary) to share the lease database over TCP port 647.

### 9.2 How Failover Works

```
Primary (192.168.1.10)              Secondary (192.168.1.11)
     │                                   │
     │  TCP 647 — BNDUPD / BNDACK        │
     │──────────────────────────────────>│
     │  Heartbeat every 10 seconds        │
     │──────────────────────────────────>│
     │                                   │
     │  Pool split:                      │
     │  Primary: 192.168.1.100-150       │
     │  Secondary: 192.168.1.151-200     │
```

### 9.3 Primary Configuration

```bash
failover peer "dhcp-failover" {
    primary;
    address 192.168.1.10;
    port 647;
    peer address 192.168.1.11;
    peer port 647;
    max-response-delay 30;
    max-unacked-updates 10;
    mclt 3600;
    split 128;
    load balance max seconds 3;
}

subnet 192.168.1.0 netmask 255.255.255.0 {
    option routers 192.168.1.1;
    pool {
        failover peer "dhcp-failover";
        range 192.168.1.100 192.168.1.200;
    }
}
```

### 9.4 Secondary Configuration

```bash
failover peer "dhcp-failover" {
    secondary;
    address 192.168.1.11;
    port 647;
    peer address 192.168.1.10;
    peer port 647;
    max-response-delay 30;
    max-unacked-updates 10;
    mclt 3600;
}

subnet 192.168.1.0 netmask 255.255.255.0 {
    option routers 192.168.1.1;
    pool {
        failover peer "dhcp-failover";
        range 192.168.1.100 192.168.1.200;
    }
}
```

### 9.5 Key Parameters

| Parameter | Description |
|-----------|-------------|
| `mclt` | Max Client Lead Time — prevents split-brain |
| `split` | Load balance ratio: 0-255, 128 = 50/50 |
| `max-response-delay` | Seconds before declaring peer down |
| `max-unacked-updates` | Max pending BNDUPD before blocking |

### 9.6 Failover States

| State | Meaning |
|-------|---------|
| `normal` | Both servers operational |
| `partner-down` | Peer unreachable, taking over its pool |
| `recover` | Resynchronizing after peer returns |
| `shut-down` | Intentional shutdown |
| `unknown` | Initial state before connection |

```bash
sudo tail -f /var/log/syslog | grep dhcpd
# "peer dhcp-failover: I move from normal to partner-down"
# "peer dhcp-failover: recovering from partner-down"
```

### 9.7 Testing Failover

```bash
# Stop primary
sudo systemctl stop isc-dhcp-server
# Secondary enters partner-down, serves both pools

# Restart primary
sudo systemctl start isc-dhcp-server
# Servers resync back to normal
```





[← Previous](12-level-3-advanced-failover-kea.md) | [↑ Index](index.md) | [Next →](14-section-10-kea-the-modern.md)
