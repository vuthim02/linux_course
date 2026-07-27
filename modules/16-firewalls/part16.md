# 🐧 Linux System Administrator — Complete Course
## Part 16 of ∞: Firewalls — iptables, firewalld, nftables

---

> **Reverse Engineering Approach:** A server without a firewall is like a house with the front door wide open and no locks anywhere. Every port you open is a potential entry point. Understanding how Linux filters packets — at the kernel level — is essential to securing any system. iptables, firewalld, and nftables are just different tools that manipulate the same kernel machinery.

---

## 🎯 What You Will Achieve in Part 16

This module is organized into three progressive levels:

| Level | You Will Learn |
|-------|---------------|
| **⭐ Basic** | How netfilter and Linux firewalling work, iptables concepts (tables, chains, rules, targets), basic filter commands |
| **⭐ Intermediary** | Saving and restoring rules, firewalld zone-based management, nftables syntax and usage |
| **⭐ Advanced** | Common iptables/nftables patterns (NAT, rate limiting, geo-blocking), troubleshooting, performance internals |

---

## ⭐ Level 1: Basic — Understanding Linux Firewalling and iptables

![Netfilter Packet Flow Diagram](https://upload.wikimedia.org/wikipedia/commons/thumb/3/37/Netfilter-packet-flow.svg/800px-Netfilter-packet-flow.svg.png)
*Netfilter packet flow diagram by Jan Engelhardt, CC BY-SA 3.0, via Wikimedia Commons*

> **Level 1 Goal:** Understand how the Linux kernel filters packets, and learn the fundamental iptables concepts of tables, chains, rules, and targets.

---

## 🔍 Section 1: How Linux Firewalling Works

### Netfilter — The Kernel Framework

All Linux firewalls (iptables, firewalld, nftables) are frontends to the same kernel subsystem: **netfilter**.

```
┌─────────────────────────────────────────────────────┐
│                    USER SPACE                        │
│                                                      │
│  iptables         firewalld         nft              │
│   (legacy)         (frontend)        (modern)        │
│       │               │                │            │
└───────┼───────────────┼────────────────┼────────────┘
        │               │                │
        ▼               ▼                ▼
┌─────────────────────────────────────────────────────┐
│                   KERNEL SPACE                       │
│                                                      │
│                   netfilter                          │
│                                                      │
│  ┌────────┐  ┌────────┐  ┌────────┐  ┌────────┐   │
│  │ PREROUT│  │ INPUT  │  │FORWARD │  │OUTPUT  │   │
│  │  ING   │  │        │  │        │  │        │   │
│  └────────┘  └────────┘  └────────┘  └────────┘   │
│  ┌────────┐                          ┌────────┐     │
│  │ POSTROU│                          │        │     │
│  │  TING  │                          │        │     │
│  └────────┘                          └────────┘     │
└─────────────────────────────────────────────────────┘
```

### The Five Netfilter Hooks

A packet traverses different hooks depending on its direction:

```
INCOMING PACKET (destined for this machine):

Packet arrives → PREROUTING → INPUT → Local Process
                    │
                    ▼ Check routing: is it for me?
                    │
                    ▼ No? → FORWARD (if forwarding enabled)

OUTGOING PACKET (from this machine):

Local Process → OUTPUT → POSTROUTING → Network
```

### The Three iptables Tables

| Table | Built-in Chains | Purpose |
|-------|----------------|---------|
| **filter** | INPUT, FORWARD, OUTPUT | Packet filtering (ALLOW/DENY) |
| **nat** | PREROUTING, OUTPUT, POSTROUTING | NAT (address translation) |
| **mangle** | PREROUTING, INPUT, FORWARD, OUTPUT, POSTROUTING | Packet modification (TOS, TTL) |
| **raw** | PREROUTING, OUTPUT | Connection tracking exceptions |
| **security** | INPUT, FORWARD, OUTPUT | SELinux security contexts |

### Packet Flow Through Tables and Chains

```
PREROUTING (raw → mangle → nat)
    │
    ▼
Routing Decision
    │
    ├── FOR LOCAL HOST: INPUT (mangle → filter) → Local Process
    │                                                    │
    └── FORWARDED: FORWARD (mangle → filter)             │
                                                         ▼
                                                  OUTPUT (raw → mangle → nat → filter)
                                                         │
                                                         ▼
                                                  POSTROUTING (mangle → nat)
```

---

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

---

## ⭐ Level 2: Intermediary — Managing Firewall Rules and Services

![Netfilter Project Logo](https://upload.wikimedia.org/wikipedia/commons/thumb/5/5d/Netfilter_logo.svg/800px-Netfilter_logo.svg.png)
*Netfilter project logo, via Wikimedia Commons*

> **Level 2 Goal:** Save and restore iptables rules, configure zone-based firewalling with firewalld, and use the modern nftables syntax for daily firewall administration.

---

## 🔍 Section 3: Saving and Restoring iptables Rules

iptables rules are **volatile** — they disappear on reboot unless saved.

```bash
# Save rules (Debian/Ubuntu)
sudo apt install iptables-persistent
sudo netfilter-persistent save
# Rules saved to /etc/iptables/rules.v4
# and /etc/iptables/rules.v6

# Save rules (Fedora/RHEL)
sudo dnf install iptables-services
sudo service iptables save
# Rules saved to /etc/sysconfig/iptables

# Manual save and restore
sudo iptables-save > /etc/iptables-backup.rules
sudo iptables-restore < /etc/iptables-backup.rules
```

---

## 🔍 Section 4: firewalld

firewalld is a firewall management tool with **zones** and **services**. It uses nftables or iptables as its backend.

### Zones

A zone defines the trust level for a network connection.

| Zone | Trust Level | Use Case |
|------|-------------|----------|
| drop | Lowest | All incoming connections dropped (no reply) |
| block | Low | All incoming rejected (icmp-host-prohibited) |
| public | Low | Public networks (coffee shop, internet) |
| external | Low | External network with masquerading |
| dmz | Medium | DMZ (public-facing servers) |
| work | Medium | Work networks |
| home | Medium | Home networks |
| internal | Medium | Internal networks |
| trusted | Highest | All connections accepted |

### Basic firewalld Commands

```bash
# Check status
sudo firewall-cmd --state

# List zones
sudo firewall-cmd --get-zones

# Show default zone
sudo firewall-cmd --get-default-zone

# Show all info about default zone
sudo firewall-cmd --list-all

# Show info about a specific zone
sudo firewall-cmd --zone=public --list-all

# List all zones in detail
sudo firewall-cmd --list-all-zones
```

### Managing Services

```bash
# List predefined services
sudo firewall-cmd --get-services

# List services enabled in a zone
sudo firewall-cmd --zone=public --list-services

# Add a service (immediate, temporary)
sudo firewall-cmd --zone=public --add-service=http

# Add a service (permanent, survives reboot)
sudo firewall-cmd --permanent --zone=public --add-service=http
sudo firewall-cmd --reload

# Remove a service
sudo firewall-cmd --permanent --zone=public --remove-service=http
sudo firewall-cmd --reload
```

### Managing Ports

```bash
# Open a port
sudo firewall-cmd --zone=public --add-port=8080/tcp

# Permanent
sudo firewall-cmd --permanent --zone=public --add-port=8080/tcp
sudo firewall-cmd --reload

# Open a port range
sudo firewall-cmd --permanent --zone=public --add-port=3000-4000/tcp

# Close a port
sudo firewall-cmd --permanent --zone=public --remove-port=8080/tcp
sudo firewall-cmd --reload

# List open ports
sudo firewall-cmd --zone=public --list-ports
```

### Rich Rules (Advanced)

```bash
# Allow specific IP to a port
sudo firewall-cmd --permanent --zone=public \
  --add-rich-rule='rule family="ipv4" source address="192.168.1.100" port protocol="tcp" port="22" accept'

# Rate limiting
sudo firewall-cmd --permanent --zone=public \
  --add-rich-rule='rule service name="ssh" limit value="10/m" accept'

# Log and drop
sudo firewall-cmd --permanent --zone=public \
  --add-rich-rule='rule family="ipv4" source address="10.0.0.0/8" log prefix="blocked " level="info" drop'

# Reload after adding rich rules
sudo firewall-cmd --reload
```

### Masquerading (NAT with firewalld)

```bash
# Enable masquerading on external zone
sudo firewall-cmd --permanent --zone=external --add-masquerade

# Port forwarding
sudo firewall-cmd --permanent --zone=external \
  --add-forward-port=port=80:proto=tcp:toport=8080:toaddr=192.168.1.50

sudo firewall-cmd --reload
```

### Changing Zones

```bash
# Change default zone
sudo firewall-cmd --set-default-zone=internal

# Change interface zone
sudo firewall-cmd --zone=internal --change-interface=eth0

# Permanent
sudo firewall-cmd --permanent --zone=internal --change-interface=eth0
```

### firewalld Runtime vs Permanent

```bash
# Without --permanent: change applies immediately, lost on reload/reboot
sudo firewall-cmd --zone=public --add-service=http

# With --permanent: change saved to config, requires --reload to take effect
sudo firewall-cmd --permanent --zone=public --add-service=http
sudo firewall-cmd --reload

# Check runtime vs permanent differences
sudo firewall-cmd --zone=public --list-all
sudo firewall-cmd --permanent --zone=public --list-all
```

---

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

## ⭐ Level 3: Advanced — Filtering Patterns, NAT, and Troubleshooting

![Packet Journey Through Netfilter](https://upload.wikimedia.org/wikipedia/commons/thumb/3/37/Netfilter-packet-flow.svg/800px-Netfilter-packet-flow.svg.png)
*Netfilter packet flow schematic, CC BY-SA 3.0, via Wikimedia Commons*

> **Level 3 Goal:** Build complex firewall rules including NAT, port forwarding, and rate limiting, troubleshoot firewall issues, and understand kernel-level packet filtering internals.

---

## 🔍 Section 6: Common iptables/nftables Patterns

### Pattern 1: Basic Web Server

```bash
# Allow: SSH, HTTP, HTTPS
# Deny: Everything else

iptables -P INPUT DROP
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -p tcp --dport 22 -j ACCEPT
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -j ACCEPT
```

### Pattern 2: NAT Gateway (Internet Sharing)

```bash
# Enable IP forwarding
echo 1 > /proc/sys/net/ipv4/ip_forward
# Or: sysctl net.ipv4.ip_forward=1
# Or permanently in /etc/sysctl.conf: net.ipv4.ip_forward=1

# Masquerade outgoing traffic
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

# Allow forwarding
iptables -A FORWARD -i eth1 -o eth0 -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A FORWARD -i eth0 -o eth1 -j ACCEPT
```

### Pattern 3: Port Forwarding

```bash
# Forward external port 8080 to internal server 192.168.1.50:80
iptables -t nat -A PREROUTING -p tcp --dport 8080 -j DNAT --to-destination 192.168.1.50:80
iptables -A FORWARD -p tcp -d 192.168.1.50 --dport 80 -j ACCEPT
```

### Pattern 4: Rate Limiting

```bash
# Limit SSH connections to 10 per minute
iptables -A INPUT -p tcp --dport 22 -m state --state NEW -m limit --limit 10/minute -j ACCEPT
iptables -A INPUT -p tcp --dport 22 -m state --state NEW -j DROP

# Limit ICMP (prevent ping flood)
iptables -A INPUT -p icmp --icmp-type echo-request -m limit --limit 1/second -j ACCEPT
iptables -A INPUT -p icmp --icmp-type echo-request -j DROP
```

### Pattern 5: Blocking Bad Actors

```bash
# Block specific IP
iptables -A INPUT -s 1.2.3.4 -j DROP

# Block an entire country (requires ipset)
ipset create china hash:net
wget -O /tmp/cn.zone http://www.ipdeny.com/ipblocks/data/countries/cn.zone
for ip in $(cat /tmp/cn.zone); do ipset add china $ip; done
iptables -A INPUT -m set --match-set china src -j DROP
```

---

## 🔍 Section 7: Troubleshooting Firewalls

### Check Current Rules

```bash
# iptables
sudo iptables -L -v -n --line-numbers
sudo iptables -t nat -L -v -n

# firewalld
sudo firewall-cmd --list-all
sudo firewall-cmd --zone=public --list-all

# nftables
sudo nft list ruleset
```

### Test Connectivity

```bash
# Test if a port is reachable
nc -zv server.example.com 22
nmap -p 22 server.example.com

# Test from the server itself
curl localhost:80
ss -tlnp | grep 80

# Check if the service is listening
sudo netstat -tulpn | grep LISTEN
```

### Check Firewall Logs

```bash
# iptables logs go to syslog/kernel
sudo grep "iptables" /var/log/kern.log

# Or journald
journalctl -k | grep -i "iptables\|nftables\|DROP\|REJECT"

# Check firewall logs in real-time
journalctl -k -f | grep -i "DROP\|REJECT"
```

### Common Issues

```bash
# Issue: "Connection refused" when service is running
# Cause: Firewall blocking the port
# Fix: Add allow rule for the port

# Issue: After iptables -F, SSH connection drops
# Cause: Default policy is DROP and no SSH allow rule was added
# Fix: NEVER flush rules remotely without a recovery plan
# Better: Use a script with a timeout
```

### Safe Remote Firewall Management

```bash
# Always have a recovery plan when managing firewalls remotely:

# Method 1: Script with timeout
#!/bin/bash
iptables -A INPUT -p tcp --dport 22 -j ACCEPT
iptables -P INPUT DROP
# If connection drops, wait for a cron job to restore

# Method 2: at job recovery
at now + 5 minutes <<< "iptables -P INPUT ACCEPT; iptables -F"
# Changes iptables; if you don't cancel the at job within 5 min,
# the firewall opens up (recovery)

# Method 3: Use a management tool like fwbuilder or ansible
# Or: Keep a second out-of-band connection (iDRAC, IPMI, serial console)
```

---

## 💻 PRACTICE SECTION — 15 Hands-On Exercises

### Level 1 Practices: Exploring and Basic Filtering

---

### ✅ Practice 1: Explore Current Firewall State

```bash
mkdir -p ~/linux-course/part16
cd ~/linux-course/part16

# Check if iptables is available
which iptables
iptables --version

# List current rules
sudo iptables -L -n -v

# List NAT rules
sudo iptables -t nat -L -n -v

# List all rules with line numbers
sudo iptables -L --line-numbers -n
```

---

### ✅ Practice 2: Check firewalld/ufw

```bash
cd ~/linux-course/part16

# Check which firewall service is active
if systemctl is-active firewalld &>/dev/null; then
    echo "firewalld is active"
    sudo firewall-cmd --state
    sudo firewall-cmd --list-all
elif systemctl is-active ufw &>/dev/null; then
    echo "ufw is active"
    sudo ufw status verbose
else
    echo "No firewall management service running"
    echo "(iptables rules may still be in effect)"
fi
```

---

### ✅ Practice 3: Create a Simple iptables Rule

```bash
cd ~/linux-course/part16

# Allow ICMP (ping) for testing
sudo iptables -A INPUT -p icmp --icmp-type echo-request -j ACCEPT

# Verify
sudo iptables -L INPUT -n -v

# Test ping localhost
ping -c 2 localhost

# Remove the rule
sudo iptables -D INPUT -p icmp --icmp-type echo-request -j ACCEPT

# Verify removal
sudo iptables -L INPUT -n -v
```

---

### ✅ Practice 4: Block an IP Address

```bash
cd ~/linux-course/part16

# Simulate blocking a bad IP
sudo iptables -A INPUT -s 192.168.1.200 -j DROP

# Verify
sudo iptables -L INPUT -n -v | grep "192.168.1.200"

# Remove the rule
sudo iptables -D INPUT -s 192.168.1.200 -j DROP

# Verify removal
sudo iptables -L INPUT -n -v | grep "192.168.1.200" || echo "Rule removed"
```

---

### Level 2 Practices: Configuration, firewalld, and nftables

### ✅ Practice 5: Allow/Block a Port

```bash
cd ~/linux-course/part16

# Before: Check if port 8080 is accessible
echo "Testing port 8080 (should be blocked by default):"
nc -zv localhost 8080 2>&1 || echo "Port is not accessible"

# Allow port 8080
sudo iptables -A INPUT -p tcp --dport 8080 -j ACCEPT
echo ""
echo "After adding allow rule:"
sudo iptables -L INPUT -n -v | grep 8080

# Remove it
sudo iptables -D INPUT -p tcp --dport 8080 -j ACCEPT
```

---

### ✅ Practice 6: Stateful Firewall Rules

```bash
cd ~/linux-course/part16

# Always allow established connections
sudo iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Verify
sudo iptables -L INPUT -n -v | grep "state"

# This is critical: without this, responses to your outgoing
# connections would be blocked
```

---

### ✅ Practice 7: Log Dropped Packets

```bash
cd ~/linux-course/part16

# Add logging for dropped packets (rate limited)
sudo iptables -A INPUT -m limit --limit 5/min -j LOG --log-prefix "IPTABLES-DROP: "

# Add final drop rule
sudo iptables -A INPUT -j DROP

# Verify
sudo iptables -L INPUT -n -v --line-numbers

# Check kernel log for dropped packets
echo ""
echo "Checking for iptables log entries:"
sudo dmesg | tail -5 | grep "IPTABLES" || echo "No drops logged yet"

# Clean up (carefully - remove by rule number)
# sudo iptables -D INPUT <linenumber>
```

---

### ✅ Practice 8: firewalld Zone Exploration

```bash
cd ~/linux-course/part16

# Only if firewalld is active
if systemctl is-active firewalld &>/dev/null; then
    echo "=== Available zones ==="
    sudo firewall-cmd --get-zones
    
    echo ""
    echo "=== Default zone ==="
    sudo firewall-cmd --get-default-zone
    
    echo ""
    echo "=== Default zone details ==="
    sudo firewall-cmd --list-all
    
    echo ""
    echo "=== All zones ==="
    sudo firewall-cmd --list-all-zones
else
    echo "firewalld not active — installing for demonstration"
    # Can't assume we can install, so just show the expected output
    cat << 'EOF'
Available zones: block dmz drop external home internal public trusted work

Default zone: public

public zone details:
  interfaces: eth0
  services: dhcpv6-client ssh
  ports: 
  masquerade: no
  forward-ports: 
  icmp-blocks: 
  rich rules: 
EOF
fi
```

---

### ✅ Practice 9: firewalld Service Management

```bash
cd ~/linux-course/part16

# Only if firewalld is active
if systemctl is-active firewalld &>/dev/null; then
    echo "=== Available services ==="
    sudo firewall-cmd --get-services | tr ' ' '\n' | head -20
    
    echo ""
    echo "=== Current services in public zone ==="
    sudo firewall-cmd --zone=public --list-services
    
    echo ""
    echo "=== Adding HTTP service temporarily ==="
    sudo firewall-cmd --zone=public --add-service=http
    sudo firewall-cmd --zone=public --list-services
    
    echo ""
    echo "=== Removing HTTP service ==="
    sudo firewall-cmd --zone=public --remove-service=http
    sudo firewall-cmd --zone=public --list-services
else
    echo "firewalld not active — showing expected commands"
    echo "sudo firewall-cmd --zone=public --add-service=http"
    echo "sudo firewall-cmd --permanent --zone=public --add-service=http"
    echo "sudo firewall-cmd --reload"
fi
```

---

### ✅ Practice 10: firewalld Port Management

```bash
cd ~/linux-course/part16

# Using firewall-cmd (simulated)
cat << 'EOF'
Opening a port with firewalld:
  sudo firewall-cmd --zone=public --add-port=3000/tcp         (runtime, temporary)
  sudo firewall-cmd --permanent --zone=public --add-port=3000/tcp  (permanent)
  sudo firewall-cmd --reload                                (apply permanent changes)

Closing a port:
  sudo firewall-cmd --permanent --zone=public --remove-port=3000/tcp
  sudo firewall-cmd --reload

Checking open ports:
  sudo firewall-cmd --zone=public --list-ports
EOF
```

---

### ✅ Practice 11: Save and Restore iptables Rules

```bash
cd ~/linux-course/part16

# Save current rules
sudo iptables-save > current_rules.txt
echo "Rules saved to current_rules.txt"
wc -l current_rules.txt

# Restore from saved file
sudo iptables-restore < current_rules.txt
echo "Rules restored from file"

# Or for persistent saving:
sudo mkdir -p /etc/iptables
sudo iptables-save > /etc/iptables/rules.v4 2>/dev/null || \
  echo "Would save to /etc/iptables/rules.v4"
```

---

### ✅ Practice 12: nftables Quick Tour

```bash
cd ~/linux-course/part16

# Check if nftables is available
if command -v nft &>/dev/null; then
    echo "nftables is available"
    nft --version
    
    echo ""
    echo "=== Current nftables ruleset ==="
    sudo nft list ruleset 2>/dev/null || echo "No nftables rules"
else
    echo "nftables not installed"
    echo "Install with: sudo apt install nftables"
fi

# Show the iptables-to-nft comparison
cat << 'EOF'
iptables                       nftables
──────────────────────────────────────────────────
iptables -A INPUT ...          nft add rule inet filter input ...
iptables -L                    nft list ruleset
iptables -F                    nft flush ruleset
iptables-save                  nft list ruleset > file
iptables-restore < file        nft -f file

# "inet" table works for both IPv4 and IPv6
# No separate ip6tables needed
EOF
```

---

### Level 3 Practices: Advanced Patterns and Auditing

### ✅ Practice 13: Test Firewall Rules with nc

```bash
cd ~/linux-course/part16

# Start a test listener
nc -l -p 9999 &
LISTENER_PID=$!
sleep 1

# Test connection (should work if no restrictive rules)
nc -zv localhost 9999 2>&1

# Block port 9999
sudo iptables -A INPUT -p tcp --dport 9999 -j DROP

# Test again (should fail)
echo ""
echo "After blocking port 9999:"
nc -zv localhost 9999 2>&1 || echo "Connection blocked (expected)"

# Clean up
sudo iptables -D INPUT -p tcp --dport 9999 -j DROP
kill $LISTENER_PID 2>/dev/null || true
```

---

### ✅ Practice 14: Masquerading (Simulated)

```bash
cd ~/linux-course/part16

# Show the commands for setting up NAT/masquerading
cat << 'EOF'
NAT Masquerading Commands:

1. Enable IP forwarding:
   sudo sysctl net.ipv4.ip_forward=1

2. Add MASQUERADE rule:
   sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

3. Allow forwarding:
   sudo iptables -A FORWARD -i eth1 -o eth0 -m state --state ESTABLISHED,RELATED -j ACCEPT
   sudo iptables -A FORWARD -i eth0 -o eth1 -j ACCEPT

4. Make IP forwarding permanent:
   echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf

In firewalld:
   sudo firewall-cmd --permanent --zone=external --add-masquerade
   sudo firewall-cmd --reload
EOF
```

---

### ✅ Practice 15: Real SysAdmin Scenario — Firewall Report

```bash
cd ~/linux-course/part16

cat > firewall_audit.sh << 'EOF'
#!/bin/bash
set -euo pipefail

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
HOSTNAME=$(hostname)
REPORT="firewall_audit_report.txt"

echo "============================================" > "$REPORT"
echo "  FIREWALL AUDIT REPORT" >> "$REPORT"
echo "  Hostname: $HOSTNAME" >> "$REPORT"
echo "  Date:     $TIMESTAMP" >> "$REPORT"
echo "============================================" >> "$REPORT"
echo "" >> "$REPORT"

# Section 1: Active firewall
echo "1. ACTIVE FIREWALL" >> "$REPORT"
if systemctl is-active firewalld &>/dev/null; then
    echo "  firewalld is active" >> "$REPORT"
    echo "  Default zone: $(sudo firewall-cmd --get-default-zone 2>/dev/null)" >> "$REPORT"
elif systemctl is-active ufw &>/dev/null; then
    echo "  ufw is active" >> "$REPORT"
    sudo ufw status verbose >> "$REPORT" 2>/dev/null
else
    echo "  No firewall service running (iptables may apply)" >> "$REPORT"
fi
echo "" >> "$REPORT"

# Section 2: iptables rules
echo "2. IPTABLES FILTER RULES" >> "$REPORT"
sudo iptables -L -n --line-numbers 2>/dev/null >> "$REPORT" || echo "  Not available" >> "$REPORT"
echo "" >> "$REPORT"

# Section 3: NAT rules
echo "3. NAT RULES" >> "$REPORT"
sudo iptables -t nat -L -n --line-numbers 2>/dev/null >> "$REPORT" || echo "  Not available" >> "$REPORT"
echo "" >> "$REPORT"

# Section 4: Open ports (listening services)
echo "4. LISTENING SERVICES" >> "$REPORT"
ss -tlnp 2>/dev/null | grep LISTEN >> "$REPORT" || netstat -tulpn 2>/dev/null | grep LISTEN >> "$REPORT"
echo "" >> "$REPORT"

# Section 5: IP forwarding
echo "5. IP FORWARDING" >> "$REPORT"
if [ "$(cat /proc/sys/net/ipv4/ip_forward)" = "1" ]; then
    echo "  IP forwarding is ENABLED (this system is a router/NAT)" >> "$REPORT"
else
    echo "  IP forwarding is disabled" >> "$REPORT"
fi
echo "" >> "$REPORT"

# Section 6: firewalld configuration
echo "6. FIREWALLD CONFIGURATION" >> "$REPORT"
if systemctl is-active firewalld &>/dev/null; then
    sudo firewall-cmd --list-all-zones 2>/dev/null >> "$REPORT" || true
else
    echo "  Not applicable" >> "$REPORT"
fi
echo "" >> "$REPORT"

echo "============================================" >> "$REPORT"
echo "  END OF REPORT" >> "$REPORT"
echo "============================================" >> "$REPORT"

cat "$REPORT"
EOF

chmod +x firewall_audit.sh
./firewall_audit.sh
```

---

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

---

## 📋 Summary — Complete Command Reference for Part 16

### Level 1: Basic iptables

| Command | Action |
|---------|--------|
| `iptables -L` | List filter rules |
| `iptables -A CHAIN -j TARGET` | Append rule |
| `iptables -I CHAIN N -j TARGET` | Insert rule at position N |
| `iptables -D CHAIN N` | Delete rule at position N |
| `iptables -F` | Flush all rules |
| `iptables -P CHAIN TARGET` | Set default policy |
| `iptables -A INPUT -s IP -j DROP` | Block by source IP |
| `iptables -A INPUT -p tcp --dport PORT -j ACCEPT` | Allow a port |

### Level 2: Rule Persistence, firewalld, and nftables

| Command | Action |
|---------|--------|
| `iptables -t nat -L` | List NAT rules |
| `iptables-save` | Save rules to stdout |
| `iptables-restore < FILE` | Restore rules from file |
| `firewall-cmd --state` | Check if running |
| `firewall-cmd --list-all` | Show default zone |
| `firewall-cmd --zone=Z --add-service=SVC` | Allow a service |
| `firewall-cmd --zone=Z --add-port=PORT` | Allow a port |
| `firewall-cmd --permanent --zone=Z --add-service=SVC` | Make rule permanent |
| `firewall-cmd --reload` | Reload permanent rules |
| `nft list ruleset` | Show all rules |
| `nft add table inet NAME` | Create table |
| `nft add chain ...` | Create chain |
| `nft add rule ...` | Add rule |
| `nft flush ruleset` | Delete all rules |
| `nft -f FILE` | Load rules from file |

### Level 3: Advanced and Troubleshooting

| Command | Action |
|---------|--------|
| `iptables -t nat -A PREROUTING -p tcp --dport P -j DNAT --to-destination IP` | Port forwarding (DNAT) |
| `iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE` | Source NAT (masquerading) |
| `iptables -A INPUT -m limit --limit N/min -j LOG --log-prefix "DROP: "` | Rate-limited logging |
| `iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT` | Stateful filtering |
| `iptables -A INPUT -m set --match-set BLACKLIST src -j DROP` | IP set matching |
| `journalctl -k \| grep -i "DROP\|REJECT"` | Check firewall kernel logs |
| `nc -zv host port` | Test port connectivity |
| `sudo cat /proc/net/nf_conntrack \| head` | View connection tracking table |

---

## 🚀 What's Coming in Part 17

**Part 17: SELinux and AppArmor — Mandatory Access Control**

You will learn:
- Discretionary vs Mandatory Access Control
- SELinux concepts: contexts, booleans, policies
- AppArmor profiles
- Troubleshooting SELinux denials
- Configuring SELinux for common services
- 15 hands-on practices

---

## 📝 Self-Test — Can You Answer These?

1. What kernel subsystem powers iptables, firewalld, and nftables?
2. Name the five netfilter hooks.
3. What are the three default chains in the filter table?
4. What is the difference between DROP and REJECT?
5. What does `-m state --state ESTABLISHED,RELATED` do?
6. How does firewalld's concept of "zones" work?
7. What is the difference between runtime and permanent changes in firewalld?
8. What is the main advantage of nftables over iptables?
9. How do you make iptables rules persistent across reboots?
10. What is a NAT masquerade rule used for?
11. How do you log dropped packets with iptables?
12. What does `iptables -F` do and why is it dangerous over SSH?
13. How do you check if IP forwarding is enabled?
14. What is connection tracking in iptables?
15. How do you save and restore nftables rules?

**Score:** 12/15 correct = ready for Part 17.

---

*Linux SysAdmin Course | Part 16 of ∞ | Reverse Engineering Approach*
*Previous → Part 15: SSH and Remote Access*
*Next → Part 17: SELinux and AppArmor*

[← Previous](part15.md) | [Next →](part17.md)
