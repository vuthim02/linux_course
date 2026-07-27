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



---

[← Previous](09-level-3-advanced-filtering-patterns.md) | [↑ Index](index.md) | [Next →](11-section-7-troubleshooting-firewalls.md)
