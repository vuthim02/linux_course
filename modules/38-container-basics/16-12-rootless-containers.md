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



---

[← Previous](15-11-docker-compose.md) | [↑ Index](index.md) | [Next →](17-13-security.md)
