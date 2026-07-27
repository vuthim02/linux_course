# 🐧 Linux System Administrator — Complete Course
## Part 61 of ∞: Filesystem Internals — Inodes, Journaling, and Recovery

---

> **Reverse Engineering Approach:** When `df` says you have space but `No space left on device` errors appear, when a power outage corrupts your filesystem, when you need to understand why `du` and `df` disagree — you need to understand filesystem internals. This part takes apart ext4, XFS, and Btrfs from the inside, tracing every disk write through inodes, superblocks, journals, and allocation strategies until you can diagnose and repair any filesystem problem.

---

## 🎯 What You Will Achieve

- Understand inode structure, number allocation, and why you can run out of inodes
- Explain superblock, block groups, and filesystem layout on disk
- Trace writes through journaling (ext4 journal, XFS log, Btrfs CoW)
- Diagnose `df` vs `du` discrepancies using `debugfs` and `xfs_db`
- Repair corrupted filesystems with `fsck`, `e2fsck`, `xfs_repair`
- Recover deleted files with `extundelete` and `testdisk`
- Tune filesystem parameters for performance and reliability
- Monitor filesystem health proactively

---

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

## 2. Inodes — The Heart of Linux Filesystems

### What Is an Inode?

An inode is a data structure that describes a single file or directory:

```bash
# Create a test file and inspect its inode
echo "Hello, inode world" > /tmp/testfile
ls -i /tmp/testfile          # Show inode number
stat /tmp/testfile           # Show full inode details

# Output:
# File: /tmp/testfile
# Size: 20              Blocks: 8          IO Block: 4096   regular file
# Device: 253h/37d       Inode: 131073      Links: 1
# Access: (0644/-rw-r--r--)  Uid: ( 1000/   user)   Gid: ( 1000/   user)
# Access: 2026-07-26 10:15:22.123456789 -0400
# Modify: 2026-07-26 10:15:22.123456789 -0400
# Change: 2026-07-26 10:15:22.123456789 -0400
#  Birth: 2026-07-26 10:15:22.123456789 -0400
```

### Inode Contents

```
┌─────────────────────────────────────────────────────┐
│                    INODE (256 bytes)                  │
├─────────────────────────────────────────────────────┤
│  Mode (file type + permissions)                      │
│  UID (owner)                                         │
│  GID (group)                                         │
│  Size (in bytes)                                     │
│  Access time (atime)                                 │
│  Modification time (mtime)                           │
│  Change time (ctime)                                 │
│  Creation time (crtime)                              │
│  Link count                                          │
│  Block count                                         │
│  Direct blocks (12 × 4KB = 48KB)                    │
│  Single indirect block (→ 1024 pointers)             │
│  Double indirect block (→ 1024² pointers)            │
│  Triple indirect block (→ 1024³ pointers)            │
│  Extended attributes (xattr)                         │
│  ACL                                                 │
│  Encryption info                                     │
└─────────────────────────────────────────────────────┘
```

### Inode Number Exhaustion

```bash
# Check inode usage
df -i /home

# Example output:
# Filesystem      Inodes  IUsed   IFree IUse% Mounted on
# /dev/sda2       655360  655360      0  100%  /home

# You have free space but NO free inodes!
df -h /home
# Filesystem      Size  Used Avail Use% Mounted on
# /dev/sda2        50G   20G   30G  40%  /home

# Find which directories consume the most inodes
sudo find /home -xdev -printf '%h\n' | sort | uniq -c | sort -rn | head -20

# Common culprit: mail server with millions of small files
# /var/mail or /var/spool/mail
```

> 🔍 **Reverse Engineering Insight:** Each file needs exactly ONE inode, regardless of size. A 1-byte file and a 1GB file both consume one inode. Systems with millions of small files (email servers, caches, npm projects) run out of inodes long before running out of disk space.

### Inode Allocation

```bash
# How many inodes per group?
sudo dumpe2fs /dev/sda1 | grep "Inodes per group"

# Default: one inode per 16KB of disk space
# For a 1TB partition: 1TB / 16KB = 67,108,864 inodes

# Create filesystem with specific inode ratio
sudo mkfs.ext4 -i 8192 /dev/sdb1    # 1 inode per 8KB (more inodes)
sudo mkfs.ext4 -i 65536 /dev/sdb1   # 1 inode per 64KB (fewer inodes)
```

---

