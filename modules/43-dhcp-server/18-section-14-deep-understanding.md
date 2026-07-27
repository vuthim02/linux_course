## 🧠 Section 14: Deep Understanding

### 14.1 DHCP Packet Format

```
 0                   1                   2                   3
 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|  op  | htype | hlen  | hops  |           xid                  |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|          secs          |              flags                    |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                          ciaddr (4)                            |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                          yiaddr (4)                            |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                          siaddr (4)                            |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                          giaddr (4)                            |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                          chaddr (16)                           |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                          sname (64)                            |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                          file (128)                            |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                   options (variable, 312+ bytes)              |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
```

| Field | Bytes | Description |
|-------|-------|-------------|
| `op` | 1 | 1=BOOTREQUEST (client), 2=BOOTREPLY (server) |
| `htype` | 1 | Hardware type: 1 = Ethernet |
| `hlen` | 1 | Hardware addr length: 6 for MAC |
| `hops` | 1 | Set by client to 0, incremented by relays (max 16) |
| `xid` | 4 | Transaction ID matching request to reply |
| `secs` | 2 | Seconds since client started booting |
| `flags` | 2 | Bit 0 = Broadcast flag (1=must broadcast reply) |
| `ciaddr` | 4 | Client IP (filled in RENEWING, else 0) |
| `yiaddr` | 4 | Your IP — set by server in OFFER/ACK |
| `siaddr` | 4 | Next server IP (TFTP server) |
| `giaddr` | 4 | Gateway IP — set by relay agent |
| `chaddr` | 16 | Client MAC address |
| `sname` | 64 | Server hostname (optional) |
| `file` | 128 | Boot file name (PXE boot path) |
| `options` | 312+ | DHCP options (magic cookie + TLV) |

### 14.2 The Magic Cookie

The options field starts with `0x63825363` — the **magic cookie** distinguishing DHCP from BOOTP.

### 14.3 How DHCP Relay Adds giaddr

```
Client (192.168.2.50)    Router (192.168.2.1)     DHCP Server (192.168.1.10)
     │                          │                        │
     │  DHCPDISCOVER (BC)       │                        │
     │─────────────────────────>│                        │
     │                    Router sets:                   │
     │                    giaddr = 192.168.2.1           │
     │                          │  Unicast w/ giaddr     │
     │                          │───────────────────────>│
     │                          │  Server sees giaddr →  │
     │                          │  picks 192.168.2.0/24  │
     │                          │<───────────────────────│
```

Without giaddr, the server cannot know which subnet the client is on.

### 14.4 How Failover Protocol Works

The failover protocol uses TCP 647 with these message types:

| Message | Description |
|---------|-------------|
| BNDUPD | Binding update — notify peer of lease assignment |
| BNDACK | Peer confirms receipt |
| UPDREQ | Request all bindings from peer |
| UPDDONE | All bindings sent |
| CONREQ | Start failover session |

**Failover FSM states:**
```
START → UNKNOWN → NORMAL (both operational)
                           ↓
                   PARTNER-DOWN (peer lost)
                           ↓
                      RECOVER (resync)
                           ↓
                      NORMAL
```

### 14.5 Lease States (Finite State Machine)

```
FREE → OFFERED → COMMITTED → EXPIRED → FREE
                    ↓
               RELEASED → FREE
                    ↓
              ABANDONED (client DECLINE)
```

| State | Meaning |
|-------|---------|
| **FREE** | IP is available |
| **OFFERED** | Server offered IP, waiting for REQUEST |
| **COMMITTED** | Actively leased to a client |
| **EXPIRED** | Lease ended, waiting before reuse |
| **RELEASED** | Client sent DHCPRELEASE |
| **ABANDONED** | Client sent DHCPDECLINE (IP conflict) |
| **RESERVED** | Static reservation (never dynamic) |

**Lease timer progression:**
```
COMMITTED ─T1 (50%)──> RENEWING ─T2 (87.5%)──> REBINDING ─expiry──> EXPIRED
          (unicast)              (broadcast)
```

### 14.6 Lease File Format

```bash
# /var/lib/dhcp/dhcpd.leases
lease 192.168.1.100 {
    starts 2 2026/06/23 10:00:00;
    ends 3 2026/06/24 10:00:00;
    binding state active;
    next binding state free;
    hardware ethernet 52:54:00:ab:cd:ef;
    client-hostname "client-laptop";
}
```

### 14.7 DHCP Security Considerations

| Attack | Mitigation |
|--------|-----------|
| **DHCP starvation** (fake MACs exhaust pool) | DHCP snooping on switch, rate-limit |
| **Rogue DHCP server** (MITM via fake DHCP) | DHCP snooping (trusted ports), 802.1X |
| **DHCP spoofing** | Use `authoritative;`, monitor for unexpected OFFERs |

**Cisco DHCP Snooping:**
```cisco
ip dhcp snooping
ip dhcp snooping vlan 10,20,30
interface GigabitEthernet0/1
    ip dhcp snooping trust
interface GigabitEthernet0/2
    ip dhcp snooping limit rate 10
```

**nftables rate limit:**
```bash
sudo nft add rule inet filter input udp sport 67 limit rate 10/second accept
```

---



---

[← Previous](17-section-13-15-hands-on-practices.md) | [↑ Index](index.md) | [Next →](19-section-15-command-reference.md)
