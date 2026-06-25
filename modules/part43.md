# 🐧 Linux System Administrator — Complete Course
## Part 43 of ∞: DHCP Server — ISC DHCP and Kea

---

> **Reverse Engineering Approach:** You will inherit DHCP servers configured by someone who left the company. You'll debug why a client got `169.254.x.x` (APIPA), why PXE booting fails with "No boot filename received", why a reservation isn't matching, why DHCP relay stopped working after a router upgrade, and why the failover peer is in "communications-interrupted" state. This part teaches you to **read configs, decode packet captures, and fix broken address assignment** — skills every sysadmin needs daily. You'll build a production-grade DHCP infrastructure from scratch with failover and PXE.

---

## 🎯 What You Will Achieve

| Level | Focus | Key Skills |
|-------|-------|------------|
| **Level 1: Basic** | DHCP concepts, DORA | Understanding IP assignment, DHCP packet flow, lease lifecycle |
| **Level 2: Intermediary** | ISC DHCP config, subnets, relay | Server setup, static reservations, options, multiple subnets, relay, logging, DHCPv6 |
| **Level 3: Advanced** | Failover, Kea, PXE | High availability, Kea configuration, PXE boot infrastructure |

---

## ⭐ Level 1: Basic — DHCP Concepts

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

---

## ⭐ Level 2: Intermediary — DHCP Server Configuration and Management

## ⚙️ Section 2: ISC DHCP Server Installation

### 2.1 What is ISC DHCP?

The reference implementation from the Internet Systems Consortium (same as BIND). Provides `dhcpd` (server), `dhcrelay` (relay), and `dhclient` (client).

### 2.2 Installation

```bash
sudo apt update
sudo apt install -y isc-dhcp-server
dhcpd --version
```

### 2.3 Configure Which Interface to Listen On

```bash
# /etc/default/isc-dhcp-server
INTERFACESv4="eth0"
INTERFACESv6=""
OPTIONS=""
```

### 2.4 Start and Enable

```bash
sudo systemctl enable --now isc-dhcp-server
sudo systemctl status isc-dhcp-server
sudo ss -tulpn | grep ':67'
```

### 2.5 RHEL/CentOS

```bash
sudo dnf install -y dhcp-server
echo 'DHCPDARGS="eth0"' | sudo tee /etc/sysconfig/dhcpd
sudo systemctl enable --now dhcpd
```

### 2.6 Troubleshooting

```bash
sudo dhcpd -t                    # Test syntax
sudo dhcpd -f -d                 # Foreground debug mode
sudo ss -tulpn | grep :67        # Check port 67
sudo aa-status | grep dhcp       # AppArmor
```

---

## 🔧 Section 3: ISC DHCP Configuration

### 3.1 The Main Config File

`/etc/dhcp/dhcpd.conf` uses a **declarative** syntax with curly braces.

```bash
sudo dhcpd -t    # Always test syntax after changes
```

### 3.2 Basic Configuration

```bash
option domain-name "example.com";
option domain-name-servers 8.8.8.8, 8.8.4.4;
option ntp-servers pool.ntp.org;
default-lease-time 86400;
max-lease-time 172800;
authoritative;
log-facility local7;

subnet 192.168.1.0 netmask 255.255.255.0 {
    range 192.168.1.100 192.168.1.200;
    option routers 192.168.1.1;
    option subnet-mask 255.255.255.0;
    option broadcast-address 192.168.1.255;
    option domain-name-servers 192.168.1.1, 8.8.8.8;
    option domain-name "example.com";
    default-lease-time 86400;
    max-lease-time 172800;
}
```

### 3.3 Directive Reference

| Directive | Purpose | Example |
|-----------|---------|---------|
| `subnet` | Declare a subnet pool | `subnet 10.0.0.0 netmask 255.255.255.0 { ... }` |
| `range` | IP range to assign | `range 10.0.0.100 10.0.0.200;` |
| `option routers` | Default gateway | `option routers 10.0.0.1;` |
| `option subnet-mask` | Subnet mask | `option subnet-mask 255.255.255.0;` |
| `option broadcast-address` | Broadcast address | `option broadcast-address 10.0.0.255;` |
| `option domain-name-servers` | DNS servers | `option domain-name-servers 8.8.8.8, 1.1.1.1;` |
| `option domain-name` | DNS search domain | `option domain-name "example.com";` |
| `option ntp-servers` | NTP servers | `option ntp-servers time.example.com;` |
| `default-lease-time` | Default lease length (s) | `default-lease-time 86400;` |
| `max-lease-time` | Maximum lease | `max-lease-time 172800;` |
| `authoritative` | This server is the authority | `authoritative;` |
| `log-facility` | Syslog facility | `log-facility local7;` |

### 3.4 The `authoritative` Directive

Without `authoritative`, the server is **timid** — it will not send NAK even if a client has an IP from the wrong subnet. With it, the server sends DHCPNAK to force clients to get a correct IP.

