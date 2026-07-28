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


*Linux SysAdmin Course | Part 62 of ∞ | Reverse Engineering Approach*
*Previous → Part 61: Filesystem Internals*
*Next → Part 63: eBPF & Modern Tracing*

[← Previous](part61.md) | [Next →](part63.md)



[← Previous](14-whats-coming-in-part-63.md) | [↑ Index](index.md)
