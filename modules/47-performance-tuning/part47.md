# 🐧 Linux System Administrator — Complete Course
## Part 47 of ∞: Performance Tuning and Optimization

---

> **Reverse Engineering Approach:** Systems don't come with a label saying "I am slow because of X." Instead of blindly applying tuning recipes from blog posts, we start from measurable symptoms — high latency, low throughput, OOM kills, CPU steals — and trace them backward through kernel machinery until we find the root cause. Every knob we turn is grounded in evidence.

---

## 🎯 What You Will Achieve in Part 47

By the end of this part, you will:

- **Apply a systematic tuning methodology** (USE method, latency analysis) instead of guessing
- **Tune CPU performance** — governors, isolation, affinity, irqbalance
- **Optimize memory** — swappiness, dirty pages, huge pages, NUMA binding
- **Tune disk I/O** — schedulers, queue depth, ionice, filesystem mount flags
- **Tune network** — kernel buffers, ring buffers, RSS, RPS, XPS
- **Use perf, strace, bpftrace** to identify real bottlenecks
- **Benchmark** systems properly with stress-ng, fio, iperf3, sysbench
- **Write a full performance audit report**

---

## 📋 Prerequisites

| Requirement | Details |
|-------------|---------|
| OS | Ubuntu 22.04+ / Debian 12+ / RHEL 9+ |
| Access | Root or `sudo` on a physical or virtual machine |
| Packages | `linux-tools-common`, `linux-tools-$(uname -r)`, `perf`, `bpftrace`, `strace`, `stress-ng`, `fio`, `iperf3`, `sysbench`, `numactl` |
| Kernel | 5.x+ recommended (for bpftrace, BTF support) |
| Time | 4–5 hours of hands-on lab work |

---

## 🔍 Section 1: Performance Tuning Methodology

### Measure Before Changing

Every performance intervention must start with measurement. If you cannot measure the problem, you cannot confirm the fix.

```
┌─────────────┐     ┌──────────────┐     ┌─────────────┐
│  Measure    │────►│  Identify    │────►│  Change     │
│  Baseline   │     │  Bottleneck  │     │  One Thing  │
└─────────────┘     └──────────────┘     └─────────────┘
                                                  │
                  ┌──────────────┐               │
                  │  Verify      │◄──────────────┘
                  │  Improvement │
                  └──────────────┘
```

### Baseline

Before you touch anything, record your current performance:

```bash
# CPU baseline
mpstat -P ALL 1 5

# Memory baseline
vmstat 1 5

# Disk I/O baseline
iostat -x 1 5

# Network baseline
sar -n DEV 1 5

# Overall
dstat --cpu --mem --disk --net 1 5
```

### The USE Method (Utilization, Saturation, Errors)

Developed by Brendan Gregg, USE is the most systematic approach to bottleneck identification:

| Resource | Utilization | Saturation | Errors |
|----------|-------------|------------|--------|
| **CPU** | `mpstat` %usr+%sys | Load average, run queue (`vmstat` r column) | `mcelog`, `perf` |
| **Memory** | `free -m` used/total | swap usage, `vmstat` si/so | `dmesg` OOM |
| **Disk** | `iostat -x` %util | `iostat -x` avgqu-sz, await vs svctm | `dmesg` I/O errors |
| **Network** | `sar -n DEV` %ifutil | `netstat` overflows, drops | `ethtool -S` errors |

**The USE checklist:**

1. For every resource, check **Utilization** — is it near 100%?
2. Check **Saturation** — is there more demand than the resource can handle?
3. Check **Errors** — are there error counters incrementing?

```bash
# Quick USE scan script
echo "=== CPU ===" && mpstat 1 1 | tail -1
echo "=== LOAD ===" && uptime
echo "=== MEMORY ===" && free -h
echo "=== SWAP ===" && vmstat 1 1 | tail -1 | awk '{print "si=" $7 " so=" $8}'
echo "=== DISK ===" && iostat -x 1 1 | tail -3
echo "=== NETWORK ERRORS ===" && ip -s link | grep -E "(errors|dropped|over)"
```

### Latency Analysis

Latency analysis measures *how long* each operation takes, then breaks it down into components:

```bash
# Measure command execution time
time some_command

# Measure latency distribution with perf
perf stat some_command

# Trace specific system call latencies
strace -T -e trace=read some_command 2>&1 | grep "<0.0"
```

**The key insight:** Throughput problems are often caused by latency spikes at a lower level. A single slow disk I/O can stall an entire application pipeline.

### One Change at a Time

Change exactly one variable, remeasure, confirm improvement, revert if not. Never tune multiple knobs simultaneously — you won't know which one helped or hurt.

```bash
# WRONG — changed three things at once
echo 10 > /proc/sys/vm/swappiness
echo 50 > /proc/sys/vm/dirty_ratio
echo 1 > /sys/block/sda/queue/scheduler

# RIGHT — tune, measure, verify, then move on
sysctl vm.swappiness=10
# remeasure
# now change dirty_ratio
```

---

## 🔍 Section 2: CPU Tuning

### CPU Governors

Linux CPU frequency scaling allows the kernel to adjust clock speed and voltage.

```bash
# List available governors
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors

# Check current governor
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor

# Set all CPUs to performance (maximum frequency, no scaling down)
echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

# Set to powersave (lowest frequency)
echo powersave | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

# On some systems, use cpupower
sudo cpupower frequency-set -g performance
```

| Governor | Use Case |
|----------|----------|
| `performance` | Latency-sensitive workloads (databases, trading, real-time) |
| `powersave` | Battery-powered, idle-heavy systems |
| `ondemand` | Default on older kernels — ramp up on demand |
| `conservative` | Slower ramp-up than ondemand |
| `schedutil` | Modern default — frequency hints from scheduler |

### CPU Isolation — `isolcpus`

Isolate cores from the general scheduler so dedicated processes can run without interference:

Add to kernel command line in `/etc/default/grub`:

```
GRUB_CMDLINE_LINUX="isolcpus=2,3 nohz_full=2,3 rcu_nocbs=2,3"
```

Then rebuild:

```bash
sudo update-grub
sudo reboot
```

| Parameter | Effect |
|-----------|--------|
| `isolcpus=2,3` | Kernel scheduler will not schedule regular tasks on CPU 2-3 |
| `nohz_full=2,3` | Disable timer ticks on isolated CPUs (reduce overhead) |
| `rcu_nocbs=2,3` | Offload RCU callbacks from isolated CPUs |

After isolation, bind your workload:

```bash
# Bind a process to isolated CPUs
sudo taskset -c 2,3 ./my_latency_sensitive_app
```

### Process Affinity with `taskset`

Control which CPUs a process or thread can run on:

```bash
# Check affinity of a running process
taskset -p 1234

# Set affinity (bind to CPUs 0 and 2)
sudo taskset -pc 0,2 1234

# Launch a program on specific CPUs
taskset -c 0,1 ./myapp

# Mask format (hexadecimal bitmask)
taskset -p 0x3 1234   # CPUs 0 and 1
taskset -p 0xF 1234   # CPUs 0,1,2,3
```

### `irqbalance`

IRQ balancing spreads hardware interrupt handlers across CPUs:

```bash
# Check status
systemctl status irqbalance

# Stop irqbalance for manual IRQ affinity (advanced tuning)
sudo systemctl stop irqbalance

# Manual IRQ affinity — assign NIC IRQs to specific CPUs
# Find IRQ for your NIC
grep eth0 /proc/interrupts

# Set smp_affinity for that IRQ (CPU 0 only = 0x00000001)
echo 1 | sudo tee /proc/irq/48/smp_affinity
```

### CPU Pinning for VMs and Containers

**KVM/QEMU:**

```bash
# Pin vCPUs to physical CPUs in libvirt XML
virsh vcpupin vm_name 0 2   # vCPU 0 -> pCPU 2
virsh vcpupin vm_name 1 3   # vCPU 1 -> pCPU 3
```

**Docker:**

```bash
# Pin container to specific CPUs
docker run --cpuset-cpus="0-2" myimage

# In docker-compose:
# deploy:
#   resources:
#     reservations:
#       cpus: "0-2"
```

**CPU steal time — the VM red flag:**

```
# Inside a VM, check for steal time
# If %steal > 5%, the hypervisor is overcommitted
top # look for %steal column
mpstat -P ALL 1 | grep steal
```

---

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

## 🔍 Section 4: Disk I/O Tuning

### I/O Schedulers

The I/O scheduler decides the order in which block requests are dispatched to storage.

```bash
# Check current scheduler
cat /sys/block/sda/queue/scheduler

# Change scheduler (takes effect immediately)
echo mq-deadline | sudo tee /sys/block/sda/queue/scheduler
echo none | sudo tee /sys/block/nvme0n1/queue/scheduler

# Make permanent with udev rule
echo 'ACTION=="add|change", KERNEL=="sd*", ATTR{queue/scheduler}="bfq"' | sudo tee /etc/udev/rules.d/60-iosched.rules
```

