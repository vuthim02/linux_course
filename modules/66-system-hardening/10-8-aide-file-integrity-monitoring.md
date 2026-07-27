## 8. AIDE — File Integrity Monitoring

### Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    AIDE WORKFLOW                              │
│                                                               │
│  STEP 1: INIT (Baseline)                                    │
│  ┌─────────────────────────────────────────────┐             │
│  │  aide --init                                │             │
│  │  Scans filesystem → generates baseline DB   │             │
│  │  Stored in: /var/lib/aide/aide.db.new       │             │
│  └─────────────────────────────────────────────┘             │
│                      │                                       │
│                      ▼                                       │
│  STEP 2: INSTALL (Activate baseline)                         │
│  ┌─────────────────────────────────────────────┐             │
│  │  cp /var/lib/aide/aide.db.new               │             │
│  │      /var/lib/aide/aide.db                  │             │
│  └─────────────────────────────────────────────┘             │
│                      │                                       │
│                      ▼                                       │
│  STEP 3: CHECK (Compare current vs baseline)                 │
│  ┌─────────────────────────────────────────────┐             │
│  │  aide --check                              │             │
│  │  Compares current state to aide.db          │             │
│  │  Reports: added, removed, changed files     │             │
│  └─────────────────────────────────────────────┘             │
│                      │                                       │
│                      ▼                                       │
│  STEP 4: UPDATE (Accept changes)                             │
│  ┌─────────────────────────────────────────────┐             │
│  │  aide --update                             │             │
│  │  Generates new DB with current state        │             │
│  │  cp aide.db.new aide.db                     │             │
│  └─────────────────────────────────────────────┘             │
│                      │                                       │
│                      ▼                                       │
│  Repeat STEP 3 → STEP 4 periodically                         │
└─────────────────────────────────────────────────────────────┘
```

### Installation and Configuration

```bash
# Install AIDE
apt install aide -y        # Debian/Ubuntu
yum install aide -y        # RHEL/CentOS

# Main config: /etc/aide.conf (Debian) or /etc/aide.conf (RHEL)
```

### AIDE Configuration Deep Dive

```bash
cat /etc/aide.conf | head -60

# Key settings in /etc/aide.conf:

# === Database locations ===
database_in=file:/var/lib/aide/aide.db
database_out=file:/var/lib/aide/aide.db.new

# === Gzip the database (recommended) ===
gzip_dbout=yes

# === Default rule sets ===
# p:  permissions    (file type + permissions)
# i:  inode          (inode number)
# n:  link count
# u:  user
# g:  group
# s:  size
# b:  block count
# m:  mtime
# a:  atime
# c:  ctime
# S:  check for growing size
# md5:    MD5 hash
# sha1:   SHA1 hash
# sha256: SHA256 hash (recommended)
# sha512: SHA512 hash

# === Rule definitions ===
NORMAL = p+i+n+u+g+s+m+c+sha256
PERMS  = p+u+g+acl+selinux+xattrs
LOG    = p+u+g+i+n+S
CONTENT = sha256+ftype
DATAONLY = p+n+u+g+s+acl+selinux+xattrs
DIR    = p+i+n+u+g

# === What to monitor ===
/etc            NORMAL
/bin            NORMAL
/sbin           NORMAL
/lib            NORMAL
/lib64          NORMAL
/usr/bin        NORMAL
/usr/sbin       NORMAL
/usr/lib        NORMAL
/boot           NORMAL
/usr/share      NORMAL

# === What to exclude ===
!/var/log
!/var/spool
!/var/cache
!/var/tmp
!/tmp
!/proc
!/sys
!/dev
!/run
!/var/lib/aide
!/var/lib/docker
!/var/lib/containerd
!/root/.ssh/known_hosts
!/var/lib/mlocate
!/var/lib/openssh/authorized_keys
```

### Running AIDE

```bash
# Step 1: Initialize baseline (takes 10-30 minutes on large systems)
sudo aide --init

# Output:
# AIDE, version 0.18.2
# AIDE found differences between database and filesystem!!
# ...
# Start timestamp: 2026-07-26 14:30:00
# Number of entries: 245678
# AIDE database initialization complete.

# Step 2: Activate the baseline
sudo cp /var/lib/aide/aide.db.new /var/lib/aide/aide.db

# Step 3: Check (daily)
sudo aide --check

# Output if changes detected:
# AIDE found differences between database and filesystem!!
# Summary:
#   Total number of entries:    245678
#   Added entries:              12
#   Removed entries:            3
#   Changed entries:            7
#
# Detailed changes:
#   /etc/passwd        : CHANGED  mtime, sha256
#   /etc/ssh/sshd_config: CHANGED  mtime, sha256, permissions
#   /tmp/malicious.sh   : ADDED
#   /usr/bin/suspicious  : ADDED

# If no changes:
# AIDE found no differences between database and filesystem.
# Everything looks clean.
```

### Automating AIDE with Daily Reports

```bash
# Daily check script
cat > /usr/local/bin/aide-check.sh << 'SCRIPT'
#!/bin/bash
REPORT="/var/log/aide/aide-check-$(date +%Y%m%d).log"
EMAIL="admin@example.com"

mkdir -p /var/log/aide

# Run check
aide --check > "$REPORT" 2>&1
exit_code=$?

if [ $exit_code -ne 0 ]; then
    # Changes detected
    mail -s "AIDE ALERT: File changes detected on $(hostname)" "$EMAIL" < "$REPORT"
    logger -t aide -p auth.alert "AIDE detected changes on $(hostname)"
else
    echo "$(date): AIDE check clean" >> /var/log/aide/aide-clean.log
fi
SCRIPT
chmod 700 /usr/local/bin/aide-check.sh

# Cron: run daily at 5 AM
echo "0 5 * * * root /usr/local/bin/aide-check.sh" > /etc/cron.d/aide-check
```

> ⚠️ **Warning:** After legitimate system updates (apt upgrade, yum update), you MUST run `aide --update` and copy the new database. Otherwise, every update will trigger false alerts.

### Protecting AIDE Database

```bash
# Store AIDE database on separate partition
# /etc/fstab:
# /dev/sdb1  /var/lib/aide  ext4  defaults,nosuid,nodev  0 2

# Set immutable attribute
chattr +i /var/lib/aide/aide.db
# (remove before aide --update, then re-set)

# Backup to off-system location
cp /var/lib/aide/aide.db /backup/aide/aide.db.$(date +%Y%m%d)
```

---



---

[← Previous](09-7-lynis-security-auditing-and.md) | [↑ Index](index.md) | [Next →](11-9-automated-compliance-openscap-and.md)
