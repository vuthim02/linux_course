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





[← Previous](06-section-3-saving-and-restoring.md) | [↑ Index](index.md) | [Next →](08-section-5-nftables-the-modern.md)
