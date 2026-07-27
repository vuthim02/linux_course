# 🐧 Linux System Administrator — Complete Course
## Part 33 of ∞: System Monitoring — top, htop, iostat, vmstat, ss, dstat, nmon, glances

> **Reverse Engineering Approach:** Most sysadmins learn monitoring by staring at dashboards. We will instead start from the kernel interfaces (`/proc`, `/sys`), understand what numbers the kernel publishes, then watch exactly how each tool reads and presents those numbers. When you know what `iostat`'s `%util` *actually means* in terms of the block layer's request queue, you stop guessing about disk performance.

---

## 🎯 What You Will Achieve

| Level | Outcome |
|-------|---------|
| **Basic** | Monitor CPU, memory, disk, and network using built-in tools (`top`, `free`, `ps`, `ss`); understand `/proc/stat`, `/proc/meminfo`, `/proc/loadavg` |
| **Intermediary** | Diagnose bottlenecks with `vmstat`, `iostat`, `mpstat`, `dstat`, `nmon`, `glances`; monitor logs and sockets; use `sar` for historical analysis |
| **Advanced** | Deploy Prometheus + `node_exporter`; interpret S.M.A.R.T. data and RAID health; understand I/O schedulers and `%util` internals; build automated health reporting |

---

## Table of Contents

1. Why Monitor?
2. `/proc` and `/sys` — The Kernel's Public API
3. `top` / `htop` — Interactive Process Monitoring
4. `vmstat` — System-Wide Snapshot Machine
5. `iostat` — Per-Disk I/O Deep Dive
6. `mpstat` — Per-CPU Breakdown
7. `free` — Memory Usage Reality
8. `ss` — Socket Statistics (Modern `netstat`)
9. `dstat` — Versatile Real-Time Aggregator
10. `nmon` — All-in-One Ncurses Monitor
11. `glances` — Python Power Monitor
12. Prometheus + `node_exporter` — Modern Metrics Stack
13. Disk Health Monitoring — `smartctl`, `badblocks`, RAID
14. Log-Based Monitoring — `tail`, `multitail`, `logwatch`, `lnav`
15. `ncdu` — NCurses Disk Usage Analyzer
16. Cockpit — Web-Based Server Administration
17. `sosreport` — System Diagnostic Reporting
18. Command Reference
19. 15 Hands-On Practices
20. Self-Test
21. What's Coming in Part 34

---

## ⭐ Level 1: Basic — Using Built-In Monitoring Tools

