## 🔍 Section 2: Reading Permission Strings — The Secret Language

Every file and directory in Linux has a permission string. Run this right now:

```bash
ls -l /etc/hosts
```

You will see something like:

```
-rw-r--r-- 1 root root 221 Jan 15 10:30 /etc/hosts
```

The first 10 characters are the **permission string**. Learn this.

### Breaking Down the 10 Characters

```
Position:  1  2 3 4  5 6 7  8 9 10
          ┌─┐└─┬─┘ └─┬─┘ └─┬─┘
          │   │      │     └── Others (everyone else)
          │   │      └──────── Group owner's permissions
          │   └─────────────── User owner's permissions
          └─────────────────── File type
```

### Position 1: File Type

| Character | Meaning |
|-----------|---------|
| `-` | Regular file |
| `d` | Directory |
| `l` | Symbolic link |
| `c` | Character device (keyboard, terminal) |
| `b` | Block device (disk, USB) |
| `p` | Named pipe (FIFO) |
| `s` | Socket |

### Positions 2-4: User (Owner) Permissions

| Character | Meaning |
|-----------|---------|
| `r` | Read — can view file contents |
| `w` | Write — can modify or delete file |
| `x` | Execute — can run as a program |
| `-` | That permission is NOT granted |

### Positions 5-7: Group Permissions

Same `r`, `w`, `x` but for any user in the file's group.

### Positions 8-10: Others Permissions

Same `r`, `w`, `x` but for every other user on the system.

### Real Examples

```bash
-rw-------  1 alice  alice   1024 Jan 15 10:30 private.txt
```
Owner can read and write. No one else can do anything.

```bash
-rwxr-xr-x  1 root   root   35000 Jan 15 10:30 /usr/bin/ls
```
Owner can read, write, execute. Group and others can read and execute (but not modify).

```bash
drwxr-xr-x  2 alice  alice   4096 Jan 15 10:30 Documents/
```
Directory. Owner can read, write, enter. Others can read and enter but not create or delete files.

### What rwx Means for DIRECTORIES (Critical Difference)

For directories, rwx means something **completely different** than for files:

| Permission | On a FILE | On a DIRECTORY |
|-----------|-----------|----------------|
| `r` (read) | View file contents | List directory contents (`ls`) |
| `w` (write) | Modify file contents | Create, rename, or delete files INSIDE the directory |
| `x` (execute) | Run as a program | Enter the directory (`cd` into it), access files inside |

> 🚨 **Critical:** You need **execute (x)** on a directory to access any files inside it, even if those files have their own permissions. `chmod -x` on a directory effectively locks everyone out of its contents.

```bash
# Example: directory with r but no x
ls -ld /tmp/test
# drw-r--r--  2 alice alice 4096 ...
ls /tmp/test     # Can LIST files
cd /tmp/test     # FAIL — no x permission
cat /tmp/test/file.txt  # FAIL — no x permission
```

---



---

[← Previous](03-section-1-why-permissions-exist.md) | [↑ Index](index.md) | [Next →](05-section-3-chmod-changing-permissions.md)