## 3. Block Groups and Allocation

### Block Group Structure

```bash
# View block group descriptor table
sudo dumpe2fs /dev/sda1 | grep -A 20 "Group 0"

# Output:
# Group 0: (Blocks 0-32767)
#   Primary superblock at 0, Group descriptors at 1
#   Reserved GDT blocks at 2-129
#   Block bitmap at 130, Inode bitmap at 131
#   Inode table at 132-139
#   27777 free blocks, 8123 free inodes, 327 directories
#   Free blocks: 3422-32767
#   Free inodes: 8132-16384
```

### Block Sizes

| Block Size | Max File Size | Max Volume | Trade-off |
|-----------|---------------|------------|-----------|
| 1KB | 16GB | 1TB | Many small files |
| 4KB | 2TB | 16TB | Default, balanced |
| 64KB | 2TB | 256TB | Large files only |

### Block Allocation Strategies

```bash
# Check filesystem block size
sudo tune2fs -l /dev/sda1 | grep "Block size"

# Check how blocks are allocated
sudo debugfs -R "stat <8>" /dev/sda1   # Stat the root inode

# Extent-based allocation (modern ext4)
sudo debugfs -R "dump_extents <12>" /dev/sda1 /tmp/testfile

# Example extent output:
# Level Entries: 1, Leafents: 1, Flatsize: 72
#  [0] start: 0, len: 8, block: 102400
```

> 🔍 **Reverse Engineering Insight:** ext4 uses **extents** (contiguous block ranges) instead of individual block pointers. A single extent can describe millions of contiguous blocks, dramatically reducing metadata overhead for large files.

---

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

---

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

---

## 6. Diagnosing df vs du Discrepancies

### Common Causes

```bash
# Scenario: df says full, du says plenty of space
df -h /
# Filesystem      Size  Used Avail Use% Mounted on
# /dev/sda2        50G   50G     0 100% /

du -sh /
# 30G     /

# Missing 20GB! Where is it?
```

### Cause 1: Deleted Files with Open File Handles

```bash
# Find processes holding deleted files
sudo lsof +L1

# Example output:
# COMMAND    PID   USER   FD   TYPE DEVICE SIZE/OFF NLINK NODE NAME
# nginx    1234   root    5w   REG  253,2  15728640     0 131073 /var/log/nginx/access.log (deleted)

# Solution: restart the process to release the file
sudo systemctl restart nginx
```

### Cause 2: Reserved Blocks

```bash
# ext4 reserves 5% of blocks for root
sudo tune2fs -l /dev/sda1 | grep "Reserved block count"

# Check reserved space
echo "Reserved: $(($(sudo tune2fs -l /dev/sda1 | grep 'Reserved block count' | awk '{print $NF}') * 4096 / 1024 / 1024))MB"

# Reduce reserved space (only for non-root partitions!)
sudo tune2fs -m 1 /dev/sda1    # Reduce to 1%
```

### Cause 3: Metadata Overhead

```bash
# Inodes, journal, superblock copies consume space
sudo dumpe2fs /dev/sda1 | grep -E "(Inode count|Block count|Reserved)"

# Btrfs metadata can grow unbounded
sudo btrfs filesystem usage /mnt
```

### Diagnostic Script

```bash
#!/bin/bash
# df_du_diagnose.sh — Find space discrepancy
echo "=== df vs du Diagnosis ==="
echo "df output:"
df -h "$1"
echo ""
echo "Top directories by space:"
sudo du -sh "$1"/* 2>/dev/null | sort -rh | head -10
echo ""
echo "Deleted files with open handles:"
sudo lsof +L1 2>/dev/null | head -10
echo ""
echo "Inode usage:"
df -i "$1"
```

---

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

---

## 8. Filesystem Monitoring

### Proactive Monitoring Script