### 3.5 Multi-Subnet Example

```bash
option domain-name "example.com";
option domain-name-servers 8.8.8.8, 8.8.4.4;
default-lease-time 86400;
max-lease-time 172800;
authoritative;

subnet 10.0.0.0 netmask 255.255.255.0 {
    range 10.0.0.100 10.0.0.200;
    option routers 10.0.0.1;
}

subnet 192.168.10.0 netmask 255.255.255.0 {
    range 192.168.10.50 192.168.10.200;
    option routers 192.168.10.1;
}

subnet 172.16.0.0 netmask 255.255.255.0 {
    range 172.16.0.100 172.16.0.200;
    option routers 172.16.0.1;
}
```

---

## 📋 Section 4: Static Assignments (Reservations)

### 4.1 Why Reservations?

Servers, printers, network equipment need the **same IP every time** but should still get DHCP options via the `host` statement.

### 4.2 Basic Reservation

```bash
host printer-01 {
    hardware ethernet 00:11:22:33:44:55;
    fixed-address 192.168.1.10;
    option host-name "printer-01";
}
```

### 4.3 Reservations Inside a Subnet (Outside the Range)

```bash
subnet 192.168.1.0 netmask 255.255.255.0 {
    range 192.168.1.100 192.168.1.200;
    option routers 192.168.1.1;

    host mail-server {
        hardware ethernet aa:bb:cc:dd:ee:01;
        fixed-address 192.168.1.10;
        option host-name "mail";
    }
    host web-server {
        hardware ethernet aa:bb:cc:dd:ee:02;
        fixed-address 192.168.1.11;
        option host-name "www";
    }
    host printer-01 {
        hardware ethernet 00:11:22:33:44:55;
        fixed-address 192.168.1.20;
        option host-name "hp-laserjet-4200";
    }
}
```

### 4.4 Reservations with Custom Options

```bash
host dev-laptop {
    hardware ethernet 52:54:00:ab:cd:ef;
    fixed-address 192.168.1.50;
    option domain-name-servers 1.1.1.1, 9.9.9.9;
    default-lease-time 604800;    # 7 days
}
```

### 4.5 Finding a Client's MAC Address

```bash
# On the client
ip link show eth0 | grep ether

# On the DHCP server — check lease file
sudo cat /var/lib/dhcp/dhcpd.leases | grep -A 5 "192.168.1.100"

# Check DHCP logs for MAC
sudo grep "DHCPACK" /var/log/syslog | grep -i "192.168.1.100"
```

---

## 🎛️ Section 5: DHCP Options

### 5.1 Standard Options

```bash
option subnet-mask 255.255.255.0;
option broadcast-address 192.168.1.255;
option time-offset -18000;              # UTC offset (EST)
option ntp-servers ntp.example.com;
option smtp-server mail.example.com;
option tftp-server-name "tftp.example.com";   # Option 66
option bootfile-name "pxelinux.0";            # Option 67
```

### 5.2 WPAD (Web Proxy Auto-Discovery)

```bash
option wpad-url code 252 = text;
option wpad-url "http://wpad.example.com/wpad.dat";
```

### 5.3 PXE Boot Options

```bash
# BIOS
option tftp-server-name "192.168.1.5";
option bootfile-name "pxelinux.0";

# UEFI
option tftp-server-name "192.168.1.5";
option bootfile-name "bootx64.efi";
```

### 5.4 Vendor-Specific Options (Code 43)

```bash
option space cisco;
option cisco.tftp-server code 1 = ip-address;
option cisco.tftp-server 192.168.1.5;

class "Cisco-Phone" {
    match if substring (option vendor-class-identifier, 0, 5) = "Cisco";
    vendor-option-space cisco;
}
```

### 5.5 Custom Option Definitions

```bash
option custom-provisioning-url code 224 = text;
option custom-provisioning-url "http://provision.example.com/config.cfg";

option custom-log-server code 225 = ip-address;
option custom-log-server 192.168.1.50;
```

---

## 🌐 Section 6: Multiple Subnets

### 6.1 Shared-Network (Same Wire, Multiple Subnets)

```bash
shared-network "office" {
    subnet 192.168.1.0 netmask 255.255.255.0 {
        range 192.168.1.100 192.168.1.200;
        option routers 192.168.1.1;
    }
    subnet 10.0.0.0 netmask 255.255.255.0 {
        range 10.0.0.100 10.0.0.200;
        option routers 10.0.0.1;
    }
}
```

### 6.2 Multi-Homed DHCP Server

```bash
# /etc/default/isc-dhcp-server
INTERFACESv4="eth0 eth1 eth2"
```

