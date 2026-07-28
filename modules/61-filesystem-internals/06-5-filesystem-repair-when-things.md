## 5. Filesystem Repair — When Things Break

### ext4 Repair with e2fsck

```bash
# ALWAYS unmount first!
sudo umount /dev/sda1

# Check filesystem (read-only)
sudo e2fsck -n /dev/sda1

# Repair filesystem (interactive)
sudo e2fsck -y /dev/sda1

# Force repair (dangerous, use only on unmounted)
sudo e2fsck -fy /dev/sda1

# Repair using backup superblock
# First, find backup superblock locations
sudo dumpe2fs /dev/sda1 | grep "Backup superblock"

# If primary superblock is corrupted
sudo e2fsck -b 32768 /dev/sda1    # Use backup at block 32768

# Common e2fsck output:
# /dev/sda1: clean, 12345/655360 files, 234567/2621440 blocks
# /dev/sda1: Inode 12345 has corrupt block extent tree
# /dev/sda1: UNEXPECTED INODE COUNT FOUND
```

### XFS Repair with xfs_repair

```bash
# XFS repair is more aggressive — it zero-fills corrupted areas
sudo xfs_repair /dev/sda1

# If log is corrupt, force log zeroing
sudo xfs_repair -L /dev/sda1     # DANGEROUS: loses unsynced data

# Repair with specific sector size
sudo xfs_repair -b 4096 /dev/sda1

# Check filesystem without repair
sudo xfs_repair -n /dev/sda1     # No modifications
```

### Btrfs Repair

```bash
# Btrfs self-heals with checksums
sudo btrfs scrub start /mnt
sudo btrfs scrub status /mnt

# If checksum mismatch, Btrfs returns error
# Can mount with degraded mode to access data
sudo mount -o degraded,ro /dev/sda1 /mnt

# Replace damaged device
sudo btrfs device replace /dev/sda1 /dev/sdb1 /mnt
```

### Recovering Deleted Files

```bash
# ext4 — use extundelete
sudo extundelete /dev/sda1 --restore-all
sudo extundelete /dev/sda1 --restore-file /path/to/file

# XFS — use xfsundelete (limited)
# Better: restore from backup (testdisk, photorec)

# Btrfs — use btrfs restore
sudo btrfs restore /dev/sda1 /recovery/

# Universal — testdisk for partition recovery
sudo testdisk /dev/sda
```





[← Previous](05-4-journaling-how-linux-prevents.md) | [↑ Index](index.md) | [Next →](07-6-diagnosing-df-vs-du.md)
