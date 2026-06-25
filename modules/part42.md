# 🐧 Linux System Administrator — Complete Course
## Part 42 of ∞: DNS Server Administration — BIND

---

> **Reverse Engineering Approach:** In production, you will almost never set up a DNS server from scratch. You will inherit one that is silently failing — users report "the internet is down," applications cannot resolve internal hostnames, email delivery stalls, or DNSSEC validation errors fill the logs. This part teaches you to **read BIND configurations, decode cryptic error messages, interrogate DNS with dig/delv, and fix broken resolutions** — skills every sysadmin must have. You will build every major BIND configuration from the ground up, then deliberately break and repair each one.

---

## 🎯 What You Will Achieve

| Level | Focus | Key Skills |
|-------|-------|------------|
| **Level 1: Basic** | DNS concepts, BIND installation | Understanding DNS hierarchy, BIND overview, installing named |
| **Level 2: Intermediary** | Configuration, zones, slaves | named.conf, zone files, reverse DNS, slave servers, logging |
| **Level 3: Advanced** | DNSSEC, views, tuning | DNSSEC signing, split DNS, rate limiting, performance tuning |

---

## ⭐ Level 1: Basic — DNS Concepts and Installation

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

## 🔧 Section 2: Installation

### 2.1 Installing BIND9 on Ubuntu/Debian

```bash
sudo apt update && sudo apt install -y bind9 bind9utils bind9-doc dnsutils
```

| Package | Purpose |
|---------|---------|
| `bind9` | The named daemon |
| `bind9utils` | Tools: named-checkconf, named-checkzone, rndc, tsig-keygen |
| `bind9-doc` | HTML documentation in `/usr/share/doc/bind9/` |
| `dnsutils` | dig, nslookup, delv, nsupdate |

### 2.2 Check Installation

```bash
named -v
# BIND 9.18.28-1~deb12u1-Ubuntu (Extended Support Version)
```

### 2.3 The `/etc/bind/` Directory

```bash
tree /etc/bind/
```

```
/etc/bind/
├── bind.keys              # DNSSEC root trust anchor
├── db.0                   # Reverse delegation for broadcast
├── db.127                 # Reverse zone for 127.0.0.1
├── db.255                 # Reverse delegation for broadcast
├── db.empty               # Template for empty zones
├── db.local               # Forward zone for localhost
├── db.root                # Root hints
├── named.conf             # Main config (includes others)
├── named.conf.default-zones  # Default zones (localhost, root hints)
├── named.conf.local       # User-defined zones (edit this)
├── named.conf.options     # Options block (edit this)
└── zones.rfc1918          # Reverse zones for RFC 1918 IPs
```

### 2.4 Service Management

```bash
sudo systemctl status named    # Check status
sudo systemctl start named     # Start
sudo systemctl stop named      # Stop
sudo systemctl restart named   # Restart
sudo systemctl reload named    # Reload config (no downtime)
sudo systemctl enable named    # Enable at boot
```

**Always run syntax check before reload:**

```bash
sudo named-checkconf
sudo systemctl reload named
```

### 2.5 AppArmor Profile

Ubuntu installs an AppArmor profile restricting named to read `/etc/bind/`, write `/var/cache/bind/`, and read `/var/lib/bind/`.

```bash
sudo aa-status | grep named
sudo grep named /var/log/syslog | grep -i denied
```

Place zone files in `/var/cache/bind/` to avoid AppArmor issues, or update the profile.

---

## ⭐ Level 2: Intermediary — Configuration, Zones, and Slave DNS

## ⚙️ Section 3: Configuration — named.conf

### 3.1 The `options` Block

Defined in `/etc/bind/named.conf.options`:

```c
options {
    directory "/var/cache/bind";

    listen-on port 53 {
        192.168.1.10;
        10.0.0.1;
    };
    listen-on-v6 { none; };

    allow-query {
        192.168.0.0/16;
        10.0.0.0/8;
        localhost;
    };

    allow-recursion {
        192.168.0.0/16;
        10.0.0.0/8;
        localhost;
    };

    recursion yes;

    forwarders { 8.8.8.8; 1.1.1.1; };
    forward first;
    // "first" = try forwarders, then recurse
    // "only" = always use forwarders

    dnssec-validation auto;

    allow-transfer { none; };
    allow-update { none; };
    allow-notify { none; };

    rate-limit {
        responses-per-second 5;
        queries-per-second 10;
        slip 2;
    };

    max-cache-size 256m;
    recursive-clients 10000;
    tcp-clients 100;
};
```

### 3.2 Key Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `listen-on` | `{ any; }` | IPs and ports to bind |
| `allow-query` | `{ any; }` | Clients permitted to query |
| `allow-recursion` | `{ any; }` | Clients permitted to recurse |
| `allow-transfer` | `{ any; }` | Servers permitted to receive transfers |
| `recursion` | `yes` | Perform recursive resolution |
| `forwarders` | none | Upstream resolvers |
| `dnssec-validation` | `yes` | DNSSEC validation mode |
| `max-cache-size` | 90% RAM | Max DNS cache memory |
| `recursive-clients` | 1000 | Max simultaneous recursive queries |
| `rate-limit` | unlimited | Query rate limiting |
| `querylog` | `no` | Log every query |

### 3.3 Logging Configuration

```c
logging {
    channel default_log {
        file "/var/log/named/default.log" versions 3 size 10m;
        severity info;
        print-time yes;
        print-severity yes;
        print-category yes;
    };

    channel queries_file {
        file "/var/log/named/queries.log" versions 3 size 50m;
        severity info;
        print-time yes;
    };

    channel security_log {
        file "/var/log/named/security.log" versions 3 size 10m;
        severity info;
        print-time yes;
    };

    category default { default_log; };
    category security { security_log; };
    category queries { queries_file; };
    category xfer-in { default_log; };
    category xfer-out { default_log; };
    category notify { default_log; };
    category dnssec { default_log; };
    category lame-servers { default_log; };
    category network { security_log; };
};
```

**Logging severities (ascending):** `debug(1–3)` → `informational` → `notice` → `warning` → `error` → `critical`

```bash
sudo mkdir -p /var/log/named && sudo chown bind:bind /var/log/named && sudo chmod 750 /var/log/named
```

