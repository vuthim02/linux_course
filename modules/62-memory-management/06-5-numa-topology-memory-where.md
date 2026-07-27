## 5. NUMA Topology — Memory Where It Matters

### Understanding NUMA

**NUMA (Non-Uniform Memory Access)** means different CPUs have different access speeds to different memory regions:

```
┌──────────────────────────────────────────────────────────────┐
│                    NUMA ARCHITECTURE                          │
│                                                                │
│  ┌─────────────────────┐    ┌─────────────────────┐          │
│  │    NUMA Node 0       │    │    NUMA Node 1       │         │
│  │  ┌──────────────┐   │    │  ┌──────────────┐   │         │
│  │  │ CPU 0  CPU 1  │   │    │  │ CPU 2  CPU 3  │   │         │
│  │  │ CPU 4  CPU 5  │   │    │  │ CPU 6  CPU 7  │   │         │
│  │  └──────┬───────┘   │    │  └──────┬───────┘   │         │
│  │         │ Local bus  │    │         │ Local bus  │         │
│  │  ┌──────┴───────┐   │    │  ┌──────┴───────┐   │         │
│  │  │ 64GB RAM      │   │    │  │ 64GB RAM      │   │         │
│  │  │ (128 ns)      │   │    │  │ (128 ns)      │   │         │
│  │  └───────────────┘   │    │  └───────────────┘   │         │
│  └──────────┬──────────┘    └──────────┬──────────┘          │
│             │                          │                       │
│             └──────── UPI Link ────────┘                       │
│                    (200-300 ns)                                │
│                                                                │
│  Local access:  128 ns                                         │
│  Remote access: 200-300 ns (50-100% slower!)                   │
└──────────────────────────────────────────────────────────────┘
```

### Reading NUMA Topology

```bash
# Install numactl
sudo apt install numactl    # Debian/Ubuntu
sudo yum install numactl    # RHEL/CentOS

# View NUMA node information
numactl --hardware
# available: 2 nodes (0-1)
# node 0 cpus: 0 1 2 3 4 5
# node 0 size: 65536 MB
# node 0 free: 45000 MB
# node 1 cpus: 6 7 8 9 10 11
# node 1 size: 65536 MB
# node 1 free: 40000 MB
# node distances:
# node   0   1
#   0:  10  21
#   1:  21  10

# View NUMA statistics
numastat
# node0:
#                numa_hit 1234567890
#            numa_miss 0
#       numa_foreign 0
#     interleave_hit 12345
#        local_node 1234567890

# Per-process NUMA allocation
numastat -p <PID>

# Check which NUMA node a process is using
cat /proc/<PID>/numa_maps | head -20
# 00007f4a3b2c0000 default file=/usr/lib/x86_64-linux-gnu/libc.so.6 mapped=8192 N0=8192

# Verify NUMA balancing is enabled
cat /proc/sys/kernel/numa_balancing
# 1 (enabled by default in modern kernels)
```

### Memory Placement with numactl

```bash
# Run process on specific NUMA node
numactl --cpunodebind=0 --membind=0 ./my_application

# Interleave memory across all nodes (for large datasets)
numactl --interleave=all ./my_application

# Spread memory allocation across nodes
numactl --membind=0,1 --cpunodebind=0,1 ./my_application

# Allocate local memory only (best for performance)
numactl --localalloc ./my_application

# PostgreSQL on specific NUMA node
# In postgresql.conf or via numactl wrapper:
numactl --interleave=all -- /usr/lib/postgresql/14/bin/postgres -D /var/lib/postgresql/14/main

# Redis on specific NUMA node
numactl --cpunodebind=0 --membind=0 redis-server /etc/redis/redis.conf

# MySQL/MariaDB with NUMA awareness
# my.cnf:
# innodb_numa_interleave = 1
# Or use numactl wrapper
```

### NUMA Diagnostics

```bash
# Find NUMA imbalance
numastat -m | head -20
# Per-node memory allocation

# Check for NUMA-related latency
numactl --hardware | grep "node distances"

# Monitor NUMA hit/miss rates
watch -d numastat    # Refreshes every 2 seconds

# lscpu shows NUMA info
lscpu | grep -i numa
# NUMA node(s):        0-1
# NUMA node0 CPU(s):   0-5
# NUMA node1 CPU(s):   6-11

# Verify memory is allocated locally
cat /proc/<PID>/numa_maps | grep -c "N0"  # Node 0 pages
cat /proc/<PID>/numa_maps | grep -c "N1"  # Node 1 pages
# If most pages are on the WRONG node, you have NUMA imbalance
```

> 🔍 **Reverse Engineering Insight:** NUMA imbalance is a silent killer of performance. A database process running on Node 0 but allocating memory on Node 1 can see 50-100% throughput degradation. Always use `numactl --interleave=all` for large shared-memory databases, or pin processes to specific nodes with `--membind`.

---



---

[← Previous](05-4-zram-and-zswap-compressed.md) | [↑ Index](index.md) | [Next →](07-6-oom-killer-last-resort.md)