```bash
subnet 192.168.1.0 netmask 255.255.255.0 {
    range 192.168.1.100 192.168.1.200;
    option routers 192.168.1.1;
}
subnet 10.0.0.0 netmask 255.255.255.0 {
    range 10.0.0.100 10.0.0.200;
    option routers 10.0.0.1;
}
subnet 172.16.0.0 netmask 255.255.255.0 {
    range 172.16.0.100 172.16.0.200;
    option routers 172.16.0.1;
}
```

### 6.3 Conditional Pool Assignment with Classes

```bash
class "Intel" {
    match if substring (hardware, 1, 3) = 00:1b:21;
}
class "Realtek" {
    match if substring (hardware, 1, 3) = 00:e0:4c;
}

subnet 192.168.1.0 netmask 255.255.255.0 {
    pool { allow members of "Intel";  range 192.168.1.100 192.168.1.120; }
    pool { allow members of "Realtek"; range 192.168.1.121 192.168.1.140; }
    pool { range 192.168.1.141 192.168.1.200; }
}
```

---

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

## 📝 Section 8: DHCP Logging

### 8.1 Default Logging

```bash
sudo tail -f /var/log/syslog | grep dhcpd
```

### 8.2 Separate Log File

```bash
# In dhcpd.conf:
log-facility local7;

# /etc/rsyslog.d/50-dhcp.conf
local7.* /var/log/dhcpd.log

sudo touch /var/log/dhcpd.log && sudo chown syslog:adm /var/log/dhcpd.log
sudo systemctl restart rsyslog
sudo systemctl restart isc-dhcp-server
```

### 8.3 Reading DHCP Logs

```bash
# Successful assignment
grep DHCPACK /var/log/dhcpd.log
# Jun 24 10:00:01 dhcpd DHCPACK on 192.168.1.100 to 52:54:00:ab:cd:ef via eth0

# Denied (NAK)
grep DHCPNAK /var/log/dhcpd.log

# No free leases — look for DHCPDISCOVER without matching ACK
grep DHCPDISCOVER /var/log/dhcpd.log | wc -l
```

### 8.4 Packet Capture

```bash
# Live capture
sudo tcpdump -i eth0 -n port 67 or port 68 -v

# Save to file
sudo tcpdump -i eth0 -n -s 0 port 67 or port 68 -w dhcp.pcap

# Sample output:
# 10:00:00.123456 IP 0.0.0.0.68 > 255.255.255.255.67:
#   BOOTP/DHCP, Request from 52:54:00:ab:cd:ef, xid 0x3a4b7c8d
#   DHCP-Message (53): Discover
#   Parameter-Request (55): 1,3,6,15,42,51,58,59
```

---

## ⭐ Level 3: Advanced — Failover, Kea, and PXE Booting

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

---

## 🆕 Section 10: Kea — The Modern ISC DHCP

### 10.1 Kea vs ISC DHCP

| Feature | ISC DHCP | Kea |
|---------|----------|-----|
| Config format | Flat file | **JSON** |
| Database | Flat file | **MySQL, PostgreSQL, memfile** |
| Performance | Single-threaded | **Multi-threaded** |
| API | None | **REST API** (kea-ctrl-agent) |
| Extensibility | None | **Hooks library** system |
| DHCPv6 | Basic | Full IA_NA, IA_PD support |
| High Availability | Failover protocol | DB-based + REST API |
| Metrics | None | Prometheus via hooks |

### 10.2 Architecture

```
kea-dhcp4 → kea-ctrl-agent (REST :8000) → kea-shell / curl
                  │
            MySQL / PostgreSQL
```

### 10.3 Installation

```bash
sudo apt install -y kea-dhcp4-server kea-ctrl-agent kea-admin
# RHEL: sudo dnf install -y kea-dhcp4 kea-ctrl-agent
```

### 10.4 JSON Configuration

```json
{
    "Dhcp4": {
        "interfaces-config": {
            "interfaces": [ "eth0" ]
        },
        "lease-database": {
            "type": "memfile",
            "lfc-interval": 3600
        },
        "valid-lifetime": 86400,
        "renew-timer": 43200,
        "rebind-timer": 75600,
        "subnet4": [
            {
                "subnet": "192.168.1.0/24",
                "id": 1,
                "pools": [
                    { "pool": "192.168.1.100 - 192.168.1.200" }
                ],
                "option-data": [
                    { "name": "routers", "data": "192.168.1.1" },
                    { "name": "domain-name-servers", "data": "8.8.8.8, 8.8.4.4" },
                    { "name": "domain-name", "data": "example.com" }
                ],
                "reservations": [
                    {
                        "hw-address": "aa:bb:cc:dd:ee:01",
                        "ip-address": "192.168.1.10",
                        "hostname": "mail-server"
                    }
                ]
            }
        ],
        "loggers": [
            {
                "name": "kea-dhcp4",
                "severity": "INFO",
                "output_options": [
                    { "output": "/var/log/kea/kea-dhcp4.log" }
                ]
            }
        ]
    }
}
```

