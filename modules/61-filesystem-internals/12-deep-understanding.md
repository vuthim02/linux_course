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





[← Previous](11-15-hands-on-practices.md) | [↑ Index](index.md) | [Next →](13-command-reference.md)