```bash
#!/bin/bash
# fs_monitor.sh — Monitor filesystem health
set -euo pipefail

THRESHOLD=80
INODE_THRESHOLD=90

echo "=== Filesystem Health Report ==="
echo "Timestamp: $(date)"
echo ""

# Disk space
echo "Disk Space:"
df -h | grep -E "^/dev/" | while read line; do
    usage=$(echo "$line" | awk '{print $5}' | tr -d '%')
    mount=$(echo "$line" | awk '{print $6}')
    if [ "$usage" -gt "$THRESHOLD" ]; then
        echo "  ⚠️  WARNING: $mount at ${usage}%"
    else
        echo "  ✅ OK: $mount at ${usage}%"
    fi
done

echo ""
echo "Inode Usage:"
df -i | grep -E "^/dev/" | while read line; do
    usage=$(echo "$line" | awk '{print $5}' | tr -d '%')
    mount=$(echo "$line" | awk '{print $6}')
    if [ "$usage" -gt "$INODE_THRESHOLD" ]; then
        echo "  ⚠️  WARNING: $mount inodes at ${usage}%"
    else
        echo "  ✅ OK: $mount inodes at ${usage}%"
    fi
done

echo ""
echo "Filesystem Errors:"
sudo dmesg | grep -i "error\|corrupt\|readonly" | tail -5
```

### SMART Monitoring for Disk Health

```bash
# Check disk health
sudo smartctl -a /dev/sda

# Key attributes to watch:
# Reallocated_Sector_Ct: Growing = disk failing
# Current_Pending_Sector: Sectors waiting to be reallocated
# Offline_Uncorrectable: Uncorrectable sectors

# Run short test
sudo smartctl -t short /dev/sda

# View test results
sudo smartctl -l selftest /dev/sda
```

---

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

---

## 15 Hands-On Practices

### Practice 1: Inspect Inode Structure

```bash
# Create test filesystem
dd if=/dev/zero of=/tmp/test.img bs=1M count=100
sudo mkfs.ext4 /tmp/test.img
mkdir /tmp/testmount
sudo mount /tmp/test.img /tmp/testmount

# Create files and inspect inodes
touch /tmp/testmount/file{1..100}
ls -i /tmp/testmount/ | head -20
stat /tmp/testmount/file1

# Check inode table
sudo dumpe2fs /tmp/test.img | grep -A 5 "Inode table"

# Cleanup
sudo umount /tmp/testmount
rm /tmp/test.img
```

✅ **Expected**: Inode numbers, stat output, inode table location

### Practice 2: Run Out of Inodes

```bash
# Create filesystem with minimal inodes
dd if=/dev/zero of=/tmp/small.img bs=1M count=10
sudo mkfs.ext4 -i 4096 /tmp/small.img   # 1 inode per 4KB
mkdir /tmp/smallmount
sudo mount /tmp/small.img /tmp/smallmount

# Fill with tiny files
for i in $(seq 1 10000); do
    echo "x" > /tmp/smallmount/file_$i 2>/dev/null || break
done

# Check inode usage
df -i /tmp/smallmount

# Cleanup
sudo umount /tmp/smallmount
rm /tmp/small.img
```

✅ **Expected**: Filesystem full with free space remaining

### Practice 3: Corrupt and Repair ext4

```bash
# Create test filesystem
dd if=/dev/zero of=/tmp/repair.img bs=1M count=50
sudo mkfs.ext4 /tmp/repair.img
mkdir /tmp/repairmount
sudo mount /tmp/repair.img /tmp/repairmount

# Create some data
echo "Important data" | sudo tee /tmp/repairmount/important.txt
sudo sync

# Corrupt the filesystem (simulated)
sudo dd if=/dev/zero of=/tmp/repair.img bs=512 count=1 seek=2 conv=notrunc

# Unmount and repair
sudo umount /tmp/repairmount
sudo e2fsck -y /tmp/repair.img

# Mount and check data
sudo mount /tmp/repair.img /tmp/repairmount
cat /tmp/repairmount/important.txt

# Cleanup
sudo umount /tmp/repairmount
rm /tmp/repair.img
```

✅ **Expected**: e2fsck repairs corruption, data may be partially recoverable

### Practice 4: Diagnose df vs du

```bash
# Simulate deleted file with open handle
sudo mkdir -p /tmp/testspace
dd if=/dev/zero of=/tmp/testspace/bigfile bs=1M count=500
sudo mount --bind /tmp/testspace /tmp/testmount

# Open file in background
sudo dd if=/tmp/testmount/bigfile of=/dev/null &

# Delete file while open
sudo rm /tmp/testmount/bigfile

# Check discrepancy
df -h /tmp/testmount
du -sh /tmp/testmount

# Find deleted file
sudo lsof +L1 | grep testmount

# Cleanup
kill %1 2>/dev/null
sudo umount /tmp/testmount
rm -rf /tmp/testspace
```

