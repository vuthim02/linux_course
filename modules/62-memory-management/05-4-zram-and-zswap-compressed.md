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



---

[← Previous](04-3-swap-architecture-when-ram.md) | [↑ Index](index.md) | [Next →](06-5-numa-topology-memory-where.md)