### 10.5 Validate and Start

```bash
sudo kea-dhcp4 -t /etc/kea/kea-dhcp4.conf
sudo systemctl enable --now kea-dhcp4-server
sudo systemctl enable --now kea-ctrl-agent
sudo tail -f /var/log/kea/kea-dhcp4.log
```

### 10.6 MySQL Backend

```bash
sudo mysql -u root -p
mysql> CREATE DATABASE kea;
mysql> GRANT ALL ON kea.* TO 'kea'@'localhost' IDENTIFIED BY 'password';
mysql> FLUSH PRIVILEGES;
# Initialize schema
sudo kea-admin db-init mysql -u kea -p password -n kea
```

### 10.7 REST API

```bash
# List all leases
curl -X POST -H "Content-Type: application/json" \
  -d '{ "command": "lease4-get-all", "service": [ "dhcp4" ] }' \
  http://localhost:8000/

# Add reservation
curl -X POST -H "Content-Type: application/json" \
  -d '{
    "command": "reservation-add",
    "service": [ "dhcp4" ],
    "parameters": {
        "reservation": {
            "hw-address": "52:54:00:aa:bb:cc",
            "ip-address": "192.168.1.99",
            "hostname": "api-test"
        }
    }
}' http://localhost:8000/

# Get statistics
curl -X POST -H "Content-Type: application/json" \
  -d '{ "command": "statistic-get-all", "service": [ "dhcp4" ] }' \
  http://localhost:8000/
```

### 10.8 Kea Hooks

```bash
sudo apt install -y kea-hook-lease-cmds kea-hook-statistics kea-hook-flex-id kea-hook-forensic-log

# Enable in config:
"hooks-libraries": [
    { "library": "/usr/lib/x86_64-linux-gnu/kea/hooks/libdhcp_lease_cmds.so" },
    { "library": "/usr/lib/x86_64-linux-gnu/kea/hooks/libdhcp_statistics.so" }
]
```

---

## 🌍 Section 11: DHCPv6

### 11.1 IPv6 Address Assignment Methods

| Method | DHCPv6 Role |
|--------|-------------|
| **SLAAC** | Client generates own address from RA + EUI-64 |
| **Stateless DHCPv6** | Client uses SLAAC for address, DHCPv6 for DNS/NTP (O flag) |
| **Stateful DHCPv6** | DHCPv6 provides addresses + options (M flag) |

### 11.2 Stateless DHCPv6

Router Advertises with **O flag** (Other Configuration). Client gets address via SLAAC, DNS via DHCPv6.

### 11.3 Stateful DHCPv6 (ISC DHCP)

```bash
# /etc/dhcp/dhcpd6.conf
option dhcp6.name-servers 2001:4860:4860::8888, 2001:4860:4860::8844;
option dhcp6.domain-search "example.com";
default-lease-time 86400;
max-lease-time 172800;

subnet6 2001:db8:1::/64 {
    range6 2001:db8:1::100 2001:db8:1::200;
    option dhcp6.name-servers 2001:db8:1::1, 2001:4860:4860::8888;
}
```

```bash
sudo dhcpd -6 -cf /etc/dhcp/dhcpd6.conf -lf /var/lib/dhcp/dhcpd6.leases eth0
```

### 11.4 IA_NA and IA_PD

| IA Type | Purpose |
|---------|---------|
| **IA_NA** | Assigns a regular IPv6 address to a client |
| **IA_TA** | Assigns temporary (privacy) addresses |
| **IA_PD** | Prefix Delegation — assigns an entire prefix to a router |

### 11.5 Prefix Delegation Example

```bash
subnet6 2001:db8:0::/48 {
    range6 2001:db8:0:1::/64 2001:db8:0:1::1000;    # Client addresses
    prefix6 2001:db8:0:: 2001:db8:ff:: /56;           # Delegated prefixes
}
```

### 11.6 Kea DHCPv6 Config

```json
{
    "Dhcp6": {
        "interfaces-config": { "interfaces": [ "eth0" ] },
        "valid-lifetime": 86400,
        "subnet6": [
            {
                "subnet": "2001:db8:1::/64",
                "id": 1,
                "pools": [
                    { "pool": "2001:db8:1::100 - 2001:db8:1::200" }
                ],
                "pd-pools": [
                    {
                        "prefix": "2001:db8::",
                        "prefix-len": 48,
                        "delegated-len": 56
                    }
                ],
                "option-data": [
                    { "name": "dns-servers", "data": "2001:4860:4860::8888" }
                ]
            }
        ]
    }
}
```

---

## 💻 Section 12: PXE Booting

### 12.1 What is PXE?

**PXE** (Preboot eXecution Environment) allows network-booting a computer with no OS. The client:
1. Gets an IP via DHCP
2. Finds a TFTP/HTTP server (option 66)
3. Downloads a bootloader (option 67)
4. Boots the OS installer

