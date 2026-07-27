## 4. Filesystem Hardening

### Mount Options: noexec, nosuid, nodev

```bash
# Mount /tmp with noexec, nosuid, nodev, tmpfs
echo "tmpfs /tmp tmpfs defaults,noexec,nosuid,nodev,size=2G 0 0" >> /etc/fstab

# Mount /var/tmp similarly
echo "tmpfs /var/tmp tmpfs defaults,noexec,nosuid,nodev,size=1G 0 0" >> /etc/fstab

# Remount /home without SUID (if no local builds needed)
# First back up data, then:
# /dev/sda3  /home  ext4  defaults,nosuid,nodev  0  2

# Remount /dev/shm restricted
mount -o remount,noexec,nosuid,nodev /dev/shm
```

> ⚠️ **Warning:** `noexec` on `/tmp` breaks programs that compile and run from `/tmp` (e.g., some installer scripts). Test in staging first.

### Dedicated Partition Layout

```
┌──────────────────────────────────────────────────┐
│              SECURE PARTITION LAYOUT               │
├──────────────────────────────────────────────────┤
│                                                    │
│  /           ext4  defaults,errors=remount-ro      │
│  /boot      ext4  defaults                        │
│  /boot/efi  vfat  umask=0077                       │
│  /home      ext4  defaults,nosuid,nodev            │
│  /tmp       tmpfs noexec,nosuid,nodev,size=2G      │
│  /var/tmp   tmpfs noexec,nosuid,nodev,size=1G      │
│  /var       ext4  defaults,nosuid                  │
│  /var/log   ext4  defaults,nosuid,nodev            │
│  /var/log/audit  ext4  defaults,nosuid,nodev       │
│  /dev/shm   tmpfs noexec,nosuid,nodev              │
│  /srv       ext4  defaults,nosuid,nodev            │
│                                                    │
└──────────────────────────────────────────────────┘
```

### File Permission Hardening

```bash
# CIS: Ensure no world-writable files
find / -xdev -type f -perm -0002 -exec chmod o-w {} \;

# CIS: Ensure no unowned files
find / -xdev -nouser -o -nogroup 2>/dev/null

# CIS: Set proper permissions on key files
chmod 600 /etc/shadow
chmod 600 /etc/gshadow
chmod 644 /etc/passwd
chmod 644 /etc/group
chmod 700 /root
chmod 600 /boot/grub/grub.cfg
chmod 700 /etc/cron.{hourly,daily,weekly,monthly}
chmod 600 /etc/crontab
chmod 700 /etc/cron.d
chmod 700 /etc/cron.daily
chmod 600 /etc/ssh/sshd_config

# Lock critical files with immutable attribute
chattr +i /etc/passwd
chattr +i /etc/shadow
chattr +i /etc/group
chattr +i /etc/gshadow
```

### Secure GRUB

```bash
# Set GRUB password
grub-mkpasswd-pbkdf2
# Enter password, get hash

# Add to /etc/grub.d/40_custom
set superusers="admin"
password_pbkdf2 admin grub.pbkdf2.sha512.10000...

# Set permissions
chmod 600 /boot/grub/grub.cfg
chmod 700 /boot/grub
```

---



---

[← Previous](04-3-kernel-hardening-sysctl-and.md) | [↑ Index](index.md) | [Next →](06-5-auditd-deep-dive-kernel-level.md)
