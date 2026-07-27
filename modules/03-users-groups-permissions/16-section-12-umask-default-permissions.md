## 🔍 Section 12: umask — Default Permissions

When you create a file or directory, it gets **default permissions**. The `umask` subtracts from those defaults.

### How umask Works

```
File default:       666 (rw-rw-rw-)
Directory default:  777 (rwxrwxrwx)
Subtract umask:     --- umask value
Result:             Actual permissions
```

```bash
# Check current umask
umask
# 0022

# What this means:
# Files:   666 - 022 = 644 (rw-r--r--)
# Dirs:    777 - 022 = 755 (rwxr-xr-x)
```

### Common umask Values

| umask | Files | Dirs | Use Case |
|-------|-------|------|----------|
| `0000` | 666 (rw-rw-rw-) | 777 (rwxrwxrwx) | Complete open — everyone can do everything |
| `0002` | 664 (rw-rw-r--) | 775 (rwxrwxr-x) | Shared projects — group can write |
| `0022` | 644 (rw-r--r--) | 755 (rwxr-xr-x) | Default — group can read but not write |
| `0027` | 640 (rw-r-----) | 750 (rwxr-x---) | Restricted — group can read, others nothing |
| `0077` | 600 (rw-------) | 700 (rwx------) | Private — only owner can do anything |

```bash
# Set umask temporarily
umask 0027

# Touch a file and check
touch test.txt
ls -l test.txt
# -rw-r----- 1 alice alice 0 Jan 15 10:30 test.txt

# Set permanently in ~/.bashrc or ~/.profile
echo "umask 0027" >> ~/.profile
```

> 💡 On shared systems, set `umask 0027` to prevent other users from reading your files by default.

---



---

[← Previous](15-section-11-special-permissions-suid.md) | [↑ Index](index.md) | [Next →](17-section-13-access-control-lists.md)
