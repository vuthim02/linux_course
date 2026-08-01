## 🔍 Section 18: Resource Limits, Group Switching, and Quotas

### ulimit — User Resource Limits

```bash
# View all limits for current user
ulimit -a

# Set limits for the current session
ulimit -n 4096                # Max open files
ulimit -u 100                 # Max user processes
ulimit -s 8192                # Stack size (KB)

# Permanent limits via /etc/security/limits.conf
# /etc/security/limits.conf format:
# <domain>  <type>  <item>  <value>

# Example:
# @developers  hard  nofile   65536
# bob          soft  nproc    200
# *            hard  maxlogins  3
```

### newgrp and sg — Temporary Group Switching

```bash
# Start a shell with a different primary group
newgrp developers
# Files created in this shell inherit 'developers' group

# Run a single command with a specific group
sg developers "touch project_file"
```

### User Quotas — Disk Space Limits

```bash
# Enable quotas on a filesystem (/etc/fstab)
# /dev/sda1  /home  ext4  defaults,usrquota,grpquota  0  2

# Initialize quota database
sudo quotacheck -cug /home
sudo quotaon -v /home

# Set quotas
sudo edquota -u bob          # Interactive editor
sudo setquota -u bob 100M 200M 0 0 /home
#               soft  hard  inode-soft inode-hard

# View quotas
quota -vs bob
repquota -as /home
```



[← Previous](26-section-17-password-aging-and-account-lockout.md) | [↑ Index](index.md) | [Next →](19-practice-section-20-hands-on-exercises.md)