### 12.2 PXE DHCP Options

```bash
option tftp-server-name "192.168.1.5";    # Option 66
option bootfile-name "pxelinux.0";         # Option 67
```

### 12.3 BIOS vs UEFI

```bash
# BIOS/Legacy
option bootfile-name "pxelinux.0";

# UEFI x64
option bootfile-name "bootx64.efi";

# UEFI IA32
option bootfile-name "bootia32.efi";

# UEFI HTTP Boot
option bootfile-name "http://install.example.com/bootx64.efi";
```

### 12.4 Architecture Type Codes

| Code | Architecture |
|------|-------------|
| 0 | BIOS x86 |
| 6 | EFI IA32 |
| 7 | EFI x64 |
| 9 | EFI x64 with HTTP |

### 12.5 Multi-Architecture PXE with Classes

```bash
class "pxeclients" {
    match if substring (option vendor-class-identifier, 0, 9) = "PXEClient";
}

subnet 192.168.1.0 netmask 255.255.255.0 {
    option routers 192.168.1.1;
    range 192.168.1.100 192.168.1.200;

    # BIOS
    group {
        match if option arch-type = 0;
        option tftp-server-name "192.168.1.5";
        option bootfile-name "pxelinux.0";
    }
    # UEFI x64
    group {
        match if option arch-type = 7;
        option tftp-server-name "192.168.1.5";
        option bootfile-name "bootx64.efi";
    }
    # UEFI HTTP
    group {
        match if option arch-type = 9;
        option bootfile-name "http://192.168.1.5/bootx64.efi";
    }
}
```

### 12.6 iPXE Chain-Loading

```bash
class "ipxe" {
    match if substring (option vendor-class-identifier, 0, 10) = "iPXE";
}

group {
    match if not (exists members of "ipxe");
    option bootfile-name "undionly.kpxe";     # Bootstrap iPXE
}
group {
    match if exists members of "ipxe";
    option bootfile-name "http://server/boot.ipxe";  # Full script
}
```

### 12.7 PXE Infrastructure

```
DHCP (67/udp) → 66/67 options → TFTP (69/udp) or HTTP (80/tcp)
    │                                │
    │  Offers IP, TFTP server        │  Sends pxelinux.0, kernel, initrd
    │<───────────────────────────────>│
```

```bash
sudo apt install -y tftpd-hpa nginx
sudo mkdir -p /srv/tftp
sudo cp /usr/lib/PXELINUX/pxelinux.0 /srv/tftp/
sudo systemctl enable --now tftpd-hpa
```

---

## 🛠️ Section 13: 15 Hands-On Practices

### ⭐ Level 1: Basic Practices

#### Practice 1: Install ISC DHCP Server

```bash
sudo apt update && sudo apt install -y isc-dhcp-server
dhcpd --version
systemctl status isc-dhcp-server
sudo ss -tulpn | grep :67
```

### ⭐ Level 2: Intermediary Practices

#### Practice 2: Configure a Basic Subnet

```bash
# /etc/dhcp/dhcpd.conf
option domain-name "homelab.local";
option domain-name-servers 8.8.8.8, 1.1.1.1;
default-lease-time 86400;
max-lease-time 172800;
authoritative;

subnet 192.168.1.0 netmask 255.255.255.0 {
    range 192.168.1.100 192.168.1.200;
    option routers 192.168.1.1;
}
```

```bash
sudo dhcpd -t && sudo systemctl restart isc-dhcp-server
sudo tail -f /var/log/syslog | grep dhcpd
```

#### Practice 3: Add a Static Reservation

Add to `dhcpd.conf`:
```bash
host my-server {
    hardware ethernet 52:54:00:ab:cd:ef;
    fixed-address 192.168.1.50;
    option host-name "my-server";
}
```

```bash
sudo dhcpd -t && sudo systemctl restart isc-dhcp-server
sudo grep my-server /var/log/syslog
```

#### Practice 4: Set Custom DNS and NTP Options

```bash
option domain-name "example.com";
option domain-name-servers 8.8.8.8, 8.8.4.4;
option ntp-servers time.google.com, pool.ntp.org;

subnet 192.168.1.0 netmask 255.255.255.0 {
    range 192.168.1.100 192.168.1.200;
    option routers 192.168.1.1;
    option domain-name-servers 192.168.1.1, 8.8.8.8;
}
```

Verify client received options:
```bash
nmcli dev show eth0 | grep DNS
sudo tcpdump -i eth0 -n port 67 or port 68 -X | grep -A 2 "Domain-Name-Server"
```

#### Practice 5: Enable DHCP Logging to Separate File

