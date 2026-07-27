# 🐧 Linux System Administrator — Complete Course
## Part 62 of ∞: Memory Management — Swap, Page Cache, NUMA

---

> **Reverse Engineering Approach:** When `free` shows no available memory, when a database OOM-kills your application at 3 AM, when NUMA imbalances cause mysterious latency spikes, when swap thrashing brings a server to its knees — you need to understand Linux memory management from the inside. This part dissects physical memory allocation, page cache behavior, swap internals, NUMA topology, OOM killer logic, and overcommit policies until you can diagnose and tune any memory-related problem on any Linux system.

---

## 🎯 What You Will Achieve

- Understand physical vs virtual memory, page tables, and TLB translation
- Explain page cache behavior and safely drop caches when needed
- Configure swap partitions, files, swappiness, and priorities
- Deploy zram and zswap for compressed memory on memory-constrained systems
- Read NUMA topology and use `numactl` for memory placement
- Control OOM Killer behavior with `oom_score_adj` and cgroups
- Tune `vm.overcommit_*` parameters for different workload profiles
- Diagnose memory pressure with `free`, `vmstat`, `/proc/meminfo`, and `slabtop`
- Optimize memory settings for databases, web servers, and JVM applications

---

## 1. Linux Memory Architecture — Physical and Virtual

### The Big Picture

```
┌────────────────────────────────────────────────────────────────┐
│                        USER SPACE                               │
│  Application sees VIRTUAL addresses (0x0000 → 0x7FFF...)      │
├────────────────────────────────────────────────────────────────┤
│                     KERNEL MEMORY MANAGEMENT                    │
│  Page Tables │ Buddy Allocator │ Slab Allocator │ Zone Manager │
├────────────────────────────────────────────────────────────────┤
│                      PHYSICAL MEMORY                            │
│  Zone DMA │ Zone DMA32 │ Zone Normal │ Zone HighMem (32-bit)  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ Physical RAM: 4KB pages (the fundamental unit)           │  │
│  └──────────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────────┘
```

### Physical Memory Layout

```bash
# View physical memory layout
cat /proc/iomem

# Example output (simplified):
# 00000000-00000fff : reserved
# 00001000-0009fbff : System RAM
# 00100000-3fffffff : System RAM
# 40000000-7fffffff : System RAM

# Total physical memory
grep MemTotal /proc/meminfo
# MemTotal:       32768000 kB  (~32GB)

# Memory zones
cat /proc/zoneinfo | head -50

# Zones:
#   DMA      = 0-16MB      (legacy ISA devices)
#   DMA32    = 4GB-16GB    (32-bit DMA capable devices)
#   Normal   = above 4GB   (regular kernel allocations)
#   HighMem  = above 896MB (32-bit only, not mapped into kernel)
```

### Virtual Memory and Page Tables

Every process gets its own virtual address space. The CPU's **MMU (Memory Management Unit)** translates virtual → physical addresses using **page tables**:

```
┌──────────────────────────────────────────────────────────────┐
│                    PAGE TABLE WALK                             │
│                                                                │
│  Process Virtual Address: 0x00007F4A3B2C1000                  │
│         │                                                      │
│         ▼                                                      │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐       │
│  │ PGD (Page   │───→│ P4D/PUD     │───→│ PMD (Page   │       │
│  │ Global Dir) │    │ (Upper Dir) │    │ Middle Dir) │       │
│  └─────────────┘    └─────────────┘    └──────┬──────┘       │
│                                                │              │
│                                                ▼              │
│                                         ┌─────────────┐       │
│                                         │ PTE (Page   │       │
│                                         │ Table Entry)│       │
│                                         └──────┬──────┘       │
│                                                │              │
│                                                ▼              │
│                                         ┌─────────────┐       │
│                                         │ Physical    │       │
│                                         │ 4KB Page    │       │
│                                         └─────────────┘       │
└──────────────────────────────────────────────────────────────┘
```

```bash
# View page table info for a process
cat /proc/<PID>/maps | head -20

# View memory mappings
pmap -x <PID> | head -30

# Example output:
# Address           Kbytes     RSS   Dirty Mode  Mapping
# 0000000000400000     512     420       0 r-x--  nginx
# 0000000000680000     256      60      40 rw---  nginx
# 00007f4a3b2c0000   131072   81920       0 r-x--  libpthread

# TLB (Translation Lookaside Buffer) stats
grep -i tlb /proc/cpuinfo

# View page size
getconf PAGE_SIZE
# 4096  (4KB - standard on x86_64)
```

### Huge Pages

```bash
# Standard vs Huge pages
# 4KB standard page × 512,000 pages ≈ 2GB (512K TLB entries needed)
# 2MB huge page × 1,024 pages ≈ 2GB (1024 TLB entries needed)

# View huge page info
cat /proc/meminfo | grep -i huge
# HugePages_Total:       0
# HugePages_Free:        0
# HugePages_Rsvd:        0
# HugePages_Surp:        0
# Hugepagesize:       2048 kB

# Allocate 1024 huge pages (2GB worth)
echo 1024 | sudo tee /proc/sys/vm/nr_hugepages

# Persistent huge pages
sudo mkdir -p /mnt/huge
sudo mount -t hugetlbfs -o pagesize=2M none /mnt/huge

# Check huge page usage
cat /proc/meminfo | grep Huge
# HugePages_Total:    1024
# HugePages_Free:      512
# HugePages_Rsvd:      256
```

> 🔍 **Reverse Engineering Insight:** TLB misses are one of the most expensive CPU events. Each TLB miss requires a full page table walk (4 memory accesses on x86_64). Huge pages reduce TLB misses by 512x for the same memory range — this is why databases and JVMs benefit enormously from huge pages.

---

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

---

## 3. Swap Architecture — When RAM Isn't Enough

### Swap Partitions vs Swap Files

```bash
# Check current swap
sudo swapon --show
# NAME      TYPE  SIZE USED PRIO
# /dev/sda2 partition 8G   2G  -2

# Or use free
free -h
#               total        used        free      shared  buff/cache   available
# Swap:         8Gi         2Gi         6Gi

# Swap partition: dedicated disk partition (slightly faster)
sudo mkswap /dev/sdb1
sudo swapon /dev/sdb1

# Swap file (flexible, can resize)
sudo fallocate -l 8G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# Priority (higher = used first)
sudo swapon -p 10 /dev/sdb1    # Priority 10 (preferred)
sudo swapon -p 5 /swapfile     # Priority 5 (backup)

# /etc/fstab for persistence
# /dev/sdb1  none  swap  sw,pri=10  0  0
# /swapfile  none  swap  sw,pri=5   0  0

# Check swap usage by process
sudo for f in /proc/[0-9]*/status; do
    awk '/VmSwap/{printf "%s %s\n", $2, $3}' "$f" 2>/dev/null
done | sort -k2 -rn | head -10
# 12345 kB  nginx
# 6789 kB   postgres
# 1234 kB   redis
```

### Swappiness — When to Swap

`vm.swappiness` (0-200) controls how aggressively Linux swaps out anonymous memory vs reclaiming page cache:

