## 11. Docker Compose

### docker-compose.yml Format

```yaml
version: "3.8"

services:
  web:
    image: nginx:alpine
    ports:
      - "80:80"
    volumes:
      - ./html:/usr/share/nginx/html:ro
    depends_on:
      - api
    networks:
      - frontend
    environment:
      - NGINX_HOST=example.com
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost"]
      interval: 30s
      timeout: 10s
      retries: 3

  api:
    build: ./api
    image: myapp/api:latest
    ports:
      - "3000:3000"
    volumes:
      - api_data:/app/data
    environment:
      - DB_HOST=db
      - DB_NAME=myapp
    depends_on:
      db:
        condition: service_healthy
    networks:
      - frontend
      - backend

  db:
    image: postgres:16-alpine
    volumes:
      - pg_data:/var/lib/postgresql/data
    environment:
      - POSTGRES_PASSWORD_FILE=/run/secrets/db_password
      - POSTGRES_DB=myapp
    secrets:
      - db_password
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
    networks:
      - backend

volumes:
  pg_data:
    driver: local
  api_data:

networks:
  frontend:
  backend:

secrets:
  db_password:
    file: ./secrets/db_password.txt
```

### Docker Compose Commands

```bash
# Start services
docker compose up -d

# View logs
docker compose logs -f

# List services
docker compose ps

# Execute command in service
docker compose exec web nginx -t

# Stop services
docker compose stop

# Down (stop + remove containers, networks)
docker compose down

# Down + remove volumes
docker compose down -v

# Rebuild images
docker compose build
docker compose up -d --build

# Scale (v1 only)
docker-compose up -d --scale web=3

# Watch changes (compose watch, Docker 25+)
docker compose watch
```

### depends_on

- **Without condition**: starts in order but doesn't wait for readiness
- **condition: service_healthy**: waits for healthcheck to pass
- **condition: service_started**: waits until container starts

### Environment File

```bash
# .env file
DB_HOST=localhost
DB_PORT=5432
POSTGRES_PASSWORD=secret123
```

```yaml
services:
  db:
    env_file:
      - .env
```

### Docker Compose Profiles

```yaml
services:
  app:
    image: myapp

  monitoring:
    image: prom/prometheus
    profiles:
      - monitoring     # only starts with --profile monitoring
```

```bash
docker compose --profile monitoring up -d
```





[← Previous](14-10-registry.md) | [↑ Index](index.md) | [Next →](16-12-rootless-containers.md)
