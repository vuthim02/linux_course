## 🔍 Section 12: Comparing RAID Levels
> **Level**: Basic (reference) — this section belongs conceptually to Level 1; placed here for document flow.

### Full Comparison Table

| Feature | RAID 0 | RAID 1 | RAID 5 | RAID 6 | RAID 10 |
|---------|--------|--------|--------|--------|---------|
| Min drives | 2 | 2 | 3 | 4 | 4 |
| Max fault tolerance | None | 1 drive | 1 drive | 2 drives | 1 per mirror |
| Effective capacity | N × | 1 × | (N-1) × | (N-2) × | N/2 × |
| Capacity efficiency | 100% | 50% | 67-94% | 50-88% | 50% |
| Read IOPS | N × | N × (both mirrors) | N × | N × | N × |
| Write IOPS (random) | N × | 1 × (both mirrors) | N/4 × | N/6 × | N/2 × |
| Sequential write | N × | 1 × | (N-1) × | (N-2) × | N/2 × |
| Write penalty | 1× | 2× | 4× | 6× | 2× |
| Rebuild impact | N/A (total loss) | Low (copy from mirror) | High (reads all drives) | Very high (reads all drives) | Low (copy from mirror) |
| Risk during rebuild | N/A | None (1 remaining) | Second failure = loss | Second failure OK | Depends on failure location |
| Use case | Temp/cache, zero concern for data loss | OS drive, small databases | General storage, archives, media | Large capacity + high uptime | Databases, VMs, high-performance |

### IOPS Calculation Example

Given 4 drives, each capable of 100 random read IOPS and 100 random write IOPS:

| Level | Read IOPS | Write IOPS | Capacity |
|-------|-----------|------------|----------|
| RAID 0 | 400 | 400 | 4 × |
| RAID 1 | 400 (both mirrors) | 100 (both write) | 2 × |
| RAID 5 | 400 (read all) | 100 (1/4 penalty) | 3 × |
| RAID 6 | 400 (read all) | ~67 (1/6 penalty) | 2 × |
| RAID 10 | 400 | 200 (half penalty) | 2 × |

RAID 10 provides the best write IOPS of any redundant RAID level, which is why it is preferred for databases.

### Capacity Efficiency Graph

```
For 4 × 1 TiB drives:

 RAID 0:  4.0 TiB usable  (100% efficiency)
 RAID 1:  1.0 TiB usable  ( 25% efficiency) — for a 2-drive mirrored pair
 RAID 5:  3.0 TiB usable  ( 75% efficiency)
 RAID 6:  2.0 TiB usable  ( 50% efficiency)
 RAID 10: 2.0 TiB usable  ( 50% efficiency)

For 10 × 1 TiB drives:

 RAID 0:  10.0 TiB usable  (100%)
 RAID 5:   9.0 TiB usable  ( 90%)
 RAID 6:   8.0 TiB usable  ( 80%)
 RAID 10:  5.0 TiB usable  ( 50%)
```

As the number of drives increases, RAID 5 and 6 become more capacity-efficient. RAID 10 always loses exactly 50% of capacity.

### When to Use What

- **RAID 0**: Scratch space, video editing temp files, scientific compute nodes where checkpointing handles failures. NEVER for valuable data.
- **RAID 1**: Boot drives, OS partitions, small databases. Simple and reliable.
- **RAID 5**: Media storage, file servers, archives, backup repositories. Good capacity efficiency with 4-8 drives.
- **RAID 6**: Large-capacity storage, archive servers, video surveillance. Protection during URE (unrecoverable read error) events during rebuild.
- **RAID 10**: Databases (MySQL, PostgreSQL, Oracle), virtual machine stores, high-performance file servers. Best write performance of any redundant level.

---



---

[← Previous](15-section-11-hardware-raid.md) | [↑ Index](index.md) | [Next →](17-15-hands-on-practices.md)
