## 🔬 Deep Understanding

### fsync and Disk Barriers

When a backup tool reports "success," writes may still be in the kernel's page cache, not on physical media.

```c
write(fd, buffer, count);   // returns immediately (cached)
fsync(fd);                  // blocks until data is on physical media
```

Without `fsync`, a crash after the backup "succeeds" loses data.
- `rsync` does NOT fsync by default (use `--fsync`)
- `borg` calls fsync on repo data
- `restic` calls fsync on saved files
- `mysqldump`/`pg_dump` call fsync on output

Disk write caches lie. Consumer drives report "written" while data sits in volatile RAM:

```bash
# Check and disable volatile write cache
sudo hdparm -W /dev/sda   # 1=enabled (risky), 0=safe
sudo hdparm -W 0 /dev/sda
```

### COW Filesystem Implications

Btrfs and ZFS (Copy-on-Write) don't overwrite in place. This is excellent for instant snapshots, but bad for random-write workloads.

```bash
# Btrfs snapshot
sudo btrfs subvolume snapshot -r /mnt/data /mnt/data/.snapshots/backup-$(date +%F)
sudo btrfs send /mnt/data/.snapshots/backup-2025-01-12 | \
    sudo btrfs receive /backup-server/data/

# ZFS snapshot
zfs snapshot tank/data@backup-$(date +%F)
zfs send tank/data@backup | ssh server zfs receive tank/backups

# Disable COW for VM images on Btrfs (avoid double-COW)
chattr +C /var/lib/libvirt/images/
```

### Sparse Files

Sparse files have "holes" — zeros not stored on disk. A 1 TB database with 100 GB real data uses 100 GB.

```bash
dd if=/dev/zero of=sparse.img bs=1M seek=1000 count=0
ls -lh sparse.img   # 1000 MB (apparent)
du -h sparse.img    # 0 bytes (actual)

# tar preserves sparseness only with -S
tar cSf backup.tar sparse.img    # preserves holes
tar cf backup.tar sparse.img     # fills holes → huge

# rsync preserves with -S
rsync -aS sparse.img /backup/

# Borg/Restic handle sparse files automatically
```

### Hard Link Detection

Hard links: multiple directory entries → same inode. Backups must preserve this.

```bash
ln original.txt link1.txt link2.txt
ls -li *.txt  # same inode

# rsync: needs -H flag
rsync -aH /source/ /backup/
# tar: preserves by default
# Borg/Restic: detect and preserve
```

### Checksumming for Integrity

| Tool | Checksum Strategy |
|------|-------------------|
| rsync | Block-level MD5 (with `--checksum`) |
| tar | None (archive structure only) |
| Borg | BLAKE2b per chunk, verified on extract |
| Restic | SHA256 per pack file, verified on `check` |
| dd | None — block-level, no error detection |

```bash
# Simulate bit rot
echo "data" > test.txt
printf '\xff' | dd of=test.txt bs=1 seek=5 conv=notrunc
# Borg/Restic detect this on next check; tar does not
```

### Incremental vs Deduplication

| Aspect | Incremental (rsync --link-dest) | Deduplication (Borg, Restic) |
|--------|-------------------------------|------------------------------|
| Granularity | File-level | Sub-file chunk-level |
| 1-byte change in 100 MB file | Copies entire 100 MB file | Stores ~4-64 KB new chunks |
| Restore chain | Full + all incrementals | Single snapshot (self-contained) |
| Complexity | Low | Medium |

Incremental = file-level tracking. Deduplication = chunk-level, detects changes WITHIN files.

### Application-Consistent Backups

File-level backup of a running database gives garbage (mixed pre/post-transaction state):

```bash
# Solution 1: LVM snapshot
lvcreate -L 10G -s -n data-snap /dev/vg/data
mount -o ro /dev/vg/data-snap /mnt/snap
tar czf backup.tar.gz /mnt/snap/
umount /mnt/snap && lvremove /dev/vg/data-snap

# Solution 2: Filesystem freeze
fsfreeze -f /var/lib/mysql   # flush + freeze
# backup here
fsfreeze -u /var/lib/mysql

# Solution 3: MySQL LOCK TABLES
mysql -e "FLUSH TABLES WITH READ LOCK;"
# snapshot here
mysql -e "UNLOCK TABLES;"
```

---



---

[← Previous](24-restore-testing.md) | [↑ Index](index.md) | [Next →](26-15-hands-on-practices.md)
