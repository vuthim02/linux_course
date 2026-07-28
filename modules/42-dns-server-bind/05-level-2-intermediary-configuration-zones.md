## ⭐ Level 2: Intermediary — Configuration, Zones, and Slave DNS

> **Level Goal:** Configure BIND properly, create forward and reverse zones, and set up slave/secondary DNS servers for redundancy.

### What You'll Cover
- `named.conf` structure: options, zones, logging, includes
- Forward zone file syntax: SOA, serial numbers, TTLs, record types
- Reverse zone files and PTR records
- Slave/secondary DNS with zone transfers (AXFR/IXFR)
- Split-horizon DNS with `view` statements
- Logging configuration and `rndc` control

At this level you configure BIND as a production DNS server with proper zone management, redundancy, and logging.

At this level you will practice:

- **`named.conf`**: The main configuration file. `options {}` sets global behavior (listen-on, forwarders, recursion). `zone "example.com" {}` defines a zone. `include "/etc/named/logging.conf"` pulls in logging config. Use `include` for secrets (TSIG keys).
- **Zone files**: SOA record defines the zone: `@ IN SOA ns1.example.com. admin.example.com. (2024010101 3600 900 604800 86400)`. Serial number (YYYYMMDDNN format) must increment on every change. Refresh/retry/expire control slave behavior.
- **Reverse zones**: `zone "1.168.192.in-addr.arpa" {}` maps IPs to names via PTR records. `10 IN PTR host.example.com.` is the reverse entry. Reverse DNS is required for mail servers and some authentication systems.
- **Slave DNS**: `type slave; masters { 192.168.1.1; };` configures a secondary server that pulls zone data from the primary via AXFR (full transfer) or IXFR (incremental). This provides redundancy and load distribution.
- **Split-horizon**: `view "internal" { match-clients { 192.168.1.0/24; }; zone "example.com" { ... }; };` serves different answers to internal vs external clients. Internal clients get private IPs; external clients get public IPs.


[← Previous](04-section-2-installation.md) | [↑ Index](index.md) | [Next →](06-section-3-configuration-namedconf.md)