---

## 📋 Section 4: Zones

### 4.1 Zone Statement

Defined in `/etc/bind/named.conf.local`:

```c
// Primary (master) zone
zone "example.com" {
    type master;
    file "/etc/bind/db.example.com";
    allow-transfer { 192.168.1.20; };
    allow-update { none; };
    notify yes;
    also-notify { 192.168.1.20; };
};

// Secondary (slave) zone
zone "example.com" {
    type slave;
    file "/var/cache/bind/db.example.com";
    masters { 192.168.1.10; };
    allow-transfer { none; };
};

// Forward zone
zone "example.com" {
    type forward;
    forwarders { 8.8.8.8; 1.1.1.1; };
    forward only;
};

// Root hints
zone "." {
    type hint;
    file "/etc/bind/db.root";
};
```

### 4.2 Zone Types

| Type | Description | Has File? | Transfers? |
|------|-------------|-----------|------------|
| `master` | Primary authoritative | Yes (read/write) | Can transfer out |
| `slave` | Replica from master | Yes (auto-created) | Usually none |
| `forward` | Forwards queries for this zone | No | No |
| `hint` | Root hints | Yes (static) | No |
| `stub` | Copies only NS records | Yes (auto-created) | No |

---

## 📄 Section 5: Zone Files

### 5.1 Forward Zone File

```dns
; /etc/bind/db.example.com
$TTL    3600
$ORIGIN example.com.

@   IN  SOA  ns1.example.com.  admin.example.com. (
        2024061701  ; Serial (YYYYMMDDNN)
        3600        ; Refresh (1 hour)
        900         ; Retry (15 minutes)
        604800      ; Expire (7 days)
        86400       ; Minimum TTL / NXDOMAIN TTL
    )

; Nameservers
@       IN  NS      ns1.example.com.
@       IN  NS      ns2.example.com.

; A records
ns1     IN  A       192.168.1.10
ns2     IN  A       192.168.1.20
www     IN  A       192.168.1.100
mail    IN  A       192.168.1.101
ftp     IN  A       192.168.1.102
api     IN  A       192.168.1.103

; AAAA records
www     IN  AAAA    2001:db8::100

; CNAME records
blog    IN  CNAME   www.example.com.

; MX records — lower priority = preferred
@       IN  MX  10  mail.example.com.
@       IN  MX  20  mail2.example.com.

; TXT records
@       IN  TXT     "v=spf1 mx ~all"
_dmarc  IN  TXT     "v=DMARC1; p=quarantine; rua=mailto:dmarc@example.com"

; SRV records
_sip._tcp   IN  SRV  10 60 5060 sip.example.com.
```

### 5.2 SOA Record Fields

| Field | Name | Description |
|-------|------|-------------|
| `MNAME` | Master server | Primary NS FQDN |
| `RNAME` | Responsible person | Email (`@` → `.`) |
| `SERIAL` | Serial number | Increment on every change |
| `REFRESH` | Refresh | How often slaves check for updates |
| `RETRY` | Retry | How long to wait after failed refresh |
| `EXPIRE` | Expire | When slave stops serving zone |
| `MINIMUM` | Minimum TTL | NXDOMAIN negative caching TTL |

Serial format: `YYYYMMDDNN` (e.g., `2024061701`). Use `date +%Y%m%d%H` to generate.

### 5.3 Record Types Quick Reference

| Record | Purpose | Example |
|--------|---------|---------|
| `SOA` | Start of Authority | `@ IN SOA ns1.example.com. admin.example.com. ( ... )` |
| `NS` | Nameserver delegation | `@ IN NS ns1.example.com.` |
| `A` | IPv4 address | `www IN A 192.168.1.100` |
| `AAAA` | IPv6 address | `www IN AAAA 2001:db8::100` |
| `CNAME` | Canonical name (alias) | `blog IN CNAME www.example.com.` |
| `MX` | Mail exchanger | `@ IN MX 10 mail.example.com.` |
| `TXT` | Text record | `@ IN TXT "v=spf1 mx ~all"` |
| `SRV` | Service location | `_sip._tcp IN SRV 10 60 5060 sip.example.com.` |
| `PTR` | Reverse pointer | `100 IN PTR www.example.com.` |
| `CAA` | Certification Authority Auth | `@ IN CAA 0 issue "letsencrypt.org"` |

### 5.4 `$ORIGIN` and `$TTL`

**`$ORIGIN`** sets the default domain suffix. Unqualified names (no trailing `.`) are appended:

```dns
$ORIGIN example.com.
www   IN A 192.168.1.100   ; Means www.example.com
www.example.com. IN A 192.168.1.100   ; FQDN (trailing dot) — literal
```

**`$TTL`** sets the default TTL. Individual records can override:

```dns
$TTL 3600
critical  IN A 86400 192.168.1.200   ; 24-hour TTL override
```

---

## 🔄 Section 6: Reverse DNS

### 6.1 Reverse Zone Naming

Reverse zones use `in-addr.arpa` (IPv4) and `ip6.arpa` (IPv6). IP octets are reversed:

| Subnet | Reverse Zone Name |
|--------|-------------------|
| `192.168.1.0/24` | `1.168.192.in-addr.arpa` |
| `10.0.0.0/8` | `0.0.10.in-addr.arpa` |
| `2001:db8::/32` | `8.b.d.0.1.0.0.2.ip6.arpa` |

### 6.2 Reverse Zone for /24

```c
// In named.conf.local
zone "1.168.192.in-addr.arpa" {
    type master;
    file "/etc/bind/db.192.168.1";
};
```

```dns
; /etc/bind/db.192.168.1
$TTL 3600
$ORIGIN 1.168.192.in-addr.arpa.

@   IN  SOA  ns1.example.com.  admin.example.com. (
        2024061701
        3600
        900
        604800
        86400
    )

@       IN  NS      ns1.example.com.
@       IN  NS      ns2.example.com.

; Host portion only
10      IN  PTR     ns1.example.com.
20      IN  PTR     ns2.example.com.
100     IN  PTR     www.example.com.
101     IN  PTR     mail.example.com.
```

### 6.3 Verification

