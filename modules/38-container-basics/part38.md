# 🐧 Linux System Administrator — Complete Course
## Part 38 of ∞: Container Basics — Docker and Podman

> **Reverse Engineering Approach:** You already know what containers *feel like* from using them. Now we tear open the abstraction — from `docker run` down to `clone()` syscalls, union mounts, and OCI runtime specs. We ask: what *actually* happens when you run a container?

---

## Table of Contents

1. What are Containers?
2. Docker vs Podman
3. Installing Docker
4. Installing Podman
5. Images
6. Dockerfile
7. Containers
8. Volumes and Bind Mounts
9. Networking
10. Registry
11. Docker Compose
12. Rootless Containers
13. Security
14. Logging and Monitoring
15. Hands-On Practices
16. Deep Understanding
17. Command Reference
18. What's Coming in Part 39
19. Self-Test

---

## 🎯 What You Will Achieve

This module is structured across three progressive levels:

| Level | Focus | What You'll Learn |
|-------|-------|-------------------|
| ⭐ Level 1: Basic — Foundations | Container Concepts & Basics | What are containers, Docker vs Podman, installation, images, Dockerfiles, running containers |
| ⭐ Level 2: Intermediary — Daily Administration | Volumes, Networking, Compose & Security | Volumes and bind mounts, networking, registry, Docker Compose, rootless containers, security, logging |
| ⭐ Level 3: Advanced — Practices & Internals | Practices & Internals | Hands-On Practices, deep understanding (overlay FS, cgroups, namespaces), command reference, self-test |

---

## ⭐ Level 1: Basic — Foundations

