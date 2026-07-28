## 15. Hands-On Practices

### Level 1 — Basic

#### Practice 1: Pull and Run Nginx

```bash
# Pull the image
docker pull nginx:alpine

# Run it
docker run -d --name myweb -p 8080:80 nginx:alpine

# Verify
curl localhost:8080
# Should return nginx default page

# Clean up
docker stop myweb && docker rm myweb
```

#### Practice 2: Build a Custom Dockerfile

Create `Dockerfile`:

```dockerfile
FROM alpine:3.19
RUN apk add --no-cache python3 py3-pip
COPY app.py /app/
WORKDIR /app
EXPOSE 5000
CMD ["python3", "app.py"]
```

Create `app.py`:

```python
from http.server import HTTPServer, BaseHTTPRequestHandler

class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.end_headers()
        self.wfile.write(b"Hello from container!\n")

HTTPServer(("0.0.0.0", 5000), Handler).serve_forever()
```

```bash
docker build -t myapp:latest .
docker run -d -p 5000:5000 myapp:latest
curl localhost:5000
```

#### Practice 3: Create and Use Volumes

```bash
# Create named volume
docker volume create web_data

# Run nginx with volume
docker run -d --name web \
  --mount type=volume,source=web_data,target=/usr/share/nginx/html \
  nginx:alpine

# Write data to volume
echo "<h1>Volume test</h1>" | docker exec -i web tee /usr/share/nginx/html/index.html
curl localhost:80

# Verify data persists after container removal
docker rm -f web
docker run -d --name web2 \
  --mount type=volume,source=web_data,target=/usr/share/nginx/html \
  nginx:alpine
curl localhost:80

# Clean up
docker rm -f web2
docker volume rm web_data
```

#### Practice 4: Set Up Bridge Networking

```bash
# Create custom network
docker network create --driver bridge demo-net

# Run two containers on same network
docker run -d --name alpine1 --network demo-net alpine sleep 3600
docker run -d --name alpine2 --network demo-net alpine sleep 3600

# Test DNS resolution
docker exec alpine1 ping alpine2
docker exec alpine2 ping alpine1

# Create isolated container
docker run -d --name isolated alpine sleep 3600

# Verify isolation
docker exec alpine1 ping isolated  # should fail

# Clean up
docker rm -f alpine1 alpine2 isolated
docker network rm demo-net
```

#### Practice 5: Write a Docker Compose for LAMP Stack

Create `docker-compose.yml`:

```yaml
version: "3.8"

services:
  db:
    image: mariadb:10.11
    volumes:
      - db_data:/var/lib/mysql
    environment:
      MYSQL_ROOT_PASSWORD: rootpass
      MYSQL_DATABASE: myapp
      MYSQL_USER: user
      MYSQL_PASSWORD: userpass
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      interval: 10s
      timeout: 5s
      retries: 5

  php:
    image: php:8.2-apache
    ports:
      - "8080:80"
    volumes:
      - ./www:/var/www/html
    environment:
      DB_HOST: db
      DB_USER: user
      DB_PASSWORD: userpass
      DB_NAME: myapp
    depends_on:
      db:
        condition: service_healthy

volumes:
  db_data:
```

Create `www/index.php`:

```php
<?php
$conn = new mysqli($_ENV['DB_HOST'], $_ENV['DB_USER'], $_ENV['DB_PASSWORD'], $_ENV['DB_NAME']);
if ($conn->connect_error) {
    http_response_code(500);
    echo "DB connection failed: " . $conn->connect_error;
} else {
    echo "<h1>LAMP Stack Running</h1>";
    echo "Connected to MariaDB successfully!";
    echo "<pre>Server: " . $_ENV['DB_HOST'] . "</pre>";
    $conn->close();
}
```

```bash
docker compose up -d
curl localhost:8080
docker compose down -v
```

### Level 2 — Intermediary

#### Practice 6: Run Rootless Podman

```bash
# As a non-root user
podman run -d --name rootless-web -p 8080:80 nginx:alpine
curl localhost:8080

# Check no root-owned files
ls -la ~/.local/share/containers/

# Verify process ownership
ps aux | grep nginx   # owned by your user, not root

# Build image rootless
cat > Dockerfile << 'EOF'
FROM alpine:3.19
CMD ["echo", "Running as:", "whoami"]
EOF
podman build -t test:latest .
podman run test:latest

# Clean up
podman rm -f rootless-web
podman rmi test:latest
```

