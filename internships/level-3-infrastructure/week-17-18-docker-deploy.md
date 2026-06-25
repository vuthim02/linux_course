# Internship — Level 3, Week 17-18
## Dockerized Web App Deployment

### Real-World Scenario

The development team has a Python web app (Flask API) that needs to be deployed to production. Currently it runs directly on a server. They want containerization for consistency, easier scaling, and simpler deployments. Your job: Dockerize the application and set up the full stack.

### Requirements

#### The Application

A simple Flask API with:
- `GET /health` — returns `{"status": "ok"}`
- `GET /users` — returns list of users from database
- `POST /users` — creates a user in database
- Database: PostgreSQL

#### Part A: Dockerfiles

**1. Application Dockerfile** (`app/Dockerfile`):
```dockerfile
FROM python:3.11-slim

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY app.py .

EXPOSE 5000
CMD ["gunicorn", "-w", "4", "-b", "0.0.0.0:5000", "app:app"]
```

- Use multi-stage build (separate builder stage with dev dependencies)
- Run as non-root user (`USER appuser`)
- Healthcheck: `HEALTHCHECK --interval=30s CMD curl -f http://localhost:5000/health`

**2. nginx Dockerfile** (`nginx/Dockerfile`):
- Based on nginx:alpine
- Custom nginx.conf that proxies `/api/` to the Flask app
- Serves static files from `/static/`
- Adds security headers (X-Frame-Options, X-Content-Type-Options, Strict-Transport-Security)

#### Part B: Docker Compose

Write `docker-compose.yml` with:

```yaml
version: '3.8'
services:
  app:
    build: ./app
    depends_on:
      db:
        condition: service_healthy
    environment:
      - DB_HOST=db
      - DB_NAME=${DB_NAME:-appdb}
      - DB_USER=${DB_USER:-appuser}
      - DB_PASSWORD=${DB_PASSWORD:-changeme}
    volumes:
      - app-static:/app/static
    networks:
      - backend
    deploy:
      replicas: 3
      restart_policy:
        condition: on-failure

  nginx:
    build: ./nginx
    ports:
      - "80:80"
      - "443:443"
    depends_on:
      - app
    volumes:
      - app-static:/static:ro
      - ./ssl:/etc/nginx/ssl:ro
    networks:
      - backend

  db:
    image: postgres:15-alpine
    volumes:
      - pgdata:/var/lib/postgresql/data
      - ./init.sql:/docker-entrypoint-initdb.d/init.sql
    environment:
      POSTGRES_DB: ${DB_NAME:-appdb}
      POSTGRES_USER: ${DB_USER:-appuser}
      POSTGRES_PASSWORD: ${DB_PASSWORD:-changeme}
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U appuser -d appdb"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - backend

  redis:
    image: redis:7-alpine
    volumes:
      - redis-data:/data
    networks:
      - backend

volumes:
  pgdata:
  redis-data:
  app-static:

networks:
  backend:
    driver: bridge
```

#### Part C: Deploy Script

Write `deploy.sh` that:

```bash
./deploy.sh [environment]

# What it does:
# 1. Pulls latest code from git
# 2. Builds images (docker compose build)
# 3. Runs database migrations
# 4. Runs health checks before switching traffic
# 5. Performs rolling update (docker compose up -d --no-deps --scale app=4)
# 6. Verifies new containers are healthy
# 7. Removes old containers
# 8. Rolls back if health check fails
```

#### Part D: Monitoring

Add a Prometheus exporter sidecar:
```yaml
  exporter:
    image: nginx/nginx-prometheus-exporter:latest
    command: ["-nginx.scrape-uri", "http://nginx:80/metrics"]
    networks:
      - backend
```

### Validation

```bash
# Build and start
docker compose build
docker compose up -d

# Test
curl http://localhost:80/health
curl http://localhost:80/api/users

# Check logs
docker compose logs app
docker compose logs db

# Scale
docker compose up -d --scale app=5

# Test failure
docker compose stop db
curl http://localhost:80/api/users  # Should return 503 gracefully

# Cleanup
docker compose down -v
```

### Deliverables

- `~/internship/docker-deploy/app/Dockerfile`
- `~/internship/docker-deploy/app/app.py`
- `~/internship/docker-deploy/app/requirements.txt`
- `~/internship/docker-deploy/nginx/Dockerfile`
- `~/internship/docker-deploy/nginx/nginx.conf`
- `~/internship/docker-deploy/docker-compose.yml`
- `~/internship/docker-deploy/.env.example`
- `~/internship/docker-deploy/deploy.sh`
- `~/internship/docker-deploy/README.md`

### Hints

- Use `gunicorn` for production WSGI (not Flask dev server)
- Use `docker compose config` to validate compose file
- Use `docker compose down --volumes` to clean up
- For migrations: `docker compose run --rm app flask db upgrade`
- For zero-downtime: use `docker compose up -d --no-deps --scale app=NEW --scale app=OLD`
- `curl --fail --max-time 5` for health checks