![Docker and Podman containers](https://upload.wikimedia.org/wikipedia/commons/7/79/Docker_%28container_engine%29_logo.png)

> *"A container is a standard unit of software that packages up code and all its dependencies."*

---

## 1. What are Containers?

### Containers vs Virtual Machines

A **VM** runs a full guest OS — kernel, drivers, init system — atop a hypervisor. Each VM consumes gigabytes of RAM and boots in minutes.

A **container** is a set of Linux processes isolated from the host using **namespaces** and constrained using **cgroups**. Containers *share the host kernel*. There is no guest OS.

```
┌─────────────────────────────────────────────┐
│                 Host Kernel                   │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  │
│  │  cgroup  │  │namespace │  │overlayfs │  │
│  └──────────┘  └──────────┘  └──────────┘  │
├─────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐           │
│  │  Container  │  │  Container  │   ...      │
│  │  (process)  │  │  (process)  │           │
│  └─────────────┘  └─────────────┘           │
└─────────────────────────────────────────────┘
```

### Linux Namespaces

Every `docker run` calls `clone()` with these flags to create isolated views:

| Namespace | `clone()` Flag | Isolates |
|-----------|---------------|----------|
| **PID** | `CLONE_NEWPID` | Process IDs — PID 1 inside != PID 1 on host |
| **Network** | `CLONE_NEWNET` | Network interfaces, routing, iptables |
| **Mount** | `CLONE_NEWNS` | Mount points — filesystem tree |
| **UTS** | `CLONE_NEWUTS` | Hostname and domain name |
| **IPC** | `CLONE_NEWIPC` | System V IPC, POSIX message queues |
| **User** | `CLONE_NEWUSER` | UID/GID mapping (rootless) |
| **Cgroup** | `CLONE_NEWCGROUP` | Cgroup root view |
| **Time** | `CLONE_NEWTIME` | Clock offsets (Linux 5.6+) |

```bash
# See what namespaces a container is using
docker inspect --format '{{.State.Pid}}' my_container
ls -la /proc/<PID>/ns/
```

Each namespace is a symlink with an inode number. Two processes in the same namespace share the same inode:

```bash
# Two containers share no namespaces by default
# --pid=container:x shares PID namespace
# --net=container:x shares network namespace
```

### Cgroups (Control Groups)

Cgroups limit *how much* a container can use — CPU, memory, disk I/O, network.

```bash
# Find cgroup for a container
docker inspect --format '{{.Id}}' my_container
cat /sys/fs/cgroup/memory/docker/<container-id>/memory.max
```

Cgroups v2 (default on modern distros) unified hierarchy under `/sys/fs/cgroup/`:

```bash
# Container cgroup on cgroupv2
ls /sys/fs/cgroup/system.slice/docker-<container-id>.scope/
```

### Union Filesystems (Overlay2)

Overlay2 layers filesystems on top of each other. Each `RUN` command in a Dockerfile creates a new layer.

```
┌─────────────────────────────────┐
│       Container (rw layer)      │  ← upperdir (writable)
├─────────────────────────────────┤
│        Image layer (ro)         │  ← lowerdir (read-only)
├─────────────────────────────────┤
│        Image layer (ro)         │
├─────────────────────────────────┤
│        Image layer (ro)         │
└─────────────────────────────────┘
```

```bash
# Inspect the overlay mount
docker inspect my_container --format '{{.GraphDriver.Data.MergedDir}}'
cat /proc/mounts | grep overlay
```

### OCI Standard

The **Open Container Initiative** defines three specs:

1. **Image Spec** — format of container images (layers, config, manifest)
2. **Runtime Spec** — how to run a container (config.json, rootfs, mounts)
3. **Distribution Spec** — pushing/pulling images to registries

Runtimes implementing OCI:
- **runc** — reference implementation (used by Docker)
- **crun** — reimplementation in C (used by Podman); faster, less memory

```bash
# runc directly (rare, but instructive)
runc run mycontainer
# needs a bundle directory with config.json and rootfs
```

---

![Docker architecture — client, daemon, registries, and container runtime](https://upload.wikimedia.org/wikipedia/commons/2/21/ArquiteturaDocker.png)

*Docker client-server architecture (DaniloBarros / Wikimedia Commons / CC-BY-SA-4.0)*

## 2. Docker vs Podman

| Feature | Docker | Podman |
|---------|--------|--------|
| **Daemon** | `dockerd` — always-running daemon | No daemon; forks directly |
| **Rootless** | Requires `dockerd-rootless-setuptool.sh` | Rootless by default |
| **Compatibility** | Native Docker CLI | Aliased: `alias docker=podman` |
| **Registry** | Docker Hub default | Docker Hub default + configurable |
| **Compose** | `docker compose` (v2) or `docker-compose` (v1) | `podman-compose` (separate) |
| **Pod concept** | No native pods | Yes — `podman pod` |
| **systemd integration** | Manual | `podman generate systemd` |
| **Architecture** | Client-server | Fork/exec model |

### Daemonless Architecture

Docker:
```
┌──────────┐     ┌──────────┐     ┌──────────┐
│  docker  │────▶│ dockerd  │────▶│ containerd│
│  client  │     │ (daemon) │     │ (daemon)  │
└──────────┘     └──────────┘     └─────┬────┘
                                        │
                                   ┌────▼────┐
                                   │  runc   │
                                   │ (OCI)   │
                                   └─────────┘
```

Podman:
```
┌──────────┐     ┌──────────┐     ┌──────────┐
│  podman  │────▶│ conmon   │────▶│ crun/runc│
│  client  │     │ (monitor)│     │ (OCI)    │
└──────────┘     └──────────┘     └──────────┘
```

Podman forks directly — no daemon, no startup delay, no central point of failure.

```bash
# Podman compatibility alias
alias docker=podman
# Most commands work identically
docker ps
docker run nginx
```

### Docker Compose vs Podman Compose

```bash
# Docker Compose
docker compose up -d

# Podman Compose (separate package)
pip install podman-compose
podman-compose up -d
```

---

## 3. Installing Docker

### Docker Engine (Ubuntu/Debian)

```bash
# Remove old versions
sudo apt remove docker docker-engine docker.io containerd runc

# Install prerequisites
sudo apt update
sudo apt install ca-certificates curl gnupg

# Add Docker's GPG key
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Add repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
  | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine
sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Start and enable
sudo systemctl enable --now docker

# Add user to docker group
sudo usermod -aG docker $USER
newgrp docker
```

### Docker Desktop

Docker Desktop runs a VM (Hyper-V/WSL2 on Windows, HyperKit on macOS, KVM on Linux). For Linux administration, **Docker Engine** is preferred — lighter, no GUI dependency.

### Configure dockerd

```json
// /etc/docker/daemon.json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2",
  "exec-opts": ["native.cgroupdriver=systemd"],
  "registry-mirrors": ["https://mirror.gcr.io"],
  "insecure-registries": ["192.168.1.100:5000"],
  "default-address-pools": [
    {"base": "172.20.0.0/16", "size": 24}
  ]
}
```

```bash
# Apply config
sudo systemctl restart docker

# Check current config
docker info
```

---

## 4. Installing Podman

```bash
# Ubuntu / Debian
sudo apt update
sudo apt install podman podman-compose

# Verify
podman --version
podman info
```

### Configuration Files

Podman uses plain text config files under `~/.config/containers/`:

```toml
# ~/.config/containers/registries.conf
unqualified-search-registries = ["docker.io", "quay.io"]

[[registry]]
location = "docker.io"
[[registry.mirror]]
location = "mirror.gcr.io"

[[registry]]
location = "192.168.1.100:5000"
insecure = true
```

```toml
# ~/.config/containers/storage.conf
[storage]
driver = "overlay"
runroot = "/run/user/1000/containers"
graphroot = "/home/user/.local/share/containers/storage"

[storage.options]
size = ""
```

```toml
# ~/.config/containers/containers.conf
[containers]
env = ["LANG=en_US.UTF-8"]

[engine]
runtime = "crun"
events_logger = "file"
```

### System-wide configs

```
/etc/containers/registries.conf
/etc/containers/storage.conf
/etc/containers/containers.conf
~/.config/containers/registries.conf.d/*.conf
```

---

## 5. Images

Images are read-only templates. You pull them from registries, list them locally, and build your own.

### Pull an Image

```bash
docker pull nginx:latest
docker pull alpine:3.19
docker pull ubuntu:22.04

# Podman identical
podman pull nginx:latest
```

### Search Images

```bash
docker search nginx
docker search --limit 10 --filter stars=100 alpine

# Podman
podman search nginx
```

### List Local Images

```bash
docker images
docker image ls
docker image ls --format "{{.Repository}}:{{.Tag}}"

# Podman
podman images
```

### Remove Images

```bash
docker rmi nginx:latest
docker image prune          # remove dangling images
docker image prune -a       # remove all unused

# Podman
podman rmi nginx:latest
```

### Tag an Image

```bash
docker tag nginx:latest myregistry.local/nginx:production
docker tag ubuntu:22.04 ubuntu:jammy
```

### Build an Image

```bash
docker build -t myapp:latest .
docker build -t myapp:v1.0 -f Dockerfile.prod .

# Podman
podman build -t myapp:latest .
```

### Image Layers and History

```bash
# See how an image was built
docker history nginx:latest
docker history --no-trunc nginx:latest

# Inspect image metadata
docker inspect alpine:latest

# Save/load image tar
docker save nginx:latest -o nginx.tar
docker load -i nginx.tar

# Export/import (strips history — single layer)
docker export my_container -o container.tar
docker import container.tar myapp:imported
```

---

## 6. Dockerfile

### Key Instructions

```dockerfile
# FROM — base image
FROM alpine:3.19

# LABEL — metadata
LABEL maintainer="admin@example.com"
LABEL version="1.0"

# RUN — execute commands in a new layer
RUN apk update && apk add --no-cache python3 py3-pip

# COPY — copy files from build context
COPY app.py /app/

# ADD — copy with URL/tar auto-extraction
ADD https://example.com/file.tar.gz /tmp/
ADD archive.tar.gz /tmp/

# ENV — environment variables
ENV PYTHONUNBUFFERED=1
ENV APP_HOME=/app

# WORKDIR — set working directory
WORKDIR /app

# EXPOSE — document port (does NOT publish)
EXPOSE 8080

# USER — run as non-root
RUN adduser -D appuser
USER appuser

# CMD — default command (can be overridden)
CMD ["python3", "app.py"]

# ENTRYPOINT — fixed command (args are appended)
ENTRYPOINT ["python3"]

# HEALTHCHECK — check container health
HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
  CMD curl -f http://localhost:8080/ || exit 1

# VOLUME — declare mount point
VOLUME /data

# STOPSIGNAL
STOPSIGNAL SIGTERM
```

### CMD vs ENTRYPOINT

| Form | Override with CLI |
|------|------------------|
| `CMD ["cmd", "arg"]` | `docker run image new_cmd` |
| `ENTRYPOINT ["cmd"]` | `docker run --entrypoint new_cmd image` |
| `ENTRYPOINT ["cmd"]` + `CMD ["arg"]` | `docker run image arg` (appends to ENTRYPOINT) |

```dockerfile
# Exec form (preferred — JSON array)
CMD ["nginx", "-g", "daemon off;"]

# Shell form (wraps in /bin/sh -c)
CMD nginx -g "daemon off;"
```

### Multi-Stage Builds

```dockerfile
# Stage 1: Build
FROM golang:1.22 AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build -o server .

# Stage 2: Runtime
FROM alpine:3.19
RUN apk add --no-cache ca-certificates
COPY --from=builder /app/server /usr/local/bin/server
EXPOSE 8080
USER nobody
CMD ["server"]
```

Benefits:
- Final image is tiny (no build tools)
- Build cache for dependencies
- Multiple stages can use different base images

### .dockerignore

```
node_modules/
.git/
*.log
.DS_Store
dist/
```

---

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

## ⭐ Level 2: Intermediary — Daily Administration

![Container volumes and networking](https://upload.wikimedia.org/wikipedia/commons/4/4e/Docker_compose_logo.png)

> *"Containers are ephemeral; data must persist. Mastering volumes and networking turns containers into production services."*

---

## 8. Volumes and Bind Mounts

### Volume Types

| Type | Use Case | Managed by Docker? | Persist on host? |
|------|----------|-------------------|-----------------|
| **Bind mount** | Dev, config files | No | Yes |
| **Named volume** | Production data | Yes | Yes |
| **Anonymous volume** | Temp data | Yes | Yes |
| **tmpfs mount** | Secrets, temp | No | No (in memory) |

### Bind Mounts

```bash
# -v (old syntax)
docker run -v /host/path:/container/path nginx
docker run -v /host/path:/container/path:ro nginx  # read-only

# --mount (new syntax, preferred)
docker run \
  --mount type=bind,source=/host/path,target=/container/path \
  nginx

docker run \
  --mount type=bind,source=/host/path,target=/container/path,readonly \
  nginx
```

### Named Volumes

```bash
# Create volume
docker volume create nginx_data

# List volumes
docker volume ls

# Inspect
docker volume inspect nginx_data

# Mount named volume
docker run -d \
  --name web \
  --mount type=volume,source=nginx_data,target=/usr/share/nginx/html \
  nginx

# Or with -v
docker run -d -v nginx_data:/usr/share/nginx/html nginx

# Anonymous volume (no name — random hash)
docker run -d -v /data nginx

# Remove volumes
docker volume rm nginx_data
docker volume prune
```

### tmpfs Mounts

```bash
docker run -d \
  --mount type=tmpfs,target=/tmp,tmpfs-size=100m \
  nginx
```

### Volume Drivers

```bash
# Use NFS volume driver
docker volume create \
  --driver local \
  --opt type=nfs \
  --opt o=addr=192.168.1.50,rw \
  --opt device=:/exported/path \
  nfs_volume
```

---

## 9. Networking

### Network Drivers

| Driver | Use Case | Scope |
|--------|----------|-------|
| **bridge** | Default — isolated network on host | Single host |
| **host** | No isolation — use host networking | Single host |
| **none** | No networking | Single host |
| **overlay** | Multi-host (Swarm) | Multi-host |
| **macvlan** | Assign MAC to container | Single host |
| **ipvlan** | Multiple IPs on same MAC | Single host |

### Bridge Network (Default)

```bash
# Default bridge — containers linked by IP
docker run -d --name web1 nginx
docker run -d --name web2 nginx

# Get IP on default bridge
docker inspect web1 --format '{{.NetworkSettings.IPAddress}}'
# 172.17.0.2

# Communication between containers on default bridge (by IP only)
docker exec web2 ping 172.17.0.2
```

### User-Defined Bridge Network

```bash
# Create network
docker network create --driver bridge mynet

# Run containers on the same network
docker run -d --name web --network mynet nginx
docker run -d --name app --network mynet nginx

# DNS resolution by container name!
docker exec app ping web

# Add container to multiple networks
docker network connect mynet2 web
docker network disconnect mynet web

# List networks
docker network ls
docker network inspect mynet
```

### Host Network

```bash
# No isolation — container uses host's IP
docker run -d --network host nginx
# Now accessible on host's IP on port 80

# Useful for high-performance networking
# No port mapping needed
```

### None Network

```bash
# No network at all
docker run -d --network none nginx
# Only loopback interface
```

### Overlay Network (Docker Swarm)

```bash
# Requires Swarm mode
docker swarm init
docker network create --driver overlay --attachable myoverlay

# Create service on overlay network
docker service create --name web --network myoverlay --replicas 3 nginx
```

### Port Publishing

```bash
# Publish to random host port
docker run -d -P nginx

# Publish specific port
docker run -d -p 8080:80 nginx

# Publish to specific interface
docker run -d -p 127.0.0.1:8080:80 nginx

# UDP port
docker run -d -p 53:53/udp dns

# Range
docker run -d -p 8000-8010:80 nginx
```

### DNS Configuration

```bash
# Custom DNS servers
docker run --dns 8.8.8.8 --dns 1.1.1.1 nginx

# Custom hosts entries
docker run --add-host db.local:10.0.0.5 nginx

# DNS search domain
docker run --dns-search example.com nginx
```

---

## 10. Registry

### Docker Hub

```bash
# Login
docker login
docker login -u username -p password

# Pull public image
docker pull nginx:latest

# Push to Docker Hub
docker tag myapp:latest username/myapp:latest
docker push username/myapp:latest

# Logout
docker logout
```

### Private Registry

```bash
# Run local registry
docker run -d -p 5000:5000 --name registry registry:2

# Push to local
docker tag myapp:latest localhost:5000/myapp:latest
docker push localhost:5000/myapp:latest

# Pull from local
docker pull localhost:5000/myapp:latest

# With TLS (self-signed)
docker run -d -p 5000:5000 \
  -v /certs:/certs \
  -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/domain.crt \
  -e REGISTRY_HTTP_TLS_KEY=/certs/domain.key \
  --name registry registry:2
```

### Insecure Registry

```json
// /etc/docker/daemon.json
{
  "insecure-registries": ["192.168.1.100:5000"]
}
```

```bash
sudo systemctl restart docker
```

### Harbor (Enterprise Registry)

```bash
# Harbor includes vulnerability scanning, replication, RBAC
# Download from https://github.com/goharbor/harbor
wget https://github.com/goharbor/harbor/releases/download/v2.10.0/harbor-offline-installer-v2.10.0.tgz
tar xzf harbor-offline-installer-*.tgz
cd harbor
cp harbor.yml.tmpl harbor.yml
# Edit harbor.yml (hostname, password)
./install.sh
```

### Quay.io

Red Hat's registry — supports Clair vulnerability scanning, robot accounts, geo-replication.

### Container Registry Config

```toml
# /etc/containers/registries.conf (Podman)
[registries.search]
registries = ["docker.io", "quay.io"]

[registries.insecure]
registries = ["192.168.1.100:5000"]

[registries.block]
registries = []
```

---

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

---

## 12. Rootless Containers

### Why Rootless?

Full root within a container should not mean root on the host. Rootless mode maps root inside to an unprivileged user outside.

### Podman Rootless (Default)

```bash
# Podman runs rootless out of the box
podman run -d -p 8080:80 nginx

# Check — no root ownership
ls -la ~/.local/share/containers/storage/

# The container runs as the current user
podman top -l user
```

### Docker Rootless Mode

```bash
# Install rootless extras
sudo apt install docker-ce-rootless-extras

# Run setup
dockerd-rootless-setuptool.sh install

# Set environment
export DOCKER_HOST=unix:///run/user/$UID/docker.sock

# Run without root
docker run -d -p 8080:80 nginx

# Systemd user service
systemctl --user enable docker
systemctl --user start docker
```

### /etc/subuid and /etc/subgid

Rootless mapping uses subordinate ID ranges:

```bash
# /etc/subuid
user:100000:65536

# /etc/subgid
user:100000:65536

# user gets 65536 UIDs starting at 100000
# UID 0 (root) inside → UID 100000 outside
# UID 1 inside → UID 100001 outside
```

```bash
# View mapping
podman info --format '{{.Host.IDMappings}}'
```

### Networking (Rootless)

Rootless containers use **slirp4netns** (default):

```
Container netns → slirp4netns → host network
```

```bash
# No direct bridge — traffic goes through userspace NAT
# Use --net=host with Podman for better perf (but less isolation)
podman run --net=host nginx

# Rootlesskit config
podman info | grep slirp4netns
```

### Storage (Rootless)

Rootless uses **fuse-overlayfs** (FUSE-based overlay) instead of kernel overlay:

```bash
# Check driver
podman info | grep overlay
# overlay_rootless or fuse-overlayfs
```

### Cgroups v2 Requirement

Rootless containers need cgroups v2:

```bash
# Check
cat /sys/fs/cgroup/cgroup.controllers

# On Ubuntu, add to kernel cmdline:
# systemd.unified_cgroup_hierarchy=1
```

---

## 13. Security

### Run as Non-Root

```dockerfile
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser
```

```bash
docker run -u 1001:1001 nginx
```

### Security Options

```bash
# Disable privilege escalation
docker run --security-opt no-new-privileges:true nginx

# Read-only root filesystem
docker run --read-only --tmpfs /tmp --tmpfs /var/run nginx

# Drop all capabilities, add selective
docker run --cap-drop ALL --cap-add NET_BIND_SERVICE nginx

# AppArmor profile
docker run --security-opt apparmor=myprofile nginx

# SELinux context
docker run --security-opt label=level:TopSecret nginx

# Seccomp profile
docker run --security-opt seccomp=/path/to/seccomp.json nginx
```

### Linux Capabilities

```bash
# Default capabilities
docker run --cap-drop ALL nginx

# Add specific capabilities
docker run --cap-drop ALL --cap-add NET_BIND_SERVICE nginx

# List capabilities
docker exec web capsh --print
```

### Seccomp

Default seccomp profile blocks ~44 syscalls (out of ~300+):

```bash
# Use custom seccomp
docker run --security-opt seccomp=custom.json nginx

# Disable seccomp
docker run --security-opt seccomp=unconfined nginx
```

### AppArmor

```bash
# Load profile
sudo apparmor_parser -r -W /etc/apparmor.d/docker-custom

# Use profile
docker run --security-opt apparmor=docker-custom nginx
```

### SELinux

```bash
# On RHEL/CentOS/Fedora with SELinux
docker run --security-opt label=disable nginx          # disable
docker run --security-opt label=type:container_t nginx  # set type
```

### Privileged Mode

```bash
# ALL capabilities, host devices, no isolation
docker run --privileged nginx

# Avoid in production — this is basically a VM escape
```

### Read-Only Rootfs

```bash
docker run --read-only \
  --tmpfs /run \
  --tmpfs /tmp \
  --tmpfs /var/cache/nginx \
  nginx
```

---

## 14. Logging and Monitoring

### Default Log Driver

```bash
# Default: json-file — logs written as JSON to /var/lib/docker/containers/<id>/
docker logs web
```

### Log Drivers

```bash
# journald
docker run --log-driver journald nginx
journalctl -u docker CONTAINER_NAME=web

# syslog
docker run --log-driver syslog --log-opt syslog-address=udp://192.168.1.5:514 nginx

# fluentd
docker run --log-driver fluentd --log-opt fluentd-address=localhost:24224 nginx

# awslogs
docker run --log-driver awslogs --log-opt awslogs-group=my-group nginx

# gelf
docker run --log-driver gelf --log-opt gelf-address=udp://1.2.3.4:12201 nginx

# none
docker run --log-driver none nginx
```

### Log Rotation

```json
// /etc/docker/daemon.json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
```

```bash
sudo systemctl restart docker
```

### Podman Logs

```bash
podman logs web
podman logs -f web
podman logs --tail 100 web
```

### docker stats

```bash
# Live resource usage
docker stats
docker stats web
docker stats web db api

# No stats streaming
docker stats --no-stream
```

### cAdvisor

```bash
docker run -d \
  --name=cadvisor \
  -p 8080:8080 \
  --volume=/:/rootfs:ro \
  --volume=/var/run:/var/run:rw \
  --volume=/sys:/sys:ro \
  --volume=/var/lib/docker/:/var/lib/docker:ro \
  gcr.io/cadvisor/cadvisor:latest

# Open http://localhost:8080
```

---

## ⭐ Level 3: Advanced — Practices & Internals

![Container deep dive](https://upload.wikimedia.org/wikipedia/commons/a/a5/Terminal_icon.svg)

> *"Theory without practice is sterile; practice without theory is blind. These exercises bridge the gap."*

---

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

---

## 16. Deep Understanding

### How Containers Use Namespaces (`clone()` flags)

When a container runtime starts a process, it calls the `clone()` syscall with a mask of namespace flags:

```c
// Pseudocode of what runc does
int pid = clone(child_func,
                stack,
                CLONE_NEWPID | CLONE_NEWNET | CLONE_NEWNS |
                CLONE_NEWUTS | CLONE_NEWIPC | CLONE_NEWCGROUP,
                args);

// Or unshare() for existing processes
unshare(CLONE_NEWNS);  // mount namespace
unshare(CLONE_NEWPID); // PID namespace
```

Each flag creates a new, isolated namespace for the child process:

```bash
# strace a container runtime
sudo strace -f -e clone docker run alpine echo hi 2>&1 | grep CLONE_NEW
```

The `CLONE_NEWPID` flag means the first process inside the container sees itself as PID 1. It can't see host processes. When the kernel delivers a signal, it goes to the PID namespace where the process lives.

```
Host PID namespace:
  PID 1234 → container init (PID 1 inside)
  PID 5678 → process inside (PID 14 inside)

Container PID namespace:
  PID 1 → container init
  PID 14 → process
  (cannot see host PIDs)
```

### How Overlay2 Union Mount Works

Overlay2 combines multiple directories into one mount:

```
Lower layers: /var/lib/docker/overlay2/<hash>/diff/   (read-only)
Upper layer:  /var/lib/docker/overlay2/<hash>/diff/   (writable, per-container)
Merged view:  /var/lib/docker/overlay2/<hash>/merged/ (what container sees)
Work dir:     /var/lib/docker/overlay2/<hash>/work/   (internal)
```

```bash
# Inspect overlay mount in a running container
MOUNT=$(docker inspect mycontainer --format '{{.GraphDriver.Data.MergedDir}}')
cat /proc/mounts | grep overlay
```

The kernel overlay filesystem works as follows:

```
                 ┌──────────────────────┐
                 │      Container       │
                 │    processes see     │
                 │    /merged/ → all    │
                 └──────────┬───────────┘
                            │
                    ┌───────▼───────┐
                    │    Merged     │
                    │  (read-write) │
                    └───────┬───────┘
                            │
         ┌──────────────────┼──────────────────┐
         │                  │                  │
  ┌──────▼──────┐   ┌──────▼──────┐   ┌──────▼──────┐
  │  LowerDir1  │   │  LowerDir2  │   │  UpperDir   │
  │ (base img)  │   │ (layer RUN) │   │ (container  │
  │  read-only  │   │  read-only  │   │  writable)  │
  └─────────────┘   └─────────────┘   └─────────────┘
```

When a container reads `/etc/passwd`:
1. Check **UpperDir** first → if file exists (whiteout or modified), return it
2. Check **LowerDir** from highest to lowest priority → return first match
3. File not found

When a container writes a file:
1. File written to **UpperDir** (copy-up from lower if needed)
2. Deleting a file from a lower layer creates a **whiteout** character device in UpperDir

```bash
# See whiteout files
ls -la /var/lib/docker/overlay2/<hash>/diff/
# A whiteout is a char device 0:0 named .wh.<filename>
```

### How runc/containerd Work

**containerd** is the container *manager* — handles image transfer, storage, networking, and lifecycle. It communicates with **runc** (the OCI runtime) via `containerd-shim`:

```
docker → dockerd → containerd → containerd-shim → runc → container
```

The shim keeps stdin/stdout open even if the daemon restarts.

**runc** is the low-level OCI runtime — it:
1. Reads `config.json` from a bundle directory
2. Creates namespaces via `clone()`/`unshare()`
3. Sets up cgroups
4. Mounts the root filesystem
5. Drops capabilities, sets seccomp filters
6. `exec()`s the container process

```bash
# config.json example structure
{
  "ociVersion": "1.0.2-dev",
  "process": {
    "terminal": true,
    "user": {"uid": 0, "gid": 0},
    "args": ["/bin/sh"],
    "env": ["PATH=/usr/local/sbin:...", "TERM=xterm"],
    "capabilities": {
      "bounding": ["CAP_CHOWN", "CAP_DAC_OVERRIDE", ...]
    }
  },
  "root": {
    "path": "rootfs",
    "readonly": true
  },
  "hostname": "container-host",
  "mounts": [
    {"destination": "/proc", "type": "proc", "source": "proc"},
    {"destination": "/dev", "type": "tmpfs", "source": "tmpfs"}
  ],
  "linux": {
    "namespaces": [
      {"type": "pid"},
      {"type": "network"},
      {"type": "mount"},
      {"type": "uts"}
    ],
    "cgroupsPath": "/docker/abcdef123",
    "resources": {
      "memory": {"limit": 268435456},
      "cpu": {"shares": 512}
    },
    "seccomp": {
      "defaultAction": "SCMP_ACT_ERRNO",
      "architectures": ["SCMP_ARCH_X86_64"],
      "syscalls": [...]
    }
  }
}
```

### OCI Runtime Spec

The OCI Runtime Spec defines:

1. **Filesystem Bundle** — a directory with:
   - `config.json` — runtime configuration
   - `rootfs/` — root filesystem

2. **Lifecycle**:
   - `create` → creates container (process exists in cgroups, namespaces set up)
   - `start` → `exec()`s the process
   - `kill` → sends signal
   - `delete` → cleans up

3. **State** JSON:
   - `ociVersion`
   - `id`
   - `status` (creating, created, running, stopped)
   - `pid`
   - `bundle`

### How Podman Uses conmon/crun/runc

Podman's architecture (no daemon):

```
podman → conmon → crun/runc → container
```

**conmon** (container monitor):
- Manages stdin/stdout/stderr
- Reports exit code
- Handles terminal resizing
- Keeps container alive if Podman exits
- Attaches to the container's PID namespace

```
podman run -d nginx
  ├── podman (client, exits after container starts)
  └── conmon (monitor, PID 1234)
      └── crun (OCI runtime, PID 1235)
          └── nginx (container process, PID 1236)
                          ↓
                    (PID 1 inside container namespace)
```

**crun** vs **runc**:
- `crun` — written in C (~50 KB binary), faster startup, less memory
- `runc` — written in Go (~10 MB binary), reference implementation

```bash
# Check which runtime Podman uses
podman info | grep runtime
```

### Rootless Mapping (slirp4netns, fuse-overlayfs)

**Rootless networking** uses `slirp4netns`:

```
Container netns → slirp4netns (userspace NAT) → host's network
```

```bash
# slirp4netns creates a tap device in the container namespace
# and translates packets via userspace IP stack
# Drawback: slower than kernel bridge (no iptables, no direct routing)
```

**Rootless storage** uses `fuse-overlayfs` (or native overlay with `rootless_mode`):

```
Kernel overlayfs requires root (CAP_SYS_ADMIN) to create overlay mounts.
fuse-overlayfs implements overlay in userspace via FUSE.
```

```bash
# Check storage driver
podman info | grep overlay
```

---

## 17. Command Reference

### Level 1 — Basic

| Operation | Docker | Podman |
|-----------|--------|--------|
| Pull image | `docker pull <img>` | `podman pull <img>` |
| List images | `docker images` | `podman images` |
| Remove image | `docker rmi <img>` | `podman rmi <img>` |
| Run container | `docker run <img>` | `podman run <img>` |
| List running | `docker ps` | `podman ps` |
| List all | `docker ps -a` | `podman ps -a` |
| Stop | `docker stop <c>` | `podman stop <c>` |
| Start | `docker start <c>` | `podman start <c>` |
| Restart | `docker restart <c>` | `podman restart <c>` |
| Remove container | `docker rm <c>` | `podman rm <c>` |
| Execute | `docker exec <c> <cmd>` | `podman exec <c> <cmd>` |
| Logs | `docker logs <c>` | `podman logs <c>` |
| Inspect | `docker inspect <c>` | `podman inspect <c>` |
| Build image | `docker build -t <n> .` | `podman build -t <n> .` |
| Commit | `docker commit <c> <n>` | `podman commit <c> <n>` |
| Copy | `docker cp <c>:<s> <d>` | `podman cp <c>:<s> <d>` |

### Level 2 — Intermediary

| Operation | Docker | Podman |
|-----------|--------|--------|
| Push | `docker push <img>` | `podman push <img>` |
| Tag | `docker tag <s> <t>` | `podman tag <s> <t>` |
| Login | `docker login` | `podman login` |
| Volume create | `docker volume create <v>` | `podman volume create <v>` |
| Volume ls | `docker volume ls` | `podman volume ls` |
| Network create | `docker network create <n>` | `podman network create <n>` |
| Network ls | `docker network ls` | `podman network ls` |
| Compose up | `docker compose up` | `podman-compose up` |
| Stats | `docker stats` | `podman stats` |
| Save image | `docker save <i> -o <f>` | `podman save <i> -o <f>` |
| Load image | `docker load -i <f>` | `podman load -i <f>` |
| Export container | `docker export <c> -o <f>` | `podman export <c> -o <f>` |
| Import image | `docker import <f> <n>` | `podman import <f> <n>` |
| Info | `docker info` | `podman info` |
| Version | `docker version` | `podman version` |
| Events | `docker events` | `podman events` |
| Top | `docker top <c>` | `podman top <c>` |
| Port | `docker port <c>` | `podman port <c>` |
| Wait | `docker wait <c>` | `podman wait <c>` |
| Pause | `docker pause <c>` | `podman pause <c>` |
| Unpause | `docker unpause <c>` | `podman unpause <c>` |
| Kill | `docker kill <c>` | `podman kill <c>` |
| Attach | `docker attach <c>` | `podman attach <c>` |
| Diff | `docker diff <c>` | `podman diff <c>` |
| System prune | `docker system prune` | `podman system prune` |
| Container prune | `docker container prune` | `podman container prune` |
| Image prune | `docker image prune` | `podman image prune` |

Key differences to remember:
1. Podman doesn't need `sudo` for most operations
2. Podman runs containers in **pods** (`podman pod create`)
3. Podman can generate systemd unit files (`podman generate systemd`)
4. Docker Compose is built-in (`docker compose`); Podman needs `podman-compose`
5. Docker uses `dockerd` daemon; Podman forks directly
6. Podman supports `--pod` flag to run containers in a pod

---

## 18. What's Coming in Part 39

### Part 39: Web Servers — Apache and Nginx

We'll cover:
- Apache HTTPD — virtual hosts, modules, .htaccess, SSL termination
- Nginx — reverse proxy, load balancing, caching, static file serving
- PHP-FPM integration
- Performance tuning — worker processes, keepalive, buffers
- TLS/SSL certificate management with Let's Encrypt
- Security hardening — headers, rate limiting, WAF
- Monitoring — access logs, error logs, metrics
- Reverse engineering: how Apache's prefork/worker/event MPMs work at the kernel level

---

## 19. Self-Test

### Questions

**1.** What syscall creates Linux namespaces?
a) fork()
b) clone() with namespace flags
c) exec()
d) open()

