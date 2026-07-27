## 🔍 Section 5: nftables — The Modern Replacement

nftables is the successor to iptables. It is simpler, faster, and more consistent.

### Key Differences from iptables

| Aspect | iptables | nftables |
|--------|----------|----------|
| Syntax | Multiple tools (iptables, ip6tables, ebtables) | Single tool (nft) |
| Tables | Fixed (filter, nat, mangle, raw) | User-defined |
| Chains | Built-in chains only | User-defined chains |
| Atomic update | No (rule-by-rule) | Yes (entire ruleset) |
| Performance | O(n) rule traversal | O(1) with sets/maps |
| Kernel backend | Legacy | nf_tables |

### nftables Syntax

```bash
# List ruleset
sudo nft list ruleset

# Create a table
sudo nft add table inet filter

# Create a chain
sudo nft add chain inet filter input { type filter hook input priority 0 \; }

# Add a rule
sudo nft add rule inet filter input tcp dport 22 accept

# Delete a rule
sudo nft delete rule inet filter input handle 3

# Flush all rules
sudo nft flush ruleset
```

### Complete nftables Example

```bash
#!/usr/sbin/nft -f

# Clear existing rules
flush ruleset

# Create table (inet = both IPv4 and IPv6)
table inet filter {
    # Input chain
    chain input {
        type filter hook input priority 0
        
        # Allow loopback
        iif lo accept
        
        # Allow established connections
        ct state established,related accept
        
        # Allow SSH
        tcp dport 22 accept
        
        # Allow HTTP/HTTPS
        tcp dport {80, 443} accept
        
        # Allow ping
        icmp type echo-request accept
        
        # Log and drop everything else
        log prefix "nftables-denied: " limit rate 5/minute
        drop
    }
    
    # Forward chain
    chain forward {
        type filter hook forward priority 0
        drop
    }
    
    # Output chain
    chain output {
        type filter hook output priority 0
        accept
    }
}
```

### nftables Sets

Sets allow efficient matching against multiple values:

```bash
# Define an IP set
sudo nft add set inet filter allowed_ips { type ipv4_addr \; }

# Add elements
sudo nft add element inet filter allowed_ips { 192.168.1.100, 10.0.0.50 }

# Use the set in a rule
sudo nft add rule inet filter input ip saddr @allowed_ips accept

# Named sets with intervals
sudo nft add set inet filter blocked_nets { type ipv4_addr \; flags interval \; }
sudo nft add element inet filter blocked_nets { 10.0.0.0/8, 172.16.0.0/12 }
```

### Saving and Restoring nftables

```bash
# Save rules
sudo nft list ruleset > /etc/nftables.conf

# Restore rules
sudo nft -f /etc/nftables.conf

# Enable nftables service
sudo systemctl enable --now nftables

# Or load config at boot via /etc/nftables.conf
```

---



---

[← Previous](07-section-4-firewalld.md) | [↑ Index](index.md) | [Next →](09-level-3-advanced-filtering-patterns.md)