![Linux Performance Tools overview diagram showing monitoring tools mapped to subsystems](https://upload.wikimedia.org/wikipedia/commons/8/8f/Linux_Performance_Tools_Diagram.png)

> *"You can't fix what you can't measure. But you also can't measure what you don't understand. Start with the kernel interfaces — every monitoring tool is just a pretty face on `/proc`."*

---

## 1. Why Monitor?

Monitoring is the act of collecting, analyzing, and acting on system metrics. It answers three questions:

| Question | Example |
|---|---|
| What is happening right now? | CPU at 95%, swap filling up |
| What happened before? | OOM killer fired at 03:14, load spiked |
| What will happen? | Disk fills in 6 days at current rate |

### Use Cases

- **Baselining:** Record "normal" metric ranges so anomalies stand out.
- **Capacity Planning:** Trend disk, memory, and CPU over weeks to predict when you need to scale.
- **Incident Response:** When a service goes down, monitoring tells you which resource was exhausted.
- **Performance Tuning:** Identify exactly which subsystem is the bottleneck.
- **SLA Validation:** Prove that your systems met uptime and latency targets.

### The Observation Pyramid

```
   ┌─────────────┐
   │  Business   │  ← Revenue, signups, latency p99
   ├─────────────┤
   │ Application │  ← Request rate, error rate, GC pauses
   ├─────────────┤
   │   System    │  ← CPU, memory, disk, network (THIS PART)
   ├─────────────┤
   │   Hardware  │  ← S.M.A.R.T., IPMI, fan speed
   └─────────────┘
```

This part covers the **System** layer. You monitor hardware to detect impending failure, system resources to detect exhaustion, and applications to detect logic bugs.

---

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

## 3. `top` / `htop` — Interactive Process Monitoring

### `top` — The OG

```
$ top
top - 14:23:45 up 30 days,  2:15,  3 users,  load average: 0.45, 0.30, 0.25
Tasks: 245 total,   1 running, 244 sleeping,   0 stopped,   0 zombie
%Cpu(s):  5.2 us,  2.1 sy,  0.0 ni, 92.0 id,  0.5 wa,  0.0 hi,  0.2 si,  0.0 st
MiB Mem :  15884.7 total,   3845.2 free,   2234.5 used,   9805.0 buff/cache
MiB Swap:   8192.0 total,   7588.6 free,    603.4 used.  12891.2 avail Mem 

    PID USER      PR  NI    VIRT    RES    SHR S  %CPU  %MEM     TIME+ COMMAND
   1234 root      20   0  567.2m 123.4m  45.6m S   8.2   0.8   123:45.67 nginx
   5678 www-data  20   0  234.5m  56.7m  23.4m S   3.1   0.4   12:34.56 node
```

**Interactive commands inside `top`:**

| Key | Action |
|---|---|
| `1` | Toggle per-CPU view |
| `P` | Sort by CPU (descending) |
| `M` | Sort by memory (descending) |
| `T` | Sort by TIME+ |
| `k` | Kill a process (prompts PID + signal) |
| `r` | Renice a process |
| `f` | Enter field management screen |
| `u` | Filter by user |
| `W` | Write configuration to `~/.toprc` |
| `?` | Help |
| `q` | Quit |

**CPU percentage fields:**
- `us` — User space (apps)
- `sy` — System (kernel)
- `ni` — User processes with nice adjustment
- `id` — Idle
- `wa` — I/O wait (CPU idle but at least one I/O pending)
- `hi` — Hardware interrupts
- `si` — Software interrupts
- `st` — Steal time (hypervisor)

### `htop` — Better `top`

```
$ htop
```

`htop` is `top` with:
- Color-coded bars for CPU/memory per core
- Mouse support (click to sort, click to kill)
- Tree view (`F5`)
- Vertical and horizontal scrolling
- Process search (`F3`)
- Filter by multiple criteria
- Configurable columns via `F2`
- Much friendlier `kill` interface

**Install:**
```
$ sudo apt install htop        # Debian/Ubuntu
$ sudo dnf install htop        # Fedora/RHEL
```

**Key htop columns:**

| Column | Meaning |
|---|---|
| PID | Process ID |
| USER | Owner |
| PRI | Kernel priority |
| NI | Nice value |
| VIRT | Virtual memory (total mapped) |
| RES | Resident memory (physical RAM) |
| SHR | Shared memory |
| S | State |
| CPU% | CPU usage percentage |
| MEM% | Memory usage percentage |
| TIME+ | Total CPU time |
| Command | The executable |

### Batch Mode (Scripting)

```
$ top -b -n 1                # Single batch snapshot
$ top -b -n 5 -d 2 > top.log # 5 snapshots, 2s apart, to file
$ top -b -n 1 -p 1234        # Single process only
```

---

## 7. `free` — Memory Usage Reality

```
$ free -h
               total        used        free      shared  buff/cache   available
Mem:            15Gi       2.2Gi       3.7Gi       123Mi       9.6Gi        12Gi
Swap:          8.0Gi       603Mi       7.4Gi
```

### Understanding Each Column

| Column | Source | Meaning |
|---|---|---|
| `total` | `MemTotal` | Physical RAM installed |
| `used` | `MemTotal - MemFree - Buffers - Cached - Slab` | Memory actually in active use |
| `free` | `MemFree` | Completely unused RAM |
| `shared` | `Shmem` | Shared memory (tmpfs, shared segments) |
| `buff/cache` | `Buffers + Cached + Slab` | Filesystem metadata + page cache + kernel slabs |
| `available` | `MemAvailable` | **The real answer** — Free + reclaimable cache |

### The Memory Trap

Many newcomers see `used: 12Gi` and panic. But `buff/cache: 9.6Gi` means most of that "used" memory is actually the page cache — file contents the kernel has cached. It is reclaimable instantly.

**Rule of thumb:** Watch `available`, not `free`.

### Minimal `free` Usage

```
$ free -g        # Gigabyte units
$ free -m        # Megabyte units
$ free -s 5      # Repeat every 5 seconds
```

### `/proc/meminfo` Helper

```
$ grep -E "^(MemTotal|MemFree|MemAvailable|SwapTotal|SwapFree)" /proc/meminfo
MemTotal:       16266280 kB
MemFree:         3845212 kB
MemAvailable:    8912345 kB
SwapTotal:       8388604 kB
SwapFree:        7588604 kB
```

---

## ⭐ Level 2: Intermediary — Diagnosing Bottlenecks and Monitoring in Depth

![Linux Performance observability tools — Brendan Gregg's flame graph and perf-tools summary](https://upload.wikimedia.org/wikipedia/commons/7/7b/Linux_observability_tools_%28Brendan_Gregg%29.png)

> *"The difference between a beginner and an experienced sysadmin is knowing not just what tool to run, but which column to look at. `vmstat`'s `r` column tells you if you need more CPU; `wa` tells you if your disk is lying."*

---

## 4. `vmstat` — System-Wide Snapshot Machine

`vmstat` reports **processes, memory, paging, block I/O, traps, and CPU activity** in a compact single-line format.

```
$ vmstat 2 5
procs -----------memory---------- ---swap-- -----io---- -system-- ------cpu-----
 r  b   swpd   free   buff  cache   si   so    bi    bo   in   cs us sy id wa st
 2  0 618496 3895312 213456 6123456  0    1    45    67  1234 5678  5  2 92  1  0
 1  0 618496 3895123 213456 6123456  0    0    32    55  1189 5432  4  2 93  1  0
 0  0 618496 3894890 213456 6123457  0    0    28    61  1201 5510  4  2 93  1  0
```

**Column breakdown:**

**procs:**
- `r` — Number of processes waiting for CPU (run queue). If consistently > core count, CPU-bound.
- `b` — Processes in uninterruptible sleep (usually waiting for I/O). Persistent >0 indicates I/O bottleneck.

**memory:**
- `swpd` — Amount of swap used (KB). High here doesn't mean thrashing — check `si`/`so`.
- `free` — Idle memory (KB).
- `buff` — Buffer cache (metadata, filesystem structures).
- `cache` — Page cache (file contents).

**swap:**
- `si` — Memory swapped *in* from disk (KB/s).
- `so` — Memory swapped *out* to disk (KB/s).

**When both are non-zero and sustained, you are *actively thrashing*.** Swapping is 1000x slower than RAM.

**io:**
- `bi` — Blocks received from block device (KB/s).
- `bo` — Blocks sent to block device (KB/s).

**system:**
- `in` — Interrupts per second (including clock).
- `cs` — Context switches per second.

**cpu:**
- `us`, `sy`, `id`, `wa`, `st` — Same as `top` breakdown.

### Spotting Problems with `vmstat`

| Symptom | Columns to Watch | Meaning |
|---|---|---|
| CPU saturation | `r` > core count | Processes fighting for CPU |
| I/O bottleneck | `b` > 0, `wa` > 10% | Disk cannot keep up |
| Memory pressure | `si` > 0, `so` > 0 | Active swapping — add RAM |
| Excessive context switching | `cs` > 100000 | Too many threads, lock contention |

### Example: Diagnosing a Bottleneck

```
$ vmstat 1 10
procs -----------memory---------- ---swap-- -----io---- -system-- ------cpu-----
 r  b   swpd   free   buff  cache   si   so    bi    bo   in   cs us sy id wa st
12  0      0 1234567  45678 9123456   0    0     8    15 45000 89000 95  4  1  0  0
```

- `r = 12`, CPU cores = 4 → **CPU saturation** (12 > 4)
- `us = 95` → almost entirely user-space CPU
- `si/so = 0`, `wa = 0` → no I/O or swap issues
- `cs = 89000` → high context switching from many threads

**Conclusion:** CPU-bound workload with too many runnable threads for available cores.

---

## 5. `iostat` — Per-Disk I/O Deep Dive

`iostat` reports per-disk and per-partition I/O statistics. It reads directly from `/proc/diskstats`.

```
$ iostat -x 2 5
Linux 6.2.0 (hostname)   2024-01-15  _x86_64_  (4 CPU)

avg-cpu:  %user   %nice %system %iowait  %steal   %idle
           5.23    0.00    2.10    1.05    0.00   91.62

Device      r/s     rkB/s   rrqm/s  %rrqm  r_await  rareq-sz  w/s     wkB/s   wrqm/s  %wrqm  w_await  wareq-sz  d/s     dkB/s   drqm/s  %drqm  d_await  dareq-sz   aqu-sz  %util
sda       123.4    2048.0     0.0    0.0     1.23    16.6     67.8    1024.0    12.3   15.3     5.67    15.1      0.0      0.0     0.0    0.0     0.00     0.0       0.45   45.6
sdb        5.6      89.0     0.5    8.2     0.89    15.9      2.1      32.0     0.8   27.6     3.45    15.2      0.0      0.0     0.0    0.0     0.00     0.0       0.02    1.2
```

### Understanding I/O Statistics

**Key fields from `-x` (extended stats):**

| Field | Unit | Meaning |
|---|---|---|
| `r/s` | I/Os per sec | Read I/O requests completed |
| `w/s` | I/Os per sec | Write I/O requests completed |
| `rkB/s` | KB per sec | Kilobytes read per second |
| `wkB/s` | KB per sec | Kilobytes written per second |
| `rrqm/s` | I/Os per sec | Read requests *merged* per second |
| `wrqm/s` | I/Os per sec | Write requests merged per second |
| `r_await` | ms | Average time for read I/Os (queue + service) |
| `w_await` | ms | Average time for write I/Os |
| `aqu-sz` | I/Os | Average queue length |
| `%util` | % | Percentage of time device was busy processing I/O |

### Identifying I/O Bottlenecks

Scenario 1: **High latency, low utilization**
```
r/s: 10    r_await: 500ms    %util: 20%
```
Each I/O takes 500ms (disk might be failing or contended). Only 20% busy because request rate is low.

Scenario 2: **High utilization, okay latency**
```
r/s: 1000  r_await: 5ms      %util: 95%
```
Device is busy but latency is acceptable. Working near its limit.

Scenario 3: **High utilization, high latency**
```
r/s: 500   r_await: 150ms    %util: 100%
```
**Bottleneck confirmed.** Queue is building up. Need faster storage or fewer I/Os.

---

## 6. `mpstat` — Per-CPU Breakdown

`mpstat` reports individual CPU core statistics.

```
$ mpstat -P ALL 2 3
Linux 6.2.0 (hostname)   2024-01-15  _x86_64_  (4 CPU)

14:23:45     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
14:23:47     all    5.23    0.00    2.10    1.05    0.00    0.25    0.00    0.00    0.00   91.37
14:23:47       0   12.45    0.00    3.20    2.10    0.00    0.50    0.00    0.00    0.00   81.75
14:23:47       1    2.10    0.00    1.50    0.50    0.00    0.10    0.00    0.00    0.00   95.80
14:23:47       2    3.00    0.00    1.80    0.80    0.00    0.20    0.00    0.00    0.00   94.20
14:23:47       3    3.37    0.00    1.90    0.80    0.00    0.20    0.00    0.00    0.00   93.73
```

### Identifying CPU Imbalance

- CPU 0 handles all hardware interrupts (IRQ affinity by default). It is normal for CPU 0 to have slightly higher `%sys` and `%irq`.
- **Severe imbalance** (>2x difference between cores) suggests single-threaded bottleneck, IRQ affinity misconfiguration, or NUMA imbalance.

---

## 8. `ss` — Socket Statistics (Modern `netstat`)

`ss` dumps socket statistics. It reads from kernel netlink interfaces, making it faster and more detailed than `netstat`.

### Basic Usage

```
$ ss -tuln      # All listening TCP/UDP sockets, numeric
Netid  State   Recv-Q  Send-Q  Local Address:Port   Peer Address:Port
tcp    LISTEN  0       128     0.0.0.0:22           0.0.0.0:*
tcp    LISTEN  0       128     127.0.0.1:3306       0.0.0.0:*
udp    UNCONN  0       0       0.0.0.0:5353         0.0.0.0:*
```

### Key Options

| Option | Meaning |
|---|---|
| `-t` | TCP sockets |
| `-u` | UDP sockets |
| `-l` | Listening sockets only |
| `-n` | Numeric (no DNS resolution) |
| `-p` | Show process (PID + name) |
| `-a` | All sockets (listening + established) |
| `-s` | Summary statistics |
| `-i` | Internal TCP info (ssthresh, cwnd, rtt) |

### Established Connections

```
$ ss -tpn
State      Recv-Q  Send-Q  Local Address:Port      Peer Address:Port              Process
ESTAB      0       0       10.0.0.5:22             192.168.1.10:54321             users:(("sshd",pid=1234,fd=3))
ESTAB      0       0       10.0.0.5:3306           10.0.0.20:45678                users:(("mysqld",pid=5678,fd=17))
```

### Monitoring Connection States

For web servers, watch `TIME-WAIT` and `CLOSE-WAIT`:

```
$ ss -t state time-wait
$ ss -t state close-wait
```

- **TIME-WAIT** — Normal for short-lived connections. Many is fine but can exhaust port ranges.
- **CLOSE-WAIT** — The remote peer closed, but local app hasn't called `close()`. This is a **socket leak**.

---

## 9. `dstat` — Versatile Real-Time Aggregator

`dstat` combines `vmstat`, `iostat`, `netstat`, and `ifstat` into a single configurable view.

```
$ dstat
You did not select any stats, using -cdngy by default.
----total-cpu-usage---- -dsk/total- -net/total- ---paging-- ---system--
usr sys idl wai hiq siq| read  writ| recv  send|  in   out | int   csw
  5   2  92   1   0   0|  45k   67k| 123k  456k|   0     0 |1234  5678
  4   2  93   1   0   0|  32k   55k| 110k  420k|   0     0 |1189  5432
```

### Key Options

| Option | Meaning |
|---|---|
| `-c` | CPU stats |
| `-d` | Disk I/O |
| `-n` | Network |
| `-g` | Page (swap) stats |
| `-y` | System (interrupts, context switches) |
| `-l` | Load average |
| `-m` | Memory |
| `--output file.csv` | Write CSV to file |
| `--top-cpu` | Show top CPU consumer |
| `--top-io` | Show process doing the most I/O |
| `--top-mem` | Show top memory consumer |

### Real-World Examples

```
$ dstat -tc --top-cpu 2
$ dstat -td --top-io --top-bio 2
$ dstat -tcmdngy --output /tmp/performance.csv 5 120
$ dstat -tn --top-cpu --top-io --top-mem 2
```

### Plugins

```
$ dstat --list
```

Plugins include `dstat-freespace`, `dstat-mysql`, `dstat-nginx`, `dstat-sendmail`, `dstat-thermal`, `dstat-top-oom`.

---

## 10. `nmon` — All-in-One Ncurses Monitor

`nmon` (Nigel's Monitor) presents system statistics in a ncurses TUI with single-key toggles.

```
$ nmon
```

### Interactive Keys

| Key | Function |
|---|---|
| `c` | CPU utilization (per-core bar chart) |
| `m` | Memory and swap (bar + numbers) |
| `d` | Disks (per-disk I/O rates) |
| `k` | Kernel (load, context switches, uptime) |
| `n` | Network (per-interface) |
| `N` | NFS |
| `j` | Filesystem usage |
| `t` | Top processes (consuming CPU) |
| `h` | Help |
| `q` | Quit |

### Capture Mode (for scripting)

```
$ nmon -f -s 5 -c 120
```

Captures data every 5 seconds for 10 minutes, writing to a `.nmon` file.

---

## 11. `glances` — Python Power Monitor

`glances` is a cross-platform monitoring tool written in Python. It is the most feature-rich CLI monitor available.

```
$ glances
```

### Server/Client Mode

```
# On server (default port 61209)
$ glances -s

# On client
$ glances -c <server-ip>
```

### Export Modes

```
$ glances --export csv --export-csv-file /tmp/glances.csv
$ glances --export json
$ glances -w             # Web interface
$ curl http://localhost:61208/api/3/cpu
```

### Container Awareness

```
$ glances --docker
```

Shows per-container CPU, memory, network, and I/O.

---

## 14. Log-Based Monitoring

### `tail` and `multitail`

```
$ tail -f /var/log/syslog
$ tail -f /var/log/syslog | grep -i error
$ sudo multitail /var/log/syslog /var/log/auth.log
$ sudo multitail -s 2 /var/log/syslog /var/log/kern.log
```

### `logwatch` — Daily Report Generator

```
$ sudo logwatch --detail high --range today --service sshd --service auth
$ sudo logwatch --detail high --range "between -7 days and today" --service all
```

### `lnav` — The Log File Navigator

```
$ lnav /var/log/syslog /var/log/kern.log
```

Features: automatic log format detection, colorized output, timeline view, SQL-based querying.

```
; SELECT COUNT(*) FROM syslog WHERE loglevel = 'error' GROUP BY date_logged
; SELECT * FROM syslog WHERE regexp(message, 'OOM|out of memory')
```

### `journalctl` — systemd's Log Manager

```
$ journalctl -xe                     # Current boot, explanation
$ journalctl -f                      # Follow mode
$ journalctl -u nginx.service        # Specific unit
$ journalctl -p err                  # Priority=error and above
$ journalctl --since "1 hour ago"    # Time range
$ journalctl -k -f                   # Kernel messages, follow
$ journalctl -o json-pretty          # JSON output for parsing
```

---

## 15. `ncdu` — NCurses Disk Usage Analyzer

```
$ sudo apt install ncdu
$ ncdu /home
$ sudo ncdu /
```

Export to CSV: `ncdu -o report.csv /path`

---

## 16. Cockpit — Web-Based Server Administration

```
$ sudo apt install cockpit
$ sudo systemctl enable --now cockpit.socket
# Access at https://your-server:9090
```

Features: real-time graphs, terminal access, storage management, container management.

---

## 17. `sosreport` — System Diagnostic Reporting

```
$ sudo dnf install sos           # RHEL/Fedora
$ sudo apt install sosreport     # Debian/Ubuntu
$ sudo sos report
```

Collects system configuration and diagnostic info into a compressed archive for support tickets.

---

## ⭐ Level 3: Advanced — S.M.A.R.T., Prometheus, and Deep Monitoring Infrastructure

![Prometheus architecture diagram showing metric collection flow](https://upload.wikimedia.org/wikipedia/commons/3/38/Prometheus_architecture.png)

> *"When you've outgrown `top` and `iostat`, you build monitoring infrastructure. Prometheus scrapes, Grafana visualizes, and your pager goes off before users notice. The goal isn't more data — it's the right data at the right time."*

---

## 12. Prometheus + `node_exporter` — Modern Metrics Stack

Prometheus is a pull-based monitoring system. `node_exporter` exposes Linux system metrics on an HTTP endpoint.

### Architecture

```
[Linux Host] → node_exporter (:9100/metrics) → Prometheus (scrape) → Grafana (dashboard)
```

### Installing `node_exporter`

```
$ wget https://github.com/prometheus/node_exporter/releases/download/v1.7.0/node_exporter-1.7.0.linux-amd64.tar.gz
$ tar xzf node_exporter-1.7.0.linux-amd64.tar.gz
$ sudo cp node_exporter-1.7.0.linux-amd64/node_exporter /usr/local/bin/
$ node_exporter &
$ curl http://localhost:9100/metrics
```

### Installing Prometheus

```
$ wget https://github.com/prometheus/prometheus/releases/download/v2.50.0/prometheus-2.50.0.linux-amd64.tar.gz
$ tar xzf prometheus-2.50.0.linux-amd64.tar.gz
$ cd prometheus-2.50.0.linux-amd64
```

### Configuring Prometheus (`prometheus.yml`)

```yaml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'node'
    static_configs:
      - targets:
        - 'localhost:9100'
        - 'web-server-01:9100'
        - 'db-server-01:9100'
```

### Key Metrics from `node_exporter`

| Metric | Type | Meaning |
|---|---|---|
| `node_cpu_seconds_total` | counter | CPU time per mode per core |
| `node_memory_MemAvailable_bytes` | gauge | Available memory |
| `node_disk_reads_completed_total` | counter | Total completed reads |
| `node_disk_io_time_seconds_total` | counter | Total I/O time |
| `node_filesystem_avail_bytes` | gauge | Available filesystem space |
| `node_network_receive_bytes_total` | counter | Total bytes received |
| `node_load1` | gauge | 1-minute load average |

### Rate Queries (Common Patterns)

```
# CPU utilization per core
100 - avg by (instance, cpu) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100

# Memory utilization
(1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) * 100

# Disk I/O utilization
rate(node_disk_io_time_seconds_total[5m])

# Network throughput
rate(node_network_receive_bytes_total[5m])
```

### Installing Grafana

```
$ sudo apt install grafana
$ sudo systemctl start grafana-server
```

Access at http://localhost:3000. Import dashboard ID `1860` (Node Exporter Full).

---

## 13. Disk Health Monitoring

### S.M.A.R.T. with `smartctl`

S.M.A.R.T. (Self-Monitoring, Analysis and Reporting Technology) is built into modern drives.

```
$ sudo smartctl -a /dev/sda
```

**Critical attributes for SSDs:**
- `Reallocated_Sector_Ct` — Bad sectors remapped. Any non-zero value indicates the drive is failing.
- `Wear_Leveling_Count` — Shows NAND wear. When it reaches 0, the drive is write-exhausted.
- `Temperature_Celsius` — High temps accelerate NAND wear.

**Critical attributes for HDDs:**
- `Reallocated_Sector_Ct` — Same. Non-zero = failing.
- `Current_Pending_Sector` — Sectors pending remap.
- `Spin_Retry_Count` — Drive failing to spin up.

### Health Check and Tests

```
$ sudo smartctl -H /dev/sda
$ sudo smartctl -t short /dev/sda       # ~2 minutes
$ sudo smartctl -t long /dev/sda        # Several hours (HDD) or ~10 min (SSD)
$ sudo smartctl -l selftest /dev/sda    # View test results
```

### `badblocks` — Surface Scan

```
$ sudo badblocks -sv /dev/sda           # Destructive read-write (WIPES DATA!)
$ sudo badblocks -svn /dev/sda          # Non-destructive read-write
$ sudo badblocks -sv /dev/sda           # Read-only scan
```

### RAID Health

**Software RAID (mdadm):**
```
$ cat /proc/mdstat
$ sudo mdadm --detail /dev/md0
$ sudo mdadm --monitor --syslog /dev/md0
```

**Hardware RAID:**
```
$ sudo megaraid-status     # LSI/Avago/Broadcom
$ sudo perccli /c0 show    # Dell PERC controllers
$ sudo hpssacli ctrl all show config  # HP SmartArray
```

---

### `/proc/diskstats` — Per-Disk I/O (Advanced)

```
$ cat /proc/diskstats
   8       0 sda 123456 78901 9876543 123456 543210 98765 7654321 654321 0 789012 777777
```

Fields (each is cumulative since boot):

| # | Name | Meaning |
|---|---|---|
| 1 | major | Device major number |
| 2 | minor | Device minor number |
| 3 | name | Device name |
| 4 | reads_completed | Successful reads finished |
| 5 | reads_merged | Adjacent reads merged |
| 6 | sectors_read | Sectors read |
| 7 | time_reading_ms | Time spent reading |
| 8 | writes_completed | Successful writes finished |
| 9 | writes_merged | Adjacent writes merged |
| 10 | sectors_written | Sectors written |
| 11 | time_writing_ms | Time spent writing |
| 12 | io_in_progress | I/Os currently in flight |
| 13 | time_doing_io_ms | Time device had I/O in flight |
| 14 | weighted_time_doing_io_ms | Weighted sum of I/O time |

**This is what `iostat` reads.** Every I/O statistic (`tps`, `await`, `%util`) is derived from these 14 numbers.

### `%util` — The Most Misunderstood Metric

**`%util` does NOT mean "disk utilization as a percentage of capacity."** It is the percentage of time the device had at least one I/O in progress. A single disk can show 100% `%util` while only doing 50 IOPs if each takes 20ms.

**For SSDs, `%util` is almost meaningless.** Modern SSDs can process hundreds of thousands of IOPs with deep queues. Instead watch `iowait` and request latency (`r_await`, `w_await`).

### I/O Schedulers

```
$ cat /sys/block/sda/queue/scheduler
[mq-deadline] none kyber
```

- **mq-deadline** — Ensures each request gets a deadline (good for HDDs)
- **kyber** — Designed for fast SSDs/NVMe
- **none** — No scheduling (NVMe devices with their own controller)

### `/sys` Block Device Interface

`/sys/block/<device>/` exposes I/O scheduler, queue parameters, and device characteristics:

```
/sys/block/sda/queue/scheduler        # Current I/O scheduler
/sys/block/sda/queue/nr_requests      # Queue depth
/sys/block/sda/queue/rotational       # 1=HDD, 0=SSD
```

### Interrupt Distribution

```
$ cat /proc/interrupts
           CPU0       CPU1       CPU2       CPU3
 0:         45          0          0          0  IO-APIC   2-edge      timer
```

To spread interrupts across CPUs:
```
$ echo f > /proc/irq/129/smp_affinity
```

Modern systems use `irqbalance` daemon to distribute interrupts automatically.

---

## 18. Command Reference

### Level 1: Basic Monitoring

| Command | Package | Purpose | Key Flags |
|---|---|---|---|
| `top` | procps-ng | Interactive process viewer | `-b` batch, `-n` iterations, `-p` PID |
| `htop` | htop | Enhanced interactive viewer | `-s` sort, `-t` tree, `-u` user |
| `free` | procps-ng | Memory usage | `-h`, `-g`, `-m`, `-s` seconds |

### Level 2: Intermediary Monitoring

| Command | Package | Purpose | Key Flags |
|---|---|---|---|
| `vmstat` | procps-ng | System-wide snapshot | `delay count`, `-s` stats, `-d` disk |
| `iostat` | sysstat | Per-disk I/O | `-x` extended, `-p` per partition |
| `mpstat` | sysstat | Per-CPU breakdown | `-P ALL`, `-I` interrupts |
| `ss` | iproute2 | Socket stats | `-tulnp`, `-s`, `-i`, `-o` |
| `dstat` | dstat | Aggregated real-time | `-c`, `-d`, `-n`, `--top-cpu` |
| `nmon` | nmon | TUI all-in-one | `-f` capture, `-s` interval, `-c` count |
| `glances` | glances (pip) | Python comprehensive | `-s` server, `-c` client, `-w` web |
| `sar` | sysstat | Historical data collection | `-u`, `-r`, `-b`, `-n DEV` |
| `lnav` | lnav | Log file navigator | Color, SQL, multi-format |
| `journalctl` | systemd | systemd journal | `-xe`, `-u`, `-f`, `-k`, `-p` |
| `ncdu` | ncdu | Interactive disk usage analyzer | `-o` export CSV, `-f` read export |
| `cockpit` | cockpit | Web-based server admin | `cockpit.socket` service, port 9090 |
| `sos` | sos | System diagnostic report | `report`, `collect`, `--batch` |

### Level 3: Advanced Monitoring

| Command | Package | Purpose | Key Flags |
|---|---|---|---|
| `smartctl` | smartmontools | S.M.A.R.T. control | `-a`, `-H`, `-t short/long`, `-l selftest` |
| `badblocks` | e2fsprogs | Disk surface scan | `-sv`, `-svn`, `-w` |
| `perf` | linux-tools | Linux profiling | `top`, `record`, `report`, `stat` |
| `bcc` | bpfcc-tools | BPF-based tracing | `execsnoop`, `biolatency`, `tcptop` |
| `atop` | atop | Advanced process/performance | `-r` replay, `-w` write |
| `collectl` | collectl | High-precision monitoring | `-s` subsystems, `-o` output |

### Quick Installation by Distribution

**Debian/Ubuntu:**
```bash
sudo apt install htop sysstat dstat nmon glances smartmontools lnav atop bpfcc-tools
```

**RHEL/Fedora:**
```bash
sudo dnf install htop sysstat dstat nmon glances smartmontools lnav atop bcc-tools
```

---

## 19. 15 Hands-On Practices

### Level 1 Practices: Basic Monitoring

#### Practice 1: Identify Top CPU Consumers

```bash
$ top -b -n 1 | head -20
$ ps aux --sort=-%cpu | head -10
$ htop  # interactive, press P to sort by CPU
```

Write a one-liner that lists the top 5 CPU consumers with PID, %CPU, and command:
```bash
$ ps aux --sort=-%cpu | awk 'NR>1 {print $2, $3, $11}' | head -5
```

#### Practice 2: Identify Top Memory Consumers

```bash
$ top -b -n 1 -o %MEM | head -15
$ ps aux --sort=-%mem | head -10
$ ps -eo pid,pmem,rss,comm --sort=-pmem | head -5
```

#### Practice 3: Analyze I/O Bottlenecks with `iostat`

**Setup:** Simulate I/O load:
```bash
$ dd if=/dev/zero of=/tmp/testfile bs=1M count=1000 &
```

**Monitor:**
```bash
$ iostat -x 1 10
```

Watch `r_await`, `w_await`, `%util`. Note what happens to `%iowait` in `mpstat`.

#### Practice 4: Monitor Network Connections with `ss`

```bash
# Show all listening services
$ ss -tulnp

# Count connections per state
$ ss -t | awk '{print $1}' | sort | uniq -c

# Find process listening on port 8080
$ ss -tulnp | grep 8080
```

#### Practice 5: Track Swap Usage

```bash
$ free -h -s 2
$ vmstat 2
$ swapon --show
```

Create a stress test:
```bash
$ stress --vm 2 --vm-bytes 2G --timeout 30
```

Watch `si` and `so` in `vmstat`. Record peak swap rates.

### Level 2 Practices: Intermediary Monitoring

#### Practice 6: Create a Monitoring Dashboard with `glances`

```bash
# Run glances with CSV export
$ glances --export csv --export-csv-file /tmp/glances.csv

# Run in server mode on remote host
$ glances -s -B 0.0.0.0

# Connect from local machine
$ glances -c <remote-ip>

# Web interface
$ glances -w
$ curl http://localhost:61208/api/3/mem
```

#### Practice 7: Generate a Performance Baseline Report

Create a script that captures current system performance:
```bash
#!/bin/bash
# /tmp/baseline.sh - System Performance Baseline

REPORT="/tmp/baseline-$(date +%Y%m%d-%H%M).txt"

{
echo "=========================================="
echo "  SYSTEM PERFORMANCE BASELINE"
echo "  Generated: $(date)"
echo "  Hostname: $(hostname)"
echo "=========================================="
echo ""

echo "--- CPU ---"
echo "Model: $(grep 'model name' /proc/cpuinfo | head -1 | cut -d: -f2)"
echo "Cores: $(nproc)"
echo ""

echo "--- Memory ---"
free -h
echo ""

echo "--- Disks ---"
lsblk -o NAME,SIZE,TYPE,MOUNTPOINT,FSTYPE
echo ""

echo "--- Network ---"
ip -br addr | grep -v lo
echo ""

echo "--- Load Average ---"
cat /proc/loadavg
echo ""

echo "--- Top 10 CPU Consumers ---"
ps aux --sort=-%cpu | head -11
echo ""

echo "--- Top 10 Memory Consumers ---"
ps aux --sort=-%mem | head -11
echo ""

echo "--- Filesystem Usage ---"
df -h
echo ""
} > "$REPORT"

cat "$REPORT"
```

#### Practice 8: `dstat` Plugin Exploration

```bash
# List all plugins
$ dstat --list

# Monitor top CPU, I/O, and memory processes
$ dstat --top-cpu --top-io --top-mem 2

# Save output to CSV
$ dstat -tcdngy --output /tmp/dstat-export.csv 5 10
```

#### Practice 9: Using `sar` for Historical Data

```bash
# Enable sar collection (if not already)
$ sudo systemctl enable sysstat
$ sudo systemctl start sysstat

# Report CPU usage from today
$ sar -u

# Report memory for a specific date
$ sar -r -f /var/log/sysstat/sa15

# Report disk I/O
$ sar -b

# Report network
$ sar -n DEV
```

#### Practice 10: Log Anomaly Detection

```bash
# Find authentication failures
$ journalctl -u sshd -p err --since "24 hours ago" | grep "Failed password"

# Count OOM occurrences
$ zgrep -c "OOM" /var/log/syslog*

# Monitor kernel errors in real-time
$ dmesg -w | grep -i error

# Use lnav for multi-log correlation
$ lnav /var/log/syslog /var/log/kern.log
```

### Level 3 Practices: Advanced Monitoring

#### Practice 11: Set Up Prometheus `node_exporter`

```bash
# Download and run
$ wget https://github.com/prometheus/node_exporter/releases/download/v1.7.0/node_exporter-1.7.0.linux-amd64.tar.gz
$ tar xzf node_exporter-1.7.0.linux-amd64.tar.gz
$ ./node_exporter-1.7.0.linux-amd64/node_exporter &

# Query metrics
$ curl http://localhost:9100/metrics | head -50

# Filter specific metrics
$ curl -s http://localhost:9100/metrics | grep "^node_cpu_seconds_total"
$ curl -s http://localhost:9100/metrics | grep "^node_memory_Mem"
```

#### Practice 12: Query S.M.A.R.T. Data

```bash
# Check overall health
$ sudo smartctl -H /dev/sda

# Run short test
$ sudo smartctl -t short /dev/sda
$ sleep 120
$ sudo smartctl -l selftest /dev/sda

# Extract key attributes
$ sudo smartctl -A /dev/sda | grep -E "Reallocated|Wear_Leveling|Temperature|Percent_Lifetime"

# JSON output for scripting
$ sudo smartctl -a /dev/sda --json | jq '.ata_smart_attributes.table[] | select(.id == 5 or .id == 177) | {id: .id, name: .name, value: .value, raw: .raw.value}'
```

#### Practice 13: Disk Health Monitoring with Alert

```bash
#!/bin/bash
# /usr/local/bin/disk-health-check.sh

THRESHOLD_REALLOC=10
THRESHOLD_TEMP=55

for disk in sda sdb sdc; do
    [ -b "/dev/$disk" ] || continue
    
    realloc=$(sudo smartctl -A "/dev/$disk" | awk '/Reallocated_Sector_Ct/ {print $10}')
    temp=$(sudo smartctl -A "/dev/$disk" | awk '/Temperature_Celsius/ {print $10}')
    
    echo "=== /dev/$disk ==="
    echo "Reallocated Sectors: $realloc"
    echo "Temperature: ${temp}°C"
    
    if [ "$realloc" -gt "$THRESHOLD_REALLOC" ]; then
        echo "ALERT: High reallocated sector count on $disk!"
    fi
    
    if [ "${temp%%.*}" -gt "$THRESHOLD_TEMP" ]; then
        echo "ALERT: High temperature on $disk!"
    fi
done
```

#### Practice 14: Monitor Specific Process with `top` in Batch

```bash
$ top -b -n 10 -d 2 -p 1 | grep "^  PID\|^    1 " > /tmp/init-cpu.log
$ cat /tmp/init-cpu.log
```

#### Practice 15: Real-World Integration — Comprehensive System Health Report

```bash
#!/bin/bash
# /usr/local/bin/system-health-report.sh

REPORT_DIR="/var/log/system-health"
mkdir -p "$REPORT_DIR"

OUTPUT="$REPORT_DIR/health-report-$(date +%Y%m%d-%H%M).txt"
EMAIL="admin@example.com"

{
echo "==========================================="
echo "  SYSTEM HEALTH REPORT"
echo "  Host: $(hostname)"
echo "  Date: $(date)"
echo "  Uptime: $(uptime -p)"
echo "==========================================="
echo ""

# ── SECTION 1: Critical Resource Status ──
echo "== [1] CRITICAL RESOURCE STATUS =="

# CPU Load
LOAD=$(cat /proc/loadavg | awk '{print $1}')
CORES=$(nproc)
echo "CPU Load (1min): $LOAD / $CORES cores"

# Memory
MEM_AVAIL=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
MEM_TOTAL=$(grep MemTotal /proc/meminfo | awk '{print $2}')
MEM_PCT=$(echo "scale=2; (1 - $MEM_AVAIL / $MEM_TOTAL) * 100" | bc)
echo "Memory Usage: ${MEM_PCT}%"

# Swap
SWAP_USED=$(free -m | awk '/Swap:/ {print $3}')
echo "Swap Used: ${SWAP_USED}M"

# Disk
df -h --type=ext4 --type=xfs | tail -n+2 | while read line; do
    pct=$(echo "$line" | awk '{print $5}' | sed 's/%//')
    mount=$(echo "$line" | awk '{print $6}')
    [ "$pct" -gt 90 ] 2>/dev/null && echo "  ⚠ WARNING: $mount is ${pct}% full"
done

echo ""

# ── SECTION 2: Performance Metrics ──
echo "== [2] PERFORMANCE METRICS =="

# CPU breakdown
mpstat -P ALL 1 1 | tail -n+4 | head -n-1
echo ""

# Disk I/O
iostat -x 1 1 | tail -n+4 | head -n-1 | grep -v "^loop"
echo ""

# Network connections summary
echo "TCP Connection States:"
ss -t | awk '{print $1}' | sort | uniq -c | sort -rn
echo ""

# Top 5 by CPU
echo "Top 5 CPU Consumers:"
ps aux --sort=-%cpu | head -6 | awk '{print $2, $3"%", $11}'
echo ""

# Top 5 by memory
echo "Top 5 Memory Consumers:"
ps aux --sort=-%mem | head -6 | awk '{print $2, $4"%", $11}'
echo ""

# ── SECTION 3: Services Status ──
echo "== [3] CRITICAL SERVICES =="
for svc in sshd nginx mysql docker prometheus node_exporter; do
    systemctl is-active --quiet "$svc" 2>/dev/null
    if [ $? -eq 0 ]; then
        echo "  ✓ $svc is running"
    else
        echo "  ✗ $svc is NOT running (or not installed)"
    fi
done
echo ""

# ── SECTION 4: Disk Health ──
echo "== [4] DISK HEALTH (S.M.A.R.T.) =="
for disk in $(lsblk -d -o NAME | grep -v "^loop\|NAME"); do
    if smartctl -H "/dev/$disk" &>/dev/null; then
        status=$(sudo smartctl -H "/dev/$disk" | grep "SMART overall-health" | awk -F: '{print $2}')
        echo "  /dev/$disk: $status"
    fi
done
echo ""

# ── SECTION 5: Recent Errors ──
echo "== [5] RECENT SYSTEM ERRORS (last 24h) =="
journalctl -p err --since "24 hours ago" | tail -20
echo ""

echo "==========================================="
echo "  END OF HEALTH REPORT"
echo "==========================================="
} > "$OUTPUT"

cat "$OUTPUT"

# Optionally email
# mail -s "Health Report $(hostname) $(date +%Y-%m-%d)" "$EMAIL" < "$OUTPUT"
```

**Usage:**
```bash
# Run manually
$ sudo bash /usr/local/bin/system-health-report.sh

# Add to cron for daily report
$ sudo crontab -e
0 6 * * * /usr/local/bin/system-health-report.sh
```

---

## 20. Self-Test

**Instructions:** Answer each question. Score 12/15 or higher before proceeding to Part 34.

**Question 1:** What kernel file does `iostat` read to obtain per-disk I/O statistics?
- A) `/proc/meminfo`
- B) `/proc/stat`
- C) `/proc/diskstats`
- D) `/sys/block`

