## 2. `/proc` and `/sys` — The Kernel's Public API

Every monitoring tool on Linux ultimately reads from `procfs` (`/proc`) or `sysfs` (`/sys`). Understanding these files removes the magic.

### `/proc/stat` — CPU and System Statistics

```
$ cat /proc/stat
cpu  521695 1234 892345 10234567 98765 54321 67890 0 0 0
cpu0 260847 617 446172 5117283 49382 27160 33945 0 0 0
cpu1 260848 617 446173 5117284 49383 27161 33945 0 0 0
intr 98213421 ...
ctxt 789123456
btime 1700000000
processes 123456
procs_running 2
procs_blocked 0
```

The columns for each CPU line (from `man proc`):

| Column | Name | Meaning |
|---|---|---|
| 1 | user | Normal user-space processes |
| 2 | nice | User-space processes with niceness |
| 3 | system | Kernel-space time |
| 4 | idle | Idle (no runnable task) |
| 5 | iowait | Waiting for I/O completion |
| 6 | irq | Servicing hardware interrupts |
| 7 | softirq | Servicing software interrupts |
| 8 | steal | Stolen by hypervisor (VMs) |
| 9 | guest | Running a guest OS |
| 10 | guest_nice | Guest with nice |

**Key insight:** These are *jiffies* (kernel ticks), not percentages. Monitoring tools sample `/proc/stat` twice, subtract, divide by the total delta, and compute percentages. This is why `top` shows CPU percentages that change every refresh.

### `/proc/meminfo` — Memory Statistics

```
$ cat /proc/meminfo
MemTotal:       16266280 kB
MemFree:         3845212 kB
MemAvailable:    8912345 kB
Buffers:          213456 kB
Cached:          6123456 kB
SwapCached:        12345 kB
SwapTotal:       8388604 kB
SwapFree:        7588604 kB
```

**Critical distinction:** `MemFree` is *unused* RAM. `MemAvailable` is an estimate of RAM available for starting new applications (includes reclaimable cache). Always use `MemAvailable` for real-world "how much free RAM."

### `/proc/loadavg` — Load Average

```
$ cat /proc/loadavg
2.45 1.80 1.20 3/456 12345
```

- 1-min, 5-min, 15-min load averages (number of processes in TASK_RUNNING or TASK_UNINTERRUPTIBLE)
- `3/456` = running processes / total threads
- `12345` = last PID assigned

---



---

[← Previous](04-1-why-monitor.md) | [↑ Index](index.md) | [Next →](06-3-top-htop-interactive-process.md)