| Scheduler | Best For | Characteristics |
|-----------|----------|-----------------|
| `mq-deadline` | HDDs, general-purpose | Per-disk fairness with deadline guarantees |
| `kyber` | Fast SSDs, NVMe | Low-latency, self-tuning |
| `BFQ` | Desktop, interactive | Per-process fairness, good for shared storage |
| `none` | NVMe, high-end SSDs | No reordering — pass through to device |

**Scheduler tunables:**

```bash
# mq-deadline tunables
cat /sys/block/sda/queue/iosched/read_expire       # default 500 ms
cat /sys/block/sda/queue/iosched/write_expire      # default 5000 ms
cat /sys/block/sda/queue/iosched/front_merges      # 1 (enable)

# BFQ tunables
cat /sys/block/sda/queue/iosched/weight_sched      # proportional weight scheduling
```

### Block Device Queue Depth

Controls how many I/O requests can be queued at the device driver level:

```bash
# Check current queue depth
cat /sys/block/sda/queue/nr_requests

# Increase for better throughput on NVMe (at cost of latency)
echo 1024 | sudo tee /sys/block/sda/queue/nr_requests

# Also check device hardware queue depth
cat /sys/block/nvme0n1/device/queue_depth
```

### Read-Ahead

Controls how much data the kernel reads ahead when detecting sequential access:

```bash
# Check read-ahead (in 512-byte sectors)
blockdev --getra /dev/sda

# Set read-ahead to 4 MB (8192 sectors)
sudo blockdev --setra 8192 /dev/sda
```

### I/O Priority with `ionice`

Set I/O scheduling class and priority for processes:

```bash
# Check current ionice class/priority
ionice -p 1234

# Set Best Effort priority 4 (0=highest, 7=lowest)
ionice -c 2 -n 4 -p 1234

# Launch a backup at idle priority (only runs when no one else needs I/O)
ionice -c 3 -n 0 tar czf backup.tar.gz /data
```

| Class (`-c`) | Name | When to use |
|--------------|------|-------------|
| 0 | None (default) | Normal best-effort |
| 1 | RT (Real-time) | Highest priority — can starve others |
| 2 | Best Effort | Normal processes, default priority 4 |
| 3 | Idle | Only runs when disk is otherwise idle |

### Filesystem Mount Options

Mount options have a significant effect on I/O performance:

```bash
# Check current mount options
mount | grep /data

# Remount with performance options
sudo mount -o remount,noatime,nodiratime,relatime /data
```

| Option | Effect | Performance Impact |
|--------|--------|-------------------|
| `noatime` | Do not update access time on reads | Avoids a write on every read |
| `nodiratime` | Do not update directory access times | Same for directories |
| `relatime` | Update atime only if older than mtime | Good compromise (kernel default since 2.6.30) |
| `noexec` | Disable binary execution from the mount | Security + minor perf (no exec check) |
| `barrier=0` | Disable write barriers (XFS/ext4) | Danger: risk of metadata corruption on crash |
| `nobarrier` | Disable barriers (btrfs, others) | Same warning |
| `data=writeback` | ext4 — no journaling for data | Faster, risk of stale data on crash |

**Warning:** Never disable barriers on production databases. The performance gain is not worth the corruption risk.

---

## 🔍 Section 5: Network Tuning

### sysctl Network Parameters

Most network tuning is done through sysctl parameters under `net.*`.

**Socket Buffers:**

```bash
# Default socket buffer sizes
sysctl net.core.rmem_default     # default receive buffer (212992)
sysctl net.core.wmem_default     # default send buffer (212992)

# Maximum socket buffer sizes
sysctl net.core.rmem_max          # max receive buffer
sysctl net.core.wmem_max          # max send buffer

# TCP buffer sizes (min, default, max in bytes)
sysctl net.ipv4.tcp_rmem          # "4096 131072 6291456"
sysctl net.ipv4.tcp_wmem          # "4096 16384 4194304"
```

**Tuning for high-throughput network:**

```bash
# Increase max socket buffer
sudo sysctl net.core.rmem_max=134217728
sudo sysctl net.core.wmem_max=134217728

# Auto-tune TCP buffers aggressively
sudo sysctl net.ipv4.tcp_rmem="4096 87380 134217728"
sudo sysctl net.ipv4.tcp_wmem="4096 65536 134217728"

# Enable TCP window scaling
sudo sysctl net.ipv4.tcp_window_scaling=1

# Enable TCP timestamps (better RTT estimation)
sudo sysctl net.ipv4.tcp_timestamps=1
```

**Packet Processing:**

```bash
# netdev_budget — how many packets to process per NAPI poll
# Higher = more throughput per interrupt, higher latency
sudo sysctl net.core.netdev_budget=600

# somaxconn — max listen backlog
sudo sysctl net.core.somaxconn=65536

# tcp_max_syn_backlog — SYN flood protection buffer
sudo sysctl net.ipv4.tcp_max_syn_backlog=65536

# Enable TCP fast open
sudo sysctl net.ipv4.tcp_fastopen=3
```

### Interface Queue Length

```bash
# Check current txqueuelen
ip link show eth0 | grep qlen

# Increase for high-throughput scenarios
sudo ip link set dev eth0 txqueuelen 10000

# Make permanent in /etc/rc.local or netplan/network-scripts
```

### Ring Buffers (`ethtool -G`)

NIC ring buffers hold packets between the hardware and the kernel:

```bash
# Check current ring buffer sizes
sudo ethtool -g eth0

# Increase RX and TX ring buffers (reduces drops under load)
sudo ethtool -G eth0 rx 4096 tx 4096

# Check for packet drops
sudo ethtool -S eth0 | grep -E "(drop|discard|error)"
```

### RSS (Receive Side Scaling) with RPS/XPS

**RSS (hardware):** NIC distributes packets across multiple RX queues, each handled by a different CPU.

```bash
# Check number of RX queues
ls /sys/class/net/eth0/queues/rx-*

# Set RSS with ethtool
# Distribute to CPUs 0-3 (bitmask 0xF)
sudo ethtool -X eth0 equal 4

# Or set custom indirection table
sudo ethtool -X eth0 weight 1 1 1 1
```

**RPS (software RSS):** Distribute packet processing across CPUs when NIC doesn't support RSS:

```bash
# Enable RPS on eth0 — use CPUs 0-3
echo f | sudo tee /sys/class/net/eth0/queues/rx-0/rps_cpus

# Flow count table size
echo 4096 | sudo tee /sys/class/net/eth0/queues/rx-0/rps_flow_cnt
```

**XPS (Transmit Packet Steering):** Spread TX processing across CPUs:

```bash
# Set XPS for TX queue 0 to use CPUs 0-3
echo f | sudo tee /sys/class/net/eth0/queues/tx-0/xps_cpus
```

---

## 🔍 Section 6: Kernel Parameters

### sysctl Overview

`sysctl` reads and writes kernel parameters at runtime through `/proc/sys/`.

```bash
# List all parameters
sudo sysctl -a | wc -l    # thousands of tunables

# Read a single parameter
sysctl net.ipv4.tcp_tw_reuse

# Write a parameter (runtime only, resets on reboot)
sudo sysctl vm.swappiness=10

# Make permanent
echo "vm.swappiness=10" | sudo tee -a /etc/sysctl.conf

# Apply from config files
sudo sysctl -p              # /etc/sysctl.conf
sudo sysctl -p /etc/sysctl.d/99-custom.conf
```

### Configuration File Layout

```
/etc/sysctl.conf              # Main config (legacy)
/etc/sysctl.d/                # Drop-in directory
  ├── 10-network-security.conf
  ├── 99-custom.conf
  └── README
/usr/lib/sysctl.d/            # Distribution defaults
```

Files are loaded in lexicographic order. Later values override earlier ones.

### Parameter Groups

| Group | Prefix | Examples |
|-------|--------|---------|
| Kernel | `kernel.*` | `kernel.pid_max`, `kernel.sched_migration_cost_ns`, `kernel.numa_balancing` |
| Virtual Memory | `vm.*` | `vm.swappiness`, `vm.dirty_ratio`, `vm.overcommit_memory`, `vm.nr_hugepages` |
| Network | `net.*` | `net.ipv4.tcp_rmem`, `net.core.rmem_max`, `net.ipv4.ip_forward` |
| Filesystem | `fs.*` | `fs.file-max`, `fs.inotify.max_user_watches`, `fs.aio-max-nr` |

### Applying Changes

```bash
# Immediate (but not persistent)
sudo sysctl -w vm.swappiness=10

# From a config file
sudo sysctl -p /etc/sysctl.d/custom.conf

# Reload all sysctl configs
sudo sysctl --system

# Check if change took effect
sysctl vm.swappiness
```

---