✅ **Expected**: df shows 500MB used, du shows 0, lsof reveals deleted file

### Practice 5: Filesystem Performance Comparison

```bash
# Benchmark different mount options
for opts in "default" "noatime" "data=writeback"; do
    sudo umount /tmp/testmount 2>/dev/null
    sudo mount -o $opts /tmp/test.img /tmp/testmount
    echo "Mount options: $opts"
    dd if=/dev/zero of=/tmp/testmount/benchmark bs=1M count=100 oflag=direct 2>&1 | tail -1
    rm /tmp/testmount/benchmark
done
```

✅ **Expected**: Performance differences between mount options

### Practice 6: XFS Repair

```bash
# Create XFS filesystem
dd if=/dev/zero of=/tmp/xfs.img bs=1M count=50
sudo mkfs.xfs /tmp/xfs.img
mkdir /tmp/xfsmount
sudo mount /tmp/xfs.img /tmp/xfsmount

# Create data
for i in $(seq 1 1000); do echo "data_$i" > /tmp/xfsmount/file_$i; done
sudo sync

# Corrupt log area
sudo dd if=/dev/zero of=/tmp/xfs.img bs=512 count=10 seek=1 conv=notrunc

# Repair
sudo umount /tmp/xfsmount
sudo xfs_repair -L /tmp/xfs.img

# Mount and verify
sudo mount /tmp/xfs.img /tmp/xfsmount
ls /tmp/xfsmount | wc -l

# Cleanup
sudo umount /tmp/xfsmount
rm /tmp/xfs.img
```

✅ **Expected**: xfs_repair fixes log, data recovered

### Practice 7: Recover Deleted Files with extundelete

```bash
# Install extundelete
sudo apt install extundelete

# Create test filesystem
dd if=/dev/zero of=/tmp/recover.img bs=1M count=50
sudo mkfs.ext4 /tmp/recover.img
mkdir /tmp/recovermount
sudo mount /tmp/recover.img /tmp/recovermount

# Create and delete files
echo "recover me" > /tmp/recovermount/deleted.txt
echo "also me" > /tmp/recovermount/also_deleted.txt
sudo sync
sudo rm /tmp/recovermount/deleted.txt /tmp/recovermount/also_deleted.txt

# Recover
sudo umount /tmp/recovermount
sudo extundelete /tmp/recover.img --restore-all
ls RECOVERED_FILES/

# Cleanup
sudo umount /tmp/recovermount 2>/dev/null
rm -rf RECOVERED_FILES /tmp/recover.img
```

✅ **Expected**: Deleted files recovered to RECOVERED_FILES/

### Practice 8: Monitor Inode Usage

```bash
# Find directories with most inodes
sudo find / -xdev -printf '%h\n' 2>/dev/null | sort | uniq -c | sort -rn | head -20

# Watch inode usage in real-time
watch -n 5 'df -i / | tail -1'
```

✅ **Expected**: Top inode-consuming directories identified

### Practice 9: Btrfs Checksum Verification

```bash
# Create Btrfs filesystem
dd if=/dev/zero of=/tmp/btrfs.img bs=1M count=100
sudo mkfs.btrfs /tmp/btrfs.img
mkdir /tmp/btrfsmount
sudo mount /tmp/btrfs.img /tmp/btrfsmount

# Write data
for i in $(seq 1 100); do
    dd if=/dev/urandom of=/tmp/btrfsmount/file_$i bs=1K count=10 2>/dev/null
done

# Verify checksums
sudo btrfs scrub start /tmp/btrfsmount
sudo btrfs scrub status /tmp/btrfsmount

# Cleanup
sudo umount /tmp/btrfsmount
rm /tmp/btrfs.img
```

✅ **Expected**: All checksums verify, scrub reports no errors

### Practice 10: Filesystem Backup and Restore

```bash
# Backup ext4 filesystem
dd if=/dev/sda1 of=/tmp/ext4_backup.img bs=4M status=progress

# Verify backup
sudo e2fsck -n /tmp/ext4_backup.img

# Restore
dd if=/tmp/ext4_backup.img of=/dev/sda1 bs=4M status=progress
```

✅ **Expected**: Backup and restore complete without errors

### Practice 11: Compare Filesystem Performance

