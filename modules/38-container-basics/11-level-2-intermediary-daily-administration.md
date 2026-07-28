## ⭐ Level 2: Intermediary — Daily Administration

![Container volumes and networking](https://upload.wikimedia.org/wikipedia/commons/4/4e/Docker_compose_logo.png)

> *"Containers are ephemeral; data must persist. Mastering volumes and networking turns containers into production services."*

### What You'll Cover
- Volumes vs bind mounts: named volumes, `-v` vs `--mount`
- Container networking: bridge, host, none, custom networks
- Registry: Docker Hub, private registries, `docker push`/`docker pull`
- Docker Compose: multi-container apps, services, volumes, networks
- Rootless containers: Podman rootless, `uidmap`, user namespaces
- Security: least privilege, non-root users, read-only filesystems
- Logging: `docker logs`, logging drivers, journald integration

At this level you move from running single containers to building complete application stacks with persistent data, networking, and security.

At this level you will practice:

- **Volumes**: Named volumes (`docker volume create mydata`) persist data independently of containers. Bind mounts (`-v /host/path:/container/path`) map host directories. Volumes are managed by Docker; bind mounts depend on host filesystem permissions. Use `--mount type=volume` for explicit syntax.
- **Networking**: Default bridge network allows container-to-container communication. Host networking shares the host's network stack (no port mapping). Custom bridge networks provide DNS resolution between containers by name. `docker network create mynet` creates a custom network.
- **Docker Compose**: A `docker-compose.yml` defines multi-container apps. `services:`, `volumes:`, `networks:` sections declaratively describe the stack. `docker compose up -d` starts everything. `docker compose logs -f` follows logs. Essential for development and testing environments.
- **Security**: Run containers as non-root: `USER nginx` in Dockerfile. Use `--read-only` with `--tmpfs /tmp` for read-only filesystems. Drop capabilities: `--cap-drop ALL --cap-add NET_BIND_SERVICE`. Never run containers with `--privileged` in production.
- **Logging**: `docker logs -f container` follows stdout. `--log-driver=journald` sends logs to systemd journal. `--log-opt max-size=10m --log-opt max-file=3` limits log rotation. For production, use centralized logging (ELK, Loki).


[← Previous](10-7-containers.md) | [↑ Index](index.md) | [Next →](12-8-volumes-and-bind-mounts.md)
