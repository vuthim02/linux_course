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


![Docker architecture — client, daemon, registries, and container runtime](https://upload.wikimedia.org/wikipedia/commons/2/21/ArquiteturaDocker.png)

*Docker client-server architecture (DaniloBarros / Wikimedia Commons / CC-BY-SA-4.0)*




[← Previous](03-level-1-basic-foundations.md) | [↑ Index](index.md) | [Next →](05-2-docker-vs-podman.md)