```bash
# Create test images
for fs in ext4 xfs; do
    dd if=/dev/zero of=/tmp/${fs}.img bs=1M count=200
    sudo mkfs.$fs /tmp/${fs}.img
done

# Benchmark with fio
for fs in ext4 xfs; do
    mkdir -p /tmp/${fs}_mount
    sudo mount /tmp/${fs}.img /tmp/${fs}_mount
    echo "=== $fs ==="
    sudo fio --name=test --directory=/tmp/${fs}_mount --rw=randwrite --bs=4k --size=100M --numjobs=1 --runtime=10 --group_reporting
    sudo umount /tmp/${fs}_mount
done
```

✅ **Expected**: Performance comparison between ext4 and XFS

### Practice 12: Repair with Backup Superblock

```bash
# Create filesystem
dd if=/dev/zero of=/tmp/sb.img bs=1M count=50
sudo mkfs.ext4 /tmp/sb.img

# Find backup superblock locations
sudo dumpe2fs /tmp/sb.img | grep "Backup superblock"

# Corrupt primary superblock
sudo dd if=/dev/zero of=/tmp/sb.img bs=4096 count=1 conv=notrunc

# Repair using backup
BACKUP_BLOCK=$(sudo dumpe2fs /tmp/sb.img | grep "Backup superblock" | head -1 | awk '{print $NF}')
sudo e2fsck -b $BACKUP_BLOCK /tmp/sb.img

rm /tmp/sb.img
```

✅ **Expected**: Filesystem recovered from backup superblock

### Practice 13: Journal Analysis

```bash
# View ext4 journal
sudo debugfs -R "ls -l <8>" /dev/sda1   # Root inode

# XFS log info
sudo xfs_db -r /dev/sda1 -c "log" -c "print"

# Monitor journal activity
sudo iotop -a -o -d 5
```

✅ **Expected**: Journal structure visible and understood

### Practice 14: Filesystem Health Dashboard

```bash
#!/bin/bash
# fs_health.sh — Complete filesystem health check
echo "=== Filesystem Health Dashboard ==="
echo "Timestamp: $(date)"
echo ""

echo "1. Disk Space:"
df -h | grep -E "^/dev/"
echo ""

echo "2. Inode Usage:"
df -i | grep -E "^/dev/"
echo ""

echo "3. Filesystem Errors:"
sudo dmesg | grep -iE "ext4|xfs|btrfs|error|corrupt" | tail -10
echo ""

echo "4. SMART Status:"
for disk in /dev/sd?; do
    if [ -b "$disk" ]; then
        echo "  $disk: $(sudo smartctl -H $disk 2>/dev/null | grep "overall" | awk -F: '{print $2}' || echo "N/A")"
    fi
done
echo ""

echo "5. Mount Options:"
mount | grep -E "^/dev/"
```

✅ **Expected**: Complete health report with all filesystem metrics

### Practice 15: Real-World Recovery Scenario

```bash
# Simulate production scenario: power loss during write
# 1. Create "production" filesystem
dd if=/dev/zero of=/tmp/prod.img bs=1M count=200
sudo mkfs.ext4 /tmp/prod.img
mkdir /tmp/prodmount
sudo mount /tmp/prod.img /tmp/prodmount

# 2. Simulate workload
for i in $(seq 1 1000); do
    echo "data_$i" > /tmp/prodmount/file_$i
    sync
done

# 3. Simulate crash (corrupt journal)
sudo dd if=/dev/zero of=/tmp/prod.img bs=512 count=10 seek=100 conv=notrunc

# 4. Recovery procedure
sudo umount /tmp/prodmount
sudo e2fsck -y /tmp/prod.img
sudo mount /tmp/prod.img /tmp/prodmount

# 5. Verify data integrity
echo "Files recovered: $(ls /tmp/prodmount/ | wc -l)"
cat /tmp/prodmount/file_1
cat /tmp/prodmount/file_500
cat /tmp/prodmount/file_1000

# Cleanup
sudo umount /tmp/prodmount
rm /tmp/prod.img
```

✅ **Expected**: Filesystem repaired, majority of files recovered

---

## Deep Understanding

### How ext4 Extents Work

An extent is a contiguous range of blocks described by three values:

```
┌─────────────────────────────────────────────────────┐
│ EXTENT: [start_block, length, physical_block]        │
│                                                       │
│ Example: [1000, 50, 50000]                            │
│   → Logical blocks 1000-1049 map to physical 50000-50049 │
│                                                       │
│ A single extent can describe millions of blocks!      │
│ A large file might have:                              │
│   - 12 direct blocks (48KB)                           │
│   - 1 indirect block (4MB)                            │
│   - 1 double indirect (4GB)                           │
│   - 1 triple indirect (4TB)                           │
│   - 1 extent (unlimited) ← modern ext4 uses this     │
└─────────────────────────────────────────────────────┘
```

