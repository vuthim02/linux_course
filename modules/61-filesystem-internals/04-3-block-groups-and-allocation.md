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





[← Previous](03-2-inodes-the-heart-of.md) | [↑ Index](index.md) | [Next →](05-4-journaling-how-linux-prevents.md)
