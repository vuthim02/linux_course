## 🔍 Section 3: The `ls` Command — Far More Than "List Files"

Most beginners use `ls` and think they know it. Let's go deeper.

### Basic Usage

```bash
ls              # List current directory
ls /etc         # List a specific directory
ls -l           # Long format (details)
ls -a           # Show ALL files including hidden
ls -la          # Long format + hidden files (most useful combination)
ls -lh          # Long format with human-readable file sizes
ls -lt          # Sort by modification time (newest first)
ls -ltr         # Sort by time, reversed (oldest first — useful for logs)
ls -R           # Recursive — show all subdirectories too
ls -ld /etc     # Show info about the DIRECTORY itself, not its contents
```

### Understanding `ls -l` Output

```bash
ls -l /etc/hosts
```

Output:
```
-rw-r--r-- 1 root root 221 Jan 15 10:30 /etc/hosts
```

Breaking this down piece by piece:

```
-rw-r--r--   1     root   root   221    Jan 15 10:30   /etc/hosts
│            │     │      │      │      │              │
│            │     │      │      │      │              └─ File name
│            │     │      │      │      └─ Last modified date/time
│            │     │      │      └─ File size in bytes
│            │     │      └─ Group owner
│            │     └─ User owner
│            └─ Number of hard links
└─ Permissions (we cover this deeply in Part 3)
```

The first character tells you the **type**:

| Character | Type |
|-----------|------|
| `-` | Regular file |
| `d` | Directory |
| `l` | Symbolic link (shortcut) |
| `c` | Character device (keyboard, terminal) |
| `b` | Block device (hard drive, USB) |
| `p` | Named pipe |
| `s` | Socket |

---



---

[← Previous](04-section-2-paths-the-address.md) | [↑ Index](index.md) | [Next →](06-section-4-hidden-files-linuxs.md)
