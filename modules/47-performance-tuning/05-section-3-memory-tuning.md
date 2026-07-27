## 🔍 Section 3: Memory Tuning

### Swappiness

Controls the kernel's preference for swapping anonymous pages vs dropping file-backed pages.

```bash
# Check current value
cat /proc/sys/vm/swappiness

# Default is 60 (balance)
# For servers with plenty of RAM, lower it
sudo sysctl vm.swappiness=10

# Keep in /etc/sysctl.conf
echo "vm.swappiness=10" | sudo tee -a /etc/sysctl.conf
```

| Value | Behavior |
|-------|----------|
| 0 | Swap only when OOM (kernel 3.5+; earlier 0 = disable swap) |
| 1 | Minimum swap (Linux 5.8+ — `vm.swappiness=1` is the real minimum) |
| 10 | Good for servers with adequate RAM |
| 60 | Default |
| 100 | Aggressive swapping |

### Dirty Page Tuning

When applications write to files, the kernel caches writes as *dirty pages* before flushing them to disk.

```bash
# View current settings
sysctl vm.dirty_ratio
sysctl vm.dirty_background_ratio

# Tuning for write-heavy workloads (more caching, better throughput)
sudo sysctl vm.dirty_ratio=30
sudo sysctl vm.dirty_background_ratio=10

# Tuning for latency-sensitive workloads (less caching, less blocking)
sudo sysctl vm.dirty_ratio=5
sudo sysctl vm.dirty_background_ratio=2
```

| Parameter | Default | Meaning |
|-----------|---------|---------|
| `vm.dirty_ratio` | 20 | Max % of total RAM that can be dirty before *writers block* |
| `vm.dirty_background_ratio` | 10 | % of RAM at which background flusher (pdflush) starts |
| `vm.dirty_expire_centisecs` | 3000 | How long (in cs) before dirty data is considered expired |
| `vm.dirty_writeback_centisecs` | 500 | How often (in cs) flusher thread wakes up |

### vfs_cache_pressure

Controls how aggressively the kernel reclaims dentry and inode caches.

```bash
# Default = 100
# Lower = keep more in cache (good for file-server workloads)
sudo sysctl vm.vfs_cache_pressure=50

# Higher = reclaim more aggressively (free memory faster)
sudo sysctl vm.vfs_cache_pressure=200
```

### Huge Pages

Modern CPUs support page sizes larger than the default 4 KB. Huge pages reduce TLB misses significantly for memory-intensive applications.

**HugeTLB (static, pre-allocated):**

```bash
# Check current huge page usage
cat /proc/meminfo | grep Huge

# Allocate 1024 huge pages (2 MB each)
echo 1024 | sudo tee /proc/sys/vm/nr_hugepages

# Or via sysctl
sudo sysctl vm.nr_hugepages=1024

# Make permanent in /etc/sysctl.conf
echo "vm.nr_hugepages=1024" | sudo tee -a /etc/sysctl.conf
```

**Transparent Huge Pages (THP):**

```bash
# Check status
cat /sys/kernel/mm/transparent_hugepage/enabled

# Possible values: always, madvise, never
echo never | sudo tee /sys/kernel/mm/transparent_hugepage/enabled

# Why disable? THP can cause latency jitter due to compaction.
# Database workloads (MongoDB, Cassandra) often recommend 'never'
```

| Feature | HugeTLB | THP |
|---------|---------|-----|
| Allocation | Pre-boot/pre-start, fixed | Dynamic, automatic |
| Fragmentation | None (locked in RAM) | Can cause stalls during compaction |
| TLB coverage | Excellent | Good |
| Configuration | Manual | Automatic (`always`) or per-process (`madvise`) |

### NUMA (Non-Uniform Memory Access)

In multi-socket systems, accessing memory on a remote socket is slower than local memory.

```bash
# Show NUMA topology
numactl --hardware
lscpu | grep NUMA

# Check current memory allocation policy for a process
cat /proc/1234/numa_maps

# Run a process on local NUMA node only (memory and CPU)
numactl --cpunodebind=0 --membind=0 ./myapp

# Run with interleaved allocation (all nodes equally)
numactl --interleave=all ./myapp

# Execute on specific CPUs
numactl --physcpubind=0-3 ./myapp
```

**NUMA-aware application tuning:**

```bash
# Database example: bind PostgreSQL to NUMA node 0 and isolate
sudo numactl --cpunodebind=0 --membind=0 pg_ctl start -D /var/lib/postgresql/data

# Nginx: one worker per NUMA node
# worker_processes auto;
# worker_cpu_affinity auto;
```

**The NUMA penalty:**

```
Local memory access:    ~100 ns
Remote memory access:   ~150-200 ns (1.5-2x slower)
```

---



---

[← Previous](04-section-2-cpu-tuning.md) | [↑ Index](index.md) | [Next →](06-section-4-disk-io-tuning.md)
