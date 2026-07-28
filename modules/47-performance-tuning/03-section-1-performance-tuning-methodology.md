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





[← Previous](02-prerequisites.md) | [↑ Index](index.md) | [Next →](04-section-2-cpu-tuning.md)
