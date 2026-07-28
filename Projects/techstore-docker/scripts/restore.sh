#!/bin/bash
set -e

BACKUP_DIR="$HOME/techstore-backups"

echo "╔══════════════════════════════════════╗"
echo "║   TechStore Restore                  ║"
echo "╚══════════════════════════════════════╝"
echo ""

# List available backups
echo "Available backups:"
echo ""
ls -1t "$BACKUP_DIR"/*.sql.gz 2>/dev/null | head -5 | while read f; do
    DATE=$(basename "$f" | sed 's/postgres_//; s/.sql.gz//')
    SIZE=$(du -h "$f" | cut -f1)
    echo "  $DATE ($SIZE)"
done

echo ""
echo "Usage: ./scripts/restore.sh <date>"
echo "Example: ./scripts/restore.sh 20240115_143022"