```bash
dig -x 192.168.1.100 +short
# www.example.com.

host 192.168.1.100
# 100.1.168.192.in-addr.arpa domain name pointer www.example.com.
```

### 6.4 Large Subnets with `$GENERATE`

```dns
; Generate PTR records for 10.0.0.0/24
$GENERATE 1-254 $ IN PTR host-10-0-0-$.example.com.
```

---

## 🔁 Section 7: Slave/Secondary DNS

### 7.1 Purpose of Slaves

- Redundancy (master goes down, slaves still answer)
- Geographic distribution
- Load distribution
- ICANN requires ≥2 NS for domain delegation

### 7.2 Transfer Types

| Type | Description |
|------|-------------|
| **AXFR** | Full zone transfer (entire zone) |
| **IXFR** | Incremental transfer (only changed records) |

### 7.3 Master Configuration

```c
zone "example.com" {
    type master;
    file "/etc/bind/db.example.com";
    allow-transfer { 192.168.1.20; };
    notify yes;
    also-notify { 192.168.1.20; };
};
```

### 7.4 Slave Configuration

```c
zone "example.com" {
    type slave;
    file "/var/cache/bind/db.example.com";
    masters { 192.168.1.10; };
    allow-transfer { none; };
};
```

Slave zone files go in `/var/cache/bind/` (AppArmor allows write there).

### 7.5 TSIG Key for Secure Transfers

Generate key:

```bash
sudo tsig-keygen -a hmac-sha256 xfer-key > /etc/bind/keys.conf
sudo chmod 640 /etc/bind/keys.conf
```

On master — include key, restrict `allow-transfer`:

```c
include "/etc/bind/keys.conf";

zone "example.com" {
    type master;
    file "/etc/bind/db.example.com";
    allow-transfer { key xfer-key; };
    notify yes;
};
```

On slave — copy `keys.conf` and reference key in `masters`:

```c
include "/etc/bind/keys.conf";

zone "example.com" {
    type slave;
    file "/var/cache/bind/db.example.com";
    masters { 192.168.1.10 key xfer-key; };
};
```

### 7.6 Verification

```bash
dig @192.168.1.10 example.com AXFR +short   # Should fail (REFUSED)
dig @192.168.1.20 www.example.com +short     # Should return 192.168.1.100
sudo rndc retransfer example.com             # Force transfer on slave
```

---

## ⭐ Level 3: Advanced — DNSSEC, Access Control, and Tuning

## 🔐 Section 8: DNSSEC

### 8.1 What DNSSEC Does

DNSSEC cryptographically signs DNS records so resolvers verify **authenticity** and **integrity**. It does **not** provide confidentiality.

### 8.2 Key Components

| Component | Purpose |
|-----------|---------|
| **KSK** | Key Signing Key (4096-bit RSA) — signs DNSKEY set |
| **ZSK** | Zone Signing Key (2048-bit RSA) — signs all other records |
| **RRSIG** | Digital signature for each record set |
| **DNSKEY** | Public keys published in the zone |
| **DS** | Delegation Signer — hash of KSK in parent zone |
| **NSEC/NSEC3** | Authenticated denial of existence |

### 8.3 Chain of Trust

```
Root DNSKEY (trust anchor in bind.keys)
  └─ . DS → TLD KSK
      └─ example.com DS → example.com KSK
          └─ DNSKEY set (signed by KSK)
              └─ RRSIG over A, MX, NS, etc. (signed by ZSK)
```

### 8.4 Signing a Zone Manually

**Generate keys:**

```bash
cd /etc/bind
dnssec-keygen -a RSASHA256 -b 2048 -n ZONE example.com      # ZSK
dnssec-keygen -a RSASHA256 -b 4096 -n ZONE -f KSK example.com  # KSK
```

**Add key includes to zone file:**

```dns
$INCLUDE /etc/bind/Kexample.com.+008+NNNNN.key   ; ZSK
$INCLUDE /etc/bind/Kexample.com.+008+MMMMM.key   ; KSK
```

**Sign:**

```bash
dnssec-signzone -A -3 $(head -c 16 /dev/urandom | xxd -p) \
    -N INCREMENT -o example.com -t /etc/bind/db.example.com
```

**Point to signed file:**

```c
zone "example.com" {
    type master;
    file "/etc/bind/db.example.com.signed";
};
```

**Submit DS record to parent/registrar:**

```bash
cat /etc/bind/dsset-example.com.
# example.com. IN DS 12345 8 2 ABCDEF1234567890...
```

### 8.5 DNSSEC Validation

```c
options {
    dnssec-validation auto;   // Uses bind.keys for root trust anchor
};
```

### 8.6 Checking DNSSEC

```bash
delv www.example.com +short       # Validated lookup
dig www.example.com +dnssec +multi # Show RRSIG
dig www.example.com +dnssec        # Check AD flag
dig www.example.com +cd +short     # Bypass validation (checking disabled)
sudo rndc secroots                 # Show trust anchors
```

### 8.7 Automated DNSSEC (BIND 9.16+)

```c
zone "example.com" {
    type master;
    file "/etc/bind/db.example.com";
    dnssec-policy default;
    inline-signing yes;
};
```

---

## 🛡️ Section 9: Access Control

### 9.1 ACL Definitions

```c
acl internal {
    192.168.0.0/16;
    10.0.0.0/8;
    172.16.0.0/12;
    localhost;
};

acl slaves {
    192.168.1.20;
    10.10.0.10;
};

options {
    allow-query { internal; };
    allow-recursion { internal; };
    allow-transfer { none; };
};
```

### 9.2 Using ACLs

```c
zone "example.com" {
    type master;
    file "/etc/bind/db.example.com";
    allow-query { any; };
    allow-transfer { slaves; };
    allow-update { admin; };
};
```

### 9.3 Views (Split DNS)

Serve different data based on client IP:

```c
acl internal-clients {
    192.168.0.0/16;
    10.0.0.0/8;
    localhost;
};

view "internal" {
    match-clients { internal-clients; };
    recursion yes;

    zone "example.com" {
        type master;
        file "/etc/bind/internal/db.example.com";
    };
};

view "external" {
    match-clients { any; };
    recursion no;

    zone "example.com" {
        type master;
        file "/etc/bind/external/db.example.com";
    };
};
```

