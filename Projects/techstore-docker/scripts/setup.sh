#!/bin/bash
set -e

echo "╔══════════════════════════════════════╗"
echo "║   TechStore Docker Setup             ║"
echo "║   One command to rule them all       ║"
echo "╚══════════════════════════════════════╝"
echo ""

# Check Docker
if ! command -v docker &> /dev/null; then
    echo "Docker not found. Installing..."
    curl -fsSL https://get.docker.com | sudo sh
    sudo usermod -aG docker $USER
    echo "Docker installed. Please run: newgrp docker"
    echo "Then run this script again."
    exit 1
fi

echo "[1/4] Building containers..."
docker compose build --no-cache

echo "[2/4] Starting all services..."
docker compose up -d

echo "[3/4] Waiting for services to be ready..."
sleep 10

# Health check
echo "[4/4] Running health checks..."
echo ""

# Check each service
for service in techstore-app techstore-db techstore-redis techstore-nginx techstore-monitor; do
    if docker ps --format '{{.Names}}' | grep -q "$service"; then
        echo "  ✓ $service is running"
    else
        echo "  ✗ $service failed to start"
    fi
done

echo ""
echo "╔══════════════════════════════════════╗"
echo "║   Deployment Complete!               ║"
echo "╠══════════════════════════════════════╣"
echo "║                                      ║"
echo "║   App:      http://localhost:4000   ║"
echo "║   Monitor:  http://localhost:19999   ║"
echo "║   API:      http://localhost:3000/api/products"
echo "║   Health:   http://localhost:3000/health"
echo "║                                      ║"
echo "║   Stop:     docker compose down      ║"
echo "║   Logs:     docker compose logs -f   ║"
echo "║   Backup:   ./scripts/backup.sh      ║"
echo "║                                      ║"
echo "╚══════════════════════════════════════╝"