## 🔍 Section 7: Tuned — Automated Performance Tuning

`tuned` is a system tuning daemon that applies predefined or custom performance profiles. It adjusts kernel parameters, disk scheduler settings, CPU governor, and more — all from a single profile switch.

```bash
# Install
sudo dnf install tuned      # RHEL/Fedora
sudo apt install tuned      # Debian/Ubuntu

# Enable and start
sudo systemctl enable --now tuned

# List available profiles
tuned-adm list

# Check active profile
tuned-adm active

# Switch to a profile
sudo tuned-adm profile throughput-performance
sudo tuned-adm profile latency-performance
sudo tuned-adm profile powersave
```

### Common Profiles

| Profile | Use Case |
|---------|----------|
| `throughput-performance` | Server workloads — maximizes disk/network throughput |
| `latency-performance` | Low-latency applications — disables power saving |
| `virtual-guest` | VMs — optimizes for virtualization overhead |
| `powersave` | Laptops/energy-efficient — minimizes power consumption |
| `balanced` | Default — good mix of performance and power |

### Creating Custom Profiles

```bash
# Copy an existing profile
sudo cp -r /usr/lib/tuned/throughput-performance /etc/tuned/myprofile

# Edit the tuned.conf
sudo vi /etc/tuned/myprofile/tuned.conf

# Customize sections:
# [cpu] governor=performance
# [disk] elevator=none
# [vm] transparent_hugepages=always
# [sysctl] kernel.numa_balancing=1

# Activate custom profile
sudo tuned-adm profile myprofile
```

`tuned` also supports `tuned-adm recommend` which detects the hardware (bare metal, VM, laptop) and suggests the best profile automatically.

---

## 🔍 Section 8: Perf — Linux Profiler

`perf` uses hardware Performance Monitoring Counters (PMCs) and kernel tracepoints to profile the system with minimal overhead.

### perf stat — Count Events

Counts specific events during a command's execution:

```bash
# Basic CPU cycle count
perf stat ls

# Count specific events
perf stat -e cycles,instructions,cache-misses,branch-misses ./myapp

# Count all available events on a running process
sudo perf stat -p 1234 -e cycles,instructions,cache-misses sleep 10

# System-wide counting for 5 seconds
sudo perf stat -a -e cycles,instructions,cache-misses sleep 5

# Get IPC (Instructions Per Cycle) — lower IPC = less efficient code
# perf stat automatically shows IPC
```

Output example:
```
 Performance counter stats for 'ls':

          1,234,567      cycles                    #    3.45 GHz
          2,345,678      instructions              #    1.90  insn per cycle
             12,345      cache-misses              #    5.2% of all cache refs
              5,678      branch-misses             #    2.1% of all branches

       0.001234567 seconds time elapsed
```

### perf record/report — CPU Profiling

Samples the running program at a fixed frequency and records what it's executing:

```bash
# Profile a command
perf record ./myapp

# Profile an already running process for 10 seconds
sudo perf record -p 1234 -a --sleep 10

# Record with call-graph (dwarf for user-space, fp for kernel)
perf record -g ./myapp
perf record --call-graph dwarf ./myapp

# View the profile
perf report

# Interactive TUI: sort by overhead, zoom into functions
# Press 'h' for help, 'Enter' to zoom into a function
```

### perf top — Live Profiling

Shows live CPU usage, sampled in-kernel:

```bash
# Live view of hottest functions
sudo perf top

# Annotate specific calls
sudo perf top -e cache-misses

# Show user-space symbols too
sudo perf top -a -g
```

### perf list — Available Events

```bash
# List all events
perf list

# List hardware events
perf list hw

# List software events
perf list sw

# List tracepoints
perf list tracepoint

# List PMU events (Intel)
perf list pmu
```

### Flame Graphs

Flame graphs visualize CPU profiles — each rectangle is a function call, width = time spent:

```bash
# Step 1: Record with stack traces
sudo perf record -F 99 -ag -- sleep 60

# Step 2: Generate folded stack output
sudo perf script > /tmp/perf.script

# Step 3: Generate SVG flamegraph
# Requires FlameGraph tools
git clone https://github.com/brendangregg/FlameGraph
cd FlameGraph
./stackcollapse-perf.pl /tmp/perf.script > /tmp/perf.folded
./flamegraph.pl /tmp/perf.folded > /tmp/perf.svg
# Open perf.svg in browser
```

---

## 🔍 Section 9: strace and ltrace

### strace — System Call Tracing

Traces every system call a process makes:

```bash
# Trace a command's syscalls
strace ls

# Show only specific syscalls
strace -e trace=open,read,write ls

# Show a summary (count, time, errors per syscall)
strace -c ls

# Attach to a running process
strace -p 1234

# Follow child processes (forks)
strace -f -c nginx

# Timestamps and relative times
strace -r ls         # relative timestamps
strace -T ls         # syscall duration

# Output to file
strace -o /tmp/strace.out -p 1234
```

**Identifying slow syscalls:**

```bash
# Find syscalls taking longer than 1 ms
strace -T -e trace=all 2>&1 ./slowapp | grep "<0.00[1-9]"

# Summarize the slowest
strace -c -w ./slowapp   # -w = summarize wall-clock time

# Common performance-draining syscalls:
# - read()/write() on slow I/O
# - poll()/select()/epoll_wait() with long timeouts
# - open()/stat() on many small files
# - mmap()/munmap() frequent allocations
```

**Practical example — find what's slowing a web request:**

```bash
# Attach to an nginx worker
sudo strace -p $(pgrep -o nginx) -e trace=network -T 2>&1 | head -50

# Or Apache
sudo strace -p $(pgrep httpd | head -1) -e trace=file -T 2>&1 | head -50
```

### ltrace — Library Call Tracing

Traces calls to dynamically linked library functions:

```bash
# Trace library calls
ltrace ls

# With summary
ltrace -c ls

# Attach to process
ltrace -p 1234

# Filter specific library
ltrace -e strcmp+ ./myapp
```

---

## 🔍 Section 10: SystemTap and bpftrace

### bpftrace — Dynamic Tracing

`bpftrace` is a high-level tracing language for Linux eBPF. It can probe kernel functions, user-space functions, tracepoints, and hardware events.

**Installation:**

```bash
# Ubuntu/Debian
sudo apt install bpftrace

# RHEL/CentOS 8+
sudo dnf install bpftrace
```

**One-liners:**

```bash
# New processes with arguments
bpftrace -e 'tracepoint:syscalls:sys_enter_execve { printf("%s\n", str(args->filename)); }'

# Files opened per second
bpftrace -e 'tracepoint:syscalls:sys_enter_openat { @[comm] = count(); }'

# Block I/O latency histogram
bpftrace -e 'kprobe:blk_account_io_done { @usecs = hist(nsecs / 1000); }'

# Read distribution for a process
bpftrace -e 'tracepoint:syscalls:sys_exit_read /pid == 1234/ { @bytes = hist(args->ret); }'

# Disk I/O size distribution
bpftrace -e 'tracepoint:block:block_rq_issue { @bytes = hist(args->bytes); }'

# TCP connect by process
bpftrace -e 'kprobe:tcp_connect { @[comm] = count(); }'

# Count syscalls by process
bpftrace -e 'tracepoint:syscalls:sys_enter_read { @[comm] = count(); }'
```

**Latency histogram for block I/O:**

```bash
sudo bpftrace -e 'kprobe:blk_account_io_start { @start[tid] = nsecs; }
    kprobe:blk_account_io_done /@start[tid]/ {
        @usecs = hist((nsecs - @start[tid]) / 1000);
        delete(@start[tid]);
    }'
```

**Latency histogram for syscalls:**

```bash
sudo bpftrace -e 'tracepoint:syscalls:sys_enter_read { @start[tid] = nsecs; }
    tracepoint:syscalls:sys_exit_read /@start[tid]/ {
        @usecs = hist((nsecs - @start[tid]) / 1000);
        delete(@start[tid]);
    }'
```

### SystemTap

SystemTap is an older tracing framework that compiles probe scripts into kernel modules:

```bash
# Install
sudo apt install systemtap systemtap-runtime

# Hello world probe
sudo stap -e 'probe begin { printf("Hello from SystemTap\n"); exit(); }'

# Count syscalls per process
sudo stap -e 'global c; probe syscall.read { c[pid(), execname()]++ }
    probe timer.s(10) { foreach([pid, name] in c) printf("%d %s %d\n", pid, name, c[pid, name]); exit() }'

# I/O latency histogram
sudo stap -e 'global iotime; probe ioblock.request { iotime[tid()] = gettimeofday_us() }
    probe ioblock.end { t = iotime[tid()]; if (t) { latency = gettimeofday_us() - t;
    printf("%d\n", latency); delete iotime[tid()]; } }'
```

**bpftrace vs SystemTap:**

