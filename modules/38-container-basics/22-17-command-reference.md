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



---

[← Previous](21-16-deep-understanding.md) | [↑ Index](index.md) | [Next →](23-18-whats-coming-in-part.md)
