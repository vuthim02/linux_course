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





[← Previous](04-1-what-are-containers.md) | [↑ Index](index.md) | [Next →](06-3-installing-docker.md)
