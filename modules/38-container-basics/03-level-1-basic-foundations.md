## ⭐ Level 1: Basic — Foundations

![Docker and Podman containers](https://upload.wikimedia.org/wikipedia/commons/7/79/Docker_%28container_engine%29_logo.png)

> *"A container is a standard unit of software that packages up code and all its dependencies."*

### What You'll Cover
- Containers vs VMs: shared kernel, namespaces, cgroups
- Docker vs Podman: daemon vs daemonless, root vs rootless
- Installing Docker and Podman on RHEL/Ubuntu
- Images: pulling, listing, inspecting, tagging, layers
- Writing Dockerfiles: FROM, RUN, COPY, CMD, EXPOSE
- Running containers: `docker run`, `docker ps`, `docker exec`, `docker logs`

Containers package applications with their dependencies, providing isolation without the overhead of virtual machines. They share the host kernel but have their own filesystem, network, and process space.

At this level you will learn:

- **Containers vs VMs**: Containers share the host kernel (lightweight, fast startup). VMs include a full guest OS (heavy, strong isolation). Containers use Linux namespaces (PID, NET, MNT) for isolation and cgroups for resource limits. A container is a process, not a machine.
- **Docker vs Podman**: Docker uses a daemon (`dockerd`) running as root. Podman is daemonless and supports rootless operation. Both use the same CLI commands. Podman is preferred for security-sensitive environments.
- **Images**: `docker pull nginx` downloads an image. `docker images` lists local images. `docker inspect nginx` shows image details. Images are layered — each Dockerfile instruction creates a layer. Layers are cached and shared between images.
- **Dockerfiles**: `FROM ubuntu:22.04` sets the base. `RUN apt-get update && apt-get install -y nginx` installs packages. `COPY index.html /var/www/html/` copies files. `CMD ["nginx", "-g", "daemon off;"]` sets the default command. `EXPOSE 80` documents the port.
- **Running containers**: `docker run -d -p 8080:80 nginx` runs nginx in detached mode, mapping port 8080 on the host to 80 in the container. `docker ps` shows running containers. `docker exec -it container bash` opens an interactive shell. `docker logs container` shows stdout/stderr.


[← Previous](02-what-you-will-achieve.md) | [↑ Index](index.md) | [Next →](04-1-what-are-containers.md)