| Feature | bpftrace | SystemTap |
|---------|----------|-----------|
| Kernel requirement | 4.9+ (BPF), 5.x+ recommended | Any (compiles module) |
| Safety | Safe by default (eBPF verifier) | Can crash kernel if misused |
| Overhead | Very low | Low to moderate |
| Ease of use | One-liners, simple syntax | More complex |
| Distribution | Limited (needs BTF or debuginfo) | Needs kernel debuginfo |

---

## 🔍 Section 11: Benchmarking

### stress-ng — System Stress Testing

Generates controlled load on CPU, memory, I/O, and more:

```bash
# Install
sudo apt install stress-ng

# CPU stress — 4 workers, 60 seconds
stress-ng --cpu 4 --timeout 60

# Mixed CPU stress (sqrt, matrix, integer)
stress-ng --cpu 4 --cpu-method matrixprod --timeout 60

# Memory stress — allocate 2 GB per worker
stress-ng --vm 2 --vm-bytes 2G --timeout 60

# I/O stress
stress-ng --hdd 2 --hdd-bytes 4G --timeout 60

# Combined stress (real-world simulation)
stress-ng --cpu 4 --vm 2 --hdd 1 --timeout 120

# Check temperature and throttling during stress
watch -n 1 sensors
```

### fio — Disk Benchmarking

The gold standard for filesystem and block device benchmarking:

```bash
# Install
sudo apt install fio

# Sequential read test
fio --name=seqread --ioengine=libaio --direct=1 --rw=read --bs=1M --size=4G --numjobs=1 --runtime=60 --group_reporting

# Random read test (simulates database workload)
fio --name=randread --ioengine=libaio --direct=1 --rw=randread --bs=4K --size=4G --numjobs=4 --runtime=60 --group_reporting

# Random write test
fio --name=randwrite --ioengine=libaio --direct=1 --rw=randwrite --bs=4K --size=4G --numjobs=4 --runtime=60 --group_reporting

# Mixed 70/30 read-write (typical DB workload)
fio --name=mixed --ioengine=libaio --direct=1 --rw=randrw --rwmixread=70 --bs=8K --size=4G --numjobs=4 --runtime=60 --group_reporting

# Latency percentile output
fio --name=latency --ioengine=libaio --direct=1 --rw=randread --bs=4K --size=1G --runtime=30 --lat_percentiles=1 --output-format=json
```

**fio output — what to look for:**

| Metric | What it tells you |
|--------|-------------------|
| IOPS | Throughput capacity (higher = better) |
| BW (MiB/s) | Bandwidth (higher = better) |
| lat (usec) min/avg/max | Latency distribution |
| clat percentiles | 99th/99.9th percentile latency (critical for QoS) |
| CPU usage | How much CPU the I/O path consumes |

### iperf3 — Network Throughput

```bash
# Install
sudo apt install iperf3

# Server mode
iperf3 -s

# Client mode (10 seconds, 4 parallel streams)
iperf3 -c 192.168.1.100 -t 10 -P 4

# Reverse test (measure download)
iperf3 -c 192.168.1.100 -t 10 -R

# UDP test (jitter and packet loss)
iperf3 -c 192.168.1.100 -t 10 -u -b 1000M
```

### UnixBench

Classic Unix system benchmark:

```bash
# Install
sudo apt install unixbench

# Run (may take 30+ minutes)
ubench

# Or
cd /usr/lib/ubench && ./Run
```

### sysbench

Multi-purpose benchmark for CPU, memory, mutex, and database:

```bash
# Install
sudo apt install sysbench

# CPU benchmark (prime number calculation)
sysbench cpu run

# Memory benchmark
sysbench memory run

# Thread mutex benchmark
sysbench mutex run

# File I/O benchmark
sysbench fileio --file-test-mode=rndrw prepare
sysbench fileio --file-test-mode=rndrw run
sysbench fileio --file-test-mode=rndrw cleanup
```

---

## 🔍 Section 12: Application Tuning

### Database Connection Pooling

Opening a database connection is expensive (TCP handshake + TLS + auth). Connection pooling reuses connections:

**PostgreSQL — PgBouncer:**

```bash
# Install
sudo apt install pgbouncer

# /etc/pgbouncer/pgbouncer.ini
cat <<EOF | sudo tee /etc/pgbouncer/pgbouncer.ini
[databases]
mydb = host=127.0.0.1 port=5432 dbname=mydb

[pgbouncer]
listen_addr = 127.0.0.1
listen_port = 6432
auth_type = scram-sha-256
auth_file = /etc/pgbouncer/userlist.txt
pool_mode = transaction   # best for web workloads
default_pool_size = 25    # per database
max_client_conn = 100
EOF
```

**MySQL — ProxySQL:**

```
mysql> INSERT INTO mysql_servers (hostgroup_id, hostname, port) VALUES (1, '127.0.0.1', 3306);
mysql> INSERT INTO mysql_users (username, password, default_hostgroup) VALUES ('app', 'pass', 1);
mysql> SET mysql-max_connections = 200;
mysql> LOAD MYSQL SERVERS TO RUNTIME; LOAD MYSQL USERS TO RUNTIME; SAVE CONFIG TO DISK;
```

### Web Server Tuning

**Nginx:**

```bash
# /etc/nginx/nginx.conf
worker_processes auto;              # one per CPU core
worker_connections 4096;            # connections per worker
use epoll;                          # efficient event loop

# Enable sendfile (zero-copy)
sendfile on;
tcp_nopush on;
tcp_nodelay on;

# Buffers
client_body_buffer_size 128k;
client_max_body_size 10m;
```

**Apache — MPM Event:**

```bash
# Enable MPM event (Apache 2.4+, higher performance than prefork)
sudo a2dismod mpm_prefork
sudo a2enmod mpm_event

# /etc/apache2/mods-available/mpm_event.conf
<IfModule mpm_event_module>
    StartServers         2
    MinSpareThreads      25
    MaxSpareThreads      75
    ThreadLimit          64
    ThreadsPerChild      25
    MaxRequestWorkers    150
    MaxConnectionsPerChild 10000
</IfModule>
```

### PHP-FPM Tuning

```bash
# /etc/php/8.2/fpm/pool.d/www.conf

pm = dynamic                    # start, grow, shrink children
pm.max_children = 50            # max PHP processes (memory bound)
pm.start_servers = 10
pm.min_spare_servers = 5
pm.max_spare_servers = 20
pm.max_requests = 500           # recycle after N requests (avoid memory leaks)

# Opcache (PHP bytecode cache)
# /etc/php/8.2/cli/conf.d/10-opcache.ini
opcache.enable=1
opcache.memory_consumption=256   # MB of shared memory for opcache
opcache.interned_strings_buffer=16
opcache.max_accelerated_files=10000
opcache.revalidate_freq=2
opcache.fast_shutdown=1
```

### Redis/Memcached Caching Patterns

**Cache-aside (lazy population):**

```python
def get_user(user_id):
    user = cache.get(f"user:{user_id}")
    if not user:
        user = db.query("SELECT * FROM users WHERE id = %s", user_id)
        cache.set(f"user:{user_id}", user, ttl=300)
    return user
```

**Write-through:**

```python
def update_user(user_id, data):
    db.execute("UPDATE users SET ... WHERE id = %s", data)
    cache.set(f"user:{user_id}", data, ttl=300)
```

### JVM Tuning

```bash
# Heap sizing
java -Xms4g -Xmx4g \              # min and max heap (same = no resizing)
     -XX:+UseG1GC \               # G1 garbage collector (latency-friendly)
     -XX:MaxGCPauseMillis=100 \   # target max GC pause
     -XX:+ParallelRefProcEnabled \
     -XX:+DisableExplicitGC \
     -jar myapp.jar
```

**JVM heap sizing rules of thumb:**

| App Type | Heap | GC | Notes |
|----------|------|----|-------|
| Web app | 2-4 GB | G1GC | Low latency |
| Batch processing | Up to 80% RAM | ParallelGC | High throughput |
| Microservices | 256 MB - 1 GB | G1GC or Shenandoah | Fast startup |
| Monolith | 8-32 GB | G1GC | Watch for long GC pauses |

---

## 🔍 Section 13: Capacity Planning

### Trend Analysis

Collect performance metrics over time and identify growth patterns:

```bash
# Use sar to collect historical data
sar -u -f /var/log/sysstat/sa20   # CPU from the 20th of month
sar -r -f /var/log/sysstat/sa20   # Memory

# Plot with sadf
sadf -d /var/log/sysstat/sa20 -- -u | column -t -s ';' | less

# For comprehensive trending, use Prometheus + Grafana (monitoring stack)
```

### Forecasting

Simple linear forecasting:

```
Current utilization: 60%
Monthly growth rate: 5%
Threshold: 80% (alarm), 90% (critical)

Months until 80%:  log(80/60) / log(1.05) ≈ 6 months
Months until 90%:  log(90/60) / log(1.05) ≈ 8.5 months
```