**Question 2:** In `vmstat`, what does a consistently high `r` value (greater than the number of CPU cores) indicate?
- A) I/O bottleneck
- B) CPU saturation
- C) Memory pressure
- D) Network congestion

**Question 3:** What is the difference between `MemFree` and `MemAvailable` in `/proc/meminfo`?
- A) They are the same value
- B) `MemFree` includes cache, `MemAvailable` does not
- C) `MemAvailable` estimates reclaimable memory including cache; `MemFree` is completely unused RAM
- D) `MemAvailable` is only for swap

**Question 4:** In `iostat -x`, what does `%util` actually measure?
- A) Percentage of disk storage capacity used
- B) Percentage of time the device had at least one I/O request in progress
- C) Percentage of I/O operations that failed
- D) Disk queue depth percentage

**Question 5:** A server shows `si: 500 KB/s` and `so: 450 KB/s` in `vmstat`. What does this mean?
- A) The server is transferring files to disk
- B) The server is actively swapping memory to/from disk — memory pressure
- C) The server is synchronizing NFS data
- D) The server is processing I/O requests normally

**Question 6:** Which `ss` command shows all listening TCP ports with associated process names?
- A) `ss -tulnp`
- B) `ss -a`
- C) `ss -s`
- D) `ss -e`

**Question 7:** What does a rising number of `CLOSE-WAIT` socket states indicate?
- A) A DDoS attack
- B) Normal TCP behavior
- C) The application is not properly closing connections (socket leak)
- D) Network congestion

