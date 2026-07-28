## 💻 PRACTICE SECTION — 15 Hands-On Exercises

### Level 1 Practices: Exploring and Basic Filtering


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





[← Previous](11-section-7-troubleshooting-firewalls.md) | [↑ Index](index.md) | [Next →](13-deep-understanding-how-packet-filtering.md)
