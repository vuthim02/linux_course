## 4. Journaling — How Linux Prevents Data Loss

### Why Journaling Exists

Without journaling, a power failure during a write can leave the filesystem in an inconsistent state. The journal (or log) records **intent** before applying changes:

```
┌─────────────────────────────────────────────────────┐
│              JOURNALING WORKFLOW                      │
│                                                       │
│  1. Write INTENT to journal (fast, sequential)        │
│  2. Flush journal to disk                             │
│  3. Apply actual changes to filesystem (random I/O)   │
│  4. Mark journal entry as complete                    │
│                                                       │
│  On recovery: replay incomplete journal entries       │
└─────────────────────────────────────────────────────┘
```

### ext4 Journal Modes

```bash
# Check current journal mode
sudo tune2fs -l /dev/sda1 | grep "Filesystem features"

# Modes:
# journal   = data + metadata (safest, slowest)
# writeback = metadata only (fast, data can be stale)
# ordered   = metadata + data ordering (default, balanced)

# Change journal mode
sudo tune2fs -o journal_data_writeback /dev/sda1
sudo tune2fs -o journal_data /dev/sda1
sudo tune2fs -o journal_data_ordered /dev/sda1

# Mount with specific mode
mount -o data=writeback /dev/sda1 /mnt
```

### XFS Log (Journal)

```bash
# XFS uses a circular log (internal by default)
sudo xfs_db -r /dev/sda1 -c "log" -c "print"

# XFS log is typically 64MB-1GB
# Forced to disk every 5 seconds (default)
# Can be external on a separate device for performance

# Mount XFS with external log
mkfs.xfs -l logdev=/dev/sdb1,size=256m /dev/sda1
mount -o logdev=/dev/sdb1 /dev/sda1 /mnt
```

### Btrfs Copy-on-Write (No Journal)

```bash
# Btrfs doesn't use journaling — it uses CoW
# Old data blocks are never overwritten in place
# New data goes to new blocks, then metadata updates atomically

# Verify Btrfs CoW behavior
sudo btrfs filesystem show /mnt
sudo btrfs inspect-internal dump-tree /dev/sda1 | head -50
```





[← Previous](04-3-block-groups-and-allocation.md) | [↑ Index](index.md) | [Next →](06-5-filesystem-repair-when-things.md)