```
┌──────────────────────────────────────────────────────────────┐
│                SWAPPINESS BEHAVIOR                             │
│                                                                │
│  swappiness = 0:  Never swap unless absolutely necessary       │
│                   (aggressively reclaim page cache)            │
│                                                                │
│  swappiness = 1:  Minimal swapping (preferred for most)        │
│                   (kernel default hint for containers)          │
│                                                                │
│  swappiness = 10: Default for most Linux distributions         │
│                   (balance between cache and swap)              │
│                                                                │
│  swappiness = 60: Older default (CentOS 6, RHEL 6)            │
│                   (more aggressive swapping)                    │
│                                                                │
│  swappiness = 100: Equal weight to page cache and swap         │
│                    (swap actively even when memory available)   │
└──────────────────────────────────────────────────────────────┘
```

```bash
# View current swappiness
cat /proc/sys/vm/swappiness
# 10

# Set swappiness (runtime)
sudo sysctl vm.swappiness=1

# Set permanently
echo "vm.swappiness = 1" | sudo tee -a /etc/sysctl.d/99-memory.conf
sudo sysctl -p /etc/sysctl.d/99-memory.conf

# Swappiness per-cgroup (container-level)
# In cgroup v2 memory controller:
echo 1 > /sys/fs/cgroup/myapp/memory.swap.max

# For databases (minimize swapping):
# vm.swappiness = 1
# vm.dirty_ratio = 5
# vm.dirty_background_ratio = 1

# For desktop/workstation (use swap as safety net):
# vm.swappiness = 10
# vm.dirty_ratio = 20
# vm.dirty_background_ratio = 5
```

### Swap Priority and Multiple Swap Devices

```bash
# Multiple swap devices with priorities
sudo swapon --show
# NAME      TYPE  SIZE USED PRIO
# /dev/nvme0n1p2  partition  8G   0B  100    ← faster device, higher priority
# /dev/sda2       partition 16G   2G    5    ← slower device, lower priority
# /swapfile       file       8G   0B   -2    ← least preferred

# Linux uses highest priority first, only falls back when full
# Strategy: put fast storage (NVMe) at high priority

# Swap on RAID
# Create swap on RAID1 for redundancy
sudo mdadm --create /dev/md0 --level=1 --raid-devices=2 /dev/sdb1 /dev/sdc1
sudo mkswap /dev/md0
sudo swapon /dev/md0
```

> 🔍 **Reverse Engineering Insight:** Modern Linux (5.8+) treats `swappiness=0` differently than older kernels. Instead of "never swap," it means "don't proactively swap anonymous pages, but still swap under memory pressure." For true no-swap behavior, use cgroup memory limits or `memory.low` settings.

---

## 4. zram and zswap — Compressed Swap

### zram — In-Memory Compressed Block Device

zram creates a compressed block device in RAM. It acts as swap but never touches disk:

```bash
# Load zram module
sudo modprobe zram

# Set up zram swap (4GB compressed from 8GB RAM)
sudo echo lz4 > /sys/block/zram0/comp_algorithm
sudo echo 8G > /sys/block/zram0/disksize

# Initialize as swap
sudo mkswap /dev/zram0
sudo swapon -p 100 /dev/zram0    # Highest priority — use first!

# Verify
sudo swapon --show
# NAME       TYPE       SIZE USED PRIO
# /dev/zram0 partition    8G   4G  100

# Compression ratio
cat /sys/block/zram0/mm_stat
# orig_data_size  compr_data_size  mem_used_total  mem_limit
# 8589934592      4294967296       4398046511104   0

# Typical compression: 2:1 to 3:1
# 8GB compressed → 3-4GB actual RAM used → 8GB effective swap

# Auto-setup script
#!/bin/bash
# zram-setup.sh
load_module() {
    modprobe zram
    echo lz4 > /sys/block/zram0/comp_algorithm
    echo $(( $(grep MemTotal /proc/meminfo | awk '{print $2}') * 1024 / 2 )) \
        > /sys/block/zram0/disksize
    mkswap /dev/zram0
    swapon -p 100 /dev/zram0
}
```

### zswap — Compressed Swap Cache

zswap intercepts swap writes and stores compressed pages in a memory-based pool:

```bash
# zswap is built into the kernel (no setup needed beyond enabling)
cat /sys/kernel/debug/zswap/
# same_filled_pages  stored_pages  pool_limit_size
# pool_total_size    writeback_count

# Or use sysctl
sysctl vm.zswap.enabled
# vm.zswap.enabled = 1

sysctl vm.zswap.compressor
# vm.zswap.compressor = lz4

sysctl vm.zswap.max_pool_percent
# vm.zswap.max_pool_percent = 20  (use max 20% of RAM for zswap pool)

# Disable zswap (for testing)
echo 0 | sudo tee /sys/kernel/debug/zswap/enabled

# zswap vs zram comparison:
# ┌────────────┬────────────────────┬────────────────────────┐
# │            │ zram               │ zswap                  │
# ├────────────┼────────────────────┼────────────────────────┤
# │ Type       │ Block device swap  │ Page cache interceptor │
# │ Setup      │ Manual (modprobe)  │ Built-in (sysctl)      │
# │ Compression│ All swap I/O       │ Only when memory tight │
# │ Overhead   │ Always active      │ Only under pressure    │
# │ Best for   │ No-disk systems    │ SSD protection         │
# │ Pool       │ disksize (fixed)   │ max_pool_percent       │
# └────────────┴────────────────────┴────────────────────────┘
```

### When to Use Each

```bash
# Use zram when:
# - No SSD available (embedded systems, old hardware)
# - You want to avoid ALL disk I/O for swap
# - Memory is tight and you need effective swap (containers, VMs)
# - Mobile/embedded devices (Android uses zram by default)

# Use zswap when:
# - You have SSD and want to reduce write amplification
# - You want transparent compression without setup
# - You want to extend SSD lifespan by reducing swap writes
# - Default choice for most servers with SSDs

# Use both together:
# zram (priority 100) → zswap (fallback) → disk swap (priority 5)
# This gives compressed memory first, then SSD, then spinning disk

# Disable both for benchmarks:
sudo swapoff -a
echo 0 | sudo tee /sys/kernel/debug/zswap/enabled
sudo modprobe -r zram
```

> 🔍 **Reverse Engineering Insight:** On modern servers with SSDs, zswap is often preferred over zram. zswap intercepts swap writes before they hit the SSD, reducing write amplification and extending SSD lifespan. zram is better when you have NO disk for swap at all (containers, embedded systems, Android).

---

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

## 6. OOM Killer — Last Resort Defense

### How OOM Killer Selects Victims

When the system runs completely out of memory (and swap is full), the OOM Killer activates:

```bash
# View OOM scores for all processes
for pid in /proc/[0-9]*/oom_score; do
    echo "$(cat $pid) $(cat $(dirname $pid)/comm)"
done 2>/dev/null | sort -rn | head -10
# 999 java
# 850 postgres
# 600 nginx
# 400 sshd
# 200 init

# OOM score calculation:
# score = (RSS + page cache + swap) / total memory
# Higher score = more likely to be killed
# Processes with CAP_SYS_ADMIN get score 0 (protected)

# View OOM score for specific process
cat /proc/<PID>/oom_score
cat /proc/<PID>/oom_score_adj

# OOM killer log messages
dmesg | grep -i "oom\|out of memory\|killed"
# [123456.789] Out of memory: Killed process 12345 (java) total-vm:8192000kB,
#              anon-rss:4096000kB, file-rss:0kB, shmem-rss:0kB

# Disable OOM killer for specific process
echo -1000 | sudo tee /proc/<PID>/oom_score_adj    # -1000 = never kill

# Make process more likely to be killed
echo 1000 | sudo tee /proc/<PID>/oom_score_adj     # 1000 = kill first

# oom_score_adj range: -1000 to 1000
#   -1000: completely protected (init, kernel threads)
#        0: default (most processes)
#   +1000: first to be killed (test programs, expendable services)
```

