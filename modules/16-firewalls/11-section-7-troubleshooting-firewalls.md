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



---

[← Previous](10-section-6-common-iptablesnftables-patterns.md) | [↑ Index](index.md) | [Next →](12-practice-section-15-hands-on-exercises.md)
