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





[← Previous](18-deep-understanding.md) | [↑ Index](index.md) | [Next →](20-whats-coming-in-part-48.md)
