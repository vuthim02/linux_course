## 🔍 Section 7: Looking at Files — Quick Preview Commands

### file — Identify File Type

```bash
file /bin/ls              # ELF binary
file /etc/hosts           # ASCII text
file image.jpg            # JPEG image data
file unknown_file         # Determines what it is
file -i document.pdf      # MIME type: application/pdf
```

### stat — Detailed File Information

```bash
stat /etc/hosts
# File: /etc/hosts
# Size: 221      Blocks: 8     IO Block: 4096  regular file
# Device: 801h/2049d  Inode: 1234567  Links: 2
# Access: 2024-01-15 10:30:00.000000000 -0500
# Modify: 2024-01-15 10:30:00.000000000 -0500
# Change: 2024-01-15 10:30:00.000000000 -0500
# Birth: 2023-12-01 14:22:00.000000000 -0500
```

### du — Disk Usage by File/Directory

```bash
du -sh /var/log            # Total size of directory
du -sh * | sort -rh        # Sizes of all items, sorted
du -sh /* 2>/dev/null | sort -rh | head -10  # Largest root dirs
```

### type — Where Does a Command Come From

```bash
type ls           # ls is /usr/bin/ls
type cd           # cd is a shell builtin
type -a ls        # All locations (including aliases)
```

### which — Find Executable Path

```bash
which python3     # /usr/bin/python3
which -a ssh      # All ssh binaries in PATH
```

---



---

[← Previous](07-section-6-modern-alternatives-rg.md) | [↑ Index](index.md) | [Next →](09-practice-section-18-hands-on-exercises.md)
