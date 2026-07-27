## Command Reference

| Task | Command |
|------|---------|
| View superblock | `dumpe2fs /dev/sdX \| head -50` |
| View inode | `stat file` |
| Check inode usage | `df -i` |
| Find inode-heavy dirs | `find / -xdev -printf '%h\\n' \| sort \| uniq -c \| sort -rn` |
| Repair ext4 | `e2fsck -y /dev/sdX` |
| Repair XFS | `xfs_repair /dev/sdX` |
| Force XFS log repair | `xfs_repair -L /dev/sdX` |
| Btrfs scrub | `btrfs scrub start /mnt` |
| Find deleted files | `lsof +L1` |
| Recover ext4 | `extundelete /dev/sdX --restore-all` |
| Check block size | `tune2fs -l /dev/sdX \| grep "Block size"` |
| Check journal mode | `tune2fs -l /dev/sdX \| grep features` |
| Change reserved blocks | `tune2fs -m 1 /dev/sdX` |
| Benchmark | `fio --name=test --directory=/mnt --rw=randwrite --bs=4k --size=100M` |

---



---

[← Previous](12-deep-understanding.md) | [↑ Index](index.md) | [Next →](14-whats-coming-in-part-62.md)
