## 🔍 Section 7: Real Backup Patterns

### Pattern 1: Simple Directory Backup

```bash
#!/bin/bash
# backup.sh — Simple daily backup
BACKUP_DIR="/backup"
SOURCE="/home/alice/documents"
DATE=$(date +%Y%m%d)

tar -czf "$BACKUP_DIR/documents_$DATE.tar.gz" -C "$(dirname "$SOURCE")" "$(basename "$SOURCE")"
```

### Pattern 2: Backup With Timestamp and Log

```bash
#!/bin/bash
# backup_with_log.sh
BACKUP_DIR="/var/backups"
SOURCE="/etc"
DATE=$(date +%Y%m%d_%H%M%S)
LOG_FILE="/var/log/backup.log"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') $1" >> "$LOG_FILE"
}

log "Starting backup of $SOURCE"
if tar -czf "$BACKUP_DIR/etc_$DATE.tar.gz" -C / etc 2>> "$LOG_FILE"; then
    log "Backup completed: $(du -h "$BACKUP_DIR/etc_$DATE.tar.gz" | cut -f1)"
else
    log "BACKUP FAILED!"
    exit 1
fi
```

### Pattern 3: Incremental Backup Using find + tar

```bash
#!/bin/bash
# incremental_backup.sh
BACKUP_DIR="/backup/incremental"
SOURCE="/home/alice"
DATE=$(date +%Y%m%d)
CUTOFF=$(date -d "-1 day" +%Y-%m-%d)

# Find files changed in last 24 hours
CHANGED_FILES=$(find "$SOURCE" -type f -newermt "$CUTOFF" ! -path "*/.cache/*")

if [ -n "$CHANGED_FILES" ]; then
    echo "$CHANGED_FILES" | tar -czf "$BACKUP_DIR/incremental_$DATE.tar.gz" -T -
    echo "Incremental backup created: $BACKUP_DIR/incremental_$DATE.tar.gz"
else
    echo "No files changed since $CUTOFF"
fi
```

### Pattern 4: Full System Backup (Excluding Special Dirs)

```bash
#!/bin/bash
# full_system_backup.sh
BACKUP_DIR="/backup/full"
DATE=$(date +%Y%m%d)

tar -czpf "$BACKUP_DIR/full_system_$DATE.tar.gz" \
    --exclude="/proc" \
    --exclude="/sys" \
    --exclude="/dev" \
    --exclude="/run" \
    --exclude="/mnt" \
    --exclude="/media" \
    --exclude="/lost+found" \
    --exclude="/tmp" \
    --exclude="/backup" \
    --exclude="*.swp" \
    --exclude="*.cache" \
    / 2>> "$BACKUP_DIR/backup_$DATE.log"
```





[← Previous](07-section-6-other-archiving-tools.md) | [↑ Index](index.md) | [Next →](09-section-8-splitting-large-archives.md)
