## 🔍 Section 11: ipset and Connection Tracking

### ipset — Fast IP/Domain Sets

```bash
# Create sets
sudo ipset create whitelist hash:ip       # Single IPs
sudo ipset create blocklist hash:net      # CIDR networks
sudo ipset create portlist bitmap:port    # Port ranges (for port matching)
sudo ipset allow combined list:set        # Set of sets

# Add entries
sudo ipset add whitelist 192.168.1.100
sudo ipset add whitelist 10.0.0.50
sudo ipset add blocklist 10.0.0.0/8
sudo ipset add blocklist 172.16.0.0/12

# Use with iptables
iptables -A INPUT -m set --match-set whitelist src -j ACCEPT
iptables -A INPUT -m set --match-set blocklist src -j DROP

# With ports
sudo ipset add portlist 80
sudo ipset add portlist 443
iptables -A INPUT -m set --match-set portlist dst -j ACCEPT

# Save and restore
sudo ipset save > /etc/ipset.conf
sudo ipset restore < /etc/ipset.conf

# Count entries
sudo ipset list whitelist

# Destroy set
sudo ipset destroy whitelist
```

### ipset with nftables

```bash
# nftables has native set support (no ipset command needed)
# But legacy ipset sets can be referenced:
nft add rule inet filter input ip saddr @whitelist accept
nft add rule inet filter input ip saddr @blocklist drop
# Where @whitelist is defined in the same nftables table
```

### Connection Tracking with conntrack

```bash
# View connection table
sudo conntrack -L
sudo conntrack -L -p tcp                     # TCP only
sudo conntrack -L -p udp                     # UDP only
sudo conntrack -L --state ESTABLISHED        # Only established

# Count connections
sudo conntrack -C

# Monitor new connections (like tcpdump for conntrack)
sudo conntrack -E
sudo conntrack -E -p tcp --dport 80          # Monitor HTTP

# Delete connections
sudo conntrack -D -p tcp --dport 22          # Kill SSH tracking

# Connection tracking sysctl tuning
sysctl net.netfilter.nf_conntrack_max        # Max connections (default: 262144)
sysctl net.netfilter.nf_conntrack_tcp_timeout_established  # Timeout in seconds (default: 432000 = 5 days)
sysctl net.netfilter.nf_conntrack_tcp_timeout_time_wait   # (default: 120)
sysctl net.netfilter.nf_conntrack_buckets    # Hash table size
```

### Bypassing Connection Tracking

```bash
# For high-traffic interfaces, disable tracking to save CPU
iptables -t raw -A PREROUTING -i eth0 -p tcp --dport 80 -j NOTRACK
iptables -t raw -A PREROUTING -i eth0 -p tcp --dport 443 -j NOTRACK

# You MUST then allow the traffic explicitly (no ESTABLISHED shortcut)
iptables -A INPUT -i eth0 -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -i eth0 -p tcp --dport 443 -j ACCEPT

# In nftables:
nft add table inet raw
nft add chain inet raw prerouting '{ type filter hook prerouting priority -300 ; }'
nft add rule inet raw prerouting tcp dport { 80, 443 } notrack

# Check current conntrack stats
cat /proc/sys/net/netfilter/nf_conntrack_count
# Compare with nf_conntrack_max — if close to 100%, increase max
```

### Connection Tracking and NAT

```bash
# NAT requires conntrack — each translation is tracked
conntrack -L | grep -E "snat|dnat"

# NAT helpers for complex protocols
sudo modprobe nf_conntrack_ftp      # FTP passive mode
sudo modprobe nf_conntrack_pptp     # VPN (PPTP)
sudo modprobe nf_conntrack_h323     # H.323 VoIP
sudo modprobe nf_conntrack_sip      # SIP VoIP
```



[← Previous](19-section-10-nftables-maps-counters-logging.md) | [↑ Index](index.md) | [Next →](21-section-12-firewalld-direct-rules.md)
