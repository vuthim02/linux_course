## Section 8: UFW — Uncomplicated Firewall

UFW is a frontend for iptables/nftables, designed for simplicity.

```bash
# Basic usage
sudo ufw enable                 # Enable firewall
sudo ufw disable                # Disable firewall
sudo ufw status verbose         # Show rules

# Allow/deny services
sudo ufw allow ssh              # Allow SSH (port 22)
sudo ufw allow 80/tcp           # Allow HTTP
sudo ufw deny 23                # Deny telnet

# Allow from specific IP
sudo ufw allow from 192.168.1.0/24 to any port 22

# Rules management
sudo ufw default deny incoming  # Default deny inbound
sudo ufw default allow outgoing # Default allow outbound
sudo ufw delete allow 80/tcp    # Remove a rule
sudo ufw reset                  # Reset to defaults
```

UFW is the default on Ubuntu. It stores rules in `/etc/ufw/` and generates iptables/nftables rules automatically.


[← Previous](16-self-test-can-you-answer-these.md) | [↑ Index](index.md) | [Next →](18-section-9-iptables-nat-deep-dive.md)
