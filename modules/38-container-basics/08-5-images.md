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





[← Previous](07-4-installing-podman.md) | [↑ Index](index.md) | [Next →](09-6-dockerfile.md)
