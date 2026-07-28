## mysqldump / mariadb-dump

Logical backup tool — exports SQL statements that recreate databases.

### Basic Usage

```bash
# Single database
mysqldump -u root -p company > company_backup.sql

# Specific tables
mysqldump -u root -p company products orders > products_orders.sql

# Multiple databases
mysqldump -u root -p --databases db1 db2 db3 > multi_db.sql

# All databases
mysqldump -u root -p --all-databases > full_backup.sql
```

### Various Options

```bash
# Include routines (stored procedures) and events
mysqldump -u root -p \
    --all-databases \
    --routines \
    --events \
    --triggers \
    > full_with_routines.sql

# Consistent InnoDB backup (no table locking)
mysqldump -u root -p \
    --single-transaction \
    --all-databases \
    > consistent_backup.sql

# With compression
mysqldump -u root -p company | gzip > company.sql.gz

# Exclude data (schema only)
mysqldump -u root -p --no-data company > schema_only.sql
```

### Restore

```bash
# Restore a single database
mysql -u root -p company < company_backup.sql

# Restore all databases
mysql -u root -p < full_backup.sql

# Restore from compressed file
gunzip < company.sql.gz | mysql -u root -p

# Create database then restore (if not included in dump)
mysql -u root -p -e "CREATE DATABASE newcompany"
mysql -u root -p newcompany < company_backup.sql
```

### Real-World Backup Script

```bash
#!/bin/bash
# /usr/local/bin/mariadb_backup.sh

BACKUP_DIR="/var/backups/mariadb"
DB_USER="backupuser"
DB_PASS="$(cat /etc/mariadb_backup_pass)"
DATE=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS=7

mkdir -p "$BACKUP_DIR/$DATE"

mysqldump \
    --user="$DB_USER" \
    --password="$DB_PASS" \
    --all-databases \
    --single-transaction \
    --routines \
    --events \
    --triggers \
    | gzip > "$BACKUP_DIR/$DATE/full_backup.sql.gz"

# Check exit code
if [ $? -eq 0 ]; then
    echo "$(date): Backup succeeded" >> "$BACKUP_DIR/backup.log"
else
    echo "$(date): Backup FAILED" >> "$BACKUP_DIR/backup.log"
    exit 1
fi

# Cleanup old backups
find "$BACKUP_DIR" -type d -mtime +$RETENTION_DAYS -exec rm -rf {} \;

echo "Backup complete: $BACKUP_DIR/$DATE"
```




[← Previous](18-best-practices.md) | [↑ Index](index.md) | [Next →](20-binary-log-backup-point-in-time-recovery.md)