### OOM Killer and cgroups

```bash
# cgroup v2: OOM control
# Create a cgroup for an application
sudo mkdir /sys/fs/cgroup/myapp

# Set memory limit for cgroup
echo 4G | sudo tee /sys/fs/cgroup/myapp/memory.max

# Set OOM group kill (kill entire cgroup, not just one process)
echo 1 | sudo tee /sys/fs/cgroup/myapp/memory.oom.group

# Control OOM behavior
echo 0 | sudo tee /sys/fs/cgroup/myapp/memory.oom.group
#   0 = kill single process in cgroup
#   1 = kill entire cgroup

# Disable OOM for cgroup (just fail the allocation)
echo -1 | sudo tee /sys/fs/cgroup/myapp/memory.oom.max

# Run a process in the cgroup
echo $$ | sudo tee /sys/fs/cgroup/myapp/cgroup.procs
./my_application

# Monitor cgroup memory usage
cat /sys/fs/cgroup/myapp/memory.current
cat /sys/fs/cgroup/myapp/memory.stat
```

### Preventing OOM Kills

```bash
# 1. Set memory limits (prevent runaway processes)
# Using systemd:
# [Service]
# MemoryMax=4G
# MemoryHigh=3G
# (MemoryHigh = soft limit, MemoryMax = hard limit triggers OOM)

# 2. Use cgroup memory limits
echo 4G | sudo tee /sys/fs/cgroup/myapp/memory.max

# 3. Reserve memory for critical processes
echo -1000 | sudo tee /proc/$(pgrep sshd)/oom_score_adj    # Protect SSH

# 4. Add swap as safety net
sudo fallocate -l 8G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile && sudo swapon /swapfile

# 5. Monitor memory pressure
sudo dmesg | grep -i "low memory\|oom\|killed"
```

> 🔍 **Reverse Engineering Insight:** The OOM Killer uses `oom_score_adj` to influence victim selection. Setting a process to -1000 doesn't prevent the OOM condition — it just protects that specific process. The only way to truly prevent OOM is to have enough memory (physical + swap) or to use cgroup limits that trigger allocation failures before OOM.

---

## 7. Memory Overcommit — The Kernel's Gamble

### What Is Overcommit?

The kernel may allow more virtual memory allocation than physical + swap. This is called **overcommit**:

```bash
# View overcommit settings
cat /proc/sys/vm/overcommit_memory
# 0 = heuristic (default, guesses if there's enough)
# 1 = always (no checks, allocate freely)
# 2 = never (strict limit based on overcommit_ratio)

cat /proc/sys/vm/overcommit_ratio
# 50  (percentage of physical + swap to allow for overcommit)

cat /proc/sys/vm/overcommit_kbytes
# 0  (alternative: fixed bytes instead of ratio)

# Current overcommit status
grep -E "CommitLimit|Committed_AS" /proc/meminfo
# CommitLimit:    24576000 kB   (physical + swap × overcommit_ratio)
# Committed_AS:   20480000 kB   (total memory committed by processes)

# If Committed_AS > CommitLimit, the system is overcommitted
```

### Overcommit Strategies

```
┌──────────────────────────────────────────────────────────────┐
│              OVERCOMMIT STRATEGIES                            │
│                                                                │
│  overcommit_memory = 0 (HEURISTIC - DEFAULT)                  │
│  ┌─────────────────────────────────────────────────────┐      │
│  │ Kernel estimates if allocation is "reasonable"       │      │
│  │ - Small allocations: allowed                         │      │
│  │ - Large allocations: denied if looks dangerous       │      │
│  │ - Best for: general purpose servers                  │      │
│  │ - Risk: some OOM kills possible                      │      │
│  └─────────────────────────────────────────────────────┘      │
│                                                                │
│  overcommit_memory = 1 (ALWAYS)                               │
│  ┌─────────────────────────────────────────────────────┐      │
│  │ No overcommit checks — allocate freely               │      │
│  │ - Best for: scientific computing, VMs with tmpfs     │      │
│  │ - Risk: guaranteed OOM kills possible                │      │
│  │ - Use when: you know what you're doing               │      │
│  └─────────────────────────────────────────────────────┘      │
│                                                                │
│  overcommit_memory = 2 (NEVER)                                │
│  ┌─────────────────────────────────────────────────────┐      │
│  │ Strict limit: physical RAM × overcommit_ratio%       │      │
│  │ - Best for: databases, real-time systems             │      │
│  │ - Risk: allocations may fail even with free memory   │      │
│  │ - Safe: guarantees no OOM from overcommit            │      │
│  └─────────────────────────────────────────────────────┘      │
└──────────────────────────────────────────────────────────────┘
```

```bash
# Set overcommit strategy
sudo sysctl vm.overcommit_memory=0     # Heuristic (default)
sudo sysctl vm.overcommit_memory=1     # Always
sudo sysctl vm.overcommit_memory=2     # Never (strict)

# Set overcommit ratio (used with mode 2)
sudo sysctl vm.overcommit_ratio=80     # 80% of RAM + swap
# With 32GB RAM + 8GB swap: limit = 40GB × 80% = 32GB

# For databases (mode 2 recommended):
echo "vm.overcommit_memory = 2" | sudo tee -a /etc/sysctl.d/99-memory.conf
echo "vm.overcommit_ratio = 80" | sudo tee -a /etc/sysctl.d/99-memory.conf
sudo sysctl -p /etc/sysctl.d/99-memory.conf

# For tmpfs (needs mode 1):
# tmpfs allocates RAM for its contents
# With mode 0, tmpfs may fail to mount if overcommit is near limit
sudo mount -t tmpfs -o size=16G tmpfs /mnt/ramdisk
# This needs overcommit_memory=1 or enough free RAM
```

### Testing Overcommit

```bash
# Test overcommit behavior
cat << 'EOF' > /tmp/test_overcommit.c
#include <stdlib.h>
#include <stdio.h>
#include <sys/mman.h>

int main() {
    // Try to allocate 90% of RAM
    size_t size = 29ULL * 1024 * 1024 * 1024;  // 29GB on 32GB system
    void *ptr = mmap(NULL, size, PROT_READ|PROT_WRITE,
                     MAP_PRIVATE|MAP_ANONYMOUS, -1, 0);
    if (ptr == MAP_FAILED) {
        printf("mmap FAILED (overcommit prevented allocation)\n");
        return 1;
    }
    printf("mmap SUCCEEDED (address: %p)\n", ptr);
    // Actually touch the memory to trigger OOM
    // char *p = (char *)ptr;
    // for (size_t i = 0; i < size; i += 4096) p[i] = 'A';  // Would OOM
    munmap(ptr, size);
    return 0;
}
EOF
gcc -o /tmp/test_overcommit /tmp/test_overcommit.c
/tmp/test_overcommit
```

