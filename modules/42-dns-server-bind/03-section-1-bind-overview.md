## 📦 Section 1: BIND Overview

BIND (Berkeley Internet Name Domain) is the most widely deployed DNS server software on the Internet, originally written at UC Berkeley in the early 1980s and now maintained by ISC.

### 1.1 What is `named`?

The BIND daemon is called **`named`** (name daemon). Current major version: **BIND 9** (9.18 is the ESV as of 2024–2026; 9.20 is the latest stable).

### 1.2 History

| Version | Year | Significance |
|---------|------|--------------|
| BIND 4 | 1980s | Original release |
| BIND 8 | 1997 | Major rewrite, dynamic update support |
| BIND 9 | 2000 | Complete rewrite: multithreaded, DNSSEC, TSIG, views |
| BIND 9.16 | 2020 | ESV |
| BIND 9.18 | 2022 | Current ESV, DoT/DoH, CATZ, XFR over TLS |
| BIND 9.20 | 2024–2025 | KASP for DNSSEC policy automation |

### 1.3 DNS Server Roles

| Role | Description | Typical Use |
|------|-------------|-------------|
| **Authoritative only** | Serves zones it is authority for; refuses recursion | Public DNS (ns1.example.com) |
| **Recursive resolver** | Queries upstream servers for clients, caches | Internal LAN resolver |
| **Caching-only** | Recursive with no authoritative zones | Home router, stub resolver |
| **Forwarder** | Forwards queries upstream instead of recursing | Corporate DNS behind firewall |
| **Stealth master** | Authoritative but not in NS records; transfers to slaves | Security (hide primary) |
| **Stub resolver** | Holds only NS records for a zone | Lightweight delegation |

### 1.4 BIND vs Alternatives

| Feature | BIND 9 | Unbound | Knot DNS | PowerDNS |
|---------|--------|---------|----------|----------|
| Authoritative | ✓ | ✗ (resolver only) | ✓ | ✓ |
| Recursive resolver | ✓ | ✓ | ✗ | ✓ (Recursor) |
| DNSSEC | Full (signing + validation) | Validation only | Full | Full |
| Views (split DNS) | ✓ | ✗ | ✓ | ✓ |
| Performance | Moderate | Very high | Very high | High |
| Configuration complexity | High | Low | Moderate | Moderate |
| DoT/DoH | ✓ (9.18+) | ✓ | ✓ | ✓ |

**When to choose BIND:** Complex split-DNS views, TSIG-signed transfers, DNSSEC signing, legacy deployments.

**When to choose alternatives:** High-performance resolver (Unbound), lightweight authoritative (Knot), database-backed DNS (PowerDNS).

---



---

[← Previous](02-level-1-basic-dns-concepts.md) | [↑ Index](index.md) | [Next →](04-section-2-installation.md)