```bash
# In dhcpd.conf:
log-facility local7;

# /etc/rsyslog.d/50-dhcp.conf
echo 'local7.* /var/log/dhcpd.log' | sudo tee /etc/rsyslog.d/50-dhcp.conf
sudo touch /var/log/dhcpd.log && sudo chown syslog:adm /var/log/dhcpd.log
sudo systemctl restart rsyslog && sudo systemctl restart isc-dhcp-server
sudo tail -f /var/log/dhcpd.log
```

#### Practice 6: Set Up DHCP Relay (On VMs)

**Topology:** VM1 (DHCP: 192.168.1.10), VM2 (Relay: eth0=192.168.1.11, eth1=192.168.2.1), VM3 (Client: subnet B)

On relay:
```bash
sudo apt install -y isc-dhcp-relay
# /etc/default/isc-dhcp-relay
# SERVERS="192.168.1.10"
# INTERFACES="eth0 eth1"
sudo systemctl enable --now isc-dhcp-relay
sudo sysctl -w net.ipv4.ip_forward=1
```

On DHCP server, add subnet for relayed network:
```bash
subnet 192.168.2.0 netmask 255.255.255.0 {
    range 192.168.2.100 192.168.2.200;
    option routers 192.168.2.1;
}
```

#### Practice 7: Configure DHCPv6 (Stateless)

```bash
# /etc/dhcp/dhcpd6.conf
option dhcp6.name-servers 2001:4860:4860::8888;
option dhcp6.domain-search "example.com";
subnet6 2001:db8:1::/64 {
    range6 2001:db8:1::100 2001:db8:1::200;
}

sudo dhcpd -6 -cf /etc/dhcp/dhcpd6.conf -lf /var/lib/dhcp/dhcpd6.leases eth0
ip -6 addr show   # On client
```

#### Practice 8: Debug DHCP with tcpdump

```bash
# Terminal 1: capture
sudo tcpdump -i eth0 -n port 67 or port 68 -v -e

# Terminal 2: force renew
sudo dhclient -r eth0 && sudo dhclient -v eth0
```

Analyze each packet:
```
1. DHCPDISCOVER — src MAC, 0.0.0.0, broadcast
2. DHCPOFFER   — yiaddr (offered IP), server ID, lease time
3. DHCPREQUEST — requested IP, server ID
4. DHCPACK     — confirmed, all options
```

### ⭐ Level 3: Advanced Practices

#### Practice 9: Configure DHCP Failover

Set up two servers using the config from Section 9. Test:
```bash
# Stop primary — verify secondary takes over
sudo systemctl stop isc-dhcp-server
sudo tail -f /var/log/syslog | grep dhcpd
# "I move from normal to partner-down"

# Restart primary — verify resync
sudo systemctl start isc-dhcp-server
# "recovering from partner-down"
```

#### Practice 10: Install Kea with JSON Config

```bash
sudo apt install -y kea-dhcp4-server kea-ctrl-agent
sudo vim /etc/kea/kea-dhcp4.conf   # Use JSON from Section 10.4
sudo kea-dhcp4 -t /etc/kea/kea-dhcp4.conf
sudo systemctl enable --now kea-dhcp4-server
sudo tail -f /var/log/kea/kea-dhcp4.log
```

#### Practice 11: Use Kea REST API

```bash
sudo systemctl enable --now kea-ctrl-agent

# List leases
curl -X POST -H "Content-Type: application/json" \
  -d '{ "command": "lease4-get-all", "service": [ "dhcp4" ] }' \
  http://localhost:8000/

# Add reservation
curl -X POST -H "Content-Type: application/json" \
  -d '{
    "command": "reservation-add", "service": [ "dhcp4" ],
    "parameters": {
        "reservation": {
            "hw-address": "52:54:00:aa:bb:cc",
            "ip-address": "192.168.1.99",
            "hostname": "api-test"
        }
    }
}' http://localhost:8000/

# Get stats
curl -X POST -H "Content-Type: application/json" \
  -d '{ "command": "statistic-get-all", "service": [ "dhcp4" ] }' \
  http://localhost:8000/
```

#### Practice 12: Stateful DHCPv6 with Kea

Use the Kea DHCPv6 JSON from Section 11.6:
```bash
sudo systemctl enable --now kea-dhcp6-server
sudo tail -f /var/log/kea/kea-dhcp6.log
```

#### Practice 13: Configure PXE Boot Options

```bash
subnet 192.168.1.0 netmask 255.255.255.0 {
    range 192.168.1.100 192.168.1.200;
    option tftp-server-name "192.168.1.5";
    option bootfile-name "pxelinux.0";
}
```

```bash
sudo apt install -y tftpd-hpa
sudo mkdir -p /srv/tftp && echo "test" | sudo tee /srv/tftp/pxelinux.0
sudo systemctl enable --now tftpd-hpa
tftp 192.168.1.5 -c get pxelinux.0
```

#### Practice 14: Multi-Arch PXE (BIOS + UEFI)

Implement the class-based config from Section 12.5. Test with VMs of different firmware types.