> 🔍 **Reverse Engineering Insight:** `overcommit_memory=1` is a common cause of mysterious OOM kills in production. The kernel allows a process to mmap() terabytes of virtual memory, but when it tries to actually use that memory, there's nothing physical available. Use `overcommit_memory=2` for databases and any process that needs guaranteed memory availability.

---

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

## 9. Tuning for Applications

### Database Servers (PostgreSQL, MySQL)

```bash
# PostgreSQL tuning
# /etc/postgresql/14/main/postgresql.conf

# Memory allocation (for 32GB system with 2GB for OS):
shared_buffers = 8GB           # 25% of RAM for shared cache
effective_cache_size = 24GB    # 75% of RAM (hint to query planner)
work_mem = 64MB                # Per-operation sort/hash memory
maintenance_work_mem = 2GB     # VACUUM, CREATE INDEX memory
huge_pages = try               # Use huge pages if available

# NUMA interleave for PostgreSQL
# Run with numactl
numactl --interleave=all /usr/lib/postgresql/14/bin/postgres

# MySQL/MariaDB tuning
# /etc/mysql/mariadb.conf.d/50-server.cnf

innodb_buffer_pool_size = 8GB       # 25% of RAM
innodb_log_file_size = 2GB          # Redo log size
innodb_log_buffer_size = 64MB       # Redo log buffer
innodb_flush_method = O_DIRECT      # Bypass page cache for data
innodb_numa_interleave = 1          # NUMA interleave

# Disable OOM killer for database
echo -1000 | sudo tee /proc/$(pgrep postgres)/oom_score_adj

# Memory settings in sysctl for databases
echo "vm.swappiness = 1" | sudo tee -a /etc/sysctl.d/99-memory.conf
echo "vm.dirty_ratio = 5" | sudo tee -a /etc/sysctl.d/99-memory.conf
echo "vm.dirty_background_ratio = 1" | sudo tee -a /etc/sysctl.d/99-memory.conf
echo "vm.overcommit_memory = 2" | sudo tee -a /etc/sysctl.d/99-memory.conf
echo "vm.overcommit_ratio = 80" | sudo tee -a /etc/sysctl.d/99-memory.conf
sudo sysctl -p /etc/sysctl.d/99-memory.conf
```

### Web Servers (Nginx, Apache)

```bash
# Nginx memory tuning
# /etc/nginx/nginx.conf

worker_processes auto;                    # One per CPU core
worker_rlimit_nofile 65535;
events {
    worker_connections 4096;              # Per-worker connections
}
http {
    # Worker memory: worker_connections × buffers
    # 4096 connections × (proxy_buffer 4KB + headers 8KB) = ~48MB per worker
    # Total: 4 × 48MB = 192MB for workers

    sendfile on;
    tcp_nopush on;
    keepalive_timeout 65;

    # Buffer settings
    proxy_buffering on;
    proxy_buffer_size 8k;
    proxy_buffers 4 16k;
}

# System tuning for high-connection web servers
echo "net.core.somaxconn = 65535" | sudo tee -a /etc/sysctl.d/99-memory.conf
echo "net.ipv4.tcp_max_syn_backlog = 65535" | sudo tee -a /etc/sysctl.d/99-memory.conf
echo "net.ipv4.ip_local_port_range = 1024 65535" | sudo tee -a /etc/sysctl.d/99-memory.conf
echo "vm.overcommit_memory = 1" | sudo tee -a /etc/sysctl.d/99-memory.conf
sudo sysctl -p /etc/sysctl.d/99-memory.conf

# Apache memory tuning
# /etc/apache2/mods-available/mpm_event.conf
# StartServers: 2
# MinSpareThreads: 25
# MaxSpareThreads: 75
# ThreadLimit: 64
# ThreadsPerChild: 25
# MaxRequestWorkers: 400   (25 threads × 16 workers)
# Each thread uses ~2MB, so: 400 × 2MB = 800MB total
```

### JVM (Java Virtual Machine)

```bash
# JVM memory model:
# ┌─────────────────────────────────────────────────┐
# │ JVM Process Memory                                │
# │  ┌─────────────────────────────────────────┐     │
# │  │         Heap (-Xmx/-Xms)                 │     │
# │  │  Young Gen │ Old Gen │ Metaspace         │     │
# │  │  (-Xmn)    │         │ (-XX:MaxMetaspace)│    │
# │  └─────────────────────────────────────────┘     │
# │  ┌─────────────────────────────────────────┐     │
# │  │      Off-Heap (Native Memory)            │     │
# │  │  Thread stacks, JIT code cache,          │     │
# │  │  NIO direct buffers, internal            │     │
# │  └─────────────────────────────────────────┘     │
# │  ┌─────────────────────────────────────────┐     │
# │  │      OS overhead (page cache, etc.)      │     │
# │  └─────────────────────────────────────────┘     │
# └─────────────────────────────────────────────────┘

# Example: 32GB system running Elasticsearch
# Reserve 4GB for OS → 28GB for JVM
java -Xmx24g -Xms24g \               # 24GB heap
     -Xmn4g \                         # 4GB young gen
     -XX:MaxMetaspaceSize=1g \         # 1GB metaspace
     -XX:ReservedCodeCacheSize=256m \  # JIT code cache
     -XX:MaxDirectMemorySize=4g \      # NIO direct buffers
     -XX:+UseG1GC \
     -XX:MaxGCPauseMillis=200 \
     -jar myapp.jar

# Use huge pages for JVM (reduces TLB misses)
# Calculate pages needed: ceil(24GB / 2MB) = 12288
echo 12288 | sudo tee /proc/sys/vm/nr_hugepages
java -Xmx24g -XX:+UseLargePages -jar myapp.jar

# Disable OOM killer for JVM
echo -1000 | sudo tee /proc/$(pgrep java)/oom_score_adj

# Monitor JVM memory from outside
jstat -gcutil <PID> 1000    # GC stats every second
jcmd <PID> VM.info          # JVM memory details
jcmd <PID> GC.heap_info    # Heap usage
```

### Redis

```bash
# Redis memory tuning
# /etc/redis/redis.conf

maxmemory 8gb                 # Set memory limit
maxmemory-policy allkeys-lru  # Evict least-recently-used keys

# Redis uses fork() for BGSAVE — ensure enough memory for COW
# If Redis uses 6GB and saves frequently, you need ~6GB extra for COW
# Total: 6GB (Redis) + 6GB (COW during save) = 12GB minimum

# Disable THP (Transparent Huge Pages) for Redis
echo never | sudo tee /sys/kernel/mm/transparent_hugepage/enabled
echo never | sudo tee /sys/kernel/mm/transparent_hugepage/defrag

# Use jemalloc instead of libc malloc
# (compiled in by default on most Redis builds)

# Redis on NUMA
numactl --cpunodebind=0 --membind=0 redis-server /etc/redis/redis.conf

# Monitor Redis memory
redis-cli info memory
# used_memory:8589934592
# used_memory_human:8.00G
# mem_fragmentation_ratio:1.05
# mem_allocator:jemalloc-5.2.1
```

> 🔍 **Reverse Engineering Insight:** The biggest mistake in JVM tuning is setting `-Xmx` too close to physical RAM. If you have 32GB RAM and set `-Xmx30g`, the OS has only 2GB for page cache, slab, and kernel structures. Leave 4-6GB for the OS, and use `jcmd` or `jstat` to monitor actual heap usage before tuning.

