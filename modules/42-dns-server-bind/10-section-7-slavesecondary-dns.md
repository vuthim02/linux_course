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



---

[← Previous](09-section-6-reverse-dns.md) | [↑ Index](index.md) | [Next →](11-level-3-advanced-dnssec-access.md)
