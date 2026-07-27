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



---

[← Previous](02-1-filesystem-architecture-what-lives.md) | [↑ Index](index.md) | [Next →](04-3-block-groups-and-allocation.md)
