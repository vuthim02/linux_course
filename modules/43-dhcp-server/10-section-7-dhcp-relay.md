## 🔄 Section 7: DHCP Relay

### 7.1 The Problem

DHCP uses **broadcasts** (255.255.255.255). Routers do not forward broadcasts between subnets. A **DHCP relay agent** (on the router) intercepts the broadcast, adds `giaddr` (gateway IP), and unicasts to the DHCP server. The server uses `giaddr` to select the correct subnet pool.

### 7.2 How giaddr Works

```
Client (subnet B)           Router (relay)           DHCP Server (A)
     │                           │                           │
     │  DHCPDISCOVER (BC)        │                           │
     │──────────────────────────>│                           │
     │                     giaddr = router's IP on subnet B  │
     │                           │  Unicast                  │
     │                           │──────────────────────────>│
     │                           │  Server selects pool for  │
     │                           │  subnet B via giaddr      │
     │                           │<──────────────────────────│
     │  DHCPOFFER (BC on B)      │                           │
     │<──────────────────────────│                           │
```

### 7.3 dhcrelay (Linux)

```bash
sudo apt install -y isc-dhcp-relay
```

```bash
# /etc/default/isc-dhcp-relay
SERVERS="192.168.1.10"
INTERFACES="eth1 eth2"
```

```bash
sudo systemctl enable --now isc-dhcp-relay
```

### 7.4 IP Helper-Address (Cisco)

```cisco
interface GigabitEthernet0/1
 ip address 192.168.2.1 255.255.255.0
 ip helper-address 192.168.1.10
```

### 7.5 Multiple Relay Targets

```bash
SERVERS="192.168.1.10 192.168.1.11"
```

### 7.6 Debug Relay

```bash
sudo dhcrelay -d 192.168.1.10
```

---



---

[← Previous](09-section-6-multiple-subnets.md) | [↑ Index](index.md) | [Next →](11-section-8-dhcp-logging.md)