**Internal zone file** (private IPs):
```dns
www  IN A 192.168.1.100
mail IN A 192.168.1.101
```

**External zone file** (public IPs):
```dns
www  IN A 203.0.113.100
mail IN A 203.0.113.101
```

**Rules:** More-specific views first; all zones must be in a view; root hints in every view.

### 9.4 Restricting Recursion

Open recursion enables DNS amplification attacks:

```c
options {
    recursion yes;
    allow-recursion { 192.168.0.0/16; 10.0.0.0/8; localhost; };
};
```

```bash
dig @YOUR_SERVER_IP www.google.com   # Should fail from external
```

---

## 📝 Section 10: Logging

### 10.1 Query Logging

**Config method:**

```c
options { querylog yes; };
```

**Runtime toggle:**

```bash
sudo rndc querylog on
sudo rndc querylog off
```

Query log format:
```
24-Jun-2026 14:32:15.123 queries: client 192.168.1.100#54321 (www.google.com): query: www.google.com IN A + (192.168.1.10)
```

### 10.2 Log Rotation

Built-in: `file "path.log" versions 3 size 50m;`

External logrotate (`/etc/logrotate.d/named`):

```bash
/var/log/named/*.log {
    daily
    rotate 30
    compress
    delaycompress
    postrotate
        /usr/sbin/rndc reload 2>&1 > /dev/null || true
    endscript
}
```

### 10.3 Debugging with rndc

```bash
sudo rndc trace 3           # Set debug level
sudo rndc notrace           # Disable debugging
sudo rndc dumpdb -cache     # Dump cache to file
sudo rndc stats             # Dump statistics
sudo journalctl -u named -f # Follow live logs
```

---

## ⚡ Section 11: Tuning and Performance

```c
options {
    max-cache-size 512m;           // Max cache memory
    max-cache-ttl 86400;           // Max cached record TTL
    recursive-clients 10000;       // Max recursive queries
    tcp-clients 150;               // Max TCP connections
    transfers-in 10;               // Concurrent incoming transfers
    transfers-out 10;              // Concurrent outgoing transfers
    edns-udp-size 1232;            // EDNS UDP size (avoid fragmentation)
    max-udp-size 1232;
    prefetch 10 15;                // Refresh when TTL ≤ 10s

    rate-limit {
        responses-per-second 10;
        queries-per-second 20;
        slip 2;
    };
};
```

BIND 9 uses a **task manager** with N worker threads (default = CPU count). Each query becomes multiple events: parse → cache lookup → recurse → validate → respond.

---

## 🔍 Section 12: Troubleshooting

### 12.1 Syntax Checking

```bash
sudo named-checkconf                               # Check named.conf
sudo named-checkzone example.com /etc/bind/db.example.com   # Check zone
sudo named-checkzone -s example.com db.example.com.signed   # Check signed zone
```

**Common named-checkzone errors:**

| Error | Meaning |
|-------|---------|
| `has no NS records` | Needs at least one NS record |
| `CNAME and other data` | CNAME cannot coexist with other records |
| `bad FQDN` | Missing trailing dot |
| `out of zone` | Data outside $ORIGIN scope |

### 12.2 DNS Query Tools

```bash
dig example.com +short              # Basic query, short answer
dig example.com MX +short           # MX records
dig example.com +trace              # Trace delegation chain
dig @192.168.1.10 example.com       # Query specific NS
dig -x 192.168.1.100                # Reverse lookup
dig www.example.com +dnssec +multi  # DNSSEC records
dig www.example.com +cd +short      # Bypass DNSSEC validation

delv www.example.com +short         # DNSSEC-validated lookup
host www.example.com                # Simple lookup
```

### 12.3 Common Errors

| Error | Meaning | Common Causes |
|-------|---------|---------------|
| **REFUSED** | Server refused query | `allow-query` or recursion restriction |
| **SERVFAIL** | Server failure | Zone load error, DNSSEC failure, upstream timeout |
| **NXDOMAIN** | Domain does not exist | Typo, missing zone data |
| **timeout** | No response | Firewall, network, server not listening |

### 12.4 Diagnosing SERVFAIL

```bash
# Step 1: Check zone loads
sudo named-checkzone example.com /etc/bind/db.example.com

# Step 2: Test with DNSSEC disabled
dig www.example.com +cd +short
# If this works → DNSSEC issue

# Step 3: Test directly against authoritative
dig @192.168.1.10 www.example.com +short

# Step 4: Check logs
sudo journalctl -u named -n 50 | grep -i error
```

### 12.5 rndc Runtime Commands

```bash
sudo rndc status                    # Server status
sudo rndc reload                    # Reload all zones
sudo rndc reload example.com        # Reload one zone
sudo rndc flush                     # Flush entire cache
sudo rndc flushname example.com     # Flush specific domain
sudo rndc reconfig                  # Reload named.conf only
sudo rndc querylog on               # Enable query logging
sudo rndc trace 3                   # Set debug level
sudo rndc notrace                   # Disable debug
sudo rndc dumpdb -cache             # Dump cache
sudo rndc stats                     # Dump statistics
sudo rndc secroots                  # Show DNSSEC trust anchors
sudo rndc freeze example.com        # Freeze dynamic zone for editing
sudo rndc thaw example.com          # Thaw dynamic zone
sudo rndc retransfer example.com    # Force zone transfer
sudo rndc notify example.com        # Send NOTIFY
```

---

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

## 💻 Section 14: 15 Hands-On Practices

### ⭐ Level 1: Basic Practices

#### Practice 1: Install BIND9

```bash
sudo apt update && sudo apt install -y bind9 bind9utils dnsutils
named -v
sudo systemctl status named
sudo systemctl enable named
ls -la /etc/bind/
```

**Verify:** `sudo systemctl is-active named` → `active`

---

### ⭐ Level 2: Intermediary Practices

#### Practice 2: Configure Caching-Only DNS

