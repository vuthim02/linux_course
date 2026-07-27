## 🧠 Section 11: Deep Understanding — How Linux Stores Files

### The Inode — What a File Really Is

When you create a file, Linux creates two things:

1. **The inode** — stores all metadata: permissions, owner, size, timestamps, location on disk
2. **The directory entry** — maps the filename to the inode number

This is why you can have two names (hard links) for one file — two directory entries pointing to the same inode.

```bash
# See inode numbers
ls -i ~/practice/project1/docs/README.md

# See inode usage on your filesystem
df -i
```

### The Real Meaning of "Delete"

When you `rm file.txt`:
1. Linux removes the **directory entry** (the name)
2. The inode's **link count** drops by 1
3. If link count reaches **0**, the disk space is marked as free
4. The data isn't actually erased — it just becomes "available to overwrite"

This is why:
- Hard links protect data (link count > 1 even after one name is removed)
- Forensic tools can sometimes recover deleted files (data not overwritten yet)
- SSD "secure erase" is a different, explicit process

---



---

[← Previous](15-level-3-advanced-storage-internals.md) | [↑ Index](index.md) | [Next →](17-summary-complete-command-reference-for.md)
