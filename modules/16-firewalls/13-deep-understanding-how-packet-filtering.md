## 🧠 Deep Understanding — How Packet Filtering Really Works

### The Packet Journey Through Netfilter

```
Packet arrives on eth0
    ↓
1. PREROUTING (raw) — Does packet bypass connection tracking?
    ↓
2. PREROUTING (mangle) — Modify packet (TOS, TTL)?
    ↓
3. PREROUTING (nat) — DNAT (destination address translation)?
    ↓
4. Routing Decision — Is the packet for this host?
    ↓
   YES (for local)                      NO (forward)
    ↓                                      ↓
5. INPUT (mangle)                    5. FORWARD (mangle)
    ↓                                      ↓
6. INPUT (filter) — Allow or Deny?   6. FORWARD (filter) — Allow or Deny?
    ↓                                      ↓
   → Local Process                     7. POSTROUTING (mangle)
                                           ↓
                                        8. POSTROUTING (nat) — SNAT/Masquerade?
                                           ↓
                                         → Out on eth1
```

### Connection Tracking

iptables can track the state of network connections:

```bash
# States:
# NEW       — First packet of a new connection
# ESTABLISHED — Part of an existing connection (has seen both directions)
# RELATED  — Related to an existing connection (e.g., FTP data channel)
# INVALID  — Packet doesn't match any connection (usually drop these)

# Check connection tracking table
sudo cat /proc/net/nf_conntrack | head -10

# Connection tracking allows:
# - Allow incoming responses without opening high ports
# - Detect and drop invalid packets
# - Track complex protocols (FTP, SIP)
```

### Performance Considerations

```bash
# Each rule is checked in order until a match is found
# First match wins (in filter table)
# If no match, default policy applies

# Performance tips:
# 1. Put most-frequently-matched rules FIRST
# 2. Use ipsets for large IP lists (O(1) lookup vs O(n))
# 3. Put default DROP/REJECT rules LAST (after ALL allow rules)
# 4. Use connection tracking to reduce rule checks for established traffic
```





[← Previous](12-practice-section-15-hands-on-exercises.md) | [↑ Index](index.md) | [Next →](14-summary-complete-command-reference-for.md)
