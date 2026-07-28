## ⭐ Level 2: Intermediary — Resolution Configuration and Caching

![dig command output](https://upload.wikimedia.org/wikipedia/commons/thumb/f/fc/Dig_command_output.png/220px-Dig_command_output.png)  
*Querying DNS with dig — the sysadmin's primary DNS tool. Image credit: Wikimedia Commons.*

> **Level 2 Goal:** Control resolution order with nsswitch.conf. Master dig, host, and nslookup for all record types. Configure systemd-resolved, DNS caching (nscd/Unbound), mDNS, and LLMNR. Troubleshoot complex resolution failures.

### What You'll Cover
- `/etc/nsswitch.conf` — name service switch order and directives
- `systemd-resolved` — stub resolver, D-Bus API, and DNS over TLS
- `dig` advanced usage: +trace, +short, reverse lookups, DNSSEC checks
- DNS caching with nscd, systemd-resolved, and Unbound
- mDNS with Avahi for `.local` hostname resolution
- LLMNR for link-local name resolution on mixed networks
- End-to-end troubleshooting with strace and diagnostic scripts

At this level you move from understanding DNS to controlling how your system resolves names and diagnosing failures.

At this level you will master:

- **nsswitch.conf**: The line `hosts: files dns mdns` tells the resolver to check `/etc/hosts` first, then DNS, then mDNS. This is the most common cause of unexpected resolution behavior — always check nsswitch before anything else.
- **systemd-resolved**: The default resolver on modern Ubuntu and Fedora. It provides a stub resolver at `127.0.0.53`, caches queries, and supports DNS over TLS. Check status with `resolvectl status`.
- **dig +trace**: Follows the full delegation path from root to authoritative server. `dig +trace example.com` shows every delegation step. Use `+short` for just the answer.
- **DNS caching**: nscd (nscd) caches libc Name Service lookups. Unbound is a full recursive resolver you can run locally for privacy and performance. Both reduce repeated DNS queries.
- **mDNS/LLMNR**: Avahi provides `.local` resolution via multicast DNS (Bonjour/Zeroconf). LLMNR is Microsoft's link-local protocol used in Windows networks. Both are useful for small LANs without a DNS server.


[← Previous](05-section-3-etcresolvconf-the-resolver.md) | [↑ Index](index.md) | [Next →](07-section-4-etcnsswitchconf-name-service.md)
