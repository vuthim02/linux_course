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


## Answer Key

### Q1: What kernel subsystem powers iptables, firewalld, and nftables?
**Answer:** Netfilter — the Linux kernel framework for packet filtering, NAT, and port forwarding.

### Q2: Name the five netfilter hooks.
**Answer:** PREROUTING, INPUT, FORWARD, OUTPUT, POSTROUTING.

### Q3: What are the three default chains in the filter table?
**Answer:** INPUT (incoming packets), FORWARD (routed packets), OUTPUT (locally generated packets).

### Q4: What is the difference between DROP and REJECT?
**Answer:** DROP silently discards the packet (sender gets no response). REJECT sends an ICMP error back (sender knows it was blocked).

### Q5: What does `-m state --state ESTABLISHED,RELATED` do?
**Answer:** Matches packets belonging to existing connections (ESTABLISHED) or related connections (RELATED, like FTP data channels). Allows return traffic.

### Q6: How does firewalld's concept of "zones" work?
**Answer:** Zones are pre-defined trust levels (public, trusted, drop, etc.) applied to network interfaces. Each zone has its own rules.

### Q7: What is the difference between runtime and permanent changes in firewalld?
**Answer:** Runtime changes apply immediately but are lost on restart. Permanent changes require `--permanent` and take effect after reload/restart.

### Q8: What is the main advantage of nftables over iptables?
**Answer:** Atomic rule replacement (no rule numbers), atomic rule sets, better performance with large rule sets, built-in set/map support, and a unified framework.

### Q9: How do you make iptables rules persistent across reboots?
**Answer:** `sudo iptables-save > /etc/iptables/rules.v4` or install `iptables-persistent` package.

### Q10: What is a NAT masquerade rule used for?
**Answer:** Hides multiple private IPs behind one public IP (SNAT). `iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE`.

### Q11: How do you log dropped packets with iptables?
**Answer:** `iptables -A INPUT -j LOG --log-prefix "DROPPED: "` before the DROP rule. Logs to `/var/log/kern.log`.

### Q12: What does `iptables -F` do and why is it dangerous over SSH?
**Answer:** Flushes (deletes) all rules. Over SSH, this removes your SSH allow rule and locks you out immediately.

### Q13: How do you check if IP forwarding is enabled?
**Answer:** `sysctl net.ipv4.ip_forward` — 1 means enabled (needed for routing/NAT), 0 means disabled.

### Q14: What is connection tracking in iptables?
**Answer:** The `conntrack` module tracks connection states, allowing rules to match established connections rather than processing each packet independently.

### Q15: How do you save and restore nftables rules?
**Answer:** `nft list ruleset > /etc/nftables.conf` to save. `nft -f /etc/nftables.conf` to restore.


[← Previous](15-whats-coming-in-part-17.md) | [↑ Index](index.md) | [Next →](17-section-8-ufw.md)
