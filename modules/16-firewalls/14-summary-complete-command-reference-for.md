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



---

[← Previous](13-deep-understanding-how-packet-filtering.md) | [↑ Index](index.md) | [Next →](15-whats-coming-in-part-17.md)