#### Practice 7: Build Multi-Stage Image

Create `Dockerfile.multi`:

```dockerfile
FROM golang:1.22 AS builder
WORKDIR /build
COPY main.go .
RUN CGO_ENABLED=0 go build -o server .

FROM alpine:3.19
RUN apk add --no-cache ca-certificates
COPY --from=builder /build/server /server
EXPOSE 8080
CMD ["/server"]
```

Create `main.go`:

```go
package main

import (
    "fmt"
    "net/http"
)

func handler(w http.ResponseWriter, r *http.Request) {
    fmt.Fprintf(w, "Multi-stage build works!\n")
}

func main() {
    http.HandleFunc("/", handler)
    http.ListenAndServe(":8080", nil)
}
```

```bash
docker build -f Dockerfile.multi -t multi-stage:latest .
docker images | grep multi-stage
docker history multi-stage:latest
docker run -d -p 8080:8080 multi-stage:latest
curl localhost:8080
```

#### Practice 8: Push to Registry

```bash
# Run local registry
docker run -d -p 5000:5000 --name registry registry:2

# Tag and push
docker tag multi-stage:latest localhost:5000/multi-stage:latest
docker push localhost:5000/multi-stage:latest

# Verify
curl http://localhost:5000/v2/_catalog

# Pull from registry
docker rmi localhost:5000/multi-stage:latest
docker pull localhost:5000/multi-stage:latest

# Clean up
docker rm -f registry
```

#### Practice 9: Manage Container Logs

```bash
# Run container with limited log size
docker run -d --name logtest --log-opt max-size=1k --log-opt max-file=2 alpine sh -c "while true; do echo 'log entry at $(date)'; sleep 1; done"

# Watch logs
docker logs -f logtest &
sleep 5
kill %1

# Check log file location
ls -la /var/lib/docker/containers/$(docker inspect --format '{{.Id}}' logtest)/

# Switch to journald driver
docker run -d --name logtest2 --log-driver journald alpine sh -c "while true; do echo 'journal entry'; sleep 1; done"
journalctl CONTAINER_NAME=logtest2 --tail 10

# Clean up
docker rm -f logtest logtest2
```

#### Practice 10: Export/Import Images

```bash
# Save image to tar
docker save alpine:3.19 -o alpine.tar
ls -lh alpine.tar

# Load image from tar on another machine
docker load -i alpine.tar

# Export container to tar (single layer)
docker run -d --name export-test alpine touch /tmp/test.txt
docker export export-test -o exported.tar
docker rm -f export-test

# Import as new image
cat exported.tar | docker import - imported:latest
docker run imported:latest ls -la /tmp/

# Clean up
rm alpine.tar exported.tar
docker rmi imported:latest
```

#### Practice 11: Container Resource Limits

```bash
# Limit CPU and memory
docker run -d --name stress-test \
  --memory="128m" \
  --cpus="0.5" \
  alpine sh -c "while true; do true; done"

# Check limits
docker inspect stress-test --format '{{.HostConfig.Memory}}'
docker inspect stress-test --format '{{.HostConfig.NanoCpus}}'

# Monitor
docker stats stress-test

# Clean up
docker rm -f stress-test
```

#### Practice 12: Healthcheck Implementation

Create `Dockerfile.health`:

```dockerfile
FROM alpine:3.19
RUN apk add --no-cache curl
COPY app.py /app.py
HEALTHCHECK --interval=5s --timeout=3s --start-period=10s --retries=3 \
  CMD curl -f http://localhost:5000/ || exit 1
CMD python3 /app.py
```

(app.py from Practice 2)

```bash
docker build -f Dockerfile.health -t health-test:latest .
docker run -d -p 5000:5000 --name health-demo health-test:latest
docker inspect --format '{{.State.Health.Status}}' health-demo
watch -n 2 docker ps
docker rm -f health-demo
```

#### Practice 13: Docker Compose with Healthcheck

```yaml
version: "3.8"

services:
  app:
    build: .
    ports:
      - "5000:5000"
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:5000"]
      interval: 10s
      timeout: 5s
      retries: 3
      start_period: 5s

  monitor:
    image: alpine
    command: sh -c "while true; do sleep 5; done"
    depends_on:
      app:
        condition: service_healthy
```

```bash
docker compose up -d
docker compose ps
docker inspect compose_app_1 --format '{{.State.Health.Status}}'
docker compose down
```