```bash
sudo tee /etc/bind/named.conf.options << 'EOF'
options {
    directory "/var/cache/bind";
    listen-on port 53 { 127.0.0.1; 192.168.1.10; };
    listen-on-v6 { none; };
    allow-query { localhost; 192.168.1.0/24; };
    allow-recursion { localhost; 192.168.1.0/24; };
    recursion yes;
    forwarders { 8.8.8.8; 1.1.1.1; };
    forward first;
    dnssec-validation auto;
    allow-transfer { none; };
};
EOF
sudo named-checkconf && sudo systemctl reload named
dig @192.168.1.10 www.google.com +short
```

---

#### Practice 3: Create Primary Zone for example.com

```bash
sudo tee /etc/bind/named.conf.local << 'EOF'
zone "example.com" {
    type master;
    file "/etc/bind/db.example.com";
    allow-transfer { none; };
};
EOF

sudo tee /etc/bind/db.example.com << 'EOF'
$TTL 3600
$ORIGIN example.com.
@   IN  SOA  ns1.example.com.  admin.example.com. (
        2024061701 ; Serial
        3600 900 604800 86400 )
@       IN  NS      ns1.example.com.
@       IN  NS      ns2.example.com.
ns1     IN  A       192.168.1.10
ns2     IN  A       192.168.1.20
www     IN  A       192.168.1.100
mail    IN  A       192.168.1.101
@       IN  MX  10  mail.example.com.
@       IN  TXT     "v=spf1 mx ~all"
EOF

sudo named-checkzone example.com /etc/bind/db.example.com
sudo named-checkconf && sudo systemctl reload named
dig @192.168.1.10 www.example.com +short
```

---

#### Practice 4: Add DNS Records

```bash
# Append to zone file
sudo tee -a /etc/bind/db.example.com << 'EOF'
blog    IN  CNAME   www.example.com.
ftp     IN  A       192.168.1.102
api     IN  A       192.168.1.103
www     IN  AAAA    2001:db8::100
_sip._tcp   IN  SRV  10 60 5060 sip.example.com.
sip     IN  A       192.168.1.110
EOF

# Increment serial
sudo sed -i 's/2024061701/2024061702/' /etc/bind/db.example.com

sudo named-checkzone example.com /etc/bind/db.example.com
sudo systemctl reload named
dig @192.168.1.10 blog.example.com CNAME +short
dig @192.168.1.10 _sip._tcp.example.com SRV +short
```

---

#### Practice 5: Create Reverse Zone

```bash
sudo tee -a /etc/bind/named.conf.local << 'EOF'

zone "1.168.192.in-addr.arpa" {
    type master;
    file "/etc/bind/db.192.168.1";
};
EOF

sudo tee /etc/bind/db.192.168.1 << 'EOF'
$TTL 3600
$ORIGIN 1.168.192.in-addr.arpa.
@   IN  SOA  ns1.example.com.  admin.example.com. (
        2024061701 3600 900 604800 86400 )
@       IN  NS      ns1.example.com.
@       IN  NS      ns2.example.com.
10      IN  PTR     ns1.example.com.
20      IN  PTR     ns2.example.com.
100     IN  PTR     www.example.com.
101     IN  PTR     mail.example.com.
EOF

sudo named-checkzone 1.168.192.in-addr.arpa /etc/bind/db.192.168.1
sudo systemctl reload named
dig -x 192.168.1.100 +short
```

---

#### Practice 6: Set Up Slave DNS

On master (192.168.1.10):

```bash
sudo tee /etc/bind/named.conf.local << 'EOF'
zone "example.com" {
    type master;
    file "/etc/bind/db.example.com";
    allow-transfer { 192.168.1.20; };
    notify yes;
};
zone "1.168.192.in-addr.arpa" {
    type master;
    file "/etc/bind/db.192.168.1";
    allow-transfer { 192.168.1.20; };
    notify yes;
};
EOF
sudo systemctl reload named
```

On slave (192.168.1.20):

```bash
sudo apt install -y bind9 bind9utils
sudo tee /etc/bind/named.conf.local << 'EOF'
zone "example.com" {
    type slave;
    file "/var/cache/bind/db.example.com";
    masters { 192.168.1.10; };
};
zone "1.168.192.in-addr.arpa" {
    type slave;
    file "/var/cache/bind/db.192.168.1";
    masters { 192.168.1.10; };
};
EOF
sudo named-checkconf && sudo systemctl reload named
ls -la /var/cache/bind/db.example.com
dig @192.168.1.20 www.example.com +short
```

---

#### Practice 7: TSIG Key for Zone Transfers

```bash
# On master
sudo tsig-keygen -a hmac-sha256 xfer-key > /etc/bind/keys.conf
sudo chmod 640 /etc/bind/keys.conf
echo 'include "/etc/bind/keys.conf";' | sudo tee -a /etc/bind/named.conf

sudo tee /etc/bind/named.conf.local << 'EOF'
include "/etc/bind/keys.conf";
zone "example.com" {
    type master;
    file "/etc/bind/db.example.com";
    allow-transfer { key xfer-key; };
    notify yes;
};
EOF

# Copy to slave: scp /etc/bind/keys.conf root@192.168.1.20:/etc/bind/
# On slave:
sudo tee /etc/bind/named.conf.local << 'EOF'
include "/etc/bind/keys.conf";
zone "example.com" {
    type slave;
    file "/var/cache/bind/db.example.com";
    masters { 192.168.1.10 key xfer-key; };
};
EOF
sudo systemctl reload named

# Verify — AXFR without key is refused
dig @192.168.1.10 example.com AXFR +short
```

---

#### Practice 8: Enable Query Logging

```bash
echo 'querylog yes;' | sudo tee -a /etc/bind/named.conf.options

sudo mkdir -p /var/log/named && sudo chown bind:bind /var/log/named
sudo tee -a /etc/bind/named.conf << 'EOF'
logging {
    channel queries_file {
        file "/var/log/named/queries.log" versions 3 size 50m;
        severity info; print-time yes;
    };
    category queries { queries_file; };
};
EOF

sudo named-checkconf && sudo systemctl reload named
sudo tail -f /var/log/named/queries.log
```

---

#### Practice 9: Use dig and delv

```bash
dig example.com NS +short
dig example.com MX +short
dig example.com SOA +short
dig example.com +trace
dig -x 8.8.8.8 +short
delv www.example.com +short
dig www.example.com +noall +flags   # Check AD flag
```

