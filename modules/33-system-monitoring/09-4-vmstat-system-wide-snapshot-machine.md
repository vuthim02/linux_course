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



---

[← Previous](08-level-2-intermediary-diagnosing-bottlenecks.md) | [↑ Index](index.md) | [Next →](10-5-iostat-per-disk-io-deep.md)
