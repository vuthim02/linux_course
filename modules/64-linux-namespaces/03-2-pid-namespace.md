## 2. PID Namespace

### How PID Isolation Works

Without PID namespaces, every process sees every other process on the system. PID namespaces give each container (or process group) its own PID numbering starting at 1.

```
┌─────────────────────────────────────────────────────────────┐
│  HOST (PID namespace 0)                                     │
│  PID 1: systemd                                              │
│  PID 2345: containerd-shim                                  │
│  PID 2367: container entrypoint (PID 1 inside container)    │
│  PID 2389: container child process                          │
│                                                              │
│  ┌──────────────────────────────────────┐                   │
│  │  CONTAINER (PID namespace 1)         │                   │
│  │  PID 1: /app/server (entrypoint)    │                   │
│  │  PID 2: worker process              │                   │
│  │                                      │                   │
│  │  PID 1 in container = PID 2367 on host│                  │
│  │  PID 2 in container = PID 2389 on host│                  │
│  └──────────────────────────────────────┘                   │
└─────────────────────────────────────────────────────────────┘
```

### PID 1 Special Behavior

PID 1 in a namespace has special kernel semantics:

1. **Orphan reaping** — PID 1 becomes the parent of all orphaned processes in its namespace
2. **Signal handling** — PID 1 can ignore signals that would kill normal processes
3. **Init responsibility** — If PID 1 does not call `wait()`, zombie processes accumulate

```bash
# Demonstrate PID namespace isolation
sudo unshare --pid --fork --mount-proc bash

# Inside the new namespace:
ps aux
# USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
# root         1  0.0  0.0   7000  3500 pts/0    S    10:00   0:00 bash
# root         5  0.0  0.0  10600  3300 pts/0    R+   10:00   0:00 ps aux

# Only 2 processes visible — complete isolation
# PID 1 here is bash itself

# Check the host PID of this process from another terminal:
ps aux | grep "unshare"
# root  4521  0.0  0.0  ... unshare --pid --fork --mount-proc bash
# root  4522  0.0  0.0  ... bash  (this is PID 1 in the namespace, PID 4522 on host)
```

### Nested PID Namespaces

PID namespaces can be nested up to 32 levels deep. A process can see its own namespace and all child namespaces, but not parent namespaces.

```
┌──────────────────────────────────────────────────────┐
│  PID NS Level 0 (host)                               │
│  PID 1: systemd                                       │
│  PID 100: containerd-shim                             │
│                                                       │
│  ┌────────────────────────────────┐                  │
│  │  PID NS Level 1                │                  │
│  │  PID 1: container-init         │  ← PID 100 on L0│
│  │  PID 2: child                  │  ← PID 101 on L0│
│  │                                │                  │
│  │  ┌──────────────────────┐      │                  │
│  │  │  PID NS Level 2      │      │                  │
│  │  │  PID 1: nested-init  │  ← PID 1 on L1 = PID 101 on L0│
│  │  └──────────────────────┘      │                  │
│  └────────────────────────────────┘                  │
└──────────────────────────────────────────────────────┘
```

```bash
# Create nested PID namespaces
# Terminal 1: Level 0 → Level 1
sudo unshare --pid --fork --mount-proc bash
# Note: PID 1 is bash, let's say host PID is 5000

# Terminal 2: Inside Level 1, create Level 2
# (from inside the Level 1 namespace)
unshare --pid --fork --mount-proc bash
# PID 1 here is bash; on host this is PID 5001
# PID 1 in Level 1 (our parent) sees us as PID 2
# PID 1 in Level 0 (host) sees us as PID 5001
```

### Orphan Reaping in Practice

When a process in a PID namespace exits, its children become orphans. PID 1 must `wait()` for them or they become zombies.

```bash
# Demonstrate zombie reaping problem
sudo unshare --pid --fork --mount-proc bash

# Inside namespace: PID 1 is bash
# Start a child that spawns a grandchild then exits
(sleep 100 &; exit 0) &

# The sleep(100) is now an orphan — parent exited
# PID 1 (bash) must reap it

ps aux
# root   1  bash
# root   4  sleep 100   ← orphan, parented to PID 1

# If PID 1 doesn't reap, this process stays as zombie
# In real containers, init systems (tini, dumb-init) handle this
```

> ⚠️ **Warning:** This is why running a shell as PID 1 in a container is dangerous. Bash does not properly reap orphaned children. Use `tini` or `dumb-init` as your container entrypoint.

### Process Visibility

```bash
# See which PID namespace a process belongs to
ls -la /proc/<PID>/ns/pid

# List all PID namespaces on the system
lsns -t pid

# Example output:
#         NS   NPROCS   PID USER    COMMAND
# 4026531836      234     1 root    /sbin/init
# 4026532448        3  4521 root    bash
# 4026532449        1  5000 root    sleep 100

# PID namespace info from /proc
cat /proc/sys/kernel/ns_last_pid
# Last PID allocated in the current PID namespace
```

---



---

[← Previous](02-1-what-are-namespaces.md) | [↑ Index](index.md) | [Next →](04-3-network-namespace.md)