---

### ⭐ Level 3: Advanced Practices

#### Practice 10: Sign Zone with DNSSEC

```bash
cd /etc/bind
dnssec-keygen -a RSASHA256 -b 2048 -n ZONE example.com         # ZSK
dnssec-keygen -a RSASHA256 -b 4096 -n ZONE -f KSK example.com  # KSK

echo '$INCLUDE Kexample.com.+008+*.key' >> /etc/bind/db.example.com

dnssec-signzone -A -3 $(head -c 16 /dev/urandom | xxd -p) \
    -N INCREMENT -o example.com -t /etc/bind/db.example.com

sudo tee /etc/bind/named.conf.local << 'EOF'
zone "example.com" {
    type master;
    file "/etc/bind/db.example.com.signed";
};
EOF

sudo systemctl reload named
dig @192.168.1.10 www.example.com +dnssec +multi | grep RRSIG
cat /etc/bind/dsset-example.com.
```

---

#### Practice 11: Split DNS with Views

```bash
sudo mkdir -p /etc/bind/internal /etc/bind/external

sudo tee /etc/bind/internal/db.example.com << 'EOF'
$TTL 3600
$ORIGIN example.com.
@   IN  SOA  ns1.example.com.  admin.example.com. (2024061701 3600 900 604800 86400)
@      IN  NS   ns1.example.com.
ns1    IN  A    192.168.1.10
www    IN  A    192.168.1.100
mail   IN  A    192.168.1.101
EOF

sudo tee /etc/bind/external/db.example.com << 'EOF'
$TTL 3600
$ORIGIN example.com.
@   IN  SOA  ns1.example.com.  admin.example.com. (2024061701 3600 900 604800 86400)
@      IN  NS   ns1.example.com.
ns1    IN  A    203.0.113.10
www    IN  A    203.0.113.100
mail   IN  A    203.0.113.101
EOF

sudo tee /etc/bind/named.conf << 'EOF'
include "/etc/bind/named.conf.options";

acl internal-net { 192.168.0.0/16; 10.0.0.0/8; localhost; };

view "internal" {
    match-clients { internal-net; };
    recursion yes;
    zone "example.com" { type master; file "/etc/bind/internal/db.example.com"; };
    include "/etc/bind/named.conf.default-zones";
};

view "external" {
    match-clients { any; };
    recursion no;
    zone "example.com" { type master; file "/etc/bind/external/db.example.com"; };
    zone "." { type hint; file "/etc/bind/db.root"; };
};
EOF

sudo named-checkconf && sudo systemctl reload named
dig @192.168.1.10 www.example.com +short   # 192.168.1.100
```

---

#### Practice 12: Rate Limiting

```bash
sudo tee -a /etc/bind/named.conf.options << 'EOF'
rate-limit {
    responses-per-second 5;
    queries-per-second 10;
    slip 2;
    window 15;
};
EOF

sudo named-checkconf && sudo systemctl reload named
# Test with rapid queries: for i in $(seq 1 100); do dig @127.0.0.1 example.com +short & done
```

---

#### Practice 13: Zone Transfer Troubleshooting

```bash
# Check serials match
MASTER_SERIAL=$(dig @192.168.1.10 example.com SOA +short | awk '{print $1}')
SLAVE_SERIAL=$(dig @192.168.1.20 example.com SOA +short | awk '{print $1}')
echo "Master: $MASTER_SERIAL  Slave: $SLAVE_SERIAL"

# Test AXFR
dig @192.168.1.10 example.com AXFR +short

# Check logs
sudo journalctl -u named -n 20 | grep -i "xfer"

# Force retransfer
sudo rndc retransfer example.com
```

---

#### Practice 14: DNSSEC Validation Debugging

```bash
# 1. Check time sync
timedatectl status | grep "NTP service"

# 2. Bypass DNSSEC
dig www.example.com +cd +short

# 3. Check key timing
cd /etc/bind && dnssec-settime -p all Kexample.com.*.key

# 4. Check trust anchors
sudo rndc secroots

# 5. Check validation
sudo rndc validation-status

# 6. Check logs
sudo journalctl -u named | grep -i "dnssec\|validation"
```

---

#### Practice 15: Real-World Integration — Full Authoritative DNS with DNSSEC and Slave

**Objective:** Deploy production-ready DNS: authoritative master with DNSSEC, TSIG-secured transfers to slave.

**Architecture:**
```
Master 192.168.1.10  ─── TSIG ───→  Slave 192.168.1.20
```

**Phase 1 — Master:**

```bash
# /etc/bind/named.conf.options
sudo tee /etc/bind/named.conf.options << 'OPT'
options {
    directory "/var/cache/bind";
    listen-on port 53 { 127.0.0.1; 192.168.1.10; };
    listen-on-v6 { none; };
    allow-query { any; };
    allow-recursion { 192.168.1.0/24; 127.0.0.0/8; };
    recursion yes;
    dnssec-validation auto;
    allow-transfer { none; };
    rate-limit { responses-per-second 10; queries-per-second 20; slip 2; };
};
OPT

# Generate TSIG key
sudo tsig-keygen -a hmac-sha256 xfer-key | sudo tee /etc/bind/keys.conf

# Zone definitions
sudo tee /etc/bind/named.conf.local << 'LOC'
include "/etc/bind/keys.conf";
zone "example.com" {
    type master;
    file "/etc/bind/db.example.com.signed";
    allow-transfer { key xfer-key; };
    notify yes; also-notify { 192.168.1.20; };
};
zone "1.168.192.in-addr.arpa" {
    type master;
    file "/etc/bind/db.192.168.1";
    allow-transfer { key xfer-key; };
    notify yes; also-notify { 192.168.1.20; };
};
LOC

# Zone file with DNSSEC
sudo tee /etc/bind/db.example.com << 'EOF'
$TTL 3600
$ORIGIN example.com.
@   IN  SOA  ns1.example.com.  admin.example.com. (2024061701 3600 900 604800 86400)
@      IN  NS   ns1.example.com.
@      IN  NS   ns2.example.com.
ns1    IN  A    192.168.1.10
ns2    IN  A    192.168.1.20
www    IN  A    192.168.1.100
mail   IN  A    192.168.1.101
@      IN  MX  10  mail.example.com.
@      IN  TXT  "v=spf1 mx -all"
EOF

# DNSSEC
cd /etc/bind
dnssec-keygen -a RSASHA256 -b 2048 -n ZONE example.com
dnssec-keygen -a RSASHA256 -b 4096 -n ZONE -f KSK example.com
echo '$INCLUDE Kexample.com.+008+*.key' >> /etc/bind/db.example.com
dnssec-signzone -A -3 $(head -c 16 /dev/urandom | xxd -p) \
    -N INCREMENT -o example.com -t /etc/bind/db.example.com

# Reverse zone
sudo tee /etc/bind/db.192.168.1 << 'REV'
$TTL 3600
$ORIGIN 1.168.192.in-addr.arpa.
@   IN  SOA  ns1.example.com.  admin.example.com. (2024061701 3600 900 604800 86400)
@      IN  NS   ns1.example.com.
@      IN  NS   ns2.example.com.
10     IN  PTR  ns1.example.com.
20     IN  PTR  ns2.example.com.
100    IN  PTR  www.example.com.
101    IN  PTR  mail.example.com.
REV

sudo named-checkconf && sudo systemctl reload named
```

