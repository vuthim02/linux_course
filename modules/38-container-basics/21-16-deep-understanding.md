## 16. Deep Understanding

### How Containers Use Namespaces (`clone()` flags)

When a container runtime starts a process, it calls the `clone()` syscall with a mask of namespace flags:

```c
// Pseudocode of what runc does
int pid = clone(child_func,
                stack,
                CLONE_NEWPID | CLONE_NEWNET | CLONE_NEWNS |
                CLONE_NEWUTS | CLONE_NEWIPC | CLONE_NEWCGROUP,
                args);

// Or unshare() for existing processes
unshare(CLONE_NEWNS);  // mount namespace
unshare(CLONE_NEWPID); // PID namespace
```

Each flag creates a new, isolated namespace for the child process:

```bash
# strace a container runtime
sudo strace -f -e clone docker run alpine echo hi 2>&1 | grep CLONE_NEW
```

The `CLONE_NEWPID` flag means the first process inside the container sees itself as PID 1. It can't see host processes. When the kernel delivers a signal, it goes to the PID namespace where the process lives.

```
Host PID namespace:
  PID 1234 → container init (PID 1 inside)
  PID 5678 → process inside (PID 14 inside)

Container PID namespace:
  PID 1 → container init
  PID 14 → process
  (cannot see host PIDs)
```

### How Overlay2 Union Mount Works

Overlay2 combines multiple directories into one mount:

```
Lower layers: /var/lib/docker/overlay2/<hash>/diff/   (read-only)
Upper layer:  /var/lib/docker/overlay2/<hash>/diff/   (writable, per-container)
Merged view:  /var/lib/docker/overlay2/<hash>/merged/ (what container sees)
Work dir:     /var/lib/docker/overlay2/<hash>/work/   (internal)
```

```bash
# Inspect overlay mount in a running container
MOUNT=$(docker inspect mycontainer --format '{{.GraphDriver.Data.MergedDir}}')
cat /proc/mounts | grep overlay
```

The kernel overlay filesystem works as follows:

```
                 ┌──────────────────────┐
                 │      Container       │
                 │    processes see     │
                 │    /merged/ → all    │
                 └──────────┬───────────┘
                            │
                    ┌───────▼───────┐
                    │    Merged     │
                    │  (read-write) │
                    └───────┬───────┘
                            │
         ┌──────────────────┼──────────────────┐
         │                  │                  │
  ┌──────▼──────┐   ┌──────▼──────┐   ┌──────▼──────┐
  │  LowerDir1  │   │  LowerDir2  │   │  UpperDir   │
  │ (base img)  │   │ (layer RUN) │   │ (container  │
  │  read-only  │   │  read-only  │   │  writable)  │
  └─────────────┘   └─────────────┘   └─────────────┘
```

When a container reads `/etc/passwd`:
1. Check **UpperDir** first → if file exists (whiteout or modified), return it
2. Check **LowerDir** from highest to lowest priority → return first match
3. File not found

When a container writes a file:
1. File written to **UpperDir** (copy-up from lower if needed)
2. Deleting a file from a lower layer creates a **whiteout** character device in UpperDir

```bash
# See whiteout files
ls -la /var/lib/docker/overlay2/<hash>/diff/
# A whiteout is a char device 0:0 named .wh.<filename>
```

### How runc/containerd Work

**containerd** is the container *manager* — handles image transfer, storage, networking, and lifecycle. It communicates with **runc** (the OCI runtime) via `containerd-shim`:

```
docker → dockerd → containerd → containerd-shim → runc → container
```

The shim keeps stdin/stdout open even if the daemon restarts.

**runc** is the low-level OCI runtime — it:
1. Reads `config.json` from a bundle directory
2. Creates namespaces via `clone()`/`unshare()`
3. Sets up cgroups
4. Mounts the root filesystem
5. Drops capabilities, sets seccomp filters
6. `exec()`s the container process

```bash
# config.json example structure
{
  "ociVersion": "1.0.2-dev",
  "process": {
    "terminal": true,
    "user": {"uid": 0, "gid": 0},
    "args": ["/bin/sh"],
    "env": ["PATH=/usr/local/sbin:...", "TERM=xterm"],
    "capabilities": {
      "bounding": ["CAP_CHOWN", "CAP_DAC_OVERRIDE", ...]
    }
  },
  "root": {
    "path": "rootfs",
    "readonly": true
  },
  "hostname": "container-host",
  "mounts": [
    {"destination": "/proc", "type": "proc", "source": "proc"},
    {"destination": "/dev", "type": "tmpfs", "source": "tmpfs"}
  ],
  "linux": {
    "namespaces": [
      {"type": "pid"},
      {"type": "network"},
      {"type": "mount"},
      {"type": "uts"}
    ],
    "cgroupsPath": "/docker/abcdef123",
    "resources": {
      "memory": {"limit": 268435456},
      "cpu": {"shares": 512}
    },
    "seccomp": {
      "defaultAction": "SCMP_ACT_ERRNO",
      "architectures": ["SCMP_ARCH_X86_64"],
      "syscalls": [...]
    }
  }
}
```

### OCI Runtime Spec

The OCI Runtime Spec defines:

1. **Filesystem Bundle** — a directory with:
   - `config.json` — runtime configuration
   - `rootfs/` — root filesystem

2. **Lifecycle**:
   - `create` → creates container (process exists in cgroups, namespaces set up)
   - `start` → `exec()`s the process
   - `kill` → sends signal
   - `delete` → cleans up

3. **State** JSON:
   - `ociVersion`
   - `id`
   - `status` (creating, created, running, stopped)
   - `pid`
   - `bundle`

### How Podman Uses conmon/crun/runc

Podman's architecture (no daemon):

```
podman → conmon → crun/runc → container
```

**conmon** (container monitor):
- Manages stdin/stdout/stderr
- Reports exit code
- Handles terminal resizing
- Keeps container alive if Podman exits
- Attaches to the container's PID namespace

```
podman run -d nginx
  ├── podman (client, exits after container starts)
  └── conmon (monitor, PID 1234)
      └── crun (OCI runtime, PID 1235)
          └── nginx (container process, PID 1236)
                          ↓
                    (PID 1 inside container namespace)
```

**crun** vs **runc**:
- `crun` — written in C (~50 KB binary), faster startup, less memory
- `runc` — written in Go (~10 MB binary), reference implementation

```bash
# Check which runtime Podman uses
podman info | grep runtime
```

### Rootless Mapping (slirp4netns, fuse-overlayfs)

**Rootless networking** uses `slirp4netns`:

```
Container netns → slirp4netns (userspace NAT) → host's network
```

```bash
# slirp4netns creates a tap device in the container namespace
# and translates packets via userspace IP stack
# Drawback: slower than kernel bridge (no iptables, no direct routing)
```

**Rootless storage** uses `fuse-overlayfs` (or native overlay with `rootless_mode`):

```
Kernel overlayfs requires root (CAP_SYS_ADMIN) to create overlay mounts.
fuse-overlayfs implements overlay in userspace via FUSE.
```

```bash
# Check storage driver
podman info | grep overlay
```

---



---

[← Previous](20-15-hands-on-practices.md) | [↑ Index](index.md) | [Next →](22-17-command-reference.md)