**2.** Which namespace is NOT isolated by default in Docker containers?
a) PID
b) Network
c) User
d) Mount

**3.** What does `overlay2` use for copy-on-write?
a) Btrfs snapshots
b) Upper directory
c) Device mapper
d) ZFS clones

**4.** What is the key architectural difference between Docker and Podman?
a) Docker uses runc, Podman uses crun
b) Docker uses a daemon; Podman forks directly
c) Docker is rootless by default
d) Podman cannot run containers

**5.** Which directive in a Dockerfile sets the default command that CAN be overridden?
a) ENTRYPOINT
b) CMD
c) RUN
d) START

**6.** What does `docker compose down -v` do?
a) Stop and remove containers, networks, and volumes
b) Only stop containers
c) Remove images
d) Delete Docker Compose binary

**7.** What is the purpose of `/etc/subuid`?
a) Map host UIDs to container UIDs for rootless
b) Configure Docker subnet
c) Set user limits
d) Define container capabilities

**8.** Which flag makes a container's filesystem read-only?
a) `--read-only`
b) `--no-write`
c) `--immutable`
d) `--frozen`

**9.** What does the `USER` instruction in a Dockerfile do?
a) Sets the username for the container hostname
b) Sets the user for RUN, CMD, and ENTRYPOINT
c) Creates a new user
d) Restricts SSH access