#### Practice 15: Real-World Integration — Production DHCP Server with Failover + PXE

Build a complete production-grade DHCP infrastructure:

```bash
# ┌─────────────────────────────────────────────────────────────┐
# │  REAL-WORLD INTEGRATION CHECKLIST                          │
# │                                                             │
# │  [✓] ISC DHCP installed on primary and secondary            │
# │  [✓] Subnets configured for all VLANs                      │
# │  [✓] Static reservations for servers, printers, IP cameras │
# │  [✓] Failover peer configured (primary + secondary)         │
# │  [✓] DHCP relay configured on router for remote subnets    │
# │  [✓] PXE boot options for BIOS and UEFI                    │
# │  [✓] Logging to separate file + centralized syslog         │
# │  [✓] Kea installed and tested as next-gen replacement      │
# │  [✓] DHCPv6 stateful configured for IPv6 clients           │
# │  [✓] Backup — /etc/dhcp/ and /var/lib/dhcp/ backed up     │
# │  [✓] Monitoring — DHCP pool utilization tracked            │
# │  [✓] Firewall — only 67/udp, 647/tcp open                  │
# └─────────────────────────────────────────────────────────────┘
```

**Reference architecture:**

```
                     Router (ip helper-address 192.168.1.10)
                              │
           ┌──────────────────┼──────────────────┐
           │                  │                  │
    DHCP Primary        DHCP Secondary       TFTP/HTTP
    192.168.1.10        192.168.1.11        192.168.1.5
    (failover) ◄──────► (failover)           (PXE files)
           │                  │                  │
           └──────────────────┼──────────────────┘
                              │
                 ┌────────────┼────────────┐
                 │            │            │
           VLAN 10        VLAN 20       VLAN 30
       192.168.10.0/24  10.0.0.0/24  172.16.0.0/24
        (Users)          (Servers)    (PXE Boot)
```

**Backup script:**
```bash
#!/bin/bash
# /usr/local/bin/dhcp-backup.sh
BACKUP_DIR="/backup/dhcp"
DATE=$(date +%Y%m%d_%H%M)
mkdir -p $BACKUP_DIR
tar czf "$BACKUP_DIR/dhcp-config-$DATE.tar.gz" /etc/dhcp/ /etc/default/isc-dhcp-server
cp /var/lib/dhcp/dhcpd.leases "$BACKUP_DIR/dhcpd.leases-$DATE"
find $BACKUP_DIR -name "*.gz" -mtime +30 -delete
logger "DHCP backup completed: $DATE"
```

**Pool monitoring:**
```bash
#!/bin/bash
# /usr/local/bin/dhcp-pool-usage.sh
for pool in "192.168.1.100 192.168.1.200"; do
    read start end <<< "$pool"
    used=$(grep -c "binding state active" /var/lib/dhcp/dhcpd.leases 2>/dev/null || echo 0)
    echo "Pool $start-$end: $used active leases"
done
```

---

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

## 📖 Section 16: What's Coming in Part 44

**Part 44: Mail Servers — Postfix** — Email is one of the oldest and most complex internet services. You will learn SMTP fundamentals, Postfix installation and `main.cf` configuration, SMTP authentication (Dovecot SASL), TLS encryption (STARTTLS), Dovecot IMAP/POP3 delivery, virtual mailboxes (multi-domain), SPF/DKIM/DMARC anti-spam, mail queues (`mailq`, `postqueue`, `postcat`), rate limiting, and integration with LDAP/MySQL.

```
Previous → Part 42: DNS Server Administration (BIND)
Next → Part 44: Mail Servers — Postfix
```

---

## ✅ Section 17: Self-Test

**Instructions:** Answer each question. **Score:** 12/15 correct = ready for Part 44.

### Questions

**Q1:** What does DORA stand for, and what happens in each step?

**Q2:** A client boots up and gets IP `169.254.23.45` instead of a valid DHCP address. What is this address called and what does it indicate?

**Q3:** Write the `dhcpd.conf` configuration for a subnet `10.0.0.0/24` with range `10.0.0.100` to `10.0.0.200`, gateway `10.0.0.1`, DNS `8.8.8.8` and `1.1.1.1`, lease time 12 hours.

**Q4:** What is the purpose of the `giaddr` field in a DHCP packet, and which network device sets it?

**Q5:** You added a static reservation for a printer with MAC `00:11:22:33:44:55` and fixed-address `192.168.1.10`, but the printer got `192.168.1.150` instead. What are three possible causes?

**Q6:** What is the difference between T1 (renewal) and T2 (rebinding) in the DHCP lease lifecycle?

**Q7:** Write the configuration for a DHCP failover peer declaration. What is the purpose of `mclt` and `split`?

**Q8:** What are DHCP options 66 and 67 used for? What is the difference between BIOS and UEFI PXE boot regarding these options?