### Right-Sizing

| Symptom | Likely Issue | Fix |
|---------|-------------|-----|
| CPU idle 90%, high load | I/O bound | Faster storage |
| High CPU steal | Hypervisor overcommit | Move to dedicated hosts |
| Swap usage growing | Insufficient RAM | Add RAM or reduce allocation |
| Disk 99% util, low IOPS | Wrong storage tier | Upgrade to NVMe |
| Network drops (RX overruns) | Insufficient ring buffers | ethtool -G, increase budget |

### Headroom

Always maintain 20-30% headroom for traffic spikes, deployments, and background tasks:

```
Capacity = Peak Demand × (1 + Headroom)
Example: Peak = 1000 req/s, Headroom = 30%
  → Provision for 1300 req/s
```

### Cloud vs On-Prem Scaling

| Factor | Cloud | On-Prem |
|--------|-------|---------|
| Scaling speed | Minutes (API/provisioning) | Days/weeks (procurement) |
| Granularity | Tiny increments | Fixed hardware sizes |
| Cost model | OpEx (pay for use) | CapEx (buy upfront) |
| Performance consistency | Variable (noisy neighbors) | Predictable (dedicated hardware) |
| Right-sizing risk | Can downsize | Overprovisioning is permanent |

---

## 🛠️ Hands-On Practices

### Practice 1: CPU Governor Tuning

**Goal:** Observe the impact of CPU frequency scaling on benchmark performance.

```bash
# 1. Check current governor
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor

# 2. Run a sysbench CPU benchmark with current governor
sysbench cpu run

# 3. Switch to performance
echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

# 4. Re-run benchmark
sysbench cpu run

# 5. Switch to powersave
echo powersave | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

# 6. Run benchmark again
sysbench cpu run

# 7. Record the events/sec for each governor
```

**Observation:** performance governor should show higher throughput (at the cost of power and heat).

---

### Practice 2: taskset CPU Affinity

**Goal:** Bind a CPU-intensive process to specific cores and measure the difference.

```bash
# 1. Launch a CPU-intensive task on all cores
stress-ng --cpu 4 --timeout 30 &

# 2. Check where it's running
ps -eo pid,comm,psr | grep stress-ng

# 3. Launch another stress-ng with affinity to a single core
taskset -c 3 stress-ng --cpu 1 --timeout 30 &

# 4. Observe that it stays on CPU 3
ps -eo pid,comm,psr | grep stress-ng

# 5. Benchmark: time a task with and without affinity
time taskset -c 0 sysbench cpu run
time sysbench cpu run   # compare
```

---

### Practice 3: Tune Swappiness

**Goal:** Observe how swappiness changes memory pressure behavior.

```bash
# 1. Check current swappiness
sysctl vm.swappiness

# 2. Allocate memory and observe swap
stress-ng --vm 2 --vm-bytes 90% --timeout 120 &

# 3. In another terminal watch swap activity
vmstat 1

# 4. Now set swappiness to 100 (aggressive swap)
sudo sysctl vm.swappiness=100

# 5. Run the stress again and watch swap usage increase
# 6. Reset to 10 (avoid swapping)
sudo sysctl vm.swappiness=10

# 7. Repeat — compare swap in/out columns from vmstat
```

---

### Practice 4: Benchmarking with sysbench

**Goal:** Run a complete suite of sysbench benchmarks and document results.

```bash
# CPU test
sysbench cpu --cpu-max-prime=20000 run

# Memory test
sysbench memory --memory-block-size=1M --memory-total-size=10G run

# Thread test
sysbench threads --thread-yields=1000 --thread-locks=8 run

# Mutex test
sysbench mutex --mutex-num=1024 --mutex-locks=50000 run

# File I/O test
sysbench fileio --file-total-size=2G prepare
sysbench fileio --file-test-mode=rndrw --file-total-size=2G run
sysbench fileio --file-total-size=2G cleanup
```

**Deliverable:** A table with benchmark name, throughput, and latency values.

---

### Practice 5: Tune I/O Scheduler

**Goal:** Compare I/O performance under different I/O schedulers.

```bash
# 1. Check available schedulers
cat /sys/block/sda/queue/scheduler

# 2. Run fio with current scheduler
fio --name=bench --ioengine=libaio --direct=1 --rw=randread --bs=4K --size=1G --numjobs=4 --runtime=30 --group_reporting --output=result_$(cat /sys/block/sda/queue/scheduler | awk '{print $1}').json

# 3. Switch to each scheduler and rerun
echo mq-deadline | sudo tee /sys/block/sda/queue/scheduler
echo kyber | sudo tee /sys/block/sda/queue/scheduler
echo bfq | sudo tee /sys/block/sda/queue/scheduler
echo none | sudo tee /sys/block/nvme0n1/queue/scheduler

# 4. Compare IOPS and latency from JSON output
grep -A5 '"iops"' result_*.json
```

---

### Practice 6: Analyze with perf record/report

**Goal:** Profile a CPU-bound workload and identify the hottest code path.

```bash
# 1. Create a CPU-bound script
cat > /tmp/cpuburn.py << 'EOF'
import math
for i in range(10000000):
    math.sqrt(i) * math.sin(i) * math.cos(i)
EOF

# 2. Record with perf
perf record python3 /tmp/cpuburn.py

# 3. View report
perf report

# 4. Record with call-graph
perf record -g python3 /tmp/cpuburn.py
perf report -g

# 5. Annotate the hottest function
# In perf report, select a function and press 'a' for annotation
```

---

### Practice 7: strace a Slow Command

**Goal:** Find which system call is responsible for a slow operation.

```bash
# 1. Find a slow operation (e.g., find)
time find /usr -name "*.txt"

# 2. strace with timing
strace -T -o /tmp/find.strace find /usr -name "*.txt"

# 3. Sort by longest syscall
awk -F'[<>]' '{if ($2 != "") print $2, $0}' /tmp/find.strace | sort -rn | head -10

# 4. Show summary
strace -c find /usr -name "*.txt"

# 5. Identify the bottleneck
# Look for syscalls with high total time or high count
```

---

### Practice 8: bpftrace One-Liner for Block I/O Latency

**Goal:** Generate a latency histogram of block I/O operations.

```bash
# 1. Run the bpftrace one-liner for block I/O latency
sudo bpftrace -e 'kprobe:blk_account_io_start { @start[tid] = nsecs; }
    kprobe:blk_account_io_done /@start[tid]/ {
        @usecs = hist((nsecs - @start[tid]) / 1000);
        delete(@start[tid]);
    }'

# 2. In another terminal, generate I/O
dd if=/dev/zero of=/tmp/test bs=1M count=1000 oflag=direct

# 3. Observe the histogram output in the bpftrace terminal

# 4. Try with different I/O patterns:
fio --name=realtest --ioengine=libaio --direct=1 --rw=randread --bs=4K --size=1G --runtime=30
```

---

### Practice 9: fio Benchmark

**Goal:** Create a comprehensive disk benchmark report.

```bash
# Sequential read
fio --name=seqread --ioengine=libaio --direct=1 --rw=read --bs=1M --size=4G --numjobs=1 --runtime=30 --output-format=json --output=seqread.json
jq '.jobs[0].read' seqread.json

# Random read 4K
fio --name=randread --ioengine=libaio --direct=1 --rw=randread --bs=4K --size=2G --numjobs=4 --runtime=30 --output-format=json --output=randread.json
jq '.jobs[0].read' randread.json

# Mixed 70/30
fio --name=mixed --ioengine=libaio --direct=1 --rw=randrw --rwmixread=70 --bs=8K --size=2G --numjobs=4 --runtime=30 --output-format=json --output=mixed.json
jq '.jobs[0].read, .jobs[0].write' mixed.json

# Latency percentiles (99th, 99.9th)
fio --name=latency --ioengine=libaio --direct=1 --rw=randread --bs=4K --size=1G --runtime=30 --lat_percentiles=1 --percentile_list=50:90:99:99.9:99.99 --output-format=json --output=latency.json
jq '.jobs[0].read.clat.percentile' latency.json
```

---

### Practice 10: iperf3 Network Test

**Goal:** Measure network throughput between two machines.

```bash
# On Server A (1.2.3.4):
iperf3 -s

# On Client B:
iperf3 -c 1.2.3.4 -t 30
iperf3 -c 1.2.3.4 -t 30 -P 4          # 4 parallel streams
iperf3 -c 1.2.3.4 -t 30 -R            # reverse mode
iperf3 -c 1.2.3.4 -t 30 -u -b 1000M   # UDP test

# Check for packet loss in UDP mode
# If retr (retransmits) > 0 in TCP mode, tune buffers:
sudo sysctl net.core.rmem_max=134217728
sudo sysctl net.core.wmem_max=134217728
sudo sysctl net.ipv4.tcp_rmem="4096 87380 134217728"
sudo sysctl net.ipv4.tcp_wmem="4096 65536 134217728"
```

