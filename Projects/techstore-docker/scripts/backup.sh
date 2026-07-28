#!/bin/bash
set -e

BACKUP_DIR="$HOME/techstore-backups"
DATE=$(date +%Y%m%d_%H%M%S)
KEEP_DAYS=7

mkdir -p "$BACKUP_DIR"

echo "╔══════════════════════════════════════╗"
echo "║   TechStore Backup — $DATE"
echo "╚══════════════════════════════════════╝"
echo ""

# 1. Backup PostgreSQL
echo "[1/3] Backing up PostgreSQL..."
docker exec techstore-db pg_dump -U ${POSTGRES_USER:-techstore_admin} ${POSTGRES_DB:-techstore} | gzip > "$BACKUP_DIR/postgres_$DATE.sql.gz"
echo "  ✓ Database backup: postgres_$DATE.sql.gz"

# 2. Backup Redis
echo "[2/3] Backing up Redis..."
docker exec techstore-redis redis-cli -a ${REDIS_PASSWORD:-changeme} BGSAVE > /dev/null 2>&1
sleep 2
docker cp techstore-redis:/data/dump.rdb "$BACKUP_DIR/redis_$DATE.rdb"
echo "  ✓ Redis backup: redis_$DATE.rdb"

# 3. Backup application
echo "[3/3] Backing up application files..."
tar -czf "$BACKUP_DIR/app_$DATE.tar.gz" \
    --exclude='node_modules' \
    --exclude='.git' \
    -C "$(dirname "$0")/.." . 2>/dev/null
echo "  ✓ App backup: app_$DATE.tar.gz"

# Clean old backups
echo ""
echo "Cleaning backups older than $KEEP_DAYS days..."
find "$BACKUP_DIR" -type f -mtime +$KEEP_DAYS -delete 2>/dev/null
REMAINING=$(ls "$BACKUP_DIR" | wc -l)
echo "  $REMAINING backup(s) retained"

echo ""
echo "╔══════════════════════════════════════╗"
echo "║   Backup Complete!                   ║"
echo "╠══════════════════════════════════════╣"
echo "║   Location: $BACKUP_DIR"
echo "║   Files:"
ls -lh "$BACKUP_DIR"/*_$DATE.* 2>/dev/null | awk '{print "║     " $NF " (" $5 ")"}'
echo "╚══════════════════════════════════════╝"
