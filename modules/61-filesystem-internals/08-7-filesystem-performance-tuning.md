## 7. Filesystem Performance Tuning

### Mount Options

```bash
# ext4 performance mount options
mount -o noatime,nodiratime,data=writeback,barrier=0,commit=60 /dev/sda1 /mnt

# noatime    — don't update access time (faster reads)
# nodiratime — don't update directory access time
# data=writeback — don't journal data (faster, less safe)
# barrier=0  — disable write barriers (DANGEROUS with RAID)
# commit=60  — journal commit every 60s (default 5s)

# XFS performance
mount -o noatime,logbufs=8,logbsize=256k,allocsize=64m /dev/sda1 /mnt

# Btrfs performance
mount -o noatime,compress=lzo,ssd,discard /dev/sda1 /mnt
```

### IO Scheduler Tuning

```bash
# Check current scheduler
cat /sys/block/sda/queue/scheduler

# For SSDs (no seek time)
echo none > /sys/block/sda/queue/scheduler    # or "mq-deadline"

# For HDDs (optimize seek)
echo bfq > /sys/block/sda/queue/scheduler     # or "mq-deadline"

# Adjust read-ahead
sudo blockdev --getra /dev/sda     # Current read-ahead (usually 256)
sudo blockdev --setra 4096 /dev/sda  # Increase to 2MB for sequential
```

### Filesystem-Specific Tuning

```bash
# ext4: increase max mount count before fsck
sudo tune2fs -c 0 /dev/sda1     # Never force fsck

# ext4: increase reserved blocks for performance
sudo tune2fs -m 5 /dev/sda1     # 5% reserved

# XFS: increase internal log size
sudo xfs_repair -L /dev/sda1    # WARNING: loses log
mkfs.xfs -l logdev=/dev/sdb1,size=1g /dev/sda1  # External log

# Btrfs: enable compression
sudo btrfs property set /mnt compression zlib
sudo btrfs filesystem defragment -r -czstd /mnt
```





[← Previous](07-6-diagnosing-df-vs-du.md) | [↑ Index](index.md) | [Next →](09-8-filesystem-monitoring.md)
