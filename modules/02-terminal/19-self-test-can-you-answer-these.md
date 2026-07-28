## 📝 Self-Test — Can You Answer These?

Before moving to Part 3, answer without looking:

1. What is the difference between `/home/john/file.txt` and `./file.txt`?
2. What does `cd -` do?
3. How do you create the directory structure `a/b/c/d` in one command?
4. What is the difference between `>` and `>>` when redirecting?
5. Why should you NEVER use `rm -rf` carelessly?
6. What does `tail -f` do and when would a sysadmin use it?
7. What does a file starting with `.` mean in Linux?
8. What is the difference between a symlink and a hard link?
9. How do you find all files larger than 100MB on the system?
10. What does `ls -ltr` show and why is it useful for sysadmins?

**Score:** 8/10 correct = ready for Part 3.


## Answer Key

### Q1: What is the difference between `/home/john/file.txt` and `./file.txt`?
**Answer:** `/home/john/file.txt` is an absolute path (from root). `./file.txt` is a relative path (from the current working directory).

### Q2: What does `cd -` do?
**Answer:** Switches to the previous working directory (like a "back" button).

### Q3: How do you create the directory structure `a/b/c/d` in one command?
**Answer:** `mkdir -p a/b/c/d` — the `-p` flag creates parent directories as needed.

### Q4: What is the difference between `>` and `>>` when redirecting?
**Answer:** `>` overwrites the file; `>>` appends to the file.

### Q5: Why should you NEVER use `rm -rf` carelessly?
**Answer:** `rm -rf` recursively deletes files and directories without confirmation. A typo like `rm -rf /` or `rm -rf ~` can destroy the entire system or home directory.

### Q6: What does `tail -f` do and when would a sysadmin use it?
**Answer:** `tail -f` follows (streams) new lines appended to a file in real-time. Sysadmins use it to watch log files as events occur.

### Q7: What does a file starting with `.` mean in Linux?
**Answer:** It is a hidden file. Files prefixed with `.` are not shown by default in `ls` (use `ls -a` to see them).

### Q8: What is the difference between a symlink and a hard link?
**Answer:** A symlink (symbolic link) is a pointer to a path name; it breaks if the original is moved/deleted. A hard link points directly to the inode; the data survives even if the original filename is removed.

### Q9: How do you find all files larger than 100MB on the system?
**Answer:** `find / -type f -size +100M` — searches from root for files over 100 megabytes.

### Q10: What does `ls -ltr` show and why is it useful for sysadmins?
**Answer:** Lists files in long format, sorted by modification time (newest last). Useful for quickly finding recently modified files, especially in log directories.


*Linux SysAdmin Course | Part 2 of 50+ | Reverse Engineering Approach*
*Previous → Part 1: What Is Linux & How It Really Works*
*Next → Part 3: Users, Groups, and Permissions — Who Can Do What*
[← Previous](part1.md) | [Next →](part3.md)



[← Previous](18-whats-coming-in-part-3.md) | [↑ Index](index.md)
