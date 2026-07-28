## 🔍 Section 7: RAID 10 — Stripe of Mirrors

### The Near-Right Layout

RAID 10 in Linux md has several layout options. The default (and most common) is `near=2`:

```
Layout: near=2 (2 copies, near layout)
Chunk: 64K

Disk 1    Disk 2    Disk 3    Disk 4
┌────────┬────────┬────────┬────────┐
│ A1     │ A1     │ B1     │ B1     │
├────────┼────────┼────────┼────────┤
│ C1     │ C1     │ D1     │ D1     │
├────────┼────────┼────────┼────────┤
│ E1     │ E1     │ F1     │ F1     │
└────────┴────────┴────────┴────────┘
```

Each chunk is mirrored on the adjacent drive (1-2, 3-4). The stripes run across the mirror pairs.

### How RAID 10 Handles Failure

RAID 10 is the most fault-tolerant RAID level because any drive can fail and the mirror carries the data. With a 4-drive RAID 10:

- Survives 1 drive failure (obviously — mirror kicks in)
- Survives up to 2 drive failures IF no mirror loses both drives
- Can survive 2 failures if the failed drives are in different mirror pairs
- Could theoretically survive N/2 failures (with N=4, up to 2 failures possible)

Compare to RAID 5: any second failure during rebuild = total array loss.
Compare to RAID 6: survives exactly 2 failures, regardless of which drives.

### RAID 10 Performance Characteristics

| Metric | RAID 10 | RAID 5 | RAID 6 |
|--------|---------|--------|--------|
| Read IOPS | N x single drive | N x single drive | N x single drive |
| Write IOPS | N/2 x single drive | N/4 x single drive (random) | N/6 x single drive |
| Sequential read | N x single drive | N x single drive | N x single drive |
| Sequential write | N/2 x single drive | (N-1) x single drive | (N-2) x single drive |
| Write penalty | 2x | 4x | 6x |

For write-heavy workloads (databases, transaction logs), RAID 10 is significantly faster than RAID 5/6 because the write penalty is only 2x (both sides of the mirror).

### Creating RAID 10 with Different Layouts

```bash
# Default: near=2 (two copies, adjacent drives)
mdadm --create /dev/md10 --level=10 --raid-devices=4 \
    /dev/sda /dev/sdb /dev/sdc /dev/sdd

# Explicit near=2
mdadm --create /dev/md10 --level=10 --raid-devices=4 \
    --layout=n2 /dev/sda /dev/sdb /dev/sdc /dev/sdd

# far layout — copies are far apart on the drive
# Better read performance for sequential access
mdadm --create /dev/md10 --level=10 --raid-devices=4 \
    --layout=f2 /dev/sda /dev/sdb /dev/sdc /dev/sdd

# offset layout — copies on different drives at offset chunks
mdadm --create /dev/md10 --level=10 --raid-devices=4 \
    --layout=o2 /dev/sda /dev/sdb /dev/sdc /dev/sdd
```

The `far` layout spreads the mirrored copies to opposite ends of the drive platters, which improves sequential read performance but increases seek time for random reads.





[← Previous](09-section-6-raid-56-parity.md) | [↑ Index](index.md) | [Next →](11-section-8-raid-failure-simulation.md)
