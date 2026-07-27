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



---

[← Previous](12-deep-understanding.md) | [↑ Index](index.md) | [Next →](14-whats-coming-in-part-63.md)
