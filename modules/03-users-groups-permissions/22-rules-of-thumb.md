## 📏 Rules of Thumb

### The Permission Rules

| Rule | Description | Why |
|------|-------------|-----|
| **Never use 777** | World-writable is dangerous | Anyone can modify/delete |
| **Use 644 for files** | Read-only for others | Prevents tampering |
| **Use 755 for dirs** | Traverse but not modify | Standard security |
| **Use 700 for private** | Owner-only access | SSH keys, configs |
| **Use 600 for secrets** | No execute, no group/other | Passwords, keys |

### The Directory Permission Rules

| Permission | What It Means |
|------------|---------------|
| `r` (4) | Can list directory contents (`ls`) |
| `w` (2) | Can create/delete files inside |
| `x` (1) | Can enter directory (`cd`) and access files |

**Critical insight:** You need `x` on a directory to access ANY files inside it, even if the files have open permissions. No `x` = locked out.

### The Ownership Rules

| Rule | Description |
|------|-------------|
| **Root can do anything** | Root ignores DAC permissions (but not MAC/SELinux) |
| **Owner can change permissions** | `chmod` only works for owner or root |
| **Root can change ownership** | `chown` requires root |
| **Group determines access** | User's primary group + supplementary groups |

### The SUID/SGID Audit Rules

```bash
# Find all SUID binaries (potential escalation vectors):
find / -perm -4000 -type f 2>/dev/null

# Find all SGID binaries:
find / -perm -2000 -type f 2>/dev/null

# Remove SUID from a file:
chmod u-s /path/to/file

# Remove SGID from a directory:
chmod g-s /path/to/dir
```

### The "I Can't Access This File" Checklist

```bash
# 1. Check permissions:
ls -la /path/to/file

# 2. Check ownership:
ls -la /path/to/file

# 3. Check if you're in the right group:
groups

# 4. Check directory permissions:
ls -ld /path/to/directory

# 5. Check ACLs:
getfacl /path/to/file

# 6. Check SELinux:
ls -Z /path/to/file

# 7. Try with sudo (if appropriate):
sudo cat /path/to/file
```

### The sudoers Rules

```bash
# Always edit with visudo:
visudo

# Syntax:
user    ALL=(ALL:ALL) ALL      # Full access
user    ALL=(ALL) NOPASSWD: ALL  # No password prompt
%group  ALL=(ALL) ALL          # Group access

# Drop-in files (safer):
# Edit /etc/sudoers.d/username instead of /etc/sudoers
```

---

**Why these rules matter:** Following these rules prevents 95% of permission-related security issues. They're the "seatbelts" of Linux access control.

[← Previous](23-self-test-can-you-answer-these.md) | [↑ Index](index.md)
