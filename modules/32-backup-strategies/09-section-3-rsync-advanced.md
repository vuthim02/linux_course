## 🔍 Section 3: rsync — Advanced

### Incremental with --link-dest

The most important rsync pattern:

```bash
#!/bin/bash
BACKUP_DIR="/backups"
SOURCE="/home/user/data"
DATE=$(date +%Y-%m-%d)
LATEST=$(ls -1 "$BACKUP_DIR" | tail -1)

rsync -av --delete \
    --link-dest="$BACKUP_DIR/$LATEST" \
    "$SOURCE/" \
    "$BACKUP_DIR/$DATE/"
```

```
After 3 days:
/backups/
├── 2025-01-06/   # Monday — full copy
├── 2025-01-07/   # Tuesday — hard links to Monday's unchanged files
├── 2025-01-08/   # Wednesday — hard links to Tuesday's unchanged files

Unchanged files share inodes (zero extra space).
ls -i /backups/2025-01-06/file.txt /backups/2025-01-07/file.txt  # same inode
```

### Deletion Safety

```bash
rsync -av --delete --dry-run /source/ /backup/          # dry-run first!
rsync -av --delete /source/ /backup/
```

### Filter Rules

```bash
rsync -av --exclude='*.log' --exclude='.cache/' /data/ /backup/
rsync -av --include='*.pdf' --exclude='*' /data/documents/ /backup/
rsync -av --exclude-from=/etc/backup-excludes.txt /data/ /backup/
```

### rsync Daemon

```bash
# /etc/rsyncd.conf
[backups]
    path = /srv/backups
    read only = yes
    auth users = backup
    secrets file = /etc/rsyncd.secrets
    hosts allow = 192.168.1.0/24

# Start daemon
sudo systemctl enable --now rsync
```

---



---

[← Previous](08-section-2-tar-advanced.md) | [↑ Index](index.md) | [Next →](10-section-4-ddrescue-failing-drive.md)
