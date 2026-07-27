## 1. Filesystem Architecture — What Lives on Disk

### The Four-Layer Model

```
┌─────────────────────────────────────────────────────┐
│                    USER SPACE                         │
│   Application → POSIX API → VFS (Virtual FS)        │
├─────────────────────────────────────────────────────┤
│                    KERNEL SPACE                       │
│   VFS → Filesystem Driver → Block Layer → Driver    │
├─────────────────────────────────────────────────────┤
│                    DISK LAYER                         │
│   Superblock │ Block Groups │ Journal │ Data Blocks  │
└─────────────────────────────────────────────────────┘
```

### On-Disk Layout (ext4)

```
┌─────────┬──────────┬──────────┬──────────┬─────────┬──────────┐
│ Boot    │ Super-   │ Group    │ Group    │ Group   │ Group    │
│ Block   │ block    │ 0 Desc   │ 1 Desc   │ 2 Desc  │ N Desc   │
│ (1KB)   │ (4KB)    │ Table    │ Table    │ Table   │ Table    │
│         │          │ + inode  │ + inode  │ + inode │ + inode  │
│         │          │ bitmap   │ bitmap   │ bitmap  │ bitmap   │
│         │          │ + block  │ + block  │ + block │ + block  │
│         │          │ bitmap   │ bitmap   │ bitmap  │ bitmap   │
│         │          │ + data   │ + data   │ + data  │ + data   │
└─────────┴──────────┴──────────┴──────────┴─────────┴──────────┘
```

### Superblock — The Master Record

The superblock contains everything about the filesystem:

```bash
# View superblock contents
sudo dumpe2fs /dev/sda1 | head -50

# Example output:
# Filesystem volume name:   <none>
# Filesystem magic number:  0xEF53
# Filesystem state:         clean
# Error behavior:           Continue
# Filesystem OS type:       Linux
# Inode count:              655360
# Block count:              2621440
# Reserved block count:     131072
# Free blocks:              1843200
# Free inodes:              620000
# First block:              0
# Block size:               4096
# Fragment size:            4096
# Blocks per group:         32768
# Inodes per group:         8192
# Inode size:               256
# Journal inode:            8
```

```bash
# XFS superblock
sudo xfs_db -r /dev/sda1 -c "sb 0" -c "print"

# Btrfs superblock
sudo btrfs inspect-internal dump-super /dev/sda1
```

> 🔍 **Reverse Engineering Insight:** The superblock is written LAST during filesystem creation. If it's corrupted, the entire filesystem is lost. That's why ext4 keeps backup superblocks in every block group — you can restore from any of them.

---



---

[← Previous](01-what-you-will-achieve.md) | [↑ Index](index.md) | [Next →](03-2-inodes-the-heart-of.md)
