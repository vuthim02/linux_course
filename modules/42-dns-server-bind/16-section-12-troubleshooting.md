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





[← Previous](15-section-11-tuning-and-performance.md) | [↑ Index](index.md) | [Next →](17-section-13-command-reference.md)
