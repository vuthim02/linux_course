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

---

*Linux SysAdmin Course | Part 26 of ∞ | Reverse Engineering Approach*
*Previous → Part 25: System Rescue and Recovery*
*Next → Part 27: DNS and Name Resolution*

[← Previous](part25.md) | [Next →](part27.md)


---

[← Previous](21-whats-coming-in-part-27.md) | [↑ Index](index.md)
