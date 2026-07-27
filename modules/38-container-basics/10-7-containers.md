## 7. Containers

### Run

```bash
# Basic run
docker run nginx:latest

# Detached
docker run -d nginx:latest

# With name
docker run --name web -d nginx:latest

# Interactive + TTY
docker run -it ubuntu:22.04 bash

# Port mapping
docker run -d -p 8080:80 nginx:latest

# Volume mount
docker run -d -v /host/path:/container/path nginx:latest

# Environment variables
docker run -e DB_HOST=localhost -e DB_PORT=5432 myapp

# Restart policy
docker run --restart unless-stopped -d nginx

# Resource limits
docker run --memory="256m" --cpus="0.5" nginx

# Remove on stop
docker run --rm -it ubuntu bash

# Podman — same syntax
podman run -d --name web -p 8080:80 nginx:latest
```

### Start/Stop

```bash
docker start web
docker stop web          # sends SIGTERM, waits, then SIGKILL
docker stop -t 30 web    # custom timeout
docker restart web
docker kill web          # immediate SIGKILL
docker pause web         # freeze processes
docker unpause web
```

### Remove

```bash
docker rm web
docker rm -f web         # force remove running
docker container prune   # remove all stopped
docker rm $(docker ps -aq)  # remove all
```

### Exec

```bash
# Run command in running container
docker exec -it web bash
docker exec web ls /etc/nginx
docker exec web nginx -t
```

### Logs

```bash
docker logs web
docker logs -f web       # follow
docker logs --tail 50 web
docker logs --since 5m web
docker logs -t web       # timestamps
```

### Inspect

```bash
docker inspect web                  # everything as JSON
docker inspect --format '{{.NetworkSettings.IPAddress}}' web
docker inspect --format '{{.State.Status}}' web
docker inspect --format '{{range .Mounts}}{{.Source}}{{end}}' web
```

### Copy

```bash
docker cp web:/etc/nginx/nginx.conf ./nginx.conf
docker cp ./index.html web:/usr/share/nginx/html/
```

### Commit

```bash
# Create image from container (discouraged — use Dockerfile)
docker commit web mynginx:saved
```

### Port Mapping

```bash
# Publish all exposed ports to random host ports
docker run -d -P nginx

# Map specific ports
docker run -d -p 8080:80 nginx
docker run -d -p 192.168.1.10:8080:80 nginx   # bind to interface
docker run -d -p 8080:80/tcp -p 8080:80/udp nginx

# List port mappings
docker port web
```

---



---

[← Previous](09-6-dockerfile.md) | [↑ Index](index.md) | [Next →](11-level-2-intermediary-daily-administration.md)
