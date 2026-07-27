## 8. Diagnosing Memory Pressure

### The Essential Tools

```bash
# free - the quick overview
free -h
#               total        used        free      shared  buff/cache   available
# Mem:           31Gi       4.2Gi       100Mi       512Mi       27Gi        26Gi
# Swap:         8.0Gi       256Mi       7.7Gi
#
# Key columns:
# total     = total installed RAM
# used      = total - free - buffers - cached
# free      = completely unused
# buff/cache = page cache + buffer cache (reclaimable)
# available = free + reclaimable cache (what's actually available)
#
# ALWAYS look at "available", not "free"!

# vmstat - real-time memory stats
vmstat 1 5
# procs -----------memory---------- ---swap-- -----io---- -system-- ------cpu-----
#  r  b   swpd   free   buff  cache   si   so    bi    bo   in   cs us sy id wa st
#  1  0  12340 102400 51200 27000000  0    0     0   500  1500 3000  5  2 93  0  0
#
# Key fields:
# si = swap in (pages swapped in per second)
# so = swap out (pages swapped out per second)
# free = free memory in KB
# buff = buffer cache
# cache = page cache
# If si/so are high constantly, system is thrashing

# /proc/meminfo - detailed view
cat /proc/meminfo
# MemTotal:       32768000 kB
# MemFree:         102400 kB
# MemAvailable:   27264000 kB    ← THE number to watch
# Buffers:         524288 kB
# Cached:         28311552 kB
# SwapCached:       10240 kB
# Active:         20480000 kB
# Inactive:        8192000 kB
# Active(anon):    4194304 kB     ← anonymous (app) memory
# Inactive(anon):   262144 kB
# Active(file):   16285696 kB     ← file-backed (cache) memory
# Inactive(file):  7927808 kB
# Dirty:            524288 kB     ← modified pages not yet written
# Writeback:              0 kB    ← pages currently being written
# AnonPages:       4194304 kB     ← total anonymous memory
# Mapped:          1048576 kB      ← memory-mapped files
# Shmem:            524288 kB     ← shared memory (tmpfs, SysV shm)
# SReclaimable:    2097152 kB     ← reclaimable slab
# SUnreclaim:       524288 kB     ← unreclaimable slab
# SwapTotal:       8388608 kB
# SwapFree:        8126464 kB
```

### Slab Allocator — Kernel Memory

```bash
# slabtop - view kernel memory allocations
sudo slabtop -o | head -30
#  OBJS ACTIVE  USE OBJ SIZE  SLABS OBJ/SLAB CACHE SIZE NAME
# 1024000  819200  80%    0.50K  20480       50    40960K dentry
#  512000   409600  80%    0.25K   8192       64    16384K ext4_inode_cache
#  256000   204800  80%    1.00K   8192       32    32768K signal_cache

# Or view directly
cat /proc/slabinfo
# name            <active_objs> <num_objs> <objsize> <objperslab> <pagesperslab>
# ext4_inode_cache      819200    1024000     1024          32            8
# dentry               2048000    2048000      192          21            8

# Common slab caches to watch:
# dentry = directory entry cache (ls -R fills this)
# ext4_inode_cache = inode metadata
# signal_cache = process structures
# kernfs_node_cache = sysfs entries
# kmalloc-* = general kernel allocations

# Find what's using slab memory
sudo slabtop -s c | head -20    # Sort by cache size

# Monitor slab growth over time
watch -n 5 'sudo slabtop -o -s c | head -20'
```

### Tracking Memory Per-Process

```bash
# Top memory consumers
ps aux --sort=-%mem | head -15
# USER   PID %CPU %MEM    VSZ   RSS TTY   STAT START   TIME COMMAND
# postgres 12345  2.0 15.2 18432000 5000000 ?  Ssl  08:00  120:00 postgres
# java   6789  1.5 12.1 15000000 4000000 ?  Sl   08:00   90:00 java

# RSS = Resident Set Size (actual physical memory used)
# VSZ = Virtual Memory Size (total virtual memory mapped)
# VSZ is usually much larger than RSS (includes mapped but unused pages)

# Detailed process memory map
pmap -x <PID> | tail -5
# total kB    18432000   5000000   4800000
# RSS is the real memory usage

# smem - accurate memory accounting (includes shared)
sudo apt install smem
smem -t -k -s pss | tail -15
# PID User     Command                         Swap      USS      PSS      RSS
# ...
# Total                            256000K   4200000K  4500000K  8200000K
#
# USS = Unique Set Size (memory only this process uses)
# PSS = Proportional Set Size (shared memory divided by users)
# RSS = Resident Set Size (total physical memory including shared)
# smem is more accurate than ps for shared memory (PostgreSQL, Java)
```

### Detecting Memory Leaks

```bash
# Watch process memory growth
while true; do
    echo "$(date): $(ps -o rss= -p <PID>) kB"
    sleep 60
done > /tmp/mem_watch.log

# Compare with /proc/PID/status
cat /proc/<PID>/status | grep -E "VmRSS|VmSize|VmSwap"

# Check for memory-mapped files
cat /proc/<PID>/maps | grep -c "^[0-9a-f].*rw"

# Use valgrind (development only)
valgrind --tool=massif ./my_application
ms_print massif.out.<PID>

# System-wide leak detection
# Watch for growing slab
watch -n 10 'sudo slabtop -o -s c | head -10'

# Watch for growing page cache (should stabilize)
watch -n 10 'grep -E "Cached|Active|Inactive" /proc/meminfo'
```

> 🔍 **Reverse Engineering Insight:** The most common cause of "memory leaks" in production is actually page cache growth, not actual memory leaks. When a process reads many files, the page cache grows until the kernel reclaims it. If you see RSS staying constant but `buff/cache` growing, that's normal cache behavior — not a leak. True leaks show RSS growing continuously over hours/days.

---



---

[← Previous](08-7-memory-overcommit-the-kernels.md) | [↑ Index](index.md) | [Next →](10-9-tuning-for-applications.md)