**Q9:** You run `sudo dhcpd -t` and get "subnet 10.0.0.0 netmask 255.255.255.0: no address range." What is the problem and how do you fix it?

**Q10:** What is the difference between ISC DHCP and Kea? List at least three differences.

**Q11:** In DHCPv6, what is the difference between stateful and stateless DHCPv6? What is IA_PD used for?

**Q12:** A DHCP relay is configured but clients on the remote subnet are not getting IPs. Write three debugging commands you would run.

**Q13:** What does the `authoritative;` directive do? What happens if you omit it?

**Q14:** What is the magic cookie in DHCP? What is its hex value?

**Q15:** You have two DHCP servers configured for failover. The primary crashes. What state does the secondary enter? How does it recover when the primary comes back?

### Answer Key

**A1:**
- **D**iscover: Client broadcasts "is there a DHCP server?"
- **O**ffer: Server responds "you can use IP X"
- **R**equest: Client says "I accept IP X"
- **A**cknowledge: Server confirms "IP X is yours, here are options"

**A2:** `169.254.x.x` is an **APIPA** (Automatic Private IP Addressing) address. It indicates the client sent a DHCPDISCOVER but **received no response** (no DHCP server reachable). The client self-assigns a link-local address.

**A3:**
```bash
subnet 10.0.0.0 netmask 255.255.255.0 {
    range 10.0.0.100 10.0.0.200;
    option routers 10.0.0.1;
    option domain-name-servers 8.8.8.8, 1.1.1.1;
    default-lease-time 43200;
    max-lease-time 86400;
}
```

**A4:** The **giaddr** (Gateway IP Address) tells the DHCP server which subnet the client is on. It is set by the **DHCP relay agent** (router or Linux dhcrelay). The relay sets giaddr to its own IP on the client's subnet.

**A5:** (1) The MAC address in the reservation is wrong. (2) The `fixed-address` is inside the dynamic range — move it outside. (3) There is a typo in `hardware ethernet` or the host block is not inside the correct subnet. (4) Config was not reloaded.

**A6:** **T1** (Renewal, 50% of lease): Client unicasts DHCPREQUEST to the original server. **T2** (Rebinding, 87.5%): If T1 failed, client broadcasts DHCPREQUEST to any server.

**A7:**
```bash
failover peer "dhcp-failover" {
    primary; address 192.168.1.10; port 647;
    peer address 192.168.1.11; peer port 647;
    max-response-delay 30; mclt 3600; split 128;
}
```
- **mclt**: Maximum Client Lead Time — prevents split-brain
- **split**: Load balancing ratio (128 = 50/50)

**A8:** Option **66** (tftp-server-name) specifies the TFTP server. Option **67** (bootfile-name) specifies the boot file. **BIOS** uses `pxelinux.0`; **UEFI** uses `bootx64.efi` (x64) or `bootia32.efi` (IA32).

**A9:** The subnet has no `range` statement. Every dynamic subnet needs at least one `range` directive. Fix: add `range 10.0.0.100 10.0.0.200;`.

**A10:**
1. **Config format**: ISC uses flat file; Kea uses **JSON**
2. **Database**: ISC uses flat files; Kea supports **MySQL/PostgreSQL**
3. **Performance**: Kea is **multi-threaded**; ISC is single-threaded
4. **API**: Kea has **REST API**; ISC has none
5. **Extensibility**: Kea has **hooks** library system

**A11:** **Stateful DHCPv6** assigns addresses + options. **Stateless DHCPv6** (SLAAC + info): clients self-assign addresses via RA, DHCPv6 provides DNS/NTP only. **IA_PD** (Prefix Delegation) assigns an entire IPv6 prefix to a downstream router.

**A12:**
1. `sudo tcpdump -i eth0 port 67 or port 68 -n` — verify packets reach relay
2. `sudo systemctl status isc-dhcp-relay` — check relay is running
3. `sudo dhcrelay -d 192.168.1.10` — run relay in debug mode
4. `sysctl net.ipv4.ip_forward` — check IP forwarding is enabled

**A13:** `authoritative;` tells the server to send **DHCPNAK** to clients with IPs from the wrong subnet (forcing them to get a correct one). Without it, the server is **timid** and ignores such requests.

**A14:** The magic cookie is a 4-byte value (`0x63825363`) at the start of the options field, distinguishing DHCP from BOOTP.

**A15:** The secondary enters **partner-down** state, serving leases from the primary's pool. When the primary returns, the secondary enters **recover** state, sends its lease database via BNDUPD, both servers synchronize and return to **normal**.

### Scoring

| Score | Result |
|-------|--------|
| **15/15** | Perfect — you are ready for mail servers |
| **12–14/15** | Strong understanding — proceed to Part 44 |
| **9–11/15** | Review the sections you missed |
| **< 9/15** | Re-read Part 43 and practice with the 15 exercises |

**Score:** ___/15 correct = ready for Part 44.

---

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
