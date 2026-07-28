## 🔍 Section 10: Automation

### Rotation Script (Full + Incremental)

```bash
#!/bin/bash
# rotation-backup.sh
BACKUP_DIR="/backups"
SOURCE="/home/user/data"
DATE=$(date +%Y-%m-%d)
DOW=$(date +%u)  # 1=Monday, 7=Sunday

mkdir -p "$BACKUP_DIR"

if [ "$DOW" -eq 7 ]; then
    # Sunday: full backup
    rsync -av --delete "$SOURCE/" "$BACKUP_DIR/full-$DATE/"
    rm -f "$BACKUP_DIR/latest"
    ln -s "full-$DATE" "$BACKUP_DIR/latest"
else
    # Monday-Saturday: incremental with --link-dest
    PREV=$(readlink "$BACKUP_DIR/latest" 2>/dev/null || ls -1 "$BACKUP_DIR" | tail -1)
    rsync -av --delete --link-dest="$BACKUP_DIR/$PREV" \
        "$SOURCE/" "$BACKUP_DIR/inc-$DATE/"
    rm -f "$BACKUP_DIR/latest"
    ln -s "inc-$DATE" "$BACKUP_DIR/latest"
fi

# Retention: remove daily backups older than 30 days
find "$BACKUP_DIR" -name "full-*" -o -name "inc-*" -type d -mtime +30 -exec rm -rf {} \;
```

### cron Schedule

```bash
# /etc/crontab
0 2 * * * root /usr/local/bin/rotation-backup.sh     # daily file backup
0 3 * * * root /usr/local/bin/db-backup.sh            # daily DB backup
0 6 1 * * root /usr/local/bin/verify-backups.sh        # monthly integrity
0 7 * * 0 root /usr/local/bin/test-restore.sh          # weekly restore test
```

### Integrity Verification

```bash
#!/bin/bash
# verify-backup.sh
# For tar
tar tf /backups/data.tar.gz > /dev/null && echo "Archive OK" || echo "CORRUPT"

# File count match
diff <(find /data/ -type f | wc -l) <(find /backups/latest/ -type f | wc -l)

# Checksum verification
find /data/ -type f -exec md5sum {} \; | sort > /tmp/source.md5
find /backups/latest/ -type f -exec md5sum {} \; | sort > /tmp/backup.md5
diff /tmp/source.md5 /tmp/backup.md5 && echo "All checksums match"
```





[← Previous](12-section-9-database-backup.md) | [↑ Index](index.md) | [Next →](14-level-3-advanced-deduplication-cloud.md)
