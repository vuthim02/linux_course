## ⭐ Level 3: Advanced — DNSSEC, Access Control, and Tuning

> **Level Goal:** Sign zones with DNSSEC, implement ACLs and TSIG, optimize BIND performance, and troubleshoot real-world DNS issues.

### What You'll Cover
- DNSSEC key generation, signing, and DS record management
- Response Rate Limiting (RRL) for DDoS mitigation
- ACLs and TSIG-authenticated zone transfers
- `named.conf` tuning: `max-cache-size`, `recursive-clients`, rate limits
- Debugging with `dig +dnssec`, `delv`, and query logging

At the advanced level, you secure and optimize BIND for production use with DNSSEC, access controls, and performance tuning.

At this level you will master:

- **DNSSEC**: DNS Security Extensions sign your DNS records so resolvers can verify authenticity. Generate keys with `dnssec-keygen`, sign zones with `dnssec-signzone`, and publish DS records at the parent zone. `dig +dnssec example.com` verifies signatures. DNSSEC prevents cache poisoning and spoofing.
- **RRL (Response Rate Limiting)**: Rate-limit responses to prevent DNS amplification DDoS attacks. Configure `rate-limit { responses-per-second 10; };` in `named.conf`. RRL limits the number of identical responses sent to a single source IP per second.
- **ACLs and TSIG**: ACLs restrict who can query or transfer zones. `acl "trusted" { 192.168.1.0/24; };` defines a group. TSIG keys authenticate zone transfers between master and slave servers, preventing unauthorized zone data access.
- **Performance tuning**: `max-cache-size 256m` limits memory usage. `recursive-clients 10000` sets the maximum concurrent recursive queries. `fetches-per-zone 4` limits concurrent fetches to a single zone. Monitor with `rndc stats` and check `/var/named/data/named_stats.txt`.
- **Debugging**: `dig +dnssec +trace example.com` shows the full DNSSEC validation chain. `delv @8.8.8.8 example.com` performs DNSSEC validation locally. `querylog on` in `rndc` enables detailed query logging for troubleshooting.


[← Previous](10-section-7-slavesecondary-dns.md) | [↑ Index](index.md) | [Next →](12-section-8-dnssec.md)
