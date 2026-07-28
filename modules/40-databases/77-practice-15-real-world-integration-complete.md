## Practice 15: Real-World Integration — Complete Backup and Monitoring Script

```bash
#!/bin/bash
# /usr/local/bin/db_ops.sh — Complete database backup and monitoring
# Run daily from cron: 0 3 * * * root /usr/local/bin/db_ops.sh

set -euo pipefail

BACKUP_ROOT="/var/backups/databases"
MARIADB_USER="root"
PG_USER="postgres"
DATE=$(date +%Y%m%d_%H%M%S)
RETENTION=7
ALERT_EMAIL="admin@example.com"

# Create backup directories
mkdir -p "$BACKUP_ROOT/mariadb/$DATE"
mkdir -p "$BACKUP_ROOT/postgresql/$DATE"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') — $1" | tee -a "$BACKUP_ROOT/backup.log"
}

alert() {
    local subject="$1"
    local message="$2"
    log "ALERT: $subject — $message"
    # mail -s "$subject" "$ALERT_EMAIL" <<< "$message"
}

# === MariaDB Backup ===
backup_mariadb() {
    log "Starting MariaDB backup..."

    if ! systemctl is-active --quiet mariadb; then
        alert "MariaDB Backup Failed" "MariaDB service is not running"
        return 1
    fi

    # Check connection count
    CONN=$(mysql -u root -e "SELECT COUNT(*) FROM information_schema.PROCESSLIST;" 2>/dev/null | tail -1)
    MAXCONN=$(mysql -u root -e "SHOW VARIABLES LIKE 'max_connections';" 2>/dev/null | awk '{print $2}')
    log "MariaDB connections: $CONN / $MAXCONN"

    if [ "$CONN" -gt $((MAXCONN * 80 / 100)) ]; then
        alert "MariaDB Connection Alert" "Connection count at ${CONN} (${MAXCONN} max)"
    fi

    # Perform dump
    if mysqldump -u root \
        --all-databases \
        --single-transaction \
        --routines \
        --events \
        --triggers \
        | gzip > "$BACKUP_ROOT/mariadb/$DATE/full.sql.gz"; then
        log "MariaDB backup completed: $(du -sh "$BACKUP_ROOT/mariadb/$DATE/full.sql.gz" | cut -f1)"
    else
        alert "MariaDB Backup Failed" "mysqldump exited with code $?"
        return 1
    fi

    # Cleanup old backups
    find "$BACKUP_ROOT/mariadb" -mindepth 1 -maxdepth 1 -type d -mtime +$RETENTION \
        -exec rm -rf {} \; -exec log "Removed old MariaDB backup: {}" \;
}

# === PostgreSQL Backup ===
backup_postgresql() {
    log "Starting PostgreSQL backup..."

    if ! systemctl is-active --quiet postgresql; then
        alert "PostgreSQL Backup Failed" "PostgreSQL service is not running"
        return 1
    fi

    # Check connections
    CONN=$(sudo -u postgres psql -t -c "SELECT count(*) FROM pg_stat_activity;" | tr -d ' ')
    MAXCONN=$(sudo -u postgres psql -t -c "SHOW max_connections;" | tr -d ' ')
    log "PostgreSQL connections: $CONN / $MAXCONN"

    if [ "$CONN" -gt $((MAXCONN * 80 / 100)) ]; then
        alert "PostgreSQL Connection Alert" "Connection count at ${CONN} (${MAXCONN} max)"
    fi

    # Dump globals (roles + tablespaces)
    sudo -u postgres pg_dumpall --globals-only \
        | gzip > "$BACKUP_ROOT/postgresql/$DATE/globals.sql.gz"

    # Dump all databases (custom format, parallel)
    sudo -u postgres pg_dumpall \
        | gzip > "$BACKUP_ROOT/postgresql/$DATE/all_databases.sql.gz"

    if [ $? -eq 0 ]; then
        log "PostgreSQL backup completed: $(du -sh "$BACKUP_ROOT/postgresql/$DATE/" | cut -f1)"
    else
        alert "PostgreSQL Backup Failed" "pg_dumpall exited with code $?"
        return 1
    fi

    # Cleanup old backups
    find "$BACKUP_ROOT/postgresql" -mindepth 1 -maxdepth 1 -type d -mtime +$RETENTION \
        -exec rm -rf {} \; -exec log "Removed old PostgreSQL backup: {}" \;
}

# === Monitoring ===
monitor_databases() {
    log "Running database monitoring checks..."

    # MariaDB — check for long-running queries
    LONG_QUERIES=$(mysql -u root -e "
        SELECT id, TIME_TO_SEC(TIME) AS seconds, INFO
        FROM information_schema.PROCESSLIST
        WHERE TIME > 300 AND COMMAND != 'Sleep'
        ORDER BY TIME DESC;
    " 2>/dev/null)

    if [ -n "$LONG_QUERIES" ] && [ "$(echo "$LONG_QUERIES" | wc -l)" -gt 1 ]; then
        alert "MariaDB Long Queries" "Queries running >5 minutes:\n$LONG_QUERIES"
    fi

    # PostgreSQL — check for long-running queries
    PG_LONG=$(sudo -u postgres psql -t -c "
        SELECT pid, now() - query_start AS duration, left(query, 80)
        FROM pg_stat_activity
        WHERE state = 'active'
          AND now() - query_start > interval '5 minutes'
        ORDER BY duration DESC;
    " 2>/dev/null)

    if [ -n "$PG_LONG" ]; then
        alert "PostgreSQL Long Queries" "Queries running >5 minutes:\n$PG_LONG"
    fi

    # Check disk space for backup directory
    DISK_USAGE=$(df -h "$BACKUP_ROOT" | tail -1 | awk '{print $5}' | sed 's/%//')
    if [ "$DISK_USAGE" -gt 85 ]; then
        alert "Backup Disk Space" "Backup directory is ${DISK_USAGE}% full"
    fi

    log "Monitoring checks completed"
}

# === Main ===
log "========== Database Backup & Monitoring Run =========="

backup_mariadb
backup_postgresql
monitor_databases

log "========== Run Completed =========="
echo ""
echo "Backups stored in: $BACKUP_ROOT"
echo "  MariaDB: $BACKUP_ROOT/mariadb/$DATE/"
echo "  PostgreSQL: $BACKUP_ROOT/postgresql/$DATE/"
echo "Log: $BACKUP_ROOT/backup.log"
```

```bash
# Make it executable and set up cron
sudo chmod +x /usr/local/bin/db_ops.sh

# Add to cron (runs daily at 3 AM)
echo "0 3 * * * root /usr/local/bin/db_ops.sh" | sudo tee /etc/cron.d/db_backup
```

**Test the script**:
```bash
sudo /usr/local/bin/db_ops.sh
sudo cat /var/backups/databases/backup.log
```


# 🔬 Deep Understanding




[← Previous](76-practice-14-point-in-time-recovery.md) | [↑ Index](index.md) | [Next →](78-how-storage-engines-work-innodb.md)