**Question 8:** In CPU statistics, what does `%iowait` (`wa`) measure?
- A) Time spent servicing I/O interrupts
- B) Time the CPU is idle while at least one I/O is pending
- C) Time waiting for network data
- D) Time spent writing to disk

**Question 9:** What S.M.A.R.T. attribute should be monitored closely on SSDs?
- A) Spin_Retry_Count
- B) Reallocated_Sector_Ct
- C) Seek_Error_Rate
- D) Head_Flying_Hours

**Question 10:** How does `top` compute CPU usage percentages?
- A) It reads CPU temperature and estimates utilization
- B) It samples `/proc/stat` twice, computes deltas between jiffy counts, and divides by total delta
- C) It queries the CPU via MSR registers
- D) It reads `/proc/cpuinfo`

**Question 11:** Which tool provides a server/client architecture for remote monitoring with a web interface?
- A) `top`
- B) `vmstat`
- C) `glances`
- D) `iostat`

**Question 12:** What is the purpose of the `node_exporter` in the Prometheus ecosystem?
- A) It sends alerts when nodes go down
- B) It exposes Linux system metrics on an HTTP endpoint for Prometheus to scrape
- C) It replaces `sshd` for secure shell access
- D) It runs performance benchmarks

**Question 13:** A `dstat` command with `--top-io` flag shows which information?
- A) Top processes by CPU usage
- B) Top processes by memory usage
- C) Top processes by I/O (disk read/write) activity
- D) Top network connections