---

### Practice 11: stress-ng Test

**Goal:** Stress the system and monitor thermal and performance throttling.

```bash
# 1. Check baseline temperature and frequency
watch -n 1 "cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq; sensors"

# 2. Run mixed stress
stress-ng --cpu 4 --cpu-method all --vm 2 --vm-bytes 80% --hdd 1 --hdd-bytes 4G --timeout 120 --metrics-brief --perf

# 3. Monitor in another terminal
mpstat -P ALL 1
vmstat 1
sensors

# 4. Check the perf stats at the end
# stress-ng --perf shows cycles, instructions, cache misses

# 5. Test with different governor
echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
stress-ng --cpu 4 --timeout 30 --metrics-brief
```

---

### Practice 12: NUMA Binding with numactl

**Goal:** Measure the performance difference between NUMA-local and cross-NUMA memory access.

```bash
# 1. Show NUMA topology
numactl --hardware

# 2. Allocate memory on local node and benchmark
numactl --cpunodebind=0 --membind=0 sysbench memory run

# 3. Allocate memory on remote node
numactl --cpunodebind=0 --membind=1 sysbench memory run

# 4. Interleave allocation
numactl --interleave=all sysbench memory run

# 5. Compare latency and throughput
# (Remote memory access is typically 1.5-2x slower)
```

---

### Practice 13: Tune Network Kernel Parameters

**Goal:** Measure network throughput before and after kernel tuning.

```bash
# 1. Baseline measurement with iperf3
iperf3 -c 192.168.1.100 -t 30 -P 4 > /tmp/baseline.txt

# 2. Apply network tuning
cat <<EOF | sudo tee /etc/sysctl.d/90-network-performance.conf
net.core.rmem_max = 134217728
net.core.wmem_max = 134217728
net.ipv4.tcp_rmem = 4096 87380 134217728
net.ipv4.tcp_wmem = 4096 65536 134217728
net.core.netdev_budget = 600
net.core.somaxconn = 65536
net.ipv4.tcp_congestion_control = bbr
EOF
sudo sysctl --system

# 3. Re-run iperf3
iperf3 -c 192.168.1.100 -t 30 -P 4 > /tmp/tuned.txt

# 4. Compare throughput
grep "SUM" /tmp/baseline.txt /tmp/tuned.txt
```

---

### Practice 14: Capacity Planning Simulation

**Goal:** Project resource needs based on current growth.

```bash
# 1. Collect current stats
echo "=== Current Metrics ==="
echo "CPU load: $(uptime | awk '{print $NF}')"
echo "Memory: $(free -m | awk '/Mem:/ {print $3/$2 * 100}')% used"
echo "Disk: $(df -h / | awk 'NR==2 {print $5}')"

# 2. Simulate growth rates
cat <<'EOF' | python3
current_cpu = 55  # percent
current_mem = 62  # percent
current_disk = 45 # percent
monthly_growth = 0.05
months = 0
while current_cpu < 80 and current_mem < 80 and current_disk < 80:
    months += 1
    current_cpu *= (1 + monthly_growth)
    current_mem *= (1 + monthly_growth)
    current_disk *= (1 + monthly_growth)

print(f"At {monthly_growth*100}% monthly growth:")
print(f"  CPU threshold in: {months} months")
print(f"  Memory threshold: {current_mem:.1f}%")
print(f"  CPU threshold: {current_cpu:.1f}%")
print(f"  Disk threshold: {current_disk:.1f}%")
EOF

# 3. Write a capacity plan
echo "Action: Upgrade CPU by ${months} months"
```

---

### Practice 15: Full System Performance Audit

**Goal:** Produce a complete system performance audit document.

```bash
#!/bin/bash
# system_performance_audit.sh — Run this with sudo

AUDIT_DIR="/tmp/perf_audit_$(date +%Y%m%d)"
mkdir -p "$AUDIT_DIR"

echo "=== SYSTEM PERFORMANCE AUDIT ===" | tee "$AUDIT_DIR/audit.txt"
echo "Date: $(date)" | tee -a "$AUDIT_DIR/audit.txt"
echo "Hostname: $(hostname)" | tee -a "$AUDIT_DIR/audit.txt"
echo "Kernel: $(uname -r)" | tee -a "$AUDIT_DIR/audit.txt"

# 1. CPU Info
echo -e "\n--- CPU ---" | tee -a "$AUDIT_DIR/audit.txt"
lscpu | tee -a "$AUDIT_DIR/audit.txt"
mpstat -P ALL 1 3 | tee -a "$AUDIT_DIR/audit.txt"

# 2. Memory Info
echo -e "\n--- MEMORY ---" | tee -a "$AUDIT_DIR/audit.txt"
free -h | tee -a "$AUDIT_DIR/audit.txt"
cat /proc/meminfo | grep -E "(MemTotal|MemFree|Cached|SwapTotal|SwapFree|HugePages_Total)" | tee -a "$AUDIT_DIR/audit.txt"
echo "Swappiness: $(cat /proc/sys/vm/swappiness)" | tee -a "$AUDIT_DIR/audit.txt"

# 3. Disk Info
echo -e "\n--- DISK ---" | tee -a "$AUDIT_DIR/audit.txt"
lsblk | tee -a "$AUDIT_DIR/audit.txt"
iostat -x 1 3 | tee -a "$AUDIT_DIR/audit.txt"
for d in /sys/block/sd* /sys/block/nvme*; do
    if [ -d "$d" ]; then
        dev=$(basename "$d")
        echo "$dev scheduler: $(cat $d/queue/scheduler)" | tee -a "$AUDIT_DIR/audit.txt"
        echo "$dev nr_requests: $(cat $d/queue/nr_requests)" | tee -a "$AUDIT_DIR/audit.txt"
        echo "$dev read_ahead: $(blockdev --getra /dev/$dev)" | tee -a "$AUDIT_DIR/audit.txt"
    fi
done

# 4. Network Info
echo -e "\n--- NETWORK ---" | tee -a "$AUDIT_DIR/audit.txt"
ip addr show | tee -a "$AUDIT_DIR/audit.txt"
ip link show | tee -a "$AUDIT_DIR/audit.txt"
for iface in $(ip -br link | awk '{print $1}' | grep -v lo); do
    echo "--- $iface ---" | tee -a "$AUDIT_DIR/audit.txt"
    ethtool "$iface" 2>/dev/null | head -20 | tee -a "$AUDIT_DIR/audit.txt"
    ethtool -g "$iface" 2>/dev/null | tee -a "$AUDIT_DIR/audit.txt"
    ethtool -S "$iface" 2>/dev/null | grep -E "(drop|error|miss)" | tee -a "$AUDIT_DIR/audit.txt"
done

# 5. Kernel Parameters
echo -e "\n--- KEY SYSCTL ---" | tee -a "$AUDIT_DIR/audit.txt"
for param in vm.swappiness vm.dirty_ratio vm.dirty_background_ratio \
    vm.vfs_cache_pressure vm.overcommit_memory vm.nr_hugepages \
    net.core.rmem_default net.core.wmem_default net.core.rmem_max net.core.wmem_max \
    net.ipv4.tcp_rmem net.ipv4.tcp_wmem net.core.netdev_budget net.core.somaxconn \
    kernel.sched_migration_cost_ns; do
    echo "$param = $(sysctl -n $param 2>/dev/null || echo 'N/A')" | tee -a "$AUDIT_DIR/audit.txt"
done

# 6. Running Services
echo -e "\n--- TOP RESOURCE CONSUMERS ---" | tee -a "$AUDIT_DIR/audit.txt"
ps aux --sort=-%cpu | head -10 | tee -a "$AUDIT_DIR/audit.txt"
echo "" | tee -a "$AUDIT_DIR/audit.txt"
ps aux --sort=-%mem | head -10 | tee -a "$AUDIT_DIR/audit.txt"

# 7. perf quick stat (30 seconds)
echo -e "\n--- PERF STAT (30s system-wide) ---" | tee -a "$AUDIT_DIR/audit.txt"
perf stat -a -- sleep 30 2>&1 | tee -a "$AUDIT_DIR/audit.txt"

echo -e "\nAudit saved to $AUDIT_DIR/audit.txt"
echo "Now review the findings and write recommendations."
```

**Audit deliverable — Recommendation Report Template:**

```
# Performance Audit Report: $(hostname)
## Date: $(date)

### Findings
1. [Metric] is at [value] — [normal/problematic]
2. ...

### Recommendations
1. [Action] — expected impact: [X]
2. ...

### Priority
- Critical (address immediately): ...
- High (within 1 week): ...
- Medium (next maintenance): ...
- Low (monitor): ...
```

---

## 🧠 Deep Understanding

### How the CFS (Completely Fair Scheduler) Works

The CFS is the default Linux scheduler for normal tasks (SCHED_OTHER/NORMAL).

