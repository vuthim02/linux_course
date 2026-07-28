## ⭐ Level 1: Basic — Using Built-In Monitoring Tools

![Linux Performance Tools overview diagram showing monitoring tools mapped to subsystems](https://upload.wikimedia.org/wikipedia/commons/8/8f/Linux_Performance_Tools_Diagram.png)

> *"You can't fix what you can't measure. But you also can't measure what you don't understand. Start with the kernel interfaces — every monitoring tool is just a pretty face on `/proc`."*

### What You'll Cover
- The USE method: Utilization, Saturation, Errors for every resource
- `/proc` kernel interfaces: what the numbers actually mean
- `top` and `htop` for real-time process and resource monitoring
- `free` for memory analysis (buffers, cache, available)
- `ps` for process snapshots and sorting
- `ss` for socket statistics (replacing netstat)
- Reading `/proc/loadavg`, `/proc/stat`, `/proc/meminfo`

The USE (Utilization, Saturation, Errors) method gives you a systematic way to check every resource. Apply it to CPU, memory, disk, and network — and you will never miss a bottleneck.

At this level you will learn:

- **`/proc` kernel interfaces**: Every monitoring tool reads from `/proc`. `/proc/stat` has CPU times. `/proc/meminfo` has memory details. `/proc/loadavg` has the 1/5/15-minute load averages. Understanding these raw numbers helps you interpret what tools like `top` display.
- **`top`**: Press `1` to see per-CPU usage. `Shift+M` sorts by memory. `Shift+P` sorts by CPU. The `load average` line shows the number of processes waiting for CPU or I/O. A load average above the CPU count means saturation.
- **`free`**: The `available` column (not `free`) shows memory available for new applications. `buff/cache` is kernel-managed cache that can be reclaimed. Do not panic when `free` is low — Linux uses free memory for caching.
- **`ps`**: `ps aux --sort=-%mem` shows processes sorted by memory. `ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%mem` gives a cleaner view. `ps --forest` shows process trees.
- **`ss`**: `ss -tunlp` shows listening TCP/UDP ports with process names — faster than `netstat`. `ss -s` gives socket statistics summary. This is the first tool for "is the service listening?".


[← Previous](02-table-of-contents.md) | [↑ Index](index.md) | [Next →](04-1-why-monitor.md)