**Question 14:** In the context of the `/proc/stat` CPU line, what does the `steal` column represent?
- A) Time stolen by rootkits
- B) Time a virtual CPU waits for the hypervisor to schedule it (in virtualized environments)
- C) Time spent on unauthorized processes
- D) Time the kernel steals from user space for system calls

**Question 15:** What command would you use to run a quick non-destructive surface scan on `/dev/sdb`?
- A) `sudo badblocks -svn /dev/sdb`
- B) `sudo dd if=/dev/zero of=/dev/sdb`
- C) `sudo fdisk -l /dev/sdb`
- D) `sudo smartctl -t long /dev/sdb`

---

**Answer Key:**

| Q# | Answer | Explanation |
|---|---|---|
| 1 | **C** | `iostat` reads `/proc/diskstats` (or uses sysfs). |
| 2 | **B** | `r` is run queue. Consistently > core count means more processes want CPU than available cores. |
| 3 | **C** | `MemFree` is truly free pages; `MemAvailable` adds reclaimable cache. |
| 4 | **B** | `%util` = time device had I/O in flight, not capacity utilization. |
| 5 | **B** | `si`/`so` are swap in/out. Sustained non-zero values = active thrashing. |
| 6 | **A** | `-t` TCP, `-u` UDP, `-l` listening, `-n` numeric, `-p` process. |
| 7 | **C** | CLOSE-WAIT means remote peer closed but local app hasn't called `close()`. |
| 8 | **B** | `iowait` is idle time while at least one I/O is pending — not time *doing* I/O. |
| 9 | **B** | Reallocated_Sector_Ct is critical for both HDDs and SSDs. |
| 10 | **B** | `top` samples `/proc/stat` twice, computes jiffy deltas. |
| 11 | **C** | `glances` has server (`-s`), client (`-c`), and web (`-w`) modes. |
| 12 | **B** | `node_exporter` exposes `/metrics` endpoint with system metrics. |
| 13 | **C** | `--top-io` shows processes with highest disk I/O. |
| 14 | **B** | `steal` = time a VM vCPU waits for the hypervisor to schedule physical CPU time. |
| 15 | **A** | `-svn` = show progress + non-destructive surface scan. |

