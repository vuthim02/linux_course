## 🔍 Section 5: dump/restore

Filesystem-level backup for ext2/3/4. Understands inodes and block groups.

### Basic Usage

```bash
# Full dump (level 0)
sudo dump -0uf /backups/sda1.dump /dev/sda1

# Restore
sudo restore -rf /backups/sda1.dump

# List
sudo restore -tf /backups/sda1.dump
```

### Dump Levels

Dump levels (0-9) are true incremental:

| Level | Captures |
|-------|----------|
| 0 | Everything |
| 1 | Changes since level 0 |
| 2 | Changes since level 1 |
| etc. | |

```bash
# Sunday: level 0 (full)
sudo dump -0uf /backups/sda1-l0.dump /dev/sda1

# Monday: level 1 (changes since Sunday)
sudo dump -1uf /backups/sda1-l1.dump /dev/sda1

# Tuesday: level 2 (changes since Monday)
sudo dump -2uf /backups/sda1-l2.dump /dev/sda1

# Thursday: level 1 again (resets: captures changes since level 0)
sudo dump -1uf /backups/sda1-l1-thu.dump /dev/sda1

# Restore requires all levels
sudo restore -rf /backups/sda1-l0.dump
sudo restore -rf /backups/sda1-l1.dump
sudo restore -rf /backups/sda1-l2.dump
```

### Interactive Restore (Individual Files)

```bash
sudo restore -if /backups/sda1-l0.dump
# In interactive shell:
#   ls            list files
#   cd            change directory
#   add file      mark for extraction
#   extract       extract marked files
#   quit          exit
```

### Limitations

- ext2/3/4 only
- XFS uses `xfsdump`/`xfsrestore`
- Btrfs uses `btrfs send`/`receive`

---



---

[← Previous](10-section-4-ddrescue-failing-drive.md) | [↑ Index](index.md) | [Next →](12-section-9-database-backup.md)