**Core concept:** *Virtual runtime* (vruntime). Every task gets a fair share of the CPU over time.

```
vruntime = actual_runtime × (weight_of_default_task / weight_of_this_task)
```

- Lower vruntime = more entitled to CPU
- Tasks are stored in a red-black tree keyed by vruntime
- Scheduler picks the leftmost (smallest vruntime) task

**Time slices:**

The default time slice is not fixed. It depends on the number of tasks:

```
targeted_latency = 6 ms (sysctl_sched_latency, default 6ms for nr_running <= 8)
time_slice = targeted_latency / nr_running

When nr_running > 8:
  targeted_latency = nr_running × min_granularity (default 0.75ms)
```

**`min_granularity` (`sysctl_sched_min_granularity`):**

- Default: 0.75 ms
- Minimum time a task runs before it can be preempted
- Lower = better interactivity, higher context switch overhead
- Higher = better throughput, worse latency

**Wakeup preemption:**

When a task wakes up (e.g., after I/O), CFS checks if its vruntime is sufficiently lower than the running task:

```
if (wakeup_task.vruntime < running_task.vruntime - wakeup_granularity)
    preempt_running_task()
```

- `sysctl_sched_wakeup_granularity` — controls how aggressive this is
- Default: 1 ms
- Lower = more preemption, better latency, more context switches

**Key sysctl knobs for CFS:**

| Parameter | Default | Effect |
|-----------|---------|--------|
| `kernel.sched_min_granularity_ns` | 750000 (0.75 ms) | Minimum CPU time before preemption |
| `kernel.sched_latency_ns` | 6000000 (6 ms) | Targeted preemption latency |
| `kernel.sched_wakeup_granularity_ns` | 1000000 (1 ms) | Wakeup preemption threshold |
| `kernel.sched_migration_cost_ns` | 500000 (0.5 ms) | Time after a task wakes before it's considered cache-hot |
| `kernel.sched_nr_migrate` | 32 | Max tasks to migrate in a single balance pass |

---

### How Memory Management Works

**Page reclaim:**

When the system needs free pages, the kernel must reclaim memory from:

1. **Page cache** (clean file-backed pages — trivially reclaimed)
2. **Dirty pages** (file-backed with pending writes — must write before reclaim)
3. **Anonymous pages** (heap, stack, mmap — must swap out)
4. **Slab caches** (kernel objects — dentries, inodes)

**kswapd — Background Page Reclaim:**

kswapd is a kernel thread per NUMA node that maintains free memory above watermarks:

```
                    ┌─────────────────────┐
  pages_free        │                     │
       ▲            │      ALLOCATIONS    │
       │            │      SUCCEED        │
       │            │                     │
       │  ┌─────────┴─────────────────┐  │
       │  │   watermark high          │  │ ← kswapd stops
       │  ├───────────────────────────┤  │
       │  │   watermark low           │  │ ← kswapd starts reclaiming
       │  ├───────────────────────────┤  │
       │  │   watermark min           │  │ ← direct reclaim triggers
       │  └───────────────────────────┘  │
       ▼                                 │
       0                                 │
```

**Watermark calculation:**

```bash
# Check current watermarks
cat /proc/zoneinfo | grep -E "(min|low|high)"

# Adjust watermarks (min_free_kbytes)
sudo sysctl vm.min_free_kbytes=65536  # reserve 64 MB
```

**Direct reclaim vs background reclaim:**

| Type | Trigger | Characteristics |
|------|---------|-----------------|
| **Background (kswapd)** | Free pages < low watermark | Asynchronous, low latency impact |
| **Direct reclaim** | Free pages < min watermark | Synchronous, process stalls, high latency |
| **OOM killer** | Free pages = 0 and reclaim fails | Kills process, last resort |

**LRU Lists:**

Pages are tracked on two LRU (Least Recently Used) lists:

```
Active list (recently accessed)    ← pages start here
   │
   └── Inactive list (candidates for reclaim)
```

The kernel scans pages from the *tail* of the inactive list. If a page on the inactive list is accessed, it's promoted back to the active list.

```bash
# Check LRU sizes
cat /proc/meminfo | grep -E "(Active|Inactive)"
```

**The refault detection algorithm:**

- When a page is reclaimed and then immediately faulted back in, that's a *refault*
- High refault rate = reclaim is too aggressive
- This is how the kernel detects *thrashing*

---

### How the Network Stack Processes Packets

**1. Hardware → NIC receives packet:**

```
NIC (hardware) → DMA to ring buffer → IRQ → NAPI → softirq → socket
```

**2. NAPI (New API):**

The modern Linux network driver model:

1. NIC receives packet, DMA's it to memory
2. NIC raises IRQ
3. Driver's IRQ handler schedules NAPI poll
4. **Polling mode:** Instead of IRQ per packet, NAPI polls the ring buffer in a softirq context
5. NAPI processes up to `netdev_budget` packets per poll cycle

**3. GRO (Generic Receive Offload):**

- Merges consecutive packets that belong to the same flow into one large skb
- Reduces per-packet overhead in the stack
- Visible as `tcp-segmentation-offload` in ethtool

```bash
# Check GRO status
ethtool -k eth0 | grep generic-receive-offload

# Disable GRO (rare, for some virtual environments)
sudo ethtool -K eth0 gro off
```

**4. GSO (Generic Segmentation Offload):**

- The reverse of GRO — lets the NIC split large TCP segments
- The kernel passes a super-sized buffer to the NIC; the NIC hardware segments it
- Reduces CPU overhead per packet

```bash
# Check TCP segmentation offload
ethtool -k eth0 | grep tcp-segmentation-offload
```

**5. Interrupt Moderation:**

- NICs coalesce interrupts — instead of interrupting per packet, they wait for a batch or a timer
- Controlled via ethtool:
  - `ethtool -C eth0 rx-usecs 100` — coalesce up to 100 µs
  - `ethtool -C eth0 rx-frames 64` — coalesce up to 64 frames

```bash
# Check interrupt coalescence
ethtool -c eth0

# Tune for low latency (less coalescing)
sudo ethtool -C eth0 rx-usecs 10 tx-usecs 10

# Tune for throughput (more coalescing)
sudo ethtool -C eth0 rx-usecs 100 tx-usecs 100
```

**6. softirq:**

- Packet processing happens in softirq context (not process context)
- softirqs run on return from hardware IRQ
- They can be deferred or preempted by higher-priority interrupts
- `/proc/softirqs` shows softirq stats

```bash
# Watch softirq distribution across CPUs
watch -n 1 cat /proc/softirqs

# The NET_RX softirq handles inbound packets
# The NET_TX softirq handles outbound
```

**Full packet path (simplified):**

```
┌─────────────────────────────────────────────────┐
│                  Application                     │
│              recvfrom() / read()                 │
└────────────────────┬────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────┐
│              Socket Layer                        │
│         (TCP reassembly, congestion ctl)         │
└────────────────────┬────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────┐
│         IP Layer (routing, netfilter)            │
└────────────────────┬────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────┐
│       GRO / softirq (packet coalescing)          │
└────────────────────┬────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────┐
│       NAPI Poll (driver layer)                   │
└────────────────────┬────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────┐
│       Ring Buffer (DMA from NIC)                 │
└────────────────────┬────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────┐
│                Physical NIC                      │
│              (wire / cable)                      │
└─────────────────────────────────────────────────┘
```

---

### How NVMe/SSDs Differ from HDDs for Tuning

| Aspect | HDD | SSD | NVMe |
|--------|-----|-----|------|
| **Interface** | SATA (600 MB/s max) | SATA/SAS | PCIe (4-8 GB/s per lane) |
| **Latency** | 5-15 ms | 0.1-0.5 ms | 0.01-0.1 ms |
| **IOPS** | ~200 | ~100,000 | 500,000-1,000,000 |
| **Queue depth** | 32 (AHCI) | 32 (AHCI) | 65,535 (NVMe driver) |
| **Overhead** | High (mechanical seek) | Medium | Very low (no AHCI translation) |
| **Noise** | Clicking/spinning | Silent | Silent |
| **Wear leveling** | N/A | Yes (limited writes) | Yes (limited writes) |

**Tuning implications:**

1. **I/O Scheduler:** For NVMe, use `none`. For SATA SSDs, `none` or `kyber`. For HDDs, `mq-deadline` or `BFQ`.

2. **Queue Depth:** NVMe supports very deep queues. Tune `nr_requests` higher (1024+) for throughput on NVMe.

3. **Read-Ahead:** Useless for random I/O on any device. Beneficial for sequential scans — set higher for HDDs (to compensate for seek), moderate for NVMe.

4. **ionice:** HDDs benefit significantly because they are mechanical. SSDs/NVMe benefit less because there is no head to move — but ionice still reduces CPU contention from I/O completion.