**Scoring:**
- **12–15 correct:** Proceed to Part 34 (Process Management).
- **9–11 correct:** Review sections 2–8 (kernel interfaces, vmstat, iostat, ss), then retry.
- **0–8 correct:** Re-read the entire part; focus on running each command interactively.

---

## What's Coming in Part 34

```
🐧 Linux System Administrator — Complete Course
Part 34 of ∞: Process Management
```

**Topics:**
- Process lifecycle (fork, exec, exit, wait)
- Process states (R, S, D, T, Z, X) and what forces each transition
- Signals — full catalog (SIGHUP to SIGRTMAX), default actions, which can be caught
- `kill`, `pkill`, `killall`, `pgrep` — every signal-sending tool
- `nice`/`renice` — priority manipulation and scheduler policies
- `nohup`, `disown`, `setsid` — escaping the terminal
- `screen` and `tmux` — terminal multiplexers for session persistence
- `/proc/<pid>/` deep dive — every directory entry explained
- Process limits — `ulimit`, `limits.conf`, `systemd` resource control
- OOM killer — score adjustment, why certain processes die first
- Cgroups v2 — process grouping, resource constraints, pressure stall information (PSI)

---

## Footer

```
*Previous → Part 32: Backup Strategies*
*Next → Part 34: Process Management*
```

---

*"The system is not a black box. Every number in `top`, every column in `iostat`, every state in `ss` is a window into a specific kernel data structure. When you learn to read those windows, the system becomes transparent."*

[← Previous](part32.md) | [Next →](part34.md)
