## 5. UTS, IPC, and USER Namespaces

### UTS Namespace — Hostname Isolation

The UTS (UNIX Time-Sharing) namespace isolates hostname and NIS domain name.

```bash
# Create a UTS namespace with a custom hostname
sudo unshare --uts bash

# Set hostname inside the namespace
hostname container-web-01
hostname
# container-web-01

# Exit — host hostname unchanged
exit
hostname
# (your original hostname)

# Docker equivalent:
# docker run --hostname=web-01 nginx
# Inside: hostname is web-01
# On host: container's hostname is invisible
```

```bash
# Verify UTS namespace isolation
# Terminal 1:
sudo unshare --uts hostname mycontainer
hostname   # "mycontainer"

# Terminal 2 (host):
hostname   # Original hostname — unchanged

# Inspect the UTS namespace inode
readlink /proc/self/ns/uts
# Compare with another process to verify isolation
```

> 🔍 **Reverse Engineering Insight:** UTS isolation is why containers can have arbitrary hostnames without affecting the host. It's one of the simplest namespaces — it only isolates two strings (hostname and NIS domain), but it's essential for services that use hostname-based routing or identity.

### IPC Namespace — Inter-Process Communication

IPC namespaces isolate System V IPC objects (shared memory segments, message queues, semaphores) and POSIX message queues.

```bash
# Create an IPC namespace
sudo unshare --ipc bash

# Create a System V shared memory segment
ipcmk -M 1024
# Shared memory id: 0 (created with size 1024k)

# Create a message queue
ipcmk -Q
# Message queue id: 0

# List IPC objects
ipcs

# --- Shared Memory Segments --------
# key        shmid      owner      perms      bytes      nattch     status
# 0x00000000 0          root       644        1048576    0

# --- Messages --------
# key        msqid      owner      perms      used-bytes   messages

# --- Semaphores --------
# key        semid      owner      perms      nsems

# These are INVISIBLE from the host or other IPC namespaces
# Exit and verify:
exit
ipcs
# No IPC objects — they were namespace-private
```

```bash
# This is why containers need their own /dev/shm
# Docker creates a 64MB tmpfs at /dev/shm by default
# Without IPC namespace, container could read host shared memory
docker run --rm alpine cat /proc/1/ipc_shm
```

### USER Namespace — Unprivileged Containers

USER namespaces map a range of user IDs inside the namespace to a different (possibly unprivileged) range outside. This is the key to rootless containers.

```
┌──────────────────────────────────────────────────────────────┐
│  USER NAMESPACE IDENTITY MAPPING                              │
│                                                               │
│  Inside Namespace          │  Outside (host)                  │
│  UID 0 (root)              │  UID 100000 (unprivileged)      │
│  UID 1                     │  UID 100001                      │
│  UID 65534 (nobody)        │  UID 165533                     │
│                            │                                  │
│  This "root" has CAP_SYS_ADMIN *inside* the namespace       │
│  but is just UID 100000 on the host — no real root!          │
└──────────────────────────────────────────────────────────────┘
```

```bash
# Create a user namespace (no root required!)
unshare --user --map-root-user bash

# We are now UID 0 inside the namespace
id
# uid=0(root) gid=0(root) groups=0(root)

# But on the host, we're still an unprivileged user:
cat /proc/self/uid_map
#          0     100000      65536
# This means: inside-UID 0 → host-UID 100000, range of 65536 IDs

# Check capabilities inside
cat /proc/self/status | grep Cap
# CapPrm: 0000003fffffffff  ← full caps inside namespace
# CapBnd: 0000003fffffffff

# From host:
# The process owner is still UID 1000 (unprivileged)
# It cannot do anything on the host that UID 1000 cannot do
```

> ⚠️ **Warning:** USER namespaces grant the process *apparent* root inside the namespace, but this is bounded by the user's real capabilities. CVEs in the kernel's namespace code have allowed escaping USER namespaces to gain host root. Always keep your kernel patched.

### `/etc/subuid` and `/etc/subgid`

The kernel uses subordinate UID/GID ranges for mapping:

```bash
# View subordinate UID mappings
cat /etc/subuid
# tim:100000:65536

# View subordinate GID mappings
cat /etc/subgid
# tim:100000:65536

# Format: username:start_uid:range
# tim gets 65536 UIDs starting at 100000

# This is what tools like podman use for rootless containers
# Inside the container, UID 0 maps to UID 100000 on host
```





[← Previous](05-4-mount-namespace.md) | [↑ Index](index.md) | [Next →](07-6-cgroup-namespace.md)
