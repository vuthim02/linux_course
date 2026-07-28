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





[← Previous](08-section-5-zone-files.md) | [↑ Index](index.md) | [Next →](10-section-7-slavesecondary-dns.md)
