## 11. diff and patch

### 11.1 diff — Compare Files

```bash
diff file1 file2                   # normal format
diff -u file1 file2               # unified format (most common)
diff -c file1 file2               # context format
diff -Naur dir1/ dir2/            # recursive, new/absent as empty
diff -rq dir1/ dir2/              # recursive, only which differ
diff -y file1 file2               # side by side
diff -w file1 file2               # ignore whitespace
diff -i file1 file2               # ignore case
```

### 11.2 Creating Patches

```bash
# Unified diff (standard for patches)
diff -u original.c modified.c > fix.patch

# Recursive directory patch
diff -Naur orig/ new/ > changes.patch

# Git-style (no timestamps in headers)
diff -u original.c modified.c | grep -v '^[+-]{3}' > clean.patch
```

### 11.3 Applying Patches

```bash
patch < fix.patch                  # apply to working dir
patch -p0 < fix.patch             # strip 0 path components
patch -p1 < fix.patch             # strip 1 path component
patch -R < fix.patch              # reverse (undo)
patch --dry-run < fix.patch       # test without applying

# Applying directory patches
cd /usr/src/nginx-1.24.0/
patch -p1 < /path/to/nginx-security.patch
```

### 11.4 Admin Use Cases

```bash
# Verify config changes
diff -u /etc/ssh/sshd_config.bak /etc/ssh/sshd_config

# Package file integrity
dpkg --verify | awk '$1 ~ /^[^ ]/ {print $0}'

# Document changes before deployment
diff -rq /etc/nginx/ /etc/nginx.staging/ | grep -v '.git'

# Roll back config
patch -R < /var/backups/sshd_config.$(date +%F).patch

# Compare two servers' package lists
ssh server1 'dpkg -l' | awk 'NR>5 {print $2, $3}' | sort > svr1.txt
ssh server2 'dpkg -l' | awk 'NR>5 {print $2, $3}' | sort > svr2.txt
diff -u svr1.txt svr2.txt
```





[← Previous](14-10-xargs-building-command-lines.md) | [↑ Index](index.md) | [Next →](16-12-real-world-admin-scripts.md)
