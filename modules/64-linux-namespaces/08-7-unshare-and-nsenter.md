## 7. unshare and nsenter

### unshare — Create New Namespaces

`unshare` runs a command in new namespaces without requiring a full container runtime.

```bash
# Basic syntax
unshare [options] command [arguments]

# Key options:
# --pid          New PID namespace
# --net          New network namespace
# --mount        New mount namespace
# --uts          New UTS namespace
# --ipc          New IPC namespace
# --user         New user namespace
# --cgroup       New cgroup namespace
# --fork         Fork before exec (required for PID namespace)
# --mount-proc   Mount /proc in new PID namespace
# --map-root-user Map current user to root inside user namespace
```

```bash
# Create a full container-like environment
sudo unshare \
    --pid \
    --net \
    --mount \
    --uts \
    --ipc \
    --cgroup \
    --fork \
    --mount-proc \
    bash

# Inside this namespace:
hostname isolated-box
ip link show     # Only lo (no host interfaces)
ps aux           # Only processes in this PID namespace
mount | wc -l   # Isolated mount table
```

```bash
# Rootless full isolation (user namespace provides all caps)
unshare \
    --user \
    --pid \
    --net \
    --mount \
    --uts \
    --ipc \
    --cgroup \
    --fork \
    --map-root-user \
    bash

# Inside: you are "root" (UID 0 mapped), with full capabilities
# But on host: you are still an unprivileged user
id              # uid=0(root) inside
cat /proc/self/uid_map  # 0 → 100000 mapping
```

### nsenter — Enter Existing Namespaces

`nsenter` attaches to one or more namespaces of a running process.

```bash
# Enter the PID namespace of a container
# Find the container's PID on host
CONTAINER_PID=$(docker inspect --format '{{.State.Pid}}' my_container)

# Enter all namespaces of the container
sudo nsenter -t $CONTAINER_PID -m -u -i -n -p bash

# You're now effectively "inside" the container
# Same view as if you ran "docker exec"

# Individual namespace flags:
# -t PID     Target process
# -m         Enter mount namespace
# -u         Enter UTS namespace
# -i         Enter IPC namespace
# -n         Enter network namespace
# -p         Enter PID namespace
# -C         Enter cgroup namespace
# --all      Enter all namespaces
```

```bash
# Common real-world use cases:

# 1. Debug a container's network
CONTAINER_PID=$(docker inspect --format '{{.State.Pid}}' web_app)
sudo nsenter -t $CONTAINER_PID -n tcpdump -i eth0

# 2. Debug a container's filesystem
sudo nsenter -t $CONTAINER_PID -m ls -la /app/

# 3. Enter a container that has no shell
# (the container image might only have a static binary)
sudo nsenter -t $CONTAINER_PID -m /bin/sh

# 4. Check which network namespace a process is in
ls -la /proc/$CONTAINER_PID/ns/net
# Compare with another container to verify isolation
```

```bash
# nsenter with docker: the "unshare + nsenter" workflow
# Step 1: Start a process in isolated namespaces
sudo unshare --pid --net --fork sleep 999 &
ISOLATED_PID=$!

# Step 2: Enter those namespaces from another terminal
sudo nsenter -t $ISOLATED_PID -p -n bash

# You now share the same network and PID namespace
```

> 🔍 **Reverse Engineering Insight:** `docker exec` is implemented as `nsenter` under the hood. Docker finds the container's PID on the host and uses `nsenter -t <PID> --all` to enter all the container's namespaces, then executes the command there. This is why you can debug a container without installing tools inside it — you can run the tools from the host via `nsenter`.





[← Previous](07-6-cgroup-namespace.md) | [↑ Index](index.md) | [Next →](09-8-container-internals.md)