**Phase 2 — Slave (192.168.1.20):**

```bash
sudo apt install -y bind9
# Copy TSIG key from master: scp 192.168.1.10:/etc/bind/keys.conf /etc/bind/

sudo tee /etc/bind/named.conf.local << 'LOC'
include "/etc/bind/keys.conf";
zone "example.com" {
    type slave; file "/var/cache/bind/db.example.com";
    masters { 192.168.1.10 key xfer-key; };
};
zone "1.168.192.in-addr.arpa" {
    type slave; file "/var/cache/bind/db.192.168.1";
    masters { 192.168.1.10 key xfer-key; };
};
zone "." { type hint; file "/etc/bind/db.root"; };
LOC

sudo named-checkconf && sudo systemctl restart named
```

**Phase 3 — Verification:**

```bash
dig @192.168.1.20 www.example.com +short        # 192.168.1.100
delv @192.168.1.10 www.example.com +short       # Validated
dig @192.168.1.10 example.com AXFR +short       # REFUSED (TSIG required)
dig -x 192.168.1.100 +short                     # www.example.com.
cat /etc/bind/dsset-example.com.                # DS record for registrar

# Health check script
sudo tee /usr/local/bin/dns-check.sh << 'SCRIPT'
#!/bin/bash
ZONE="example.com"; M="192.168.1.10"; S="192.168.1.20"
dig @$M $ZONE SOA +short +timeout=5 > /dev/null || echo "CRIT: Master down"
dig @$S $ZONE SOA +short +timeout=5 > /dev/null || echo "CRIT: Slave down"
MS=$(dig @$M $ZONE SOA +short 2>/dev/null | awk '{print $1}')
SS=$(dig @$S $ZONE SOA +short 2>/dev/null | awk '{print $1}')
[ "$MS" != "$SS" ] && echo "WARN: Serial mismatch M:$MS S:$SS"
SCRIPT
sudo chmod +x /usr/local/bin/dns-check.sh
```

---

## 🧠 Deep Understanding

### How BIND Processes Queries (Recursive Resolver)

```
Client query (www.example.com A)
        │
        ▼
┌─────────────────────┐
│ 1. Query validation │  ← allow-query, rate-limit check
└─────────┬───────────┘
          ▼
┌─────────────────────┐
│ 2. Cache lookup     │  ← Already cached?
└─────────┬───────────┘
     ┌────┴────┐
     │  HIT    │  ← Return cached answer (subtract TTL)
     │ (cache) │
     └─────────┘
          │ MISS
          ▼
┌─────────────────────┐
│ 3. Recursion check  │  ← Is recursion allowed for client?
└─────────┬───────────┘
          ▼
┌─────────────────────┐
│ 4. Iterative query  │  ← Root → TLD → Authoritative
└─────────┬───────────┘
          ▼
┌─────────────────────┐
│ 5. DNSSEC validation │  ← Validate RRSIG (if DO bit set)
└─────────┬───────────┘
          ▼
┌─────────────────────┐
│ 6. Cache result     │  ← Store with TTL
└─────────┬───────────┘
          ▼
┌─────────────────────┐
│ 7. Return answer    │  ← With AD flag if DNSSEC validated
└─────────────────────┘
```

### Delegation and NS Resolution Flow

```
1. Query root (.) → "Where is .com?"
   → Root returns NS a.gtld-servers.net (+ glue A)

2. Query .com TLD → "Where is example.com?"
   → TLD returns NS ns1.example.com (+ glue A 192.168.1.10)

3. Query ns1.example.com → "What is www.example.com?"
   → Authoritative returns www.example.com A 192.168.1.100

4. Optionally fetch DNSKEY → validate RRSIG

5. Cache and return
```

`dig +trace` shows this exact chain.

### Zone Transfer Protocol

```
Master                          Slave
  │                               │
  │─── NOTIFY (example.com) ─────>│
  │<── SOA query ─────────────────│
  │─── SOA response (serial X) ──>│
  │                               │  (Slave compares serials)
  │<── AXFR/IXFR request ─────────│
  │─── Zone data (TCP 53) ───────>│
  │─── SOA (end of transfer) ────>│
  │                               │  (Slave loads zone)
```

- **AXFR:** Full transfer via TCP, all records sent sequentially
- **IXFR:** Incremental — only changed records (requires journal files)
- **NOTIFY:** Master sends notification; slave checks SOA serial and initiates transfer if needed

### DNSSEC Chain of Trust

```
Root DNSKEY (bind.keys — built-in trust anchor)
  └─ signed by Root KSK
      └─ Root DS for .com
          └─ .com DNSKEY (signed by .com KSK)
              └─ .com DS for example.com
                  └─ example.com DNSKEY
                      ├── KSK (signs DNSKEY set, verified by parent DS)
                      └── ZSK (signs all other records, verified by KSK)

Query flow:
  1. Fetch www.example.com + RRSIG
  2. Fetch example.com DNSKEY
  3. Validate RRSIG with ZSK from DNSKEY
  4. Validate ZSK with KSK (via RRSIG DNSKEY)
  5. Validate KSK with DS from .com
  6. Validate .com DNSKEY with .com DS from root
  7. Root KSK trusted via bind.keys
  → Chain of trust established ✓
```

