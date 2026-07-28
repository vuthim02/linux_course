## 🔍 Section 5: Securing Network Services

### Firewall Basics (ufw)

```bash
# Enable firewall
sudo ufw enable

# Allow services
sudo ufw allow ssh
sudo ufw allow http
sudo ufw allow https
sudo ufw allow 2222/tcp    # Custom SSH port

# Deny/block
sudo ufw deny 23/tcp       # Block telnet

# Status
sudo ufw status verbose
sudo ufw status numbered

# Delete rule by number
sudo ufw delete 3

# Default policies
sudo ufw default deny incoming
sudo ufw default allow outgoing
```

### Firewall Basics (firewalld - RHEL/CentOS)

```bash
# Check status
sudo firewall-cmd --state

# List zones
sudo firewall-cmd --get-active-zones

# Add services
sudo firewall-cmd --zone=public --add-service=http --permanent
sudo firewall-cmd --zone=public --add-service=https --permanent
sudo firewall-cmd --zone=public --add-port=2222/tcp --permanent

# Reload
sudo firewall-cmd --reload

# List rules
sudo firewall-cmd --list-all
```

### TCP Wrappers (Legacy)

```bash
# /etc/hosts.allow — Allow connections
sshd: 192.168.1.0/24
sshd: 10.0.0.0/8

# /etc/hosts.deny — Deny all other
sshd: ALL

# Note: TCP wrappers are deprecated. Use firewalld/ufw instead.
```





[← Previous](07-section-4-network-service-management.md) | [↑ Index](index.md) | [Next →](09-section-6-monitoring-network-services.md)
