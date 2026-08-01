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
*Linux SysAdmin Course | Part 61 of ∞ | Reverse Engineering Approach*
*Previous → Part 60: Final Capstone*
*Next → Part 62: Memory Management*
[← Previous](14-whats-coming-in-part-62.md) | [↑ Index](index.md)
