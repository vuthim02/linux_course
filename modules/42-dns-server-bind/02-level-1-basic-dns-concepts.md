## ⭐ Level 1: Basic — DNS Concepts and Installation

![BIND DNS Server logo](https://upload.wikimedia.org/wikipedia/en/7/75/BIND9_logo.svg)

> **Level Goal:** Understand how DNS works at a protocol level and install BIND on a Linux server.

### What You'll Cover
- DNS hierarchy: root, TLD, authoritative, and recursive resolvers
- Resource record types: A, AAAA, CNAME, MX, NS, SOA, TXT, PTR
- The BIND 9 architecture: `named`, `rndc`, `dig`, `nslookup`
- Installing BIND via the package manager
- Verifying the installation with `dig` and `nslookup`

BIND (Berkeley Internet Name Domain) is the reference implementation of DNS. Running your own BIND server means you control how your domain is resolved — both internally and to the outside world.

At this level you will learn:

- **DNS hierarchy**: Root servers (13 clusters) → TLD servers (`.com`, `.org`) → authoritative servers (your domain). Recursive resolvers (like your ISP's DNS) walk this tree. BIND can act as both authoritative (serves your zones) and recursive (resolves for clients).
- **Resource records**: `A` = IPv4 address. `AAAA` = IPv6 address. `CNAME` = alias to another name. `MX` = mail server. `NS` = authoritative nameserver. `SOA` = zone authority (serial, refresh, retry, expire). `TXT` = arbitrary text (SPF, DKIM). `PTR` = reverse lookup.
- **BIND architecture**: `named` is the DNS daemon. `rndc` controls named remotely (reload, flush cache, querylog). `dig` queries DNS servers. `nslookup` is a simpler query tool. `named-checkconf` validates configuration. `named-checkzone` validates zone files.
- **Installation**: RHEL: `dnf install bind`. Ubuntu: `apt install bind9`. Start with `systemctl enable --now named`. Open port 53 TCP and UDP in the firewall.
- **Verification**: `dig @localhost example.com` queries your local server. `rndc status` shows server status. `ss -ulnp | grep named` confirms named is listening on port 53.


[← Previous](01-what-you-will-achieve.md) | [↑ Index](index.md) | [Next →](03-section-1-bind-overview.md)