---

## 15 Hands-On Practices

### Practice 1: Read and Interpret /proc/meminfo

```bash
# Comprehensive memory analysis
echo "=== Memory Analysis ==="
echo ""
echo "Total RAM: $(awk '/MemTotal/{printf "%.1f GB", $2/1048576}' /proc/meminfo)"
echo "Available: $(awk '/MemAvailable/{printf "%.1f GB", $2/1048576}' /proc/meminfo)"
echo "Free:      $(awk '/MemFree/{printf "%.1f GB", $2/1048576}' /proc/meminfo)"
echo ""
echo "=== Breakdown ==="
awk '/^(MemTotal|MemFree|MemAvailable|Buffers|Cached|SwapCached|Active|Inactive|Dirty|Writeback|Shmem|Slab|SReclaimable|SUnreclaim|SwapTotal|SwapFree)/{printf "%-20s %10.1f MB\n", $1, $2/1024}' /proc/meminfo
```

✅ **Expected**: Complete memory breakdown showing total, available, cache, slab, and swap usage

### Practice 2: Monitor Page Cache with vmstat

```bash
# Watch page cache activity over 30 seconds
echo "=== Page Cache Activity (30s) ==="
vmstat 1 30
# Key columns: free, buff, cache, si, so, bi, bo
# bi = blocks in (disk reads → page cache)
# bo = blocks out (dirty pages → disk)
# If bi is high: lots of cache misses (cold start)
# If bi is low: cache is working (hits)
```

✅ **Expected**: Clear view of page cache behavior — low bi/bo indicates good cache hit ratio

### Practice 3: Drop Caches and Observe Impact

```bash
# Before dropping
echo "=== Before Drop ==="
free -h | grep -E "total|Mem|Swap"
echo ""
time dd if=/var/log/syslog of=/dev/null bs=1M
echo ""

# Drop caches
echo 3 | sudo tee /proc/sys/vm/drop_caches

# After dropping — first read will be slow
echo "=== After Drop ==="
free -h | grep -E "total|Mem|Swap"
echo ""
time dd if=/var/log/syslog of=/dev/null bs=1M
echo ""

# Second read (now cached again)
echo "=== Second Read (Cached) ==="
time dd if=/var/log/syslog of=/dev/null bs=1M
```

✅ **Expected**: First read after drop is slow (disk I/O), second read is fast (cache hit)

### Practice 4: Create and Configure Swap

```bash
# Create a 4GB swap file
sudo fallocate -l 4G /swapfile_test
sudo chmod 600 /swapfile_test
sudo mkswap /swapfile_test
sudo swapon -p 5 /swapfile_test

# Verify
sudo swapon --show
# NAME             TYPE    SIZE USED PRIO
# /swapfile_test   file     4G   0B    5

# Monitor swap usage
watch -n 2 'free -h | grep Swap'

# Clean up
sudo swapoff /swapfile_test
sudo rm /swapfile_test
```

✅ **Expected**: Swap file created, activated with priority 5, visible in `swapon --show`

### Practice 5: Set Up zram

```bash
# Create zram device
sudo modprobe zram
echo lz4 | sudo tee /sys/block/zram0/comp_algorithm
echo 4G | sudo tee /sys/block/zram0/disksize
sudo mkswap /dev/zram0
sudo swapon -p 100 /dev/zram0

# Verify zram is active
sudo swapon --show
# NAME       TYPE       SIZE USED PRIO
# /dev/zram0 partition    4G   0B  100

# Check compression ratio (after some usage)
cat /sys/block/zram0/mm_stat | awk '{printf "Original: %.1f GB\nCompressed: %.1f GB\nRatio: %.1f:1\n", $1/1073741824, $2/1073741824, $1/$2}'

# Load test
stress-ng --vm 2 --vm-bytes 2G --vm-method all -t 30s

# Check compression after load
cat /sys/block/zram0/mm_stat | awk '{printf "Compression ratio: %.1f:1\n", $1/$2}'
```

✅ **Expected**: zram active at priority 100, compression ratio 2:1 or better

### Practice 6: Read NUMA Topology

```bash
# Full NUMA topology
echo "=== NUMA Topology ==="
numactl --hardware
echo ""
echo "=== NUMA Statistics ==="
numastat
echo ""
echo "=== NUMA Distances ==="
lscpu | grep -A 10 "NUMA"
echo ""
echo "=== Per-CPU NUMA Node ==="
lscpu | grep "NUMA node"
```

✅ **Expected**: Clear view of NUMA nodes, CPUs per node, distances, and memory per node

### Practice 7: Test NUMA Memory Placement

```bash
# Run on local node
numactl --cpunodebind=0 --membind=0 stress-ng --vm 1 --vm-bytes 1G -t 10s &
PID1=$!
sleep 2

# Run on remote node (interleaved)
numactl --interleave=all stress-ng --vm 1 --vm-bytes 1G -t 10s &
PID2=$!
sleep 2

# Compare NUMA statistics
echo "=== NUMA Hit/Miss ==="
numastat
echo ""
echo "=== Memory placement for stress-ng processes ==="
cat /proc/$PID1/numa_maps | head -5
cat /proc/$PID2/numa_maps | head -5

wait $PID1 $PID2 2>/dev/null
```

✅ **Expected**: Local allocation shows lower NUMA miss rate; interleaved shows balanced allocation

### Practice 8: Control OOM Killer

```bash
# Create a test process
sleep 3600 &
TEST_PID=$!

# Check its OOM score
echo "=== Default OOM Score ==="
echo "PID: $TEST_PID"
echo "OOM Score: $(cat /proc/$TEST_PID/oom_score)"
echo "OOM Score Adj: $(cat /proc/$TEST_PID/oom_score_adj)"

# Protect the process
echo -1000 | sudo tee /proc/$TEST_PID/oom_score_adj
echo ""
echo "=== Protected OOM Score ==="
echo "OOM Score: $(cat /proc/$TEST_PID/oom_score)"
echo "OOM Score Adj: $(cat /proc/$TEST_PID/oom_score_adj)"

# Make it expendable
echo 1000 | sudo tee /proc/$TEST_PID/oom_score_adj
echo ""
echo "=== Expendable OOM Score ==="
echo "OOM Score: $(cat /proc/$TEST_PID/oom_score)"
echo "OOM Score Adj: $(cat /proc/$TEST_PID/oom_score_adj)"

# Cleanup
kill $TEST_PID
```

✅ **Expected**: oom_score changes from default → protected (-1000) → expendable (1000)

### Practice 9: Monitor Slab Memory

```bash
# View top slab consumers
echo "=== Top Slab Allocations ==="
sudo slabtop -o -s c | head -25

# Track slab growth
echo "=== Slab Growth Over 30 Seconds ==="
for i in $(seq 1 6); do
    echo "Sample $i: $(date)"
    grep -E "SReclaimable|SUnreclaim" /proc/meminfo
    echo ""
    sleep 5
done

# Find specific slab caches
echo "=== Filesystem-related Slab ==="
cat /proc/slabinfo | grep -E "ext4|dentry|inode" | head -10
```

✅ **Expected**: Clear view of kernel memory allocations and their growth patterns

### Practice 10: Overcommit Testing

