## ⭐ Level 3: Advanced — Practices & Internals

![Container deep dive](https://upload.wikimedia.org/wikipedia/commons/a/a5/Terminal_icon.svg)

> *"Theory without practice is sterile; practice without theory is blind. These exercises bridge the gap."*

### What You'll Cover
- 15 hands-on practices: building, deploying, and managing containers
- Overlay filesystem: how container layers are stacked and merged
- cgroups v2: resource limits for containers (CPU, memory, I/O)
- Linux namespaces: PID, NET, MNT, UTS, IPC, USER
- Container orchestration concepts: when to reach for Kubernetes
- Performance tuning: storage drivers, network performance, image optimization

At the advanced level, you understand what happens under the hood when you run a container — and you can troubleshoot issues at the kernel level.

At this level you will master:

- **Overlay filesystem**: Container images use overlayfs (or similar union filesystems) to stack read-only image layers with a writable container layer. `docker inspect container` shows the `GraphDriver` with `MergedDir` (unified view), `LowerDir` (image layers), and `UpperDir` (writable layer). Understanding this explains why deleted files still consume space in image layers.
- **cgroups v2**: Containers inherit resource limits from cgroups. `docker run --memory=512m --cpus=1.0` sets limits via cgroups. Monitor with `cat /sys/fs/cgroup/system.slice/docker-<id>.scope/memory.max`. OOM-killed containers show in `dmesg` with `Out of memory: Killed process`.
- **Namespaces**: PID namespace gives containers their own PID 1. Network namespace provides isolated networking. Mount namespace isolates filesystems. UTS namespace gives a unique hostname. IPC namespace isolates inter-process communication. USER namespace maps container root to a non-root host user.
- **Orchestration**: When you need to manage hundreds of containers across multiple hosts, you need Kubernetes. But for simple multi-host setups, Docker Swarm or Podman pods with `podman play kube` are lighter alternatives. Know when the complexity of Kubernetes is justified.
- **Image optimization**: Use multi-stage builds to reduce image size. Start from `alpine` or `distroless` base images. Combine `RUN` commands to reduce layers. Use `.dockerignore` to exclude unnecessary files. A smaller image means faster pulls and smaller attack surface.


[← Previous](18-14-logging-and-monitoring.md) | [↑ Index](index.md) | [Next →](20-15-hands-on-practices.md)
