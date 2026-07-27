## 🔍 Section 3: chmod — Changing Permissions

### Method 1: Symbolic Mode (Easier to Read)

```bash
chmod [who][operator][permission] file
```

| Who | Meaning |
|-----|---------|
| `u` | User (owner) |
| `g` | Group |
| `o` | Others |
| `a` | All (user + group + others) |

| Operator | Meaning |
|----------|---------|
| `+` | Add permission |
| `-` | Remove permission |
| `=` | Set exactly (overwrites) |

```bash
# Give owner execute permission
chmod u+x script.sh

# Remove write from group and others
chmod go-w file.txt

# Give group read and execute, set others to read-only
chmod g=rx,o=r file.txt

# Give everyone execute
chmod a+x script.sh

# Add multiple at once
chmod u+rwx,g+rx,o+r file.sh
```

### Method 2: Numeric (Octal) Mode (Faster, Professional)

Every permission has a number:

```
r = 4
w = 2
x = 1
- = 0
```

Add the numbers together for each group:

```bash
# rwx = 4+2+1 = 7  (full access)
# r-x = 4+0+1 = 5  (read + execute)
# r-- = 4+0+0 = 4  (read only)
# -wx = 0+2+1 = 3  (write + execute)
# --- = 0+0+0 = 0  (no permissions)
```

**The three digits** = owner + group + others:

```bash
chmod 755 file.sh
# 7 (rwx) for owner, 5 (r-x) for group, 5 (r-x) for others

chmod 644 file.txt
# 6 (rw-) for owner, 4 (r--) for group, 4 (r--) for others

chmod 600 private.key
# 6 (rw-) for owner, 0 (---) for group, 0 (---) for others

chmod 700 script.sh
# 7 (rwx) for owner, 0 (---) for everyone else

chmod 777 dangerous.sh
# 💀 Everyone can do EVERYTHING. Avoid this.
```

### Quick Reference — Most Common Permissions

| Number | String | Meaning | Use Case |
|--------|--------|---------|----------|
| `644` | `-rw-r--r--` | Owner read/write, everyone else read | Regular files |
| `755` | `-rwxr-xr-x` | Owner full, others read/execute | Executables, scripts |
| `700` | `-rwx------` | Only owner can do anything | Private scripts, SSH keys |
| `600` | `-rw-------` | Only owner can read/write | Private config, SSH private keys |
| `640` | `-rw-r-----` | Owner read/write, group read | Shared project files |
| `664` | `-rw-rw-r--` | Owner + group read/write | Collaborative files |
| `777` | `-rwxrwxrwx` | Everyone can do everything | AVOID |
| `000` | `----------` | No one can do anything | Lock a file |

```bash
# Practice: Convert between symbolic and numeric
# chmod u=rwx,g=rx,o=rx   =  755
# chmod u=rw,g=r,o=       =  640
# chmod u=rwx,g=,o=       =  700
# chmod u=rw,g=rw,o=r     =  664
```

---



---

[← Previous](04-section-2-reading-permission-strings.md) | [↑ Index](index.md) | [Next →](06-section-4-chown-and-chgrp.md)
