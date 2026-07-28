## ⭐ Level 1: Basic — DNS Fundamentals and Local Resolution

![DNS Hierarchy](https://i.pinimg.com/1200x/1f/a3/d5/1fa3d5244b3534b414dc5b75a9e11685.jpg)  
*The DNS hierarchy — root servers, TLDs, and authoritative nameservers. Image credit: Wikimedia Commons.*

> **Level 1 Goal:** Understand the DNS hierarchy and how domain names are resolved. Master `/etc/hosts` for local overrides and decode `/etc/resolv.conf` for resolver configuration.

### What You'll Cover
- The DNS tree: root servers, TLDs, and authoritative nameservers
- How recursive and iterative resolution work step by step
- Common record types: A, AAAA, CNAME, MX, TXT, NS, SOA, PTR
- `/etc/hosts` — local overrides and resolution precedence
- `/etc/resolv.conf` — nameservers, search domains, and resolver options
- Practical DNS queries with `dig`, `host`, and `getent`

DNS is the phone book of the internet. Before any network connection, the hostname must be resolved to an IP address. Understanding this process is fundamental to every network service you will ever configure.

At this level you will learn:

- **DNS hierarchy**: The root zone (`.`) delegates to TLDs (`.com`, `.org`), which delegate to authoritative nameservers for each domain. Recursive resolvers (like `8.8.8.8`) walk this tree on your behalf.
- **Record types**: `A` maps to IPv4, `AAAA` to IPv6, `CNAME` aliases to another name, `MX` specifies mail servers, `NS` delegates subdomains, `SOA` defines zone parameters, `PTR` does reverse lookups.
- **`/etc/hosts`**: Local overrides that bypass DNS entirely. The order in `/etc/nsswitch.conf` determines priority — typically `files dns`, meaning `/etc/hosts` is checked first.
- **`/etc/resolv.conf`**: Lists nameservers (up to 3), search domains (appended to short names), and options like `timeout:2` and `attempts:3`.
- **Query tools**: `dig @8.8.8.8 example.com A` queries a specific server. `host example.com` gives a simple answer. `getent hosts example.com` uses the system resolver (respects nsswitch).


[← Previous](01-what-you-will-achieve-in.md) | [↑ Index](index.md) | [Next →](03-section-1-what-is-dns.md)