### BIND Task Manager / Event Loop

BIND 9 uses an internal **task manager** with N worker threads (default = CPU count):

```
┌──────────────────────────────────────────┐
│           Task Manager                    │
│  Task Queue: ┌───┬───┬───┬───┬───┐      │
│              │ T │ T │ T │ T │ T │ ...  │
│              └───┴───┴───┴───┴───┘      │
│        ┌───────┴───────┬───────┘        │
│        ▼               ▼                │
│  ┌──────────┐    ┌──────────┐           │
│  │ Thread 1 │    │ Thread 2 │   ...     │
│  │ (Worker) │    │ (Worker) │           │
│  └──────────┘    └──────────┘           │
│        │               │                │
│  ┌──────────┐    ┌──────────┐           │
│  │ Socket   │    │ Socket   │           │
│  │ I/O      │    │ I/O      │           │
│  └──────────┘    └──────────┘           │
└──────────────────────────────────────────┘
```

Each query becomes multiple **events** dispatched within a task:
1. Parse incoming query
2. Cache lookup (non-blocking)
3. If recursion: dispatch upstream sub-queries
4. Wait for responses (async I/O)
5. Validate DNSSEC
6. Cache and respond

This non-blocking event model allows BIND to handle thousands of concurrent queries with few threads.

---

## 🚀 What's Coming in Part 43

**Part 43: DHCP Server** — ISC DHCP server configuration, subnet declarations, option sets, static leases, DHCP relay, DDNS integration, troubleshooting DHCP failures (no offer, bad options, IP conflicts).

---

## 📝 Self-Test: 15 Questions

**Score 12/15 correct = ready for Part 43.**

**Q1:** What is the difference between an authoritative-only BIND server and a recursive resolver?

<details>
<summary>Answer</summary>
Authoritative-only serves configured zones and refuses recursion. Recursive resolvers query upstream servers for clients and cache results. Authoritative uses `recursion no`; recursive uses `recursion yes` with restricted `allow-recursion`.
</details>

**Q2:** What three things must you do after modifying a zone file?

<details>
<summary>Answer</summary>
1. Increment the SOA serial number. 2. Run `named-checkzone <zone> <file>`. 3. Run `sudo rndc reload` or `sudo systemctl reload named`.
</details>

**Q3:** What does `$ORIGIN` do in a zone file?

<details>
<summary>Answer</summary>
Sets the default domain suffix. Unqualified names (no trailing dot) have `$ORIGIN` appended: `$ORIGIN example.com.` makes `www` become `www.example.com.`
</details>

**Q4:** How do you set up reverse DNS for `192.168.1.0/24`? What is the zone name?

<details>
<summary>Answer</summary>
Zone name: `1.168.192.in-addr.arpa`. Create zone statement with `type master` and a zone file containing PTR records mapping host portions (e.g., `100 IN PTR www.example.com.`).
</details>

**Q5:** What is the difference between AXFR and IXFR?

<details>
<summary>Answer</summary>
AXFR transfers the entire zone. IXFR transfers only changed records (incremental). IXFR is more efficient for large zones.
</details>

**Q6:** What does TSIG provide for zone transfers?

<details>
<summary>Answer</summary>
Cryptographic authentication via HMAC shared secret. Ensures only authorized servers receive zone data, preventing data leakage.
</details>

**Q7:** In DNSSEC, what is the difference between KSK and ZSK?

<details>
<summary>Answer</summary>
KSK (Key Signing Key, 4096-bit) signs the DNSKEY set; its fingerprint is published in the parent zone as a DS record. ZSK (Zone Signing Key, 2048-bit) signs all other records. ZSK can be rolled over more frequently without parent involvement.
</details>

**Q8:** How does `dig +trace` work?

<details>
<summary>Answer</summary>
Simulates full resolution from root servers: queries root → TLD → authoritative, printing delegation at each step. Reveals where resolution succeeds or fails.
</details>

**Q9:** What does SERVFAIL typically indicate?

<details>
<summary>Answer</summary>
Server failure: zone file error (zone not loaded), DNSSEC validation failure, upstream timeout, or resource exhaustion.
</details>

**Q10:** How do you restrict zone transfers to trusted slaves?

<details>
<summary>Answer</summary>
Use `allow-transfer` in zone statement with IP addresses or TSIG key. Set `allow-transfer { none; };` in global options as default.
</details>

**Q11:** What does `rndc flush` do?

<details>
<summary>Answer</summary>
Clears all cached DNS records. Use when you need immediate re-resolution (cannot wait for TTL expiry after a critical change).
</details>

**Q12:** What is split DNS (views)?

<details>
<summary>Answer</summary>
BIND serves different DNS data based on client source IP. Internal clients see private IPs; external clients see public IPs. Uses `view` blocks with `match-clients`.
</details>

**Q13:** What are the minimum required records in every authoritative zone file?

<details>
<summary>Answer</summary>
SOA record with serial/refresh/retry/expire/minimum, at least one NS record, and matching A/AAAA records for each NS (glue).
</details>

**Q14:** How do you enable query logging from the command line without restarting?

<details>
<summary>Answer</summary>
`sudo rndc querylog on` (off to disable). Requires a `logging` category for `queries` in `named.conf`.
</details>

**Q15:** What does a slave DNS server do on startup for each slave zone?

<details>
<summary>Answer</summary>
Queries master's SOA, compares serial numbers. If master's serial is higher, initiates AXFR/IXFR. If serials match, serves cached zone data.
</details>

---

**Score:** ___ / 15

| Score | Assessment |
|-------|-----------|
| 12–15 | Ready for Part 43: DHCP Server |
| 9–11 | Review sections 4, 5, 8, 12 |
| 0–8 | Review entire part and hands-on practices |

---

*Previous → Part 41: LDAP and Centralized Authentication*
*Next → Part 43: DHCP Server*

[← Previous](part41.md) | [Next →](part43.md)