5. **Filesystem:** NVMe benefits from modern filesystems like XFS or ext4 with `noatime`. HDDs benefit from avoiding defragmentation and using `noatime` aggressively.

6. **Direct I/O:** Bypassing the page cache (`O_DIRECT`) makes sense for databases on NVMe. On HDDs, the page cache is critical for performance.

---

## 📊 Command Reference

### Performance Monitoring Commands

| Command | What it shows | Key Flags |
|---------|---------------|-----------|
| `mpstat -P ALL 1` | Per-CPU utilization | `-P ALL`, `-I` for interrupts |
| `vmstat 1` | Process, memory, swap, I/O | `-s` for stats, `-d` for disk |
| `iostat -x 1` | Per-disk utilization, queue, latency | `-x` extended, `-p` per-partition |
| `sar -u 1` | Historical CPU collection | `-u`, `-r`, `-b`, `-n DEV` |
| `dstat --cpu --mem 1` | Combined stats | Many plugins (`--top-cpu`, etc.) |
| `perf top` | Live CPU profiling | `-a` system-wide, `-g` call-graph |
| `perf stat` | Event counting | `-e`, `-p` PID, `-a` system-wide |
| `strace -c` | Syscall summary | `-p`, `-e`, `-T`, `-f` |
| `bpftrace -e` | Dynamic tracing | One-liners, histograms |
| `top`/`htop` | Process overview | `P` sort CPU, `M` sort memory |
| `atop` | Advanced process monitor | Logging, disk per-process |
| `nicstat` | Network utilization | `-z` for zero-wait |
| `tcptop` (bpftrace) | Top TCP connections | `bpftrace /usr/share/bpftrace/tools/tcptop.bt` |
| `tuned-adm` | Automated system tuning | `list`, `active`, `profile <name>`, `recommend` |

### Key sysctl Tuning Parameters

| Parameter | Default | Tuning Direction | Effect |
|-----------|---------|-----------------|--------|
| `vm.swappiness` | 60 | Lower (1-10) | Reduce swap usage |
| `vm.dirty_ratio` | 20 | Higher (30-40) for throughput, lower (5-10) for latency | Write-back behavior |
| `vm.dirty_background_ratio` | 10 | 5-10% of dirty_ratio | Background flusher start |
| `vm.vfs_cache_pressure` | 100 | Lower (50) to keep more inode/dentry cache | File metadata caching |
| `vm.nr_hugepages` | 0 | Set to needed number | Reduce TLB misses |
| `vm.min_free_kbytes` | Auto | Higher (1-5% of RAM) | Prevent direct reclaim |
| `kernel.sched_min_granularity_ns` | 750000 | Lower for latency, higher for throughput | CPU scheduling |
| `kernel.sched_migration_cost_ns` | 500000 | Lower for more aggressive migration | CPU balance |
| `net.core.rmem_max` | 212992 | Higher (64M-128M) for high BDP networks | Socket receive buffer |
| `net.core.wmem_max` | 212992 | Higher (64M-128M) | Socket send buffer |
| `net.ipv4.tcp_rmem` | 4096 131072 6291456 | Increase auto-tuning range | TCP receive throughput |
| `net.ipv4.tcp_wmem` | 4096 16384 4194304 | Increase | TCP send throughput |
| `net.core.netdev_budget` | 300 | Higher (600-1200) for high PPS | NAPI packet budget |
| `net.core.somaxconn` | 128 | Higher (65536) for busy servers | Listen backlog |
| `net.ipv4.tcp_congestion_control` | cubic | bbr for modern high-BDP networks | TCP throughput |
| `fs.file-max` | Auto | Higher for many-connections servers | Max open files |

### Tuning Files

| File Path | What it Controls |
|-----------|-----------------|
| `/sys/devices/system/cpu/cpu*/cpufreq/scaling_governor` | CPU frequency governor |
| `/sys/block/*/queue/scheduler` | I/O scheduler |
| `/sys/block/*/queue/nr_requests` | Block layer queue depth |
| `/sys/block/*/queue/read_ahead_kb` | Read-ahead in KB |
| `/sys/class/net/*/queues/rx-*/rps_cpus` | RPS CPU mask |
| `/sys/class/net/*/queues/tx-*/xps_cpus` | XPS CPU mask |
| `/proc/irq/*/smp_affinity` | IRQ affinity |
| `/sys/kernel/mm/transparent_hugepage/enabled` | THP state |
| `/etc/sysctl.conf` / `/etc/sysctl.d/*.conf` | Persistent sysctl settings |
| `/etc/security/limits.conf` | Per-process resource limits |
| `/etc/udev/rules.d/*.rules` | Persistent device tunings |

---

## 🔮 What's Coming in Part 48

**Part 48: High Availability and Clustering** — Pacemaker/Corosync, DRBD, keepalived (VRRP), load balancing with HAProxy, clustering concepts (active/passive, active/active), quorum, fencing, STONITH, multi-node cluster setup for databases and web services.

---

## ✅ Self-Test

### Question 1
What does the USE method in performance analysis stand for?
```
A) Understand, Simulate, Evaluate
B) Utilization, Saturation, Errors
C) Unify, Scale, Execute
D) User, System, Environment
```

### Question 2
Which CPU governor should you use for a latency-sensitive database server?
```
A) powersave
B) ondemand
C) performance
D) conservative
```

### Question 3
What effect does setting `vm.swappiness=10` have compared to the default (60)?
```
A) It makes the system swap more aggressively
B) It reduces swapping of anonymous pages, preferring to drop file-backed pages instead
C) It disables swap entirely
D) It increases the size of swap space
```

### Question 4
Which I/O scheduler is recommended for NVMe drives?
```
A) mq-deadline
B) BFQ
C) none
D) kyber
```

### Question 5
What does `numactl --cpunodebind=0 --membind=0 ./app` do?
```
A) Runs the app on any CPU but allocates memory on node 0
B) Runs the app on CPU 0 and allocates memory on node 0 only
C) Runs the app on all CPUs but binds memory to node 0
D) Distributes the app equally across all NUMA nodes
```

### Question 6
Which sysctl parameter controls the maximum receive socket buffer size?
```
A) net.core.rmem_default
B) net.core.rmem_max
C) net.ipv4.tcp_rmem
D) net.core.netdev_budget
```

### Question 7
What is the purpose of `perf record` followed by `perf report`?
```
A) To count system calls during a program's execution
B) To sample a running program's call stack at regular intervals and display the hottest paths
C) To trace disk I/O operations
D) To benchmark network throughput
```

### Question 8
In `strace`, what does the `-T` flag do?
```
A) Filter syscalls by type
B) Show the time spent in each system call
C) Follow child processes
D) Trace threads only
```

### Question 9
Which of the following is a bpftrace tool for generating a latency histogram of block I/O?
```
A) perf stat -e block:*
B) strace -e trace=io
C) bpftrace -e 'kprobe:blk_account_io_done { @usecs = hist(nsecs / 1000); }'
D) iostat -x 1
```

### Question 10
What does the `direct=1` option do in `fio`?
```
A) Enables direct memory access
B) Bypasses the page cache, using O_DIRECT
C) Directs output to a file
D) Runs the test in the background
```

### Question 11
What is the primary benefit of using `noatime` as a filesystem mount option?
```
A) It disables all disk write operations
B) It prevents access time updates on reads, reducing write operations
C) It enables faster directory lookups
D) It disables journaling for improved performance
```

### Question 12
In the CFS scheduler, what does a lower vruntime mean for a task?
```
A) It has run longer and is less entitled to CPU time
B) It has run less and is more entitled to CPU time
C) It is a real-time task with higher priority
D) It is an I/O-bound task that should sleep longer
```

### Question 13
What is direct reclaim in Linux memory management?
```
A) kswapd freeing pages in the background
B) A process that is allocating memory is forced to wait and reclaim pages synchronously
C) The OOM killer selecting a process to terminate
D) Reclaiming memory by dropping page cache entries
```

### Question 14
Which netfilter/NAPI parameter controls how many packets are processed per softirq poll cycle?
```
A) net.core.somaxconn
B) net.core.netdev_budget
C) net.ipv4.tcp_rmem
D) net.core.rmem_default
```

### Question 15
What is the key difference between HDD and NVMe tuning?
```
A) HDDs need `none` scheduler; NVMe needs `mq-deadline`
B) HDDs benefit from lower queue depth; NVMe benefits from much higher queue depth
C) NVMe requires read-ahead to be disabled; HDDs require it enabled
D) There is no difference in tuning approach
```

---

**Score:** 12/15 correct = ready for Part 48.

**Answers:** 1-B, 2-C, 3-B, 4-C, 5-B, 6-B, 7-B, 8-B, 9-C, 10-B, 11-B, 12-B, 13-B, 14-B, 15-B

---

*Previous → Part 46: Monitoring and Alerting*
*Next → Part 48: High Availability and Clustering*

[← Previous](part46.md) | [Next →](part48.md)
