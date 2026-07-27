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



---

[← Previous](09-4-vmstat-system-wide-snapshot-machine.md) | [↑ Index](index.md) | [Next →](11-6-mpstat-per-cpu-breakdown.md)
