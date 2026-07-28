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





[← Previous](05-2-proc-and-sys-the.md) | [↑ Index](index.md) | [Next →](07-7-free-memory-usage-reality.md)
