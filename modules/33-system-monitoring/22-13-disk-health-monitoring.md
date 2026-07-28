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





[← Previous](21-12-prometheus-nodeexporter-modern-metrics.md) | [↑ Index](index.md) | [Next →](23-18-command-reference.md)
