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



---

[← Previous](11-level-3-advanced-dnssec-access.md) | [↑ Index](index.md) | [Next →](13-section-9-access-control.md)