```bash
# Check current overcommit settings
echo "=== Current Overcommit Settings ==="
echo "overcommit_memory: $(cat /proc/sys/vm/overcommit_memory)"
echo "overcommit_ratio: $(cat /proc/sys/vm/overcommit_ratio)"
echo ""
echo "CommitLimit: $(awk '/CommitLimit/{printf "%.1f GB", $2/1048576}' /proc/meminfo)"
echo "Committed_AS: $(awk '/Committed_AS/{printf "%.1f GB", $2/1048576}' /proc/meminfo)"
echo ""

# Set mode 2 (strict)
sudo sysctl vm.overcommit_memory=2
sudo sysctl vm.overcommit_ratio=80

echo "=== After Setting Mode 2 ==="
echo "overcommit_memory: $(cat /proc/sys/vm/overcommit_memory)"
echo "CommitLimit: $(awk '/CommitLimit/{printf "%.1f GB", $2/1048576}' /proc/meminfo)"
echo "Committed_AS: $(awk '/Committed_AS/{printf "%.1f GB", $2/1048576}' /proc/meminfo)"

# Restore default
sudo sysctl vm.overcommit_memory=0
```

✅ **Expected**: CommitLimit calculated as (RAM + swap) × overcommit_ratio, strict mode enforced

### Practice 11: Diagnose Memory Pressure

```bash
# Comprehensive memory pressure check
echo "=== Memory Pressure Diagnosis ==="
echo ""

echo "1. Available Memory:"
awk '/MemAvailable/{printf "   Available: %.1f GB / %.1f GB total (%.0f%%)\n", $2/1048576, $(/MemTotal/{print $2})/1048576, $2/$(/MemTotal/{print $2})*100}' /proc/meminfo

echo ""
echo "2. Swap Usage:"
awk '/SwapTotal/{total=$2} /SwapFree/{free=$2} END{printf "   Swap: %.1f GB / %.1f GB used\n", (total-free)/1048576, total/1048576}' /proc/meminfo

echo ""
echo "3. Swap Activity (10s):"
vmstat 1 10 | tail -5

echo ""
echo "4. Major Page Faults (disk reads):"
awk '/pgmajfault/{print "   " $0}' /proc/vmstat

echo ""
echo "5. Top Memory Consumers:"
ps aux --sort=-%mem | head -6
```

✅ **Expected**: Complete picture of memory health — available, swap, page faults, top consumers

### Practice 12: Database Memory Tuning

```bash
# Simulate PostgreSQL memory tuning on a 32GB system
echo "=== PostgreSQL Memory Tuning (32GB System) ==="
echo ""

TOTAL_RAM=32768  # MB
OS_RESERVED=4096  # 4GB for OS
PG_AVAILABLE=$((TOTAL_RAM - OS_RESERVED))  # 28GB

SHARED_BUFFERS=$((PG_AVAILABLE / 4))       # 7GB (25%)
EFFECTIVE_CACHE=$((PG_AVAILABLE * 75 / 100)) # 21GB (75%)
WORK_MEM=64                                 # 64MB per operation
MAINTENANCE_WORK_MEM=$((PG_AVAILABLE / 14)) # 2GB

echo "Total RAM: ${TOTAL_RAM}MB"
echo "OS Reserved: ${OS_RESERVED}MB"
echo "PostgreSQL Available: ${PG_AVAILABLE}MB"
echo ""
echo "Suggested PostgreSQL settings:"
echo "  shared_buffers = ${SHARED_BUFFERS}MB"
echo "  effective_cache_size = ${EFFECTIVE_CACHE}MB"
echo "  work_mem = ${WORK_MEM}MB"
echo "  maintenance_work_mem = ${MAINTENANCE_WORK_MEM}MB"
echo "  huge_pages = try"
echo ""
echo "NUMA: Run with: numactl --interleave=all postgres"
```

✅ **Expected**: Tuned PostgreSQL settings based on available system RAM

### Practice 13: JVM Memory Planning

```bash
# Plan JVM memory for a 32GB system running Elasticsearch
echo "=== JVM Memory Planning (32GB System) ==="
echo ""

TOTAL_RAM=32768  # MB
OS_RESERVED=4096  # 4GB for OS
JVM_TOTAL=$((TOTAL_RAM - OS_RESERVED))  # 28GB

HEAP=$((JVM_TOTAL * 85 / 100))          # 85% of JVM budget = 23GB
YOUNG_GEN=$((HEAP / 6))                 # ~4GB young gen
METASPACE=1024                          # 1GB
CODE_CACHE=256                          # 256MB
DIRECT_MEMORY=$((JVM_TOTAL - HEAP - METASPACE - CODE_CACHE))  # ~3GB

echo "Total RAM: ${TOTAL_RAM}MB"
echo "OS Reserved: ${OS_RESERVED}MB"
echo ""
echo "JVM Budget: ${JVM_TOTAL}MB"
echo "  Heap (-Xmx): ${HEAP}MB"
echo "  Young Gen (-Xmn): ${YOUNG_GEN}MB"
echo "  Metaspace: ${METASPACE}MB"
echo "  Code Cache: ${CODE_CACHE}MB"
echo "  Direct Memory: ${DIRECT_MEMORY}MB"
echo ""
echo "Java command:"
echo "  java -Xmx${HEAP}m -Xms${HEAP}m -Xmn${YOUNG_GEN}m \\"
echo "       -XX:MaxMetaspaceSize=${METASPACE}m \\"
echo "       -XX:ReservedCodeCacheSize=${CODE_CACHE}m \\"
echo "       -XX:MaxDirectMemorySize=${DIRECT_MEMORY}m \\"
echo "       -XX:+UseG1GC -XX:MaxGCPauseMillis=200 \\"
echo "       -jar elasticsearch.jar"
```

✅ **Expected**: JVM parameters calculated with proper OS reservation and memory breakdown

### Practice 14: Memory Monitoring Script

```bash
#!/bin/bash
# mem_monitor.sh — Comprehensive memory monitoring
echo "=== Memory Monitor $(date) ==="
echo ""

echo "┌─────────────────────────────────────────────────────┐"
echo "│ SYSTEM MEMORY                                        │"
echo "├─────────────────────────────────────────────────────┤"
printf "│ Total:     %8.1f GB                              │\n" $(awk '/MemTotal/{print $2/1048576}' /proc/meminfo)
printf "│ Available: %8.1f GB                              │\n" $(awk '/MemAvailable/{print $2/1048576}' /proc/meminfo)
printf "│ Free:      %8.1f GB                              │\n" $(awk '/MemFree/{print $2/1048576}' /proc/meminfo)
printf "│ Buffers:   %8.1f GB                              │\n" $(awk '/Buffers/{print $2/1048576}' /proc/meminfo)
printf "│ Cached:    %8.1f GB                              │\n" $(awk '/^Cached:/{print $2/1048576}' /proc/meminfo)
echo "├─────────────────────────────────────────────────────┤"
printf "│ Swap:      %5.1f / %.1f GB                        │\n" $(awk '/SwapTotal/{t=$2} /SwapFree/{printf "%.1f %.1f", (t-$2)/1048576, t/1048576}' /proc/meminfo)
echo "├─────────────────────────────────────────────────────┤"
echo "│ PRESSURE INDICATORS                                  │"
echo "├─────────────────────────────────────────────────────┤"
PCT_AVAIL=$(awk '/MemAvailable/{a=$2} /MemTotal/{t=$2} END{printf "%.0f", a/t*100}' /proc/meminfo)
if [ "$PCT_AVAIL" -lt 20 ]; then
    echo "│ ⚠️  CRITICAL: Available memory < 20%               │"
elif [ "$PCT_AVAIL" -lt 40 ]; then
    echo "│ ⚠️  WARNING:  Available memory < 40%               │"
else
    echo "│ ✅ OK:       Available memory > 40%               │"
fi
echo "└─────────────────────────────────────────────────────┘"
```

