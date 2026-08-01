## 📝 Self-Test — Can You Answer These?
1. What are the three main predictable network interface naming schemes (enp0s3, ens33, eno1)? What determines which one is used?
2. What kernel mechanism does the `ip` command use to communicate with the kernel (as opposed to `ifconfig`'s mechanism)?
3. How do you add a secondary IP address using `ip addr`? How was this done with `ifconfig`?
4. What is the difference between `netplan try` and `netplan apply`?
5. What file does a Debian/Ubuntu system use for network configuration before Netplan was introduced?
6. In RHEL/CentOS, what is the purpose of the `ifcfg-eth0` file and where is it located?
7. How does `/etc/nsswitch.conf` control the order of name resolution?
8. What is the difference between systemd-resolved's stub resolver (`127.0.0.53`) and a traditional `/etc/resolv.conf`?
9. What are the six bonding modes? Which mode provides LACP (802.3ad) aggregation?
10. How does a Linux bridge differ from a switch? What is STP and why is it needed?
11. What happens to a packet when it is received by a VLAN interface with a matching VID?
12. How do you use `ethtool -k` to check and disable TCP segmentation offload?
13. What does the `-M do` flag in `ping` test? How does `tracepath` use this?
14. What is the difference between `ss -t` and `ss -t state established`?
15. What kernel data structure carries every packet through the Linux network stack, and what does each layer's processing do to its `data` pointer?
**Score:** 12/15 correct = ready for Part 27.
## Answer Key
### Q1: What are the three main predictable naming schemes?
**Answer:** `enp0s3` (PCI bus), `ens33` (hotplug slot), `eno1` (onboard). Determined by firmware/driver: `en` = ethernet, followed by type and index.
### Q2: What kernel mechanism does the `ip` command use?
**Answer:** Netlink sockets — a kernel-userspace IPC mechanism. `ip` uses RTNETLINK. `ifconfig` used the older `ioctl()` interface.
### Q3: How do you add a secondary IP using `ip addr`?
**Answer:** `ip addr add 192.168.1.50/24 dev eth0`. Old way: `ifconfig eth0:0 192.168.1.50 netmask 255.255.255.0`.
### Q4: What is the difference between `netplan try` and `netplan apply`?
**Answer:** `try` applies config with a 120s timeout (reverts if not confirmed). `apply` applies immediately (risky if config is wrong).
### Q5: What file does Debian/Ubuntu use before Netplan?
**Answer:** `/etc/network/interfaces` — traditional network configuration file.
### Q6: In RHEL/CentOS, what is the purpose of `ifcfg-eth0`?
**Answer:** Located in `/etc/sysconfig/network-scripts/`, it configures the eth0 interface (IP, gateway, DNS, boot method).
### Q7: How does `/etc/nsswitch.conf` control name resolution order?
**Answer:** The `hosts:` line specifies lookup order, e.g., `files dns mDNS` — checks `/etc/hosts` first, then DNS, then mDNS.
### Q8: What is the difference between systemd-resolved's stub resolver and resolv.conf?
**Answer:** Stub resolver at `127.0.0.53` provides caching, DNSSEC, and per-link DNS. `resolv.conf` is static and lacks caching.
### Q9: What are the six bonding modes? Which provides LACP?
**Answer:** 0=round-robin, 1=active-backup, 2=balance-xor, 3=broadcast, 4=802.3ad (LACP), 5=balance-tlb, 6=balance-alb. Mode 4 provides LACP.
### Q10: How does a Linux bridge differ from a switch?
**Answer:** A bridge is software-based switching in the kernel. It forwards frames based on MAC tables. STP prevents loops.
### Q11: What happens when a VLAN packet is received with a matching VID?
**Answer:** The kernel strips the VLAN tag and delivers the frame to the matching VLAN sub-interface (e.g., `eth0.100`).
### Q12: How do you use `ethtool -k` to check TSO?
**Answer:** `ethtool -k eth0 | grep segmentation` — shows TCP/UDP segmentation offload status. Disable: `ethtool -K eth0 tso off`.
### Q13: What does `-M do` in `ping` test?
**Answer:** Path MTU discovery. `ping -M do -s 1472 host` probes the maximum packet size without fragmentation.
### Q14: What is the difference between `ss -t` and `ss -t state established`?
**Answer:** `ss -t` shows all TCP sockets. `ss -t state established` filters to only established connections.
### Q15: What kernel data structure carries packets through the network stack?
**Answer:** `sk_buff` (socket buffer). Each layer processes the packet by adjusting pointers (head/data/tail/end) within the same buffer.
*Linux SysAdmin Course | Part 26 of ∞ | Reverse Engineering Approach*
*Previous → Part 25: System Rescue and Recovery*
*Next → Part 27: DNS and Name Resolution*
[← Previous](21-whats-coming-in-part-27.md) | [↑ Index](index.md)
