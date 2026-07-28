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





[← Previous](11-level-2-intermediary-daily-administration.md) | [↑ Index](index.md) | [Next →](13-9-networking.md)
