## 📝 Self-Test — Can You Answer These?

1. What is the difference between a recursive and iterative DNS query?
2. What are the three services (sources) listed in the default `hosts` line of `/etc/nsswitch.conf`?
3. Why does `dig google.com` work even when `ping google.com` fails with "Temporary failure in name resolution"?
4. What does `options timeout:2` in `/etc/resolv.conf` control?
5. What is the purpose of the stub resolver at `127.0.0.53`?
6. How does `dig +trace` work? What servers does it contact?
7. What is the difference between mDNS and LLMNR?
8. How do you flush the DNS cache on a system using systemd-resolved?
9. What record type would you query to find a domain's mail servers?
10. What does `search example.com` in `/etc/resolv.conf` do?
11. How does TCP wrappers (`/etc/hosts.allow`, `/etc/hosts.deny`) decide whether to allow a connection?
12. What is the TTL field in a DNS response, and how does it affect caching?
13. How would you block `facebook.com` on a Linux machine using only local configuration files?
14. What is the difference between `nscd -i hosts` and `resolvectl flush-caches`?
15. When you call `getaddrinfo()` in a C program, in what order does glibc consult `files`, `dns`, and `myhostname`?

**Score:** 12/15 correct = ready for Part 28.

---

*Linux SysAdmin Course | Part 27 of ∞ | Reverse Engineering Approach*
*Previous → Part 26: Network Configuration*
*Next → Part 28: Network File System (NFS)*

[← Previous](part26.md) | [Next →](part28.md)


---

[← Previous](20-whats-coming-in-part-28.md) | [↑ Index](index.md)
