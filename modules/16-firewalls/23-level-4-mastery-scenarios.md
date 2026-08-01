## 👑 Level 4: Mastery — Real-World Firewall Scenarios

### Scenario 1: Multi-Homed NAT Gateway

```bash
#!/bin/bash
# Three interfaces: WAN (DHCP), LAN (192.168.1.0/24), DMZ (10.0.0.0/24)
WAN=eth0
LAN=eth1
DMZ=eth2

sysctl -w net.ipv4.ip_forward=1

iptables -F && iptables -t nat -F && iptables -t mangle -F
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# Local traffic
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -i "$LAN" -j ACCEPT
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# LAN → WAN NAT
iptables -t nat -A POSTROUTING -o "$WAN" -j MASQUERADE
iptables -A FORWARD -i "$LAN" -o "$WAN" -j ACCEPT
iptables -A FORWARD -i "$WAN" -o "$LAN" -m state --state ESTABLISHED,RELATED -j ACCEPT

# DMZ → WAN NAT (servers need internet too)
iptables -t nat -A POSTROUTING -o "$WAN" -s 10.0.0.0/24 -j MASQUERADE
iptables -A FORWARD -i "$DMZ" -o "$WAN" -j ACCEPT
iptables -A FORWARD -i "$WAN" -o "$DMZ" -m state --state ESTABLISHED,RELATED -j ACCEPT

# LAN → DMZ (web traffic to web server)
iptables -A FORWARD -i "$LAN" -o "$DMZ" -p tcp --dport 80 -j ACCEPT
iptables -A FORWARD -i "$LAN" -o "$DMZ" -p tcp --dport 443 -j ACCEPT
iptables -A FORWARD -i "$DMZ" -o "$LAN" -m state --state ESTABLISHED,RELATED -j ACCEPT

# WAN → DMZ (port forwarding)
iptables -t nat -A PREROUTING -i "$WAN" -p tcp --dport 80 \
    -j DNAT --to-destination 10.0.0.10:80
iptables -A FORWARD -i "$WAN" -o "$DMZ" -p tcp -d 10.0.0.10 --dport 80 -j ACCEPT
```

### Scenario 2: DDoS Mitigation with Rate Limiting

```bash
# Connection limit per IP
iptables -A INPUT -p tcp --syn -m connlimit --connlimit-above 100 -j DROP

# Rate limit new connections
iptables -A INPUT -p tcp --dport 80 -m state --state NEW \
    -m limit --limit 100/second --limit-burst 200 -j ACCEPT
iptables -A INPUT -p tcp --dport 80 -m state --state NEW -j DROP

# Hashlimit — per-IP rate limiting
iptables -A INPUT -p tcp --dport 80 -m hashlimit \
    --hashlimit-name http \
    --hashlimit-mode srcip \
    --hashlimit-upto 50/minute \
    --hashlimit-burst 100 -j ACCEPT
iptables -A INPUT -p tcp --dport 80 -j DROP

# Block port scanners
iptables -A INPUT -m state --state NEW -p tcp --tcp-flags ALL SYN,ACK \
    -m recent --name portscan --set
iptables -A INPUT -m state --state NEW -p tcp --tcp-flags ALL SYN,ACK \
    -m recent --name portscan --rcheck --seconds 60 -j DROP
```

### Scenario 3: Container Host Firewall (nftables)

```bash
#!/usr/sbin/nft -f

table inet filter {
    chain input {
        type filter hook input priority 0
        
        iif lo accept
        ct state established,related accept
        
        # Docker bridge: allow container-to-host if needed
        iif docker0 accept
        
        # SSH
        tcp dport 22 accept
        
        # Docker API (restrict to internal only)
        tcp dport 2375 ip saddr 10.0.0.0/8 accept
        tcp dport 2375 drop
        
        log prefix "INPUT-DROP: " limit rate 5/minute drop
    }
    
    chain forward {
        type filter hook forward priority 0
        
        # Docker bridge forwarding
        iif docker0 oif docker0 accept
        iif docker0 ct state established,related accept
        oif docker0 accept
        
        # Reject other forwarding
        drop
    }
}
```

### Scenario 4: Dual-Stack Lockdown (IPv4 + IPv6)

```bash
#!/bin/bash
# Lock down both IPv4 and IPv6 identically

# Enable IPv6 firewall
ip6tables -P INPUT DROP
ip6tables -P FORWARD DROP
ip6tables -P OUTPUT ACCEPT

ip6tables -A INPUT -i lo -j ACCEPT
ip6tables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# SSH on IPv6
ip6tables -A INPUT -p tcp --dport 22 -j ACCEPT

# HTTP/HTTPS
ip6tables -A INPUT -p tcp --dport 80 -j ACCEPT
ip6tables -A INPUT -p tcp --dport 443 -j ACCEPT

# ICMPv6 is REQUIRED for IPv6 to work
ip6tables -A INPUT -p icmpv6 -j ACCEPT

# With nftables (single ruleset for both):
nft add table inet firewall
nft add chain inet firewall input '{ type filter hook input priority 0 ; }'
nft add rule inet firewall input iif lo accept
nft add rule inet firewall input ct state established,related accept
nft add rule inet firewall input tcp dport { 22, 80, 443 } accept
nft add rule inet firewall input icmp type echo-request accept
nft add rule inet firewall input meta nfproto ipv6 icmpv6 type { echo-request, nd-router-advert, nd-neighbor-solicit, nd-neighbor-advert } accept
nft add rule inet firewall input drop
```



[← Previous](21-section-12-firewalld-direct-rules.md) | [↑ Index](index.md) | [Next →](22-rules-of-thumb.md)
