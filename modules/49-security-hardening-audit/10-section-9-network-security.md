## 🔍 Section 9: Network Security

### Unused Ports and Services

```bash
# List all listening TCP and UDP ports with process info
sudo ss -tlnp
sudo ss -ulnp

# Alternative with netstat
sudo netstat -tulnp

# Check what services are running
sudo systemctl list-units --type=service --state=running

# Close unnecessary ports by stopping/disabling services
sudo systemctl disable --now cups        # Printing
sudo systemctl disable --now avahi-daemon # mDNS
sudo systemctl disable --now rpcbind     # NFS portmapper
sudo systemctl disable --now bluetooth   # Bluetooth (servers)
sudo systemctl disable --now whoopsie    # Ubuntu crash reporting
```

### Firewall Lockdown

```bash
# UFW (Uncomplicated Firewall)
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw --force enable
sudo ufw status verbose

# nftables (modern replacement for iptables)
sudo tee /etc/nftables.conf > /dev/null << 'EOF'
#!/usr/sbin/nft -f
flush ruleset

table inet filter {
    chain input {
        type filter hook input priority 0; policy drop;
        ct state established,related accept
        ct state invalid drop
        iif lo accept
        tcp dport 22 accept
        tcp dport 80 accept
        tcp dport 443 accept
        ip protocol icmp accept
        log prefix "nftables-drop " drop
    }
    chain forward {
        type filter hook forward priority 0; policy drop;
    }
    chain output {
        type filter hook output priority 0; policy accept;
    }
}
EOF

sudo systemctl enable --now nftables
sudo nft -f /etc/nftables.conf
```

### TCP Wrappers (/etc/hosts.allow, /etc/hosts.deny)

**Note:** TCP wrappers are deprecated in most modern distros (sshd dropped libwrap support). Use firewall rules instead. For legacy systems:

```bash
# /etc/hosts.deny — default deny
echo "ALL: ALL" | sudo tee /etc/hosts.deny

# /etc/hosts.allow — specific allow
sudo tee /etc/hosts.allow > /dev/null << 'EOF'
# Allow SSH from management network only
sshd: 10.0.0.0/24, 192.168.1.0/24

# Allow NFS from specific hosts
portmap: 10.0.0.10, 10.0.0.11

# Allow rsync from backup server
rsync: 10.0.0.50
EOF
```

### ICMP and Network Hardening

```bash
# /etc/sysctl.d/10-network-security.conf
sudo tee /etc/sysctl.d/10-network-security.conf > /dev/null << 'EOF'
# Disable ICMP redirect acceptance
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0

# Disable sending ICMP redirects
net.ipv4.conf.all.send_redirects = 0

# Ignore ICMP echo requests (disable ping)
# net.ipv4.icmp_echo_ignore_all = 1

# Ignore broadcast pings (smurf attack prevention)
net.ipv4.icmp_echo_ignore_broadcasts = 1

# Ignore bogus ICMP errors
net.ipv4.icmp_ignore_bogus_error_responses = 1

# Reverse path filtering (martian packet prevention)
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1

# SYN cookies (protection against SYN flood attacks)
net.ipv4.tcp_syncookies = 1

# Disable IP forwarding unless acting as router
net.ipv4.ip_forward = 0

# Log martian packets
net.ipv4.conf.all.log_martians = 1

# Disable source routing
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
EOF

# Apply immediately
sudo sysctl --system
```

### Reverse Path Filtering Explained

**rp_filter** checks whether the source address of an incoming packet is reachable through the interface it arrived on. If not, the packet is dropped. This prevents **IP spoofing** and **martian packets** (packets with impossible source addresses):

```
┌──────────┐         ┌──────────┐
│ Attacker │────────►│ eth0     │
│ 1.2.3.4  │  spoof  │ Server   │
│          │  src=   │          │
│          │  1.1.1.1│          │
└──────────┘         └────┬─────┘
                          │
               rp_filter checks:
               "Is 1.1.1.1 reachable via eth0?"
               ┌────┐
               │ NO │ ──► DROP
               └────┘
```





[← Previous](09-section-8-filesystem-security.md) | [↑ Index](index.md) | [Next →](11-section-10-kernel-hardening.md)
