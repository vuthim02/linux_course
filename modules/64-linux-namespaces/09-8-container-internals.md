## 8. Container Internals

### How Docker Builds a Container

Docker (via containerd and runc/crun) orchestrates namespaces, cgroups, and security primitives:

```
┌─────────────────────────────────────────────────────────────────┐
│  $ docker run -d --name web -p 80:80 nginx                       │
│                                                                  │
│  1. Pull image layers (overlay filesystem)                      │
│  2. Create OCI bundle (config.json with all settings)           │
│  3. Call runc/crun to create container                          │
│                                                                  │
│  runc creates (via clone syscall with flags):                    │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  CLONE_NEWPID    → PID namespace (entrypoint = PID 1)     │ │
│  │  CLONE_NEWNET    → Network stack (veth → bridge)          │ │
│  │  CLONE_NEWNS     → Mount namespace (overlayFS rootfs)     │ │
│  │  CLONE_NEWUTS    → Hostname (container ID or --hostname)  │ │
│  │  CLONE_NEWIPC    → IPC isolation                          │ │
│  │  CLONE_NEWUSER   → User ID mapping (--user)               │ │
│  │  CLONE_NEWCGROUP → Cgroup root view                       │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  4. Apply resource limits (cgroup files)                        │
│  5. Set up seccomp filters (syscall whitelist)                  │
│  6. Set up AppArmor/SELinux profiles                            │
│  7. Pivot root into image filesystem                            │
│  8. Execute entrypoint (nginx) as PID 1                         │
└─────────────────────────────────────────────────────────────────┘
```

### Anatomy of a Running Container

```bash
# Find the container's PID on host
docker inspect --format '{{.State.Pid}}' web
# 5432

# Examine all its namespaces
ls -la /proc/5432/ns/
# cgroup -> cgroup:[4026532456]
# ipc     -> ipc:[4026532452]
# mnt     -> mnt:[4026532449]
# net     -> net:[4026532455]
# pid     -> pid:[4026532450]
# user    -> user:[4026532448]
# uts     -> uts:[4026532451]

# Examine its mount table
cat /proc/5432/mountinfo | head -20
# Shows overlay root, /proc, /dev, tmpfs, etc.

# Examine its network interfaces
sudo nsenter -t 5432 -n ip addr
# eth0@if7: inet 172.17.0.2/16
# lo: inet 127.0.0.1/8

# Examine its cgroup
cat /proc/5432/cgroup
# 0::/system.slice/docker-<container_id>.scope

# Examine its capabilities
cat /proc/5432/status | grep Cap
# CapPrm: 00000000a80425fb  ← limited capabilities
# CapBnd: 00000000a80425fb
# CapEff: 00000000a80425fb

# Decode capabilities:
capsh --decode=00000000a80425fb
# 0x00000000a80425fb=cap_chown,cap_dac_override,cap_fowner,cap_fsetid,
# cap_kill,cap_setgid,cap_setuid,cap_setpcap,cap_net_bind_service,
# cap_net_raw,cap_sys_chroot,cap_mknod,cap_audit_write,cap_setfcap
```

### Container Process Tree

```
HOST PROCESS TREE:
systemd (PID 1)
├── containerd (PID 100)
│   └── containerd-shim (PID 5000)        ← manages container lifecycle
│       └── nginx (PID 5432)              ← PID 1 inside container
│           ├── nginx worker (PID 5433)    ← PID 2 inside
│           └── nginx worker (PID 5434)    ← PID 3 inside

INSIDE CONTAINER (PID namespace):
PID 1: nginx            ← main process, reaps orphans
PID 2: nginx worker     ← child process
PID 3: nginx worker     ← child process

Container sees: 3 processes total
Host sees: containerd-shim (5000) + nginx (5432) + workers (5433, 5434)
```

### Docker Networking Internals

```
┌───────────────────────────────────────────────────────────┐
│  Docker Networking (bridge mode)                           │
│                                                            │
│  Host: eth0 (192.168.1.100)                               │
│    │                                                       │
│  Host: docker0 (172.17.0.1)  ← bridge                     │
│    │        │         │                                    │
│  veth-a  veth-b    veth-c    ← veth pairs                 │
│    │        │         │                                    │
│  NS-A    NS-B      NS-C     ← network namespaces          │
│  172.17.  172.17.   172.17.                                │
│   0.2      0.3       0.4                                   │
│                                                            │
│  Port mapping (docker run -p 8080:80):                    │
│  iptables -t nat -A PREROUTING -p tcp --dport 8080        │
│    -j DNAT --to-destination 172.17.0.2:80                  │
│  → Host:8080 → DNAT → Container:80                         │
└───────────────────────────────────────────────────────────┘
```

### Podman's Differences from Docker

```bash
# Podman: daemonless, rootless by default, uses crun
# Docker: daemon (containerd), usually root, uses runc

# Podman creates a user namespace for each rootless user
# The slirp4netns or pasta network stack replaces bridge

# Podman container namespaces are identical in structure:
podman inspect --format '{{.State.Pid}}' my_container
PID=$(podman inspect --format '{{.State.Pid}}' my_container)
ls -la /proc/$PID/ns/

# Key difference: Podman in rootless mode nests namespaces
# User NS (rootless user → UID mapping) + all other NS
```





[← Previous](08-7-unshare-and-nsenter.md) | [↑ Index](index.md) | [Next →](10-9-namespace-security.md)
