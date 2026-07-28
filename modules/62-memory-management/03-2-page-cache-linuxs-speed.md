## 2. Page Cache — Linux's Speed Secret

### What Is Page Cache?

When Linux reads a file, it doesn't just read it once — it caches the data in memory for future reads. This cached data is the **page cache**:

```
┌──────────────────────────────────────────────────────────────┐
│                  PAGE CACHE BEHAVIOR                          │
│                                                                │
│  Application reads file:                                       │
│    1. Check page cache → MISS → read from disk                │
│    2. Store page in cache                                      │
│                                                                │
│  Application reads same file again:                            │
│    1. Check page cache → HIT → return from memory (fast!)     │
│                                                                │
│  When memory is needed for other purposes:                     │
│    1. Evict least-recently-used pages (LRU)                   │
│    2. Dirty pages written to disk first                        │
│    3. Clean pages can be discarded immediately                 │
└──────────────────────────────────────────────────────────────┘
```

```bash
# View page cache statistics
grep -E "Cached|Buffers|Dirty|Writeback" /proc/meminfo
# Buffers:          524288 kB    (block device metadata cache)
# Cached:          20971520 kB   (page cache for file data)
# Dirty:            524288 kB    (pages modified but not yet written)
# Writeback:              0 kB   (pages currently being written)

# Total cache = Buffers + Cached = ~21GB on a 32GB system

# View page cache per-file
# Requires root to see all files
sudo fincore /var/log/syslog

# Or use /proc/PID/statm for process memory including page cache
cat /proc/1/statm
# 391456 81920 1234 5678 0 25000 0
# Total  RSS  Shared Text Lib Data Stk Unused
```

### Monitoring Page Cache Effectiveness

```bash
# vmstat shows cache hits/misses
vmstat -s | grep -E "cache|page"
#     123456789 page ins
#      9876543 page outs

# Detailed page cache stats
cat /proc/vmstat | grep -E "^pg|^pswp|^pgfault"
# pgpgin 12345678       # Pages read from disk
# pgpgout 9876543       # Pages written to disk
# pswpin 1234           # Pages swapped in
# pswpout 5678          # Pages swapped out
# pgfault 987654321     # Total page faults (minor + major)
# pgmajfault 12345      # Major page faults (required disk I/O)

# Calculate page cache hit ratio (should be >99%)
# Watch over 10 seconds
vmstat 1 10 | tail -1
# r  b  swpd  free  buff  cache  si  so  bi  bo  in   cs us sy id wa
# 1  0     0 10240 51200 20480000 0   0   0   0  1500 3000 5  2 93  0
```

### Safely Dropping Page Cache

```bash
# ⚠️ WARNING: Only do this on non-production or when you understand the impact!
# Dropping cache forces subsequent reads to hit disk

# Drop page cache only (safe)
echo 1 | sudo tee /proc/sys/vm/drop_caches

# Drop dentries and inodes (directory cache)
echo 2 | sudo tee /proc/sys/vm/drop_caches

# Drop everything (page cache + dentries + inodes)
echo 3 | sudo tee /proc/sys/vm/drop_caches

# Verify cache was dropped
free -h
#               total        used        free      shared  buff/cache   available
# Mem:           31Gi       2.1Gi       28Gi       512Mi       1.2Gi        29Gi
#                                        ^^^                          ^^^
#                                    free increased              buff/cache decreased

# Before dropping cache (production server):
# total        used        free      shared  buff/cache   available
# Mem:           31Gi       2.1Gi       100Mi       512Mi       29Gi        28Gi
# After:
# Mem:           31Gi       2.1Gi       28Gi       512Mi       1.2Gi        29Gi
# The "available" column barely changed — this is normal!
```

> 🔍 **Reverse Engineering Insight:** The `available` column in `free` is what matters, not `free`. Linux aggressively uses free memory for page cache because unused RAM is wasted RAM. When an application needs memory, Linux evicts clean cache pages instantly. Only memory pressure (not low `free`) indicates a problem.





[← Previous](02-1-linux-memory-architecture-physical.md) | [↑ Index](index.md) | [Next →](04-3-swap-architecture-when-ram.md)