**10.** In a multi-stage build, what does `COPY --from=builder` do?
a) Copies files from the builder stage to the final stage
b) Copies from the host filesystem
c) Downloads from a URL
d) Extracts a tar archive

**11.** What is `slirp4netns` used for?
a) Rootless container networking
b) Container image compression
c) Log rotation
d) Volume encryption

**12.** What does `--cap-drop ALL` in Docker do?
a) Removes all Linux capabilities
b) Drops all network traffic
c) Removes all volumes
d) Stops all containers

**13.** Which port does a local Docker registry listen on by default?
a) 80
b) 443
c) 5000
d) 8080

**14.** What is the OCI runtime used by Podman by default on modern systems?
a) runc
b) crun
c) containerd
d) docker-shim

**15.** What happens when a file is deleted from a container that exists in a lower overlay layer?
a) The file is erased from all layers
b) A whiteout file is created in the upper layer
c) The layer is rebuilt
d) The file becomes read-only

### Answers

1. **b** — `clone()` with flags like `CLONE_NEWPID`, `CLONE_NEWNET`
2. **c** — User namespace is NOT isolated by default (unless `--userns-remap` or rootless)
3. **b** — Upper directory holds new/changed files; lower layers are read-only
4. **b** — Docker uses dockerd daemon; Podman forks child processes directly
5. **b** — `CMD` can be overridden; `ENTRYPOINT` replaces
6. **a** — `down -v` stops and removes containers, networks, AND volumes
7. **a** — Maps host UID ranges to container UIDs for rootless operation
8. **a** — `--read-only` makes the container's filesystem read-only
9. **b** — Sets the user for subsequent `RUN`, `CMD`, and `ENTRYPOINT` instructions
10. **a** — Copies artifacts from a named build stage to the final image
11. **a** — Userspace NAT networking for rootless containers
12. **a** — Drops all Linux kernel capabilities from the container
13. **c** — Default registry port is 5000
14. **b** — crun (C implementation, faster than runc)
15. **b** — A character device whiteout `0:0` is created in the upper layer

**Score:** 12/15 correct = ready for Part 39.

---

```
*Previous → Part 37: Automation with Ansible*
*Next → Part 39: Web Servers — Apache and Nginx*
```

[← Previous](part37.md) | [Next →](part39.md)
