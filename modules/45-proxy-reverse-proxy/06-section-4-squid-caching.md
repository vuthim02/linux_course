## 🔍 Section 4: Squid Caching

### 4.1 Cache Directives

Squid caches HTTP responses (GET requests) to serve them faster on subsequent requests.

```apache
# /etc/squid/squid.conf — Caching directives

# Cache directory: UFS filesystem, 10 GB, 16 L1 x 256 L2 subdirectories
cache_dir ufs /var/spool/squid 10240 16 256

# In-memory cache for hot objects
cache_mem 256 MB

# Maximum object size for caching (20 MB)
maximum_object_size 20 MB

# Minimum object size for caching (0 = any)
minimum_object_size 0 bytes

# Objects larger than this are NOT cached (0 = no limit)
maximum_object_size_in_memory 512 KB

# How long to keep an object in cache without access (in days)
cache_swap_low 90
cache_swap_high 95

# Refresh patterns control freshness
refresh_pattern ^ftp:           1440    20%     10080
refresh_pattern ^gopher:        1440    0%      1440
refresh_pattern -i (/cgi-bin/|\?) 0     0%      0
refresh_pattern .               0       20%     4320
```

### 4.2 Cache Storage Types

| Type | Description | Pros | Cons |
|------|-------------|------|------|
| `ufs` | Traditional Unix File System cache | Mature, stable | Slow with many files, uses many inodes |
| `rock` | Fixed-block storage in a single file | Fast, low disk overhead | All blocks same size (wasteful for small files) |
| `aufs` | Async UFS (threaded I/O) | Better I/O performance | Still uses many files |

**Rock cache configuration:**

```apache
cache_dir rock /var/spool/squid 10240 max-size=16384
# max-size = objects larger than 16KB stored in rock; smaller objects go to memory
```

### 4.3 refresh_pattern — Controlling Freshness

The `refresh_pattern` directive tells Squid how to determine if a cached object is still fresh:

```
refresh_pattern REGEX MIN PERCENT MAX [options]
```

```apache
# Static content: cache for 1 day (1440 min), allow 20% variance, max 7 days (10080 min)
refresh_pattern -i \.(jpg|png|gif|css|js|ico)$ 1440 20% 10080

# HTML: shorter cache
refresh_pattern -i \.html$ 60 20% 1440

# API responses: never cache
refresh_pattern -i /api/ 0 0% 0

# Default: 0 min, 20% LM factor, max 4320 min (3 days)
refresh_pattern . 0 20% 4320
```

### 4.4 Measuring Cache Performance

```bash
# Restart Squid
sudo systemctl restart squid

# Generate traffic
for i in $(seq 1 100); do
  curl -x http://127.0.0.1:3128 -s http://example.com > /dev/null
done

# Check cache statistics via squidclient
sudo squidclient -h 127.0.0.1 -p 3128 mgr:info

# Extract cache hit ratio
sudo squidclient -h 127.0.0.1 -p 3128 mgr:info | grep -i "hit ratio"
# Request Hit Ratios: 5min: 89.4%, 60min: 78.2%

# Memory usage
sudo squidclient -h 127.0.0.1 -p 3128 mgr:info | grep -i "memory"
# Memory accounted for: 185928 KB

# Check stored objects count
sudo squidclient -h 127.0.0.1 -p 3128 mgr:store_digest | head -20

# Storage report
sudo squidclient -h 127.0.0.1 -p 3128 mgr:storedir | grep -E "(Files|Space)"
```

### 4.5 Cache Hit Ratio Interpretation

| Ratio | Meaning | Action |
|-------|---------|--------|
| 0–20% | Poor — cache miss most of the time | Increase cache size, check refresh_pattern, warm up cache |
| 20–50% | Fair — some benefit | Tune refresh_pattern, increase cache_mem |
| 50–80% | Good — effective caching | Monitor for drop-off |
| 80–100% | Excellent — cache working well | Ensure freshness policies are correct |

---



---

[← Previous](05-section-3-squid-access-control.md) | [↑ Index](index.md) | [Next →](07-section-5-squid-logging.md)
