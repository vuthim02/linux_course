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



---

[← Previous](16-12-rootless-containers.md) | [↑ Index](index.md) | [Next →](18-14-logging-and-monitoring.md)
