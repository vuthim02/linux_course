## 🔍 Section 6: Dig Deep — dig, host, nslookup

### dig — Domain Information Groper

`dig` is THE DNS troubleshooting tool. It queries DNS servers directly and shows every detail.

```bash
# Basic query
dig google.com

# Short answer only
dig +short google.com

# Specific record type
dig MX google.com
dig NS google.com
dig TXT google.com
dig SOA google.com
dig AAAA google.com

# Query a specific nameserver
dig @8.8.8.8 google.com
dig @1.1.1.1 google.com

# Query a specific port (non-standard)
dig @8.8.8.8 -p 53 google.com
```

### Understanding dig Output

```
; <<>> DiG 9.18.19 <<>> google.com         ← Version and query
;; global options: +cmd                     
;; Got answer:                              ← Response received
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 12345  ← Response header
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1  ← Flags

;; OPT PSEUDOSECTION:                       ← EDNS options
; EDNS: version: 0, flags:; udp: 512

;; QUESTION SECTION:                        ← What was asked
;google.com.            IN      A

;; ANSWER SECTION:                          ← The answer
google.com.         164     IN      A       142.250.80.14

;; AUTHORITY SECTION:                       ← Name servers (if no answer)
google.com.         24413   IN      NS      ns2.google.com.
google.com.         24413   IN      NS      ns1.google.com.

;; ADDITIONAL SECTION:                      ← Extra info (IPs of NS)
ns1.google.com.     24413   IN      A       216.239.32.10

;; Query time: 12 msec                      ← Performance data
;; SERVER: 8.8.8.8#53(8.8.8.8)             ← Who answered
;; WHEN: Wed Jun 24 10:00:00 UTC 2026      ← Timestamp
;; MSG SIZE  rcvd: 164                      ← Packet size
```

### dig +trace — Follow the Chain

```bash
dig +trace www.example.com
```

Shows every step: root → TLD → authoritative → answer.

### dig +short — Machine-Friendly

```bash
# Just the IP
dig +short google.com
# 142.250.80.14

# All IPs (multiple A records)
dig +short google.com A

# MX records (just priority and hostname)
dig +short MX google.com
# 10 smtp.google.com
```

### Reverse DNS Lookups

```bash
# Find hostname for an IP
dig -x 8.8.8.8
# Or
dig PTR 8.8.8.8.in-addr.arpa

dig +short -x 8.8.8.8
# dns.google.
```

### Advanced dig Tricks

```bash
# Query ANY type
dig ANY google.com   # Returns all records (some resolvers ignore ANY)

# Show only specific sections
dig +nocomment +noquestion +noauthority +noadditional +nostats google.com

# Trace with specific root server
dig @a.root-servers.net +trace google.com

# Check zone transfer (usually blocked)
dig @ns1.google.com google.com AXFR

# Query with TCP (bypass UDP limitations)
dig +tcp google.com

# Show the raw DNS packet
dig +dnssec google.com

# Check DNSSEC
dig google.com +dnssec +multiline

# Batch queries from file
dig -f domains.txt +short
```

### host — Simpler, Faster

```bash
# Basic lookup
host google.com

# Specific type
host -t MX google.com
host -t NS google.com
host -t SOA google.com

# Reverse lookup
host 8.8.8.8

# Specific server
host google.com 8.8.8.8

# Verbose
host -v google.com
```

### nslookup — The Legacy Tool

```bash
# Interactive mode
nslookup
> server 8.8.8.8
> set type=MX
> google.com
> exit

# One-shot
nslookup google.com
nslookup -type=MX google.com
nslookup google.com 8.8.8.8
```

### Comparison

| Feature | dig | host | nslookup |
|---------|-----|------|----------|
| Detail level | Maximum | Medium | Medium |
| Parseable output | Yes (+short) | Yes | No (legacy) |
| +trace | Yes | No | No |
| EDNS/DNSSEC | Full | Basic | Basic |
| Batch queries | Yes (-f) | No | No |
| Scripting | Excellent | Good | Poor |





[← Previous](08-section-5-systemd-resolved-the-modern.md) | [↑ Index](index.md) | [Next →](10-section-7-dns-caching.md)
