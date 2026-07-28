## 🎯 What You Will Achieve

Memory is often the most misunderstood subsystem in Linux. OOM kills, swap thrashing, and page cache confusion cause more production issues than almost any other resource. This part demystifies how Linux manages physical memory — from page tables and page cache to swap, NUMA, and the OOM killer.

You will:

- Understand physical vs virtual memory, page tables, and TLB translation
- Explain page cache behavior and safely drop caches when needed
- Configure swap partitions, files, swappiness, and priorities
- Deploy zram and zswap for compressed memory on memory-constrained systems
- Read NUMA topology and use `numactl` for memory placement
- Control OOM Killer behavior with `oom_score_adj` and cgroups
- Tune `vm.overcommit_*` parameters for different workload profiles
- Diagnose memory pressure with `free`, `vmstat`, `/proc/meminfo`, and `slabtop`
- Optimize memory settings for databases, web servers, and JVM applications





[↑ Index](index.md) | [Next →](02-1-linux-memory-architecture-physical.md)
