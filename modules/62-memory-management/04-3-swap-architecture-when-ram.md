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





[← Previous](03-2-page-cache-linuxs-speed.md) | [↑ Index](index.md) | [Next →](05-4-zram-and-zswap-compressed.md)