### How Journaling Prevents Corruption

```
Without journaling:
  1. Write block A ← SUCCESS
  2. Write block B ← POWER FAILURE
  → Filesystem INCONSISTENT (block B corrupt)

With journaling:
  1. Write intent to journal ← SUCCESS
  2. Flush journal to disk ← SUCCESS
  3. Write block A ← SUCCESS
  4. Write block B ← POWER FAILURE
  → On reboot: replay journal → block B written correctly
  → Filesystem CONSISTENT
```

### Why df and du Disagree

```
df reports: allocated blocks (including deleted-but-open files)
du reports: traversed directory entries (misses deleted files)

Scenario:
  1. File A: 1GB, opened by process
  2. rm file A (directory entry removed, inode still referenced)
  3. du -sh / → 0 (doesn't see file A)
  4. df -h / → 1GB (block still allocated to file A)

Fix: kill process holding file A → blocks freed → df matches du
```

---

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

## What's Coming in Part 62

```
┌─────────────────────────────────────────────────────────┐
│   Part 62: Memory Management — Swap, Page Cache, NUMA  │
├─────────────────────────────────────────────────────────┤
│   • How Linux manages physical memory                    │
│   • Page cache vs buffer cache                          │
│   • Swap architecture and vm.swappiness                 │
│   • zram and zswap for compressed swap                  │
│   • NUMA topology and memory placement                  │
│   • OOM killer deep dive                                │
│   • Memory overcommit strategies                        │
│   • Diagnosing memory pressure                          │
│   • Tuning for database and application servers          │
└─────────────────────────────────────────────────────────┘
```

---

## Self-Test

1. What is an inode and what information does it contain?
2. Why can you run out of inodes but have free disk space?
3. What is the difference between ext4 journaling modes (journal, writeback, ordered)?
4. How does XFS logging differ from ext4 journaling?
5. What is Btrfs Copy-on-Write and why doesn't it need a journal?
6. How do you repair an ext4 filesystem with a corrupted superblock?
7. What causes `df` and `du` to report different sizes?
8. How do you find processes holding deleted files?
9. What mount options improve filesystem performance on SSDs?
10. How does an ext4 extent differ from traditional block pointers?
11. What is the purpose of reserved blocks in ext4?
12. How do you run a Btrfs scrub to verify data integrity?
13. What is the danger of `xfs_repair -L`?
14. How do you reduce reserved blocks on a non-root partition?
15. What is the first step in any filesystem repair procedure?

**Answers:**
1. Inode = index node; contains mode, owner, size, timestamps, block pointers, xattr, ACL
2. Each file needs one inode regardless of size; millions of small files exhaust inodes first
3. journal = data+metadata (safest), writeback = metadata only (fastest), ordered = metadata + data ordering (default)
4. XFS uses circular log (internal or external), committed every 5s; ext4 uses journaled metadata blocks
5. CoW writes new data to new blocks, then updates metadata atomically; old blocks kept until no references
6. `e2fsck -b <backup_block>` using backup superblock from `dumpe2fs` output
7. Deleted files with open file handles — blocks still allocated but directory entry removed
8. `sudo lsof +L1` shows files with link count 0 but still open
9. `noatime,nodiratime,data=writeback` and SSD scheduler (`none` or `mq-deadline`)
10. Extent = contiguous block range (start, length, physical); reduces metadata overhead vs individual pointers
11. Reserved blocks prevent fragmentation and ensure root can write when filesystem is "full"
12. `sudo btrfs scrub start /mnt` then `sudo btrfs scrub status /mnt`
13. Forces log zeroing — loses all unsynced data still in the journal
14. `tune2fs -m 1 /dev/sdX` reduces reserved to 1%
15. Unmount the filesystem before running any repair tool

**Score:** 12/15 correct = ready for Part 62.

---

*Linux SysAdmin Course | Part 61 of ∞ | Reverse Engineering Approach*
*Previous → Part 60: Final Capstone*
*Next → Part 62: Memory Management*

[← Previous](part60.md) | [Next →](part62.md)
