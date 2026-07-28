## ⭐ Level 2: Intermediary — Diagnosing Bottlenecks and Monitoring in Depth

![Linux Performance observability tools — Brendan Gregg's flame graph and perf-tools summary](https://upload.wikimedia.org/wikipedia/commons/7/7b/Linux_observability_tools_%28Brendan_Gregg%29.png)

> *"The difference between a beginner and an experienced sysadmin is knowing not just what tool to run, but which column to look at. `vmstat`'s `r` column tells you if you need more CPU; `wa` tells you if your disk is lying."*

### What You'll Cover
- `vmstat`: system-wide snapshot of processes, memory, I/O, and CPU
- `iostat`: per-disk I/O analysis — await, svctm, %util
- `mpstat`: per-CPU breakdown for identifying hotspots
- `dstat`: real-time aggregator combining multiple metrics
- `nmon`: all-in-one ncurses monitor for interactive analysis
- `glances`: Python-powered monitoring with web interface
- `sar`: historical performance data with `sysstat`

At this level you move from observing symptoms to diagnosing root causes. Each tool reveals a different angle of system behavior.

At this level you will practice:

- **`vmstat 1`**: The `r` column shows processes waiting for CPU — if consistently above CPU count, you need more CPU. The `wa` column shows I/O wait — high `wa` means the disk is the bottleneck. The `si`/`so` columns show swap activity — any swap means memory pressure.
- **`iostat -xz 1`**: The `%util` column shows disk utilization. Above 80% indicates saturation. `await` shows average I/O latency — above 10ms for SSDs or 20ms for HDDs means problems. `rkB/s` and `wkB/s` show throughput.
- **`mpstat -P ALL 1`**: Shows per-CPU utilization. If one CPU is at 100% and others are idle, you have a single-threaded bottleneck. This is common with applications that cannot parallelize.
- **`sar`**: The Swiss Army knife of historical monitoring. `sar -u 1 10` shows 10 seconds of CPU data. `sar -d 1` shows disk I/O. `sar -n DEV 1` shows network. The `sysstat` package stores data in `/var/log/sa/` for later analysis.
- **`glances`**: `pip install glances` then `glances` gives a beautiful all-in-one dashboard. `glances -w` starts a web server. Great for quick overviews but not suitable for long-term monitoring.


[← Previous](07-7-free-memory-usage-reality.md) | [↑ Index](index.md) | [Next →](09-4-vmstat-system-wide-snapshot-machine.md)
