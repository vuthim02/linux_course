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



---

[← Previous](07-section-4-zones.md) | [↑ Index](index.md) | [Next →](09-section-6-reverse-dns.md)
