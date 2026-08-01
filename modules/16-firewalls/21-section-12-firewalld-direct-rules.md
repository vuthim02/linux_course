## 🔍 Section 12: firewalld — Direct Rules and Advanced Features

### Direct Rules

When firewalld's rich rules aren't enough, inject raw iptables/nftables rules directly:

```bash
# Syntax: --direct --add-rule {ipv4|ipv6|eb} <table> <chain> <priority> <rule>

# Add a raw iptables rule through firewalld
sudo firewall-cmd --direct --add-rule ipv4 filter INPUT 0 \
    -p tcp --dport 8080 -j ACCEPT

# With source IP
sudo firewall-cmd --direct --add-rule ipv4 filter INPUT 0 \
    -s 10.0.0.0/8 -p tcp --dport 3306 -j ACCEPT

# List direct rules
sudo firewall-cmd --direct --get-all-rules

# Permanent direct rules
sudo firewall-cmd --permanent --direct --add-rule ipv4 filter INPUT 0 \
    -p tcp --dport 9999 -j ACCEPT
sudo firewall-cmd --reload

# Remove direct rule
sudo firewall-cmd --permanent --direct --remove-rule ipv4 filter INPUT 0 \
    -p tcp --dport 9999 -j ACCEPT
```

### Direct Chains

```bash
# Create a custom chain via direct rules
sudo firewall-cmd --permanent --direct --add-chain ipv4 filter mychain

# Add rules to it
sudo firewall-cmd --permanent --direct --add-rule ipv4 filter mychain 0 \
    -s 10.0.0.5 -j ACCEPT

# Jump to it from INPUT
sudo firewall-cmd --permanent --direct --add-rule ipv4 filter INPUT 0 \
    -j mychain
```

### Passthrough — Run Arbitrary Commands

```bash
# Run any iptables/nftables command through firewalld
sudo firewall-cmd --direct --passthrough ipv4 \
    -t nat -A POSTROUTING -o eth0 -j MASQUERADE

sudo firewall-cmd --direct --passthrough ipv4 \
    -t mangle -A PREROUTING -p tcp --dport 80 -j TOS --set-tos 0x10

# Check what firewalld generated
sudo firewall-cmd --direct --passthrough ipv4 -t nat -L -n
```

### Custom Service Definitions

```bash
# Create a custom firewalld service
sudo tee /etc/firewalld/services/myapp.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<service>
  <short>MyApp</short>
  <description>My custom application</description>
  <port protocol="tcp" port="3000"/>
  <port protocol="tcp" port="3001"/>
  <source address="10.0.0.0/8"/>
</service>
EOF

sudo firewall-cmd --reload
sudo firewall-cmd --get-services | tr ' ' '\n' | grep myapp
sudo firewall-cmd --zone=public --add-service=myapp
```

### Logging and Denying with Rich Rules

```bash
# Log dropped packets
sudo firewall-cmd --permanent --add-rich-rule='rule family="ipv4" log prefix="DROP " level="info" limit value="5/m" drop'

# Rate limit SSH
sudo firewall-cmd --permanent --add-rich-rule='rule service name="ssh" limit value="5/m" accept'

# Allow specific IP through
sudo firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="192.168.1.0/24" service name="ssh" accept'

# Port forwarding via rich rule
sudo firewall-cmd --permanent --add-rich-rule='rule family="ipv4" forward-port port="8080" protocol="tcp" to-port="80" to-addr="10.0.0.50"'
```

### firewalld and nftables Backend (RHEL 9+)

```bash
# RHEL 9 / Fedora: firewalld uses nftables by default
# Check the backend:
sudo firewall-cmd --version

# The nftables ruleset firewalld generates:
sudo nft list ruleset | grep -A 5 "chain filter_IN"

# Lockdown whitelist (restrict who can use firewalld)
# /etc/firewalld/lockdown-whitelist.xml
# Only root and specific users can make changes
```



[← Previous](20-section-11-ipset-and-connection-tracking.md) | [↑ Index](index.md) | [Next →](23-level-4-mastery-scenarios.md)
