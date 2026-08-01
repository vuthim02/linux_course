## 🔍 Section 10: nftables — Maps, Counters, and Logging

### nftables Maps (vmap)

Maps dispatch to different verdicts based on a key lookup — faster than linear rule chains:

```bash
# Define a verdict map
sudo nft add table inet filter
sudo nft add map inet filter port_policy '{ type inet_service : verdict ; }'

# Add elements
sudo nft add element inet filter port_policy '{ 22 : accept, 80 : accept, 443 : accept }'

# Use in a rule
sudo nft add rule inet filter input tcp dport vmap @port_policy

# Replace multiple port rules with one map lookup
# Equivalent to three separate accept rules, but O(1) instead of O(n)
```

### Named Counters

Track packet and byte counts per rule:

```bash
# Create named counters
sudo nft add counter inet filter http_traffic
sudo nft add counter inet filter ssh_traffic

# Use in rules
sudo nft add rule inet filter input tcp dport 80 counter name http_traffic accept
sudo nft add rule inet filter input tcp dport 22 counter name ssh_traffic accept

# Read counters
sudo nft list counter inet filter http_traffic
# packets 1523 bytes 892104

# Reset counters (for monitoring)
sudo nft reset counter inet filter http_traffic
```

### Quotas

Limit total traffic with byte quotas:

```bash
# Create a quota (limit to 100 MB)
sudo nft add quota inet filter transfer_limit '{ 100 mbytes }'

# Use in a rule — drop after quota is exceeded
sudo nft add rule inet filter output quota name transfer_limit drop

# Check quota status
sudo nft list quota inet filter transfer_limit
# quota transfer_limit { until 0 bytes remain, used 42 mbytes }

# Quota with timeout (auto-resets)
sudo nft add quota inet filter daily_limit '{ 500 mbytes until 1d }'
```

### nftables Logging

```bash
# Basic logging with prefix
sudo nft add rule inet filter input log prefix "nft-drop: " drop

# Rate-limited logging (prevents log flooding)
sudo nft add rule inet filter input \
    log prefix "nft-drop: " limit rate 3/minute drop

# Log with syslog level
sudo nft add rule inet filter input \
    log prefix "nft-alert: " level warn limit rate 10/minute drop

# Log to netlink audit group (for auditd integration)
sudo nft add rule inet filter input log group 0

# Complete logging chain pattern
sudo nft add chain inet filter log_drop
sudo nft add rule inet filter log_drop \
    log prefix "nft-drop: " limit rate 5/minute drop

# Jump to it from main chain
sudo nft add rule inet filter input tcp dport 23 jump log_drop
```

### nftables Sets with Timeouts

```bash
# Dynamic set with auto-expiry (for temporary bans)
sudo nft add set inet filter ban_list '{ type ipv4_addr ; flags timeout ; gc-interval 10s ; }'

# Add a temporary ban (expires in 5 minutes)
sudo nft add element inet filter ban_list '{ 10.0.0.50 timeout 5m }'

# Check remaining time
sudo nft list set inet filter ban_list

# Set with both interval and timeout
sudo nft add set inet filter dynamic_blocks '{ type ipv4_addr ; flags interval,timeout ; auto-merge ; }'
```



[← Previous](18-section-9-iptables-nat-deep-dive.md) | [↑ Index](index.md) | [Next →](20-section-11-ipset-and-connection-tracking.md)
