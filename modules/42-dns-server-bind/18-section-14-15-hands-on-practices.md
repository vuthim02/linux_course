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





[← Previous](17-section-13-command-reference.md) | [↑ Index](index.md) | [Next →](19-deep-understanding.md)