✅ **Expected**: Color-coded memory health report with pressure indicators

### Practice 15: Complete Memory Audit

```bash
#!/bin/bash
# memory_audit.sh — Full system memory audit
echo "============================================"
echo "  COMPLETE MEMORY AUDIT — $(date)"
echo "============================================"
echo ""

echo "=== 1. Physical Memory ==="
free -h
echo ""

echo "=== 2. Memory per Process (Top 10) ==="
ps aux --sort=-%mem | head -11
echo ""

echo "=== 3. Slab Memory (Top 10) ==="
sudo slabtop -o -s c 2>/dev/null | head -15
echo ""

echo "=== 4. NUMA Topology ==="
numactl --hardware 2>/dev/null || echo "NUMA not available"
echo ""

echo "=== 5. Overcommit Settings ==="
echo "overcommit_memory: $(cat /proc/sys/vm/overcommit_memory)"
echo "overcommit_ratio: $(cat /proc/sys/vm/overcommit_ratio)"
echo "CommitLimit: $(awk '/CommitLimit/{printf "%.1f GB", $2/1048576}' /proc/meminfo)"
echo "Committed_AS: $(awk '/Committed_AS/{printf "%.1f GB", $2/1048576}' /proc/meminfo)"
echo ""

echo "=== 6. Swap Devices ==="
sudo swapon --show 2>/dev/null || echo "No swap"
echo ""

echo "=== 7. OOM Configuration ==="
echo "vm.panic_on_oom: $(cat /proc/sys/vm/panic_on_oom)"
echo ""
echo "Protected processes (oom_score_adj < 0):"
for pid in /proc/[0-9]*/oom_score_adj; do
    val=$(cat "$pid" 2>/dev/null)
    if [ "$val" -lt 0 ] 2>/dev/null; then
        comm=$(cat "$(dirname $pid)/comm" 2>/dev/null)
        echo "  PID $(basename $(dirname $pid)): $comm (adj=$val)"
    fi
done
echo ""

echo "=== 8. Recent OOM Events ==="
dmesg | grep -i "oom\|out of memory\|killed process" | tail -5 || echo "No OOM events"
echo ""

echo "=== 9. Page Fault Rate ==="
echo "Before: $(grep pgmajfault /proc/vmstat)"
sleep 5
echo "After:  $(grep pgmajfault /proc/vmstat)"
echo ""
echo "============================================"
echo "  AUDIT COMPLETE"
echo "============================================"
```

✅ **Expected**: Complete memory audit covering physical, virtual, slab, NUMA, swap, OOM, and overcommit

---

## Deep Understanding

### Linux Memory Management Pipeline

```
┌──────────────────────────────────────────────────────────────────┐
│                  MEMORY ALLOCATION PIPELINE                        │
│                                                                    │
│  Process calls malloc()                                            │
│         │                                                          │
│         ▼                                                          │
│  ┌─────────────────┐                                               │
│  │  Overcommit      │ ← Is virtual allocation allowed?            │
│  │  Check           │   (mode 0: heuristic, 1: always, 2: never) │
│  └────────┬────────┘                                               │
│           │ YES                                                    │
│           ▼                                                        │
│  ┌─────────────────┐                                               │
│  │  Virtual Address │ ← Process gets virtual pages                │
│  │  Allocated       │   (no physical RAM yet!)                    │
│  └────────┬────────┘                                               │
│           │ Process touches memory (first write/read)              │
│           ▼                                                        │
│  ┌─────────────────┐                                               │
│  │  Page Fault      │ ← CPU trap: page not in RAM                 │
│  │  Handler         │   (minor fault: page in cache)              │
│  └────────┬────────┘   (major fault: must read from disk)        │
│           │                                                        │
│           ▼                                                        │
│  ┌─────────────────┐                                               │
│  │  Physical Page   │ ← Buddy allocator finds free 4KB page      │
│  │  Allocation      │   from correct NUMA zone                    │
│  └────────┬────────┘                                               │
│           │                                                        │
│           ▼                                                        │
│  ┌─────────────────┐                                               │
│  │  Page Table      │ ← MMU maps virtual → physical              │
│  │  Update          │   (TLB updated for fast future access)     │
│  └────────┬────────┘                                               │
│           │                                                        │
│           ▼                                                        │
│  ┌─────────────────┐                                               │
│  │  Memory Ready    │ ← Process can use the page                  │
│  │  for Use         │                                             │
│  └─────────────────┘                                               │
└──────────────────────────────────────────────────────────────────┘
```

### Page Reclaim Decision Tree

```
┌──────────────────────────────────────────────────────────────────┐
│                PAGE RECLAIM DECISION TREE                          │
│                                                                    │
│  Memory pressure detected (watermark reached)                     │
│         │                                                          │
│         ▼                                                          │
│  ┌─────────────────┐                                               │
│  │ kswapd wakes up  │ ← Background reclaim daemon                │
│  └────────┬────────┘                                               │
│           │                                                        │
│           ▼                                                        │
│  ┌─────────────────┐                                               │
│  │ Check inactive   │ ← Recently unused pages go here            │
│  │ list first       │   (file-backed: clean pages can be dropped) │
│  └────────┬────────┘   (anonymous: must swap if reclaimed)       │
│           │                                                        │
│           ▼                                                        │
│  ┌─────────────────┐                                               │
│  │ Is page dirty?   │                                               │
│  │  YES → writeback │ ← Write to disk before reclaiming          │
│  │  NO  → discard   │ ← Can be reclaimed immediately             │
│  └────────┬────────┘                                               │
│           │                                                        │
│           ▼                                                        │
│  ┌─────────────────┐                                               │
│  │ Is swap full?    │                                               │
│  │  YES → OOM Kill  │ ← No place for anonymous pages             │
│  │  NO  → swap out  │ ← Write to swap, free physical page        │
│  └─────────────────┘                                               │
└──────────────────────────────────────────────────────────────────┘
```

### Why "Available" Matters More Than "Free"

```
┌──────────────────────────────────────────────────────────────────┐
│              free vs available — THE KEY INSIGHT                   │
│                                                                    │
│  "Free" = memory not used by anything                             │
│           (includes no page cache, no slab — truly empty)          │
│                                                                    │
│  "Available" = memory that CAN be used without swapping            │
│                = Free + reclaimable cache + reclaimable slab       │
│                                                                    │
│  Example on a healthy 32GB server:                                 │
│  ┌──────────────────────────────────────────────┐                 │
│  │ Total: 32GB                                   │                 │
│  │ ├─ Apps (RSS):     4GB  ████████             │                 │
│  │ ├─ Page Cache:    22GB  ██████████████████████│ ← reclaimable! │
│  │ ├─ Slab:           3GB  ██████               │ ← reclaimable! │
│  │ └─ Free:           3GB  ██████               │                 │
│  │                                                │                 │
│  │ "free" = 3GB  (looks low!)                     │                 │
│  │ "available" = 3GB + reclaimable = ~27GB (plenty!) │             │
│  └──────────────────────────────────────────────┘                 │
│                                                                    │
│  If apps need 5GB more memory:                                     │
│  → Kernel evicts 5GB of page cache (instant, no disk I/O)         │
│  → Apps get memory, system continues normally                     │
│  → This is NOT a problem — it's how Linux is designed              │
└──────────────────────────────────────────────────────────────────┘
```