#### Practice 14: Container Backup and Restore

```bash
# Create container with data
docker run -d --name prod-db \
  -e POSTGRES_PASSWORD=secret \
  -v pgdata:/var/lib/postgresql/data \
  postgres:16-alpine

# Backup volume
docker run --rm -v pgdata:/source -v $(pwd):/backup alpine \
  tar czf /backup/pgdata-backup.tar.gz -C /source .

# Restore volume
docker volume create pgdata_restored
docker run --rm -v pgdata_restored:/target -v $(pwd):/backup alpine \
  tar xzf /backup/pgdata-backup.tar.gz -C /target

# Clean up
docker rm -f prod-db
docker volume rm pgdata pgdata_restored
rm pgdata-backup.tar.gz
```

### Level 3 — Advanced

#### Practice 15: Real-World Integration — Multi-Service Compose Stack

Create `docker-compose.fullstack.yml`:

```yaml
version: "3.8"

volumes:
  postgres_data:
  redis_data:
  prometheus_data:
  grafana_data:

networks:
  frontend:
  backend:
  monitoring:

services:

  traefik:
    image: traefik:v3.0
    ports:
      - "80:80"
      - "443:443"
      - "8080:8080"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ./traefik.yml:/etc/traefik/traefik.yml:ro
    networks:
      - frontend
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.api.rule=Host(`traefik.localhost`)"
      - "traefik.http.routers.api.service=api@internal"

  api:
    build:
      context: ./api
      dockerfile: Dockerfile
    image: myapp/api:latest
    expose:
      - "3000"
    environment:
      - NODE_ENV=production
      - DATABASE_URL=postgres://user:password@db:5432/myapp
      - REDIS_URL=redis://redis:6379
    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_started
    networks:
      - frontend
      - backend
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.api.rule=Host(`api.localhost`)"
      - "traefik.http.services.api.loadbalancer.server.port=3000"

  web:
    image: nginx:alpine
    volumes:
      - ./web:/usr/share/nginx/html:ro
      - ./nginx.conf:/etc/nginx/conf.d/default.conf:ro
    networks:
      - frontend
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.web.rule=Host(`app.localhost`)"
      - "traefik.http.services.web.loadbalancer.server.port=80"

  db:
    image: postgres:16-alpine
    volumes:
      - postgres_data:/var/lib/postgresql/data
    environment:
      - POSTGRES_USER=user
      - POSTGRES_PASSWORD=password
      - POSTGRES_DB=myapp
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U user -d myapp"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - backend
    deploy:
      resources:
        limits:
          memory: 512M

  redis:
    image: redis:7-alpine
    volumes:
      - redis_data:/data
    networks:
      - backend
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 5s

  prometheus:
    image: prom/prometheus:latest
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml:ro
      - prometheus_data:/prometheus
    command:
      - "--config.file=/etc/prometheus/prometheus.yml"
      - "--storage.tsdb.path=/prometheus"
    networks:
      - monitoring
      - backend

  grafana:
    image: grafana/grafana:latest
    volumes:
      - grafana_data:/var/lib/grafana
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
    networks:
      - monitoring
      - frontend
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.grafana.rule=Host(`grafana.localhost`)"
      - "traefik.http.services.grafana.loadbalancer.server.port=3000"

  backup:
    image: alpine:3.19
    volumes:
      - postgres_data:/data:ro
      - ./backups:/backups
    command: |
      sh -c "
      apk add --no-cache postgresql-client
      while true; do
        pg_dump postgres://user:password@db:5432/myapp > /backups/dump_\$$(date +%Y%m%d_%H%M%S).sql 2>/dev/null || true
        find /backups -name 'dump_*.sql' -mtime +7 -delete
        sleep 86400
      done
      "
    depends_on:
      db:
        condition: service_healthy
    networks:
      - backend
```

```bash
# Start the full stack
docker compose -f docker-compose.fullstack.yml up -d

# Check all services
docker compose -f docker-compose.fullstack.yml ps
docker compose -f docker-compose.fullstack.yml logs -f api web

# Access services
curl -H "Host: api.localhost" http://localhost
curl -H "Host: app.localhost" http://localhost

# View metrics
curl http://localhost:8080/api/http/routers

# Clean up
docker compose -f docker-compose.fullstack.yml down -v
```





[← Previous](19-level-3-advanced-practices-internals.md) | [↑ Index](index.md) | [Next →](21-16-deep-understanding.md)
