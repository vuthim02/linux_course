## 🔍 Section 11: Special Permissions — SUID, SGID, Sticky Bit

### SUID — Set User ID (Position 3 becomes `s`)

When a file with SUID is executed, it runs as the **file's owner**, not as the user who ran it.

```bash
ls -l /usr/bin/passwd
# -rwsr-xr-x 1 root root 59976 Jan 15 10:30 /usr/bin/passwd
#   ↑
#   s = SUID set
```

When you (a regular user) run `passwd`, it runs as **root** because the file is owned by root and has SUID. This allows it to write to `/etc/shadow` — which you normally cannot access.

```bash
# Set SUID
chmod u+s script.sh
# or
chmod 4755 script.sh    # 4 = SUID
```

```bash
# Remove SUID
chmod u-s script.sh
```

### SGID — Set Group ID (Position 6 becomes `s`)

**On files:** The file runs with the group of the file, not the user's group.

```bash
ls -l /usr/bin/wall
# -rwxr-sr-x 1 root tty 34832 Jan 15 10:30 /usr/bin/wall
#          ↑
#          s = SGID set
```

**On directories (MOST USEFUL):** Files created inside an SGID directory inherit the directory's group, not the user's primary group.

```bash
# Create a shared directory where all files stay in the 'project' group
sudo mkdir /shared/project
sudo chgrp project /shared/project
sudo chmod g+s /shared/project
# Now every file created in /shared/project gets group = 'project'
```

```bash
# Set SGID on directory
chmod g+s /shared/project
# or
chmod 2755 /shared/project   # 2 = SGID
```

### Sticky Bit (Position 9 becomes `t`)

On directories with the sticky bit, users can only delete their **own** files, even if they have write access to the directory.

```bash
ls -ld /tmp
# drwxrwxrwt 20 root root 4096 Jan 15 10:30 /tmp
#               ↑
#               t = Sticky Bit set
```

Every user can write to `/tmp`, but user Alice cannot delete Bob's files.

```bash
# Set Sticky Bit
chmod o+t /shared/directory
# or
chmod 1755 /shared/directory    # 1 = Sticky Bit
```

### Special Permissions Quick Reference

| Special Bit | Numeric | On Files | On Directories |
|-------------|---------|----------|----------------|
| SUID | 4xxx | Runs as file owner | Ignored |
| SGID | 2xxx | Runs as file group | New files inherit directory's group |
| Sticky | 1xxx | Ignored (historically: keep in memory) | Users can only delete their own files |

### Finding Special Permissions

```bash
# Find all SUID files on the system (potential security risk)
find / -perm -4000 -type f 2>/dev/null

# Find all SGID files
find / -perm -2000 -type f 2>/dev/null

# Find world-writable directories with sticky bit (should be rare)
find / -type d -perm -1000 -ls 2>/dev/null
```

> 🚨 **Security:** SUID files are a common attack vector. A misconfigured SUID binary can let an attacker escalate to root. Audit them regularly.





[← Previous](14-level-3-advanced-advanced-access.md) | [↑ Index](index.md) | [Next →](16-section-12-umask-default-permissions.md)