### OOM Killer Decision Flow

```
┌──────────────────────────────────────────────────────────────────┐
│                    OOM KILLER SELECTION                            │
│                                                                    │
│  1. System out of memory + swap full + can't reclaim more         │
│         │                                                          │
│         ▼                                                          │
│  2. OOM killer activated                                           │
│         │                                                          │
│         ▼                                                          │
│  3. For each process:                                              │
│     ┌─────────────────────────────────────────────┐               │
│     │ score = RSS + page_cache + swap              │               │
│     │ if (oom_score_adj != 0)                      │               │
│     │     score += oom_score_adj × 10              │               │
│     │ if (process has CAP_SYS_ADMIN)               │               │
│     │     score = 0  (protected)                   │               │
│     └─────────────────────────────────────────────┘               │
│         │                                                          │
│         ▼                                                          │
│  4. Select process with highest score                              │
│         │                                                          │
│         ▼                                                          │
│  5. If oom_score_adj == -1000, skip (fully protected)             │
│         │                                                          │
│         ▼                                                          │
│  6. Send SIGKILL to victim process                                 │
│         │                                                          │
│         ▼                                                          │
│  7. Log to dmesg: "Out of memory: Killed process <PID> (<name>)"  │
└──────────────────────────────────────────────────────────────────┘
```

---

## Command Reference

| Task | Command |
|------|---------|
| View total/available memory | `free -h` |
| Detailed memory info | `cat /proc/meminfo` |
| Real-time memory stats | `vmstat 1` |
| Per-process memory | `ps aux --sort=-%mem` |
| Memory map of process | `pmap -x <PID>` |
| NUMA topology | `numactl --hardware` |
| NUMA statistics | `numastat` |
| Pin to NUMA node | `numactl --cpunodebind=0 --membind=0 <cmd>` |
| Interleave NUMA | `numactl --interleave=all <cmd>` |
| Drop page cache | `echo 3 > /proc/sys/vm/drop_caches` |
| View slab allocations | `slabtop -o -s c` |
| Set swappiness | `sysctl vm.swappiness=1` |
| Set overcommit mode | `sysctl vm.overcommit_memory=2` |
| Protect from OOM | `echo -1000 > /proc/<PID>/oom_score_adj` |
| Create swap file | `fallocate -l 4G /swapfile && mkswap /swapfile` |
| Setup zram | `modprobe zram && echo lz4 > /sys/block/zram0/comp_algorithm` |
| Enable huge pages | `echo 1024 > /proc/sys/vm/nr_hugepages` |
| View memory maps | `cat /proc/<PID>/maps` |
| Monitor page faults | `cat /proc/vmstat \| grep pgfault` |
| Check swap usage | `swapon --show` |

---

## What's Coming in Part 63

```
┌─────────────────────────────────────────────────────────────────┐
│   Part 63: eBPF & Modern Tracing                                │
├─────────────────────────────────────────────────────────────────┤
│   • What is eBPF and why it changed Linux tracing                │
│   • BCC tools: bpftrace, bcc, libbpf                            │
│   • Tracing syscalls, function calls, and kernel events          │
│   • Network tracing with XDP (eXpress Data Path)                 │
│   • Security monitoring with eBPF (Falco, Tracee)               │
│   • Performance analysis with perf and flame graphs              │
│   • Real-world eBPF recipes for sysadmins                       │
│   • Writing custom bpftrace one-liners                           │
│   • eBPF for container monitoring                                │
└─────────────────────────────────────────────────────────────────┘
```

---

## Self-Test

1. What is the difference between `free` and `available` in `free -h` output?
2. When should you use `vm.swappiness=0` vs `vm.swappiness=60`?
3. What is the difference between zram and zswap?
4. How does NUMA affect memory access performance?
5. What command pins a process to a specific NUMA node?
6. How does the OOM Killer select which process to kill?
7. What does `oom_score_adj=-1000` do?
8. What is the difference between `overcommit_memory=0`, `1`, and `2`?
9. Why is `overcommit_memory=2` recommended for databases?
10. How do you safely drop page cache without affecting performance?
11. What is a major page fault vs a minor page fault?
12. How do you set up zram as a compressed swap device?
13. Why should PostgreSQL be run with `numactl --interleave=all`?
14. What is slab memory and why does it grow?
15. How do you find which process is using the most swap?

**Answers:**
1. `free` = completely unused RAM; `available` = memory usable without swapping (free + reclaimable cache + reclaimable slab). Always watch `available`.
2. `swappiness=0` = avoid swapping until necessary (servers); `swappiness=60` = swap actively to free page cache (old default, desktops).
3. zram = compressed block device in RAM (acts as diskless swap); zswap = compressed cache intercepting swap writes before they hit disk. zram for no-disk systems, zswap for SSD protection.
4. Local memory access is 50-100% faster than remote. NUMA imbalance causes processes to access remote memory, degrading throughput significantly.
5. `numactl --cpunodebind=N --membind=N ./process`
6. Calculates score from RSS + page cache + swap usage, modified by `oom_score_adj`. Highest score (excluding protected processes) is killed first.
7. Completely protects a process from OOM killer — it will never be selected as the victim.
8. 0=heuristic (guesses), 1=always allow (no checks), 2=never (strict limit based on ratio).
9. Databases allocate large shared memory regions. With mode 0/1, overcommit may allow more than physical RAM, leading to OOM kills. Mode 2 guarantees allocations fit in RAM+swap.
10. `echo 3 > /proc/sys/vm/drop_caches` clears cache, but subsequent reads rebuild it. Don't drop on production during load — let the kernel manage cache naturally.
11. Minor = page was in memory (page cache hit or zero page). Major = page had to be read from disk (expensive). High major fault rate = memory pressure.
12. `modprobe zram; echo lz4 > /sys/block/zram0/comp_algorithm; echo 4G > /sys/block/zram0/disksize; mkswap /dev/zram0; swapon -p 100 /dev/zram0`
13. PostgreSQL uses shared memory. NUMA-local allocation would put all shared buffers on one node, starving other nodes. Interleaving distributes memory evenly across NUMA nodes.
14. Slab = kernel memory for data structures (inodes, dentries, task_struct). It grows to cache frequently accessed kernel objects and can be reclaimed via `slabtop` monitoring and `echo 2 > /proc/sys/vm/drop_caches`.
15. `for f in /proc/[0-9]*/status; do awk '/VmSwap/{printf "%s %s\n", $2, $3}' "$f" 2>/dev/null; done | sort -k2 -rn | head -10`

**Score:** 12/15 correct = ready for Part 63.

---

*Linux SysAdmin Course | Part 62 of ∞ | Reverse Engineering Approach*
*Previous → Part 61: Filesystem Internals*
*Next → Part 63: eBPF & Modern Tracing*

[← Previous](part61.md) | [Next →](part63.md)
