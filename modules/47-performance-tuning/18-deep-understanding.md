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



---

[← Previous](17-date-date.md) | [↑ Index](index.md) | [Next →](19-command-reference.md)
