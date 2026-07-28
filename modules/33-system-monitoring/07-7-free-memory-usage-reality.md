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





[← Previous](06-3-top-htop-interactive-process.md) | [↑ Index](index.md) | [Next →](08-level-2-intermediary-diagnosing-bottlenecks.md)
