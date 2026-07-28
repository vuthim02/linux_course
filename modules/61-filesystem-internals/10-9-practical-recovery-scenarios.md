## 9. Practical Recovery Scenarios

### Scenario 1: Corrupted ext4 After Power Loss

```bash
# 1. Boot from live USB
# 2. Unmount filesystem
sudo umount /dev/sda2

# 3. Check filesystem
sudo e2fsck -n /dev/sda2

# 4. If errors found, repair
sudo e2fsck -y /dev/sda2

# 5. If superblock corrupted, use backup
sudo e2fsck -b 32768 /dev/sda2

# 6. Mount and verify
sudo mount /dev/sda2 /mnt
ls /mnt
```

### Scenario 2: XFS Log Corruption

```bash
# 1. Try normal repair
sudo xfs_repair /dev/sda1

# 2. If log is corrupt, force zero log
sudo xfs_repair -L /dev/sda1

# 3. Mount and check
sudo mount /dev/sda1 /mnt
```

### Scenario 3: Btrfs Checksum Mismatch

```bash
# 1. Run scrub
sudo btrfs scrub start /mnt
sudo btrfs scrub status /mnt

# 2. If errors found, mount degraded
sudo mount -o degraded,ro /dev/sda1 /mnt

# 3. Copy data to safe location
sudo rsync -av /mnt/ /recovery/

# 4. Rebuild array
sudo mkfs.btrfs /dev/sda1 /dev/sdb1
sudo mount /dev/sda1 /mnt
sudo rsync -av /recovery/ /mnt/
```





[← Previous](09-8-filesystem-monitoring.md) | [↑ Index](index.md) | [Next →](11-15-hands-on-practices.md)
