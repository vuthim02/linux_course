## 🔍 Section 2: iptables Basics

### Key Concepts

- **Table**: A collection of chains (filter, nat, mangle, raw)
- **Chain**: A list of rules evaluated in order
- **Rule**: A match condition + target action
- **Target**: What happens when a rule matches (ACCEPT, DROP, REJECT, LOG, etc.)
- **Policy**: Default action for a chain (if no rule matches)

### Essential iptables Commands

```bash
# List all rules (filter table)
sudo iptables -L

# List rules with line numbers
sudo iptables -L --line-numbers

# List rules with more detail
sudo iptables -L -v -n

# List rules for a specific table
sudo iptables -t nat -L -n

# Flush (delete) all rules
sudo iptables -F

# Delete a specific rule (by line number)
sudo iptables -D INPUT 3

# Set default policy
sudo iptables -P INPUT DROP
sudo iptables -P FORWARD DROP
sudo iptables -P OUTPUT ACCEPT
```

### Basic Rule Structure

```bash
iptables -A CHAIN -m MATCH -j TARGET

# -A  Append to chain
# -m  Match module (or use built-in matching)
# -j  Jump to target
```

### Common Match Conditions

```bash
# By source IP
iptables -A INPUT -s 192.168.1.100 -j DROP
iptables -A INPUT -s 10.0.0.0/8 -j ACCEPT

# By destination IP
iptables -A INPUT -d 192.168.1.1 -j ACCEPT

# By protocol
iptables -A INPUT -p tcp -j ACCEPT
iptables -A INPUT -p udp -j ACCEPT

# By port (must specify protocol)
iptables -A INPUT -p tcp --dport 22 -j ACCEPT
iptables -A INPUT -p udp --sport 53 -j ACCEPT

# By interface
iptables -A INPUT -i eth0 -j ACCEPT
iptables -A OUTPUT -o eth0 -j ACCEPT

# Multiple conditions (AND)
iptables -A INPUT -s 10.0.0.0/8 -p tcp --dport 80 -j ACCEPT

# Connection state
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -m state --state NEW -p tcp --dport 22 -j ACCEPT
```

### Common Targets

| Target | Action |
|--------|--------|
| ACCEPT | Allow the packet |
| DROP | Silently discard (no response) |
| REJECT | Discard and send error back |
| LOG | Log the packet, then continue |
| RETURN | Return to calling chain |
| SNAT | Source NAT (translation) |
| DNAT | Destination NAT |
| MASQUERADE | Dynamic source NAT (for DHCP) |
| REDIRECT | Redirect to local port |

### A Complete Firewall Example

```bash
#!/bin/bash
# A basic secure firewall

# Flush all existing rules
iptables -F
iptables -t nat -F
iptables -t mangle -F

# Set default policies
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# Allow loopback traffic
iptables -A INPUT -i lo -j ACCEPT

# Allow established connections
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Allow SSH
iptables -A INPUT -p tcp --dport 22 -j ACCEPT

# Allow HTTP and HTTPS
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -j ACCEPT

# Allow DNS (UDP)
iptables -A INPUT -p udp --dport 53 -j ACCEPT

# Allow ping (ICMP echo-request)
iptables -A INPUT -p icmp --icmp-type echo-request -j ACCEPT

# Log dropped packets (rate limited)
iptables -A INPUT -m limit --limit 5/min -j LOG --log-prefix "iptables-dropped: "

# Drop everything else
iptables -A INPUT -j DROP
```





[← Previous](03-section-1-how-linux-firewalling.md) | [↑ Index](index.md) | [Next →](05-level-2-intermediary-managing-firewall.md)
