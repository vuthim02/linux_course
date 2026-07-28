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





[← Previous](05-section-3-memory-tuning.md) | [↑ Index](index.md) | [Next →](07-section-5-network-tuning.md)
