## 📦 Section 1: What is DHCP?

### 1.1 The Problem DHCP Solves

Before DHCP, every machine needed **manual IP configuration**. With 500 machines, that is impossible. **DHCP** = Dynamic Host Configuration Protocol. It automates IP assignment, subnet mask, gateway, DNS, NTP, PXE boot options, and custom vendor options. DHCP is defined in **RFC 2131** (core) and **RFC 2132** (options). It is an extension of BOOTP (RFC 951).

### 1.2 The DORA Process

```
Client                          Server
  │                               │
  │  1. DHCPDISCOVER (broadcast)  │
  │  src:0.0.0.0:68 → 255.255.255.255:67
  │──────────────────────────────>│
  │  2. DHCPOFFER (broadcast)     │
  │<──────────────────────────────│
  │  3. DHCPREQUEST (broadcast)   │
  │──────────────────────────────>│
  │  4. DHCPACK                   │
  │<──────────────────────────────│
```

| Step | Message | Purpose |
|------|---------|---------|
| 1 | **DHCPDISCOVER** | Client asks "is there a DHCP server?" |
| 2 | **DHCPOFFER** | Server says "here is an IP you can use" |
| 3 | **DHCPREQUEST** | Client says "I accept that IP" |
| 4 | **DHCPACK** | Server confirms "it is yours" |

DHCPREQUEST is broadcast so other DHCP servers learn the client chose a different offer.

### 1.3 DHCP Options — TLV Format

```
+--------+--------+--------+--------+
|  Code  | Length |  Value ...       |
|  1byte |  1byte |  0-255 bytes    |
+--------+--------+--------+--------+
```

| Code | Option | Description |
|------|--------|-------------|
| 1 | `subnet-mask` | Subnet mask for the client |
| 3 | `routers` | Default gateway(s) |
| 6 | `domain-name-servers` | DNS server(s) |
| 12 | `host-name` | Client hostname |
| 15 | `domain-name` | DNS domain |
| 28 | `broadcast-address` | Broadcast address |
| 42 | `ntp-servers` | NTP time server(s) |
| 50 | `requested-ip-address` | Client asks for a specific IP |
| 51 | `ip-address-lease-time` | Lease duration (seconds) |
| 53 | `dhcp-message-type` | 1=DISCOVER, 2=OFFER, 3=REQUEST, 5=ACK, 6=NAK |
| 54 | `server-identifier` | DHCP server's IP |
| 55 | `parameter-request-list` | Options the client wants |
| 58 | `renewal-time-value` | T1 — time until renewal |
| 59 | `rebinding-time-value` | T2 — time until rebinding |
| 60 | `vendor-class-identifier` | Vendor info ("PXEClient") |
| 66 | `tftp-server-name` | TFTP server (PXE boot) |
| 67 | `bootfile-name` | Boot file path (PXE boot) |

### 1.4 IP Lease Lifecycle

```
BOUND ──T1 (50%)──> RENEWING ──T2 (87.5%)──> REBINDING ──expiry──> EXPIRED
(has IP)            (unicast to server)      (broadcast to any)     (no IP)
```

- **T1** (50%): Client unicasts DHCPREQUEST directly to the server that gave the lease.
- **T2** (87.5%): Client broadcasts DHCPREQUEST to any server (if original server is down).
- **Expiry**: Client releases the IP and starts over with DISCOVER.

### 1.5 Why DHCP Matters

| Use Case | Why DHCP is Critical |
|----------|---------------------|
| **Desktop networks** | Users cannot configure IPs manually |
| **BYOD / guest Wi-Fi** | Automatic addressing for unknown devices |
| **PXE boot** | DHCP tells client where to find OS installer |
| **IPAM** | Lease logs give audit trail of who had which IP |
| **VoIP phones** | DHCP provides TFTP server for phone configs |
| **Data center** | Servers boot via DHCP/PXE with zero-touch provisioning |





[← Previous](02-level-1-basic-dhcp-concepts.md) | [↑ Index](index.md) | [Next →](04-level-2-intermediary-dhcp-server.md)
