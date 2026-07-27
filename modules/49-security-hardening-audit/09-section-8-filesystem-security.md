## 🔍 Section 8: Filesystem Security

### Mount Options — nosuid, noexec, nodev

Every filesystem mount should use security options where applicable:

```bash
# Check current mount options
mount | grep -E '^/dev|tmpfs'

# Apply security options to /etc/fstab
sudo tee -a /etc/fstab > /dev/null << 'EOF'

# /tmp as tmpfs with security options
tmpfs   /tmp    tmpfs    defaults,nosuid,nodev,noexec,size=2G    0 0

# /var/tmp with security options
tmpfs   /var/tmp    tmpfs    defaults,nosuid,nodev,noexec,size=1G    0 0

# /home — no setuid binaries allowed
/dev/sdb1   /home   ext4    defaults,nosuid,nodev    0 2

# /var — separate partition (prevents log overflow on root)
/dev/sdc1   /var    ext4    defaults,nosuid,nodev    0 2

# /dev/shm — no execution
tmpfs   /dev/shm    tmpfs    defaults,nosuid,nodev,noexec    0 0
EOF
```

### /tmp Hardening

```bash
# Option 1: tmpfs in memory (fast, no disk writes)
sudo mount -o remount,noexec,nosuid,nodev /tmp

# Option 2: Persistent but hardened
# In /etc/fstab:
# UUID=xxxx /tmp ext4 defaults,nosuid,nodev,noexec 0 2

# Option 3: systemd tmpfiles.d
sudo tee /etc/tmpfiles.d/tmp-hardening.conf > /dev/null << 'EOF'
# Set secure permissions on /tmp
D /tmp 1777 root root 10d

# Clean up old files automatically
# /usr/lib/tmpfiles.d/tmp.conf already does this
EOF
```

### SUID / SGID Audit

SUID/SGID binaries are a common privilege escalation vector:

```bash
# Find all SUID binaries
sudo find / -perm -4000 -type f 2>/dev/null

# Find all SGID binaries
sudo find / -perm -2000 -type f 2>/dev/null

# Remove SUID from binaries that don't need it
sudo chmod -s /usr/bin/wall
sudo chmod -s /usr/bin/write
sudo chmod -s /usr/bin/newgrp
sudo chmod -s /usr/bin/chsh
sudo chmod -s /usr/bin/chfn

# Document which SUID binaries should exist
sudo find / -perm -4000 -type f 2>/dev/null | sort > /etc/security/suid-baseline.txt
```

### Sticky Bit

The sticky bit prevents users from deleting each other's files in shared directories:

```bash
# /tmp should already have the sticky bit
ls -ld /tmp
# drwxrwxrwt  ...  (the 't' at the end is the sticky bit)

# Set sticky bit on a shared directory
sudo chmod +t /shared

# Find directories without sticky bit that need it
sudo find / -type d -perm -1002 -not -perm -1000 2>/dev/null
```

### Immutable Files (chattr)

```bash
# Make critical files immutable (requires chattr from e2fsprogs)
sudo chattr +i /etc/passwd      # Prevent changes to user database
sudo chattr +i /etc/shadow
sudo chattr +i /etc/group
sudo chattr +i /etc/gshadow
sudo chattr +i /etc/sudoers

# Make a directory immutable (prevents file creation/deletion)
sudo chattr +i /etc/ssh

# View immutable attributes
lsattr /etc/passwd /etc/shadow /etc/group
# ----i--------e-- /etc/passwd
# ----i--------e-- /etc/shadow

# Remove immutable attribute
sudo chattr -i /etc/passwd

# Append-only mode (logs can only be appended, not deleted)
sudo chattr +a /var/log/syslog
sudo chattr +a /var/log/auth.log

# Note: chattr requires CAP_LINUX_IMMUTABLE capability
# Even root cannot modify immutable files without first removing the flag
```

---



---

[← Previous](08-section-7-user-account-hardening.md) | [↑ Index](index.md) | [Next →](10-section-9-network-security.md)
