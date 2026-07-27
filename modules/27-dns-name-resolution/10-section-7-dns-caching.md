## 🔍 Section 7: DNS Caching

Every DNS query takes time. Caching avoids repeated lookups.

### How Caching Works

```
TTL (Time To Live) — how long a record can be cached
google.com A 300 → cache for 300 seconds

Timeline:
t=0:  Query google.com → server responds with TTL=300
t=10: Query google.com → answered from cache (290s remaining)
t=310: Cache expires → new query to upstream
```

### nscd — Name Service Cache Daemon

The traditional caching daemon for glibc.

```bash
# Install
sudo apt install nscd     # Debian/Ubuntu
sudo dnf install nscd     # RHEL/Fedora

# Start and enable
sudo systemctl enable --now nscd

# Check status
sudo systemctl status nscd

# Configuration
cat /etc/nscd.conf
```

```
# /etc/nscd.conf
enable-cache            hosts           yes
positive-time-to-live   hosts           3600
negative-time-to-live   hosts           20
suggested-size          hosts           211
check-files             hosts           yes
persistent              hosts           yes
shared                  hosts           yes
```

```bash
# Invalidate cache
sudo nscd -i hosts

# Statistics
sudo nscd -g

# Test: first lookup is slow, cache makes it instant
time getent hosts google.com
time getent hosts google.com
```

### systemd-resolved Caching

systemd-resolved includes built-in caching:

```bash
# Check cache statistics
resolvectl statistics

# Flush cache
sudo resolvectl flush-caches

# Verify
resolvectl statistics | grep -i cache
```

### Unbound — Full DNS Resolver

Unbound is a validating, recursive, caching DNS resolver. It acts as a local DNS server that does full resolution.

```bash
# Install
sudo apt install unbound     # Debian/Ubuntu
sudo dnf install unbound     # RHEL/Fedora

# Basic configuration
sudo tee /etc/unbound/unbound.conf.d/local.conf << 'EOF'
server:
    interface: 127.0.0.1
    port: 53
    access-control: 127.0.0.0/8 allow
    do-daemonize: yes
    prefetch: yes
    cache-min-ttl: 3600
    cache-max-ttl: 86400
EOF

# Start
sudo systemctl enable --now unbound

# Now use localhost as DNS
echo "nameserver 127.0.0.1" | sudo tee /etc/resolv.conf

# Query — first is slow (recursive), then fast (cached)
dig @127.0.0.1 google.com
time dig @127.0.0.1 google.com
time dig @127.0.0.1 google.com
```

### Cache Comparison

| Cache | Scope | Persistence | Negative Caching |
|-------|-------|-------------|------------------|
| nscd | All glibc queries | Configurable | Yes (20s default) |
| systemd-resolved | Systemd-managed hosts | Runtime only | Yes |
| Unbound | Full recursive resolver | Optional | Yes |

### Prefetching

Unbound can refresh entries before they expire:

```
prefetch: yes   # Refresh when TTL is 10% of original
```

This means popular domains never expire from cache.

---



---

[← Previous](09-section-6-dig-deep-dig.md) | [↑ Index](index.md) | [Next →](11-section-8-mdns-multicast-dns.md)
