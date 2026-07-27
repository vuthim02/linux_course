## 🔍 Section 10: Understanding /etc/fstab

The `/etc/fstab` file controls which filesystems are mounted at boot.

```bash
cat /etc/fstab
```

```
# <file system>    <mount point>  <type>  <options>         <dump> <pass>
UUID=abc123-...    /              ext4    defaults,errors=remount-ro 0 1
UUID=def456-...    /boot          ext4    defaults          0 2
UUID=ghi789-...    /home          ext4    defaults          0 2
UUID=xxx-...       swap           swap    sw                0 0
/dev/sr0           /media/cdrom   auto    ro,user,noauto    0 0
```

| Field | Meaning |
|-------|---------|
| File system | Device or UUID to mount |
| Mount point | Where to attach it in the tree |
| Type | Filesystem type (ext4, xfs, swap...) |
| Options | Mount options (comma-separated) |
| Dump | Backup flag (0=don't dump, 1=dump) |
| Pass | fsck order (0=skip, 1=root, 2=other) |

### Critical fstab Options

```bash
# defaults         — rw, suid, dev, exec, auto, nouser, async
# noauto           — Don't mount at boot (manual mount only)
# user             — Allow any user to mount
# ro               — Read-only mount
# errors=remount-ro — Remount read-only on error (for root fs)
# noexec           — Cannot execute binaries from this partition
# nosuid           — Ignore SUID bits on this partition
# discard          — Enable TRIM for SSDs
```

### Using UUID Instead of Device Names

```bash
# Device names like /dev/sda1 can change between boots
# UUIDs are permanent (based on the filesystem)

# Find UUID of a partition
blkid /dev/sda1

# Or list all
sudo blkid

# UUID format: UUID="abc12345-6789-def0-1234-56789abcdef0"
```

---



---

[← Previous](10-section-7-the-boot-process.md) | [↑ Index](index.md) | [Next →](12-level-3-advanced-boot-recovery.md)
