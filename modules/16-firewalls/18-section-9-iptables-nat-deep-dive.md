## 🔍 Section 9: iptables NAT Deep Dive

### The Four NAT Types

| Type | Table | Chain | Purpose |
|------|-------|-------|---------|
| **SNAT** | nat | POSTROUTING | Change source IP (outgoing) |
| **DNAT** | nat | PREROUTING | Change destination IP (incoming) |
| **MASQUERADE** | nat | POSTROUTING | Dynamic SNAT (DHCP interface) |
| **REDIRECT** | nat | PREROUTING | Redirect to local port |

### SNAT — Static Source NAT

```bash
# Replace source IP 192.168.1.0/24 with 203.0.113.1 (static public IP)
iptables -t nat -A POSTROUTING -s 192.168.1.0/24 -o eth0 -j SNAT --to-source 203.0.113.1

# Must also allow forwarding
iptables -A FORWARD -i eth1 -o eth0 -s 192.168.1.0/24 -j ACCEPT
iptables -A FORWARD -i eth0 -o eth1 -m state --state ESTABLISHED,RELATED -j ACCEPT
```

### MASQUERADE — Dynamic SNAT

```bash
# Same as SNAT but auto-detects the outgoing interface IP
# Use when the public IP is assigned via DHCP/PPPoE
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
```

### DNAT — Destination NAT (Port Forwarding)

```bash
# Forward public port 8080 to internal server 192.168.1.50:80
iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 8080 \
    -j DNAT --to-destination 192.168.1.50:80

# FORWARD rules are REQUIRED — DNAT doesn't bypass the filter table
iptables -A FORWARD -i eth0 -o eth1 -p tcp -d 192.168.1.50 --dport 80 -j ACCEPT
iptables -A FORWARD -i eth1 -o eth0 -m state --state ESTABLISHED,RELATED -j ACCEPT
```

### REDIRECT — Transparent Proxy

```bash
# Redirect all HTTP traffic to local proxy (port 3128)
iptables -t nat -A PREROUTING -i eth1 -p tcp --dport 80 \
    -j REDIRECT --to-port 3128

# Useful for transparent squid/squid proxies
```

### Complete NAT Gateway

```bash
#!/bin/bash
# Full NAT gateway with two interfaces
WAN=eth0
LAN=eth1

# Enable IP forwarding
sysctl -w net.ipv4.ip_forward=1

# Flush existing rules
iptables -F
iptables -t nat -F
iptables -t mangle -F

# Default policies
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# Allow local traffic
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -i "$LAN" -j ACCEPT

# Allow established
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT

# NAT: masquerade LAN traffic to WAN
iptables -t nat -A POSTROUTING -o "$WAN" -j MASQUERADE

# Forward LAN to WAN
iptables -A FORWARD -i "$LAN" -o "$WAN" -j ACCEPT

# Port forward: WAN:8080 → LAN server:80
iptables -t nat -A PREROUTING -i "$WAN" -p tcp --dport 8080 \
    -j DNAT --to-destination 192.168.1.100:80
iptables -A FORWARD -i "$WAN" -o "$LAN" -p tcp -d 192.168.1.100 --dport 80 -j ACCEPT

# SSH access from WAN
iptables -A INPUT -i "$WAN" -p tcp --dport 22 -j ACCEPT
```

### NAT and Connection Tracking

```bash
# NAT is connection-tracked — only the first packet goes through NAT rules
# Subsequent packets in the same flow are handled by conntrack

# View NAT translations
conntrack -L -p tcp | grep dnat
conntrack -L -p tcp | grep snat

# NAT helpers for complex protocols
# FTP (load nf_conntrack_ftp)
modprobe nf_conntrack_ftp
iptables -A INPUT -p tcp --dport 21 -j ACCEPT
iptables -A FORWARD -p tcp --dport 21 -j ACCEPT
```



[← Previous](17-section-8-ufw.md) | [↑ Index](index.md) | [Next →](19-section-10-nftables-maps-counters-logging.md)
