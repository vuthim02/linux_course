#!/bin/bash

echo "╔══════════════════════════════════════╗"
echo "║   TechStore Monitor                  ║"
echo "║   $(date '+%Y-%m-%d %H:%M:%S')"
echo "╚══════════════════════════════════════╝"
echo ""

# Container status
echo "┌─────────────────────────────────────┐"
echo "│  CONTAINER STATUS                   │"
echo "└─────────────────────────────────────┘"
docker compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || \
docker ps --format "table {{.Names}}\t{{.Status}}" | grep techstore
echo ""

# Resource usage
echo "┌─────────────────────────────────────┐"
echo "│  RESOURCE USAGE                     │"
echo "└─────────────────────────────────────┘"
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}" | grep techstore
echo ""

# Disk usage
echo "┌─────────────────────────────────────┐"
echo "│  DISK USAGE                         │"
echo "└─────────────────────────────────────┘"
df -h / | tail -1 | awk '{printf "  Root: %s used of %s (%s)\n", $3, $2, $5}'
docker system df 2>/dev/null | grep -E "Images|Containers|Volumes" | awk '{printf "  Docker %s: %s\n", $1, $3}'
echo ""

# Health check
echo "┌─────────────────────────────────────┐"
echo "│  HEALTH CHECK                       │"
echo "└─────────────────────────────────────┘"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/health 2>/dev/null)
if [ "$HTTP_CODE" = "200" ]; then
    echo "  Application: ✓ Healthy (HTTP $HTTP_CODE)"
else
    echo "  Application: ✗ Unhealthy (HTTP $HTTP_CODE)"
fi

PG_STATUS=$(docker exec techstore-db pg_isready -U techstore_admin 2>/dev/null && echo "ok" || echo "fail")
if [ "$PG_STATUS" = "ok" ]; then
    echo "  PostgreSQL:  ✓ Ready"
else
    echo "  PostgreSQL:  ✗ Not ready"
fi

REDIS_STATUS=$(docker exec techstore-redis redis-cli -a ${REDIS_PASSWORD:-changeme} ping 2>/dev/null)
if [ "$REDIS_STATUS" = "PONG" ]; then
    echo "  Redis:       ✓ Ready"
else
    echo "  Redis:       ✗ Not ready"
fi

NGINX_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:80 2>/dev/null)
if [ "$NGINX_STATUS" = "200" ] || [ "$NGINX_STATUS" = "301" ]; then
    echo "  Nginx:       ✓ Running"
else
    echo "  Nginx:       ✗ Not responding"
fi
echo ""

# Recent logs
echo "┌─────────────────────────────────────┐"
echo "│  RECENT ERRORS (last 5 min)         │"
echo "└─────────────────────────────────────┘"
docker compose logs --since 5m --tail 5 2>/dev/null | grep -i error || echo "  No errors found"
echo ""

# Backup status
echo "┌─────────────────────────────────────┐"
echo "│  LAST BACKUP                        │"
echo "└─────────────────────────────────────┘"
LAST_BACKUP=$(ls -1t ~/techstore-backups/*.sql.gz 2>/dev/null | head -1)
if [ -n "$LAST_BACKUP" ]; then
    BACKUP_DATE=$(basename "$LAST_BACKUP" | sed 's/postgres_//; s/.sql.gz//')
    BACKUP_SIZE=$(du -h "$LAST_BACKUP" | cut -f1)
    echo "  $BACKUP_DATE ($BACKUP_SIZE)"
else
    echo "  No backups found"
fi
