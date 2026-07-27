## 📚 Section 13: Command Reference

### ⭐ Level 1: Basic Commands

#### 13.1 Basic BIND Commands

| Command | Purpose |
|---------|---------|
| `named -v` | Show version |
| `named-checkconf [file]` | Validate named.conf syntax |
| `named-checkzone <zone> <file>` | Validate zone file |
| `nslookup` | Legacy DNS lookup |
| `host` | Simplified DNS lookup |
| `rndc status` | Server status |
| `rndc reload` | Reload config |
| `rndc flush` | Flush cache |

#### 13.2 Key Files

| File | Purpose |
|------|---------|
| `/etc/bind/named.conf` | Main configuration |
| `/etc/bind/named.conf.options` | Options block |
| `/etc/bind/named.conf.local` | Local zone definitions |
| `/etc/bind/db.root` | Root hints |
| `/etc/bind/bind.keys` | DNSSEC root trust anchor |
| `/etc/bind/db.local` | Localhost zone |
| `/var/cache/bind/` | Working directory (zone files, journal, cache dumps) |

### ⭐ Level 2: Intermediary Commands

#### 13.3 DNS Lookup and Management

| Command | Purpose | Example |
|---------|---------|---------|
| `dig` | DNS lookup tool | `dig example.com A +short` |
| `dig -x <ip>` | Reverse DNS lookup | `dig -x 8.8.8.8` |
| `dig <domain> +trace` | Trace delegation chain | `dig example.com +trace` |
| `rndc querylog on/off` | Toggle query logging | `rndc querylog on` |
| `tsig-keygen <name>` | Generate TSIG key | `tsig-keygen -a hmac-sha256 xfer-key` |

### ⭐ Level 3: Advanced Commands

#### 13.4 DNSSEC Commands

| Command | Purpose | Example |
|---------|---------|---------|
| `delv` | DNSSEC-aware lookup | `delv www.example.com +short` |
| `dnssec-keygen` | Generate DNSSEC keys | `dnssec-keygen -a RSASHA256 -b 2048 -n ZONE example.com` |
| `dnssec-signzone` | Sign zone file | `dnssec-signzone -A -o example.com db.example.com` |
| `dnssec-settime` | Change key timing | `dnssec-settime -I +30d Kexample.com.+008+*.key` |
| `dnssec-dsfromkey` | Generate DS from DNSKEY | `dnssec-dsfromkey Kexample.com.+008+*.key` |
| `dnssec-verify` | Verify signed zone | `dnssec-verify -o example.com db.example.com.signed` |

---



---

[← Previous](16-section-12-troubleshooting.md) | [↑ Index](index.md) | [Next →](18-section-14-15-hands-on-practices.md)
