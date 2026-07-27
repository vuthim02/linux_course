## 🔍 Section 4: ddrescue — Failing Drive Recovery

ddrescue reads good sectors first, then retries bad ones. The mapfile tracks progress.

```bash
# Install
sudo apt install ddrescue

# Basic recovery
sudo ddrescue -d /dev/sda /backups/recovery.dd /backups/mapfile.log

# Resume failed recovery, retry bad sectors 3 times
sudo ddrescue -d -r3 /dev/sda /backups/recovery.dd /backups/mapfile.log

# Reverse direction (read from end backward)
sudo ddrescue -d -r3 -R /dev/sda /backups/recovery.dd /backups/mapfile.log

# List bad sectors
ddrescuelog --list-bad /backups/mapfile.log
```

---



---

[← Previous](09-section-3-rsync-advanced.md) | [↑ Index](index.md) | [Next →](11-section-5-dumprestore.md)
