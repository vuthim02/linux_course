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



---

[← Previous](10-5-iostat-per-disk-io-deep.md) | [↑ Index](index.md) | [Next →](12-8-ss-socket-statistics-modern.md)
