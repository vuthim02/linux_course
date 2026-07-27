# 🐧 Linux System Administrator — Complete Course
## Part 64 of ∞: Linux Namespaces — The Building Blocks of Containers

---

> **Reverse Engineering Approach:** When you run `docker run`, you assume isolation — different PIDs, different network, different filesystem. But how? There is no hypervisor. There is no separate kernel. Everything runs on the same Linux kernel you already have. The answer is **namespaces**: kernel-level constructs that partition global resources so each process group sees its own private view. This part dissects every namespace type, traces through `/proc/*/ns/*`, builds containers from scratch with `unshare`, and reveals how Docker and Podman orchestrate these primitives into the illusion of a virtual machine.

---

## 🎯 What You Will Achieve

- Understand what namespaces are, how they partition kernel resources, and their history
- Master PID namespaces: PID 1, orphan reaping, PID starvation, multi-level PID trees
- Configure Network namespaces: veth pairs, bridges, routing, and `ip netns`
- Work with Mount namespaces: chroot vs namespace, pivot_root, mount propagation
- Deploy UTS, IPC, and USER namespaces for hostname isolation, IPC separation, and unprivileged containers
- Understand cgroup namespaces and the v1 vs v2 resource controller landscape
- Use `unshare` and `nsenter` to create and enter namespaces from the command line
- Reverse-engineer how Docker and Podman build containers from namespaces + cgroups + seccomp
- Identify namespace escape vectors and harden container environments

---

## 1. What Are Namespaces?

### The Core Concept

A namespace wraps a global system resource in an abstraction that makes it appear to processes within the namespace that they have their own isolated instance of that resource.

```
┌─────────────────────────────────────────────────────────────────┐
│                         HOST KERNEL                              │
│                                                                  │
│  ┌──────────────────────┐    ┌──────────────────────┐           │
│  │   Namespace A         │    │   Namespace B         │          │
│  │                       │    │                       │          │
│  │  PID 1, 2, 3         │    │  PID 1, 2, 3         │          │
│  │  eth0: 172.17.0.2    │    │  eth0: 172.17.0.3    │          │
│  │  hostname: web-a     │    │  hostname: db-a       │          │
│  │  mount: / (overlay)  │    │  mount: / (overlay)   │          │
│  │  /dev/sda1 visible   │    │  /dev/sda1 hidden     │          │
│  └──────────────────────┘    └──────────────────────┘           │
│            │                          │                          │
│            └──────────┬───────────────┘                          │
│                       │                                          │
│              Shared Kernel Subsystems                            │
│              (scheduler, memory, drivers)                        │
└─────────────────────────────────────────────────────────────────┘
```

### Available Namespaces

| Namespace | Isolates | Kernel Version | Flag |
|-----------|----------|----------------|------|
| **PID** | Process IDs | 2.6.24 (2008) | `CLONE_NEWPID` |
| **Network** | Network stack (interfaces, routes, iptables) | 2.6.29 (2009) | `CLONE_NEWNET` |
| **Mount** | Filesystem mount points | 2.4.19 (2002) | `CLONE_NEWNS` |
| **UTS** | Hostname and NIS domain name | 2.6.19 (2006) | `CLONE_NEWUTS` |
| **IPC** | System V IPC, POSIX message queues | 2.6.19 (2006) | `CLONE_NEWIPC` |
| **User** | User and group IDs | 3.8 (2013) | `CLONE_NEWUSER` |
| **cgroup** | cgroup root directory view | 4.6 (2016) | `CLONE_NEWCGROUP` |

> 🔍 **Reverse Engineering Insight:** Notice the dates — Mount namespaces (2002) existed five years before the word "container" was commonly used in Linux. Namespaces were designed as general isolation primitives. Containers are just a *consumer* of namespaces, not the reason they were built.

### Namespace System Calls

```c
// Three ways to interact with namespaces:
clone()    // Create new process in new namespace(s)
unshare()  // Move current process into new namespace(s)
setns()    // Join an existing namespace
```

```bash
# Check which namespaces a process belongs to
ls -la /proc/1/ns/

# Example output on host:
# lrwxrwxrwx 1 root root 0 ... cgroup -> 'cgroup:[4026531835]'
# lrwxrwxrwx 1 root root 0 ... ipc -> 'ipc:[4026531839]'
# lrwxrwxrwx 1 root root 0 ... mnt -> 'mnt:[4026531840]'
# lrwxrwxrwx 1 root root 0 ... net -> 'net:[4026531969]'
# lrwxrwxrwx 1 root root 0 ... pid -> 'pid:[4026531836]'
# lrwxrwxrwx 1 root root 0 ... pid_for_children -> 'pid:[4026531836]'
# lrwxrwxrwx 1 root root 0 ... time -> 'time:[4026531834]'
# lrwxrwxrwx 1 root root 0 ... time_for_children -> 'time:[4026531834]'
# lrwxrwxrwx 1 root root 0 ... user -> 'user:[4026531837]'
# lrwxrwxrwx 1 root root 0 ... uts -> 'uts:[4026531838]'
```

Each symlink points to a namespace inode. Two processes sharing the same inode number are in the same namespace.

```bash
# Compare namespaces between two processes
readlink /proc/1/ns/pid /proc/self/ns/pid

# If output differs, they are in different PID namespaces
```

---

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

## 3. Network Namespace

### The Network Isolation Model

Each network namespace gets its own complete network stack: interfaces, IP addresses, routing tables, port numbers, iptables rules, and `/proc/net` statistics.

```
┌─────────────────────────────────────────────────────────────────┐
│  HOST NETWORK NAMESPACE                                          │
│                                                                  │
│  eth0: 192.168.1.100 (physical NIC)                             │
│  docker0: 172.17.0.1/16 (bridge)                                │
│  veth-host@if2: → veth-container@if1                            │
│                                                                  │
│  ┌─────────────────────────┐  ┌─────────────────────────┐      │
│  │  Container A (net NS)   │  │  Container B (net NS)   │      │
│  │  lo: 127.0.0.1          │  │  lo: 127.0.0.1          │      │
│  │  eth0@if1: 172.17.0.2   │  │  eth0@if1: 172.17.0.3   │      │
│  │  gw: 172.17.0.1         │  │  gw: 172.17.0.1         │      │
│  └──────────┬──────────────┘  └──────────┬──────────────┘      │
│             │                             │                      │
│          veth pair                    veth pair                  │
│             │                             │                      │
│             └─────────┬───────────────────┘                      │
│                       │                                          │
│                  docker0 bridge                                   │
│                       │                                          │
│                    iptables NAT                                   │
│                       │                                          │
│                    eth0 → internet                               │
└─────────────────────────────────────────────────────────────────┘
```

### veth Pairs

Virtual ethernet (veth) pairs are tunnel endpoints — packets entering one end come out the other.

```bash
# Create a network namespace
sudo ip netns add container_a

# Create a veth pair
sudo ip link add veth-host type veth peer name veth-ns

# Move one end into the namespace
sudo ip link set veth-ns netns container_a

# Configure the host end
sudo ip addr add 10.200.1.1/24 dev veth-host
sudo ip link set veth-host up

# Configure the namespace end
sudo ip netns exec container_a ip addr add 10.200.1.2/24 dev veth-ns
sudo ip netns exec container_a ip link set veth-ns up
sudo ip netns exec container_a ip link set lo up

# Test connectivity
ping 10.200.1.2   # From host → container
sudo ip netns exec container_a ping 10.200.1.1  # Container → host
```

### Bridge Networking

```bash
# Create a bridge
sudo ip link add br0 type bridge
sudo ip addr add 10.200.0.1/24 dev br0
sudo ip link set br0 up

# Enable bridge to forward (like Docker does)
sudo sysctl -w net.bridge.bridge-nf-call-iptables=0

# Create namespaces and connect via veth pairs
for i in 1 2 3; do
    sudo ip netns add ns${i}
    sudo ip link add veth${i}-host type veth peer name veth${i}-ns
    sudo ip link set veth${i}-ns netns ns${i}
    sudo ip link set veth${i}-host master br0
    sudo ip link set veth${i}-host up
    sudo ip netns exec ns${i} ip addr add 10.200.0.${i}/24 dev veth${i}-ns
    sudo ip netns exec ns${i} ip link set veth${i}-ns up
    sudo ip netns exec ns${i} ip link set lo up
done

# All three namespaces can now communicate through the bridge
sudo ip netns exec ns1 ping 10.200.0.2
sudo ip netns exec ns2 ping 10.200.0.3
```

### NAT and Internet Access

```bash
# Enable IP forwarding
sudo sysctl -w net.ipv4.ip_forward=1

# Add NAT rule so containers reach the internet
sudo iptables -t nat -A POSTROUTING -s 10.200.0.0/24 -o eth0 -j MASQUERADE

# Add default route inside namespaces
sudo ip netns exec ns1 ip route add default via 10.200.0.1

# Now ns1 can reach the internet
sudo ip netns exec ns1 ping -c 2 8.8.8.8
```

### Network Namespace Inspection

```bash
# List all network namespaces
sudo ip netns list
# container_a
# ns1
# ns2
# ns3

# Execute command in a namespace
sudo ip netns exec container_a ip addr show

# Enter a namespace interactively
sudo ip netns exec container_a bash

# View iptables rules inside a namespace
sudo ip netns exec container_a iptables -L -n

# Check /proc/net inside a namespace
sudo ip netns exec container_a cat /proc/net/tcp

# Move an existing process into a network namespace (requires privileges)
# This is useful for attaching a running process to a container network
```

> 🔍 **Reverse Engineering Insight:** Every container gets its own port space. Two containers can both bind to port 8080 because they exist in separate network namespaces. This is why `-p 8080:80` in Docker maps the host port to the container port — it's bridging two different network namespaces.

---

## 4. Mount Namespace

### chroot vs Mount Namespace

`chroot` changes the apparent root directory for one process and its children. Mount namespaces go much further — they isolate the entire mount table.

```
┌──────────────────────────────────────────────────────┐
│  chroot (limited isolation)                           │
│                                                       │
│  Process sees / as /new/root, but:                    │
│  - Other processes see the same mount table           │
│  - /proc, /sys still show host information            │
│  - Mount operations visible to other chrooted procs   │
│  - Can often be escaped                               │
│                                                       │
│  ─────────────────────────────────────────────────    │
│                                                       │
│  Mount Namespace (full isolation)                     │
│                                                       │
│  Complete independent mount table:                    │
│  - Private /proc, /sys, /dev                          │
│  - Mount/unmount invisible to other namespaces        │
│  - OverlayFS for container layers                     │
│  - tmpfs for /run, /tmp                               │
│  - Cannot be escaped without CAP_SYS_ADMIN            │
└──────────────────────────────────────────────────────┘
```

### Creating a Mount Namespace

```bash
# Create an isolated mount namespace with a private /proc
sudo unshare --mount --fork bash

# Verify isolation
mount | wc -l    # Fewer mounts than host
ls /proc         # Fresh /proc

# Mount something — invisible to host
mkdir /tmp/mnt
mount -t tmpfs tmpfs /tmp/mnt
echo "private" > /tmp/mnt/secret.txt

# From host terminal:
cat /tmp/mnt/secret.txt   # "No such file" — isolated!
```

### pivot_root vs chroot

Containers use `pivot_root` to change the root filesystem, not `chroot`. The difference matters:

```
chroot:
  - Changes root directory pointer
  - Old root still accessible if process has fd to it
  - Mount table shared with parent namespace
  - Can be escaped via open file descriptors

pivot_root:
  - Actually moves root mount to a new mount namespace
  - Old root becomes a regular mount that can be unmounted
  - Combined with mount namespace, provides full isolation
  - Used by runc/crun in every container startup
```

```bash
# Simulate what containers do at startup
mkdir -p /tmp/newroot
# (populate with rootfs content — in Docker this is the image layers)

sudo unshare --mount --fork bash

# Mount the new root
mount --bind /tmp/newroot /tmp/newroot

# pivot_root: move to new root, unmount old
cd /tmp/newroot
mkdir old_root
pivot_root . old_root

# Now we're in the new root
ls /
# bin  etc  lib  proc  sys  usr  var  old_root

# Unmount old root completely
umount -l /old_root
rm -rf /old_root

# The old host filesystem is gone
ls /old_root   # "No such file or directory"
```

> ⚠️ **Warning:** `pivot_root` requires `CAP_SYS_ADMIN` in the mount namespace. In user namespaces, this is available to unprivileged processes inside the namespace.

### Mount Propagation

Mount events can propagate between namespaces. The propagation type controls this:

```
┌────────────────────────────────────────────────────────┐
│  Mount Propagation Types                                │
├──────────────────────┬─────────────────────────────────┤
│  MS_PRIVATE          │ No propagation at all           │
│                      │ Changes are invisible           │
├──────────────────────┼─────────────────────────────────┤
│  MS_SHARED           │ Events propagate both ways      │
│                      │ Mount in A appears in B         │
├──────────────────────┼─────────────────────────────────┤
│  MS_SLAVE            │ One-way from master to slave    │
│                      │ Master changes appear in slave  │
│                      │ Slave changes are private       │
├──────────────────────┼─────────────────────────────────┤
│  MS_UNBINDABLE       │ Cannot be bind-mounted          │
│                      │ Private + unbindable            │
└──────────────────────┴─────────────────────────────────┘
```

```bash
# Check current propagation
cat /proc/self/mountinfo | grep " / "
# Look for shared/master/slave markers

# Docker makes container mounts private by default
# You can see this in container mountinfo:
cat /proc/<container_pid>/mountinfo | head -20

# Example output:
# 123 89 253:2 / / rw,relatime master:1 - ext4 /dev/vda1 rw
# 124 123 0:25 / /proc rw,nosuid,nodev,noexec,relatime - proc proc rw
# 125 123 0:26 / /sys rw,nosuid,nodev,noexec,relatime - sysfs sysfs rw
# 126 123 0:5 / /dev rw,nosuid - devtmpfs devtmpfs rw
```

---

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

---

## 6. cgroup Namespace

### cgroup v1 vs v2

The cgroup namespace provides an isolated view of the cgroup hierarchy. Without it, a container can see the entire host cgroup tree.

```
┌─────────────────────────────────────────────────────────────┐
│  cgroup v1 (legacy)                                          │
│                                                              │
│  /sys/fs/cgroup/                                             │
│  ├── cpu/          ← separate hierarchy for CPU              │
│  ├── memory/       ← separate hierarchy for memory          │
│  ├── blkio/        ← separate hierarchy for I/O             │
│  ├── devices/      ← separate hierarchy for devices         │
│  ├── pids/         ← separate hierarchy for PIDs            │
│  ├── freezer/      ← separate hierarchy for freeze          │
│  └── net_cls/      ← separate hierarchy for net class       │
│                                                              │
│  Each controller mounted at different paths                  │
│  Complex, hard to manage, inconsistent                       │
├─────────────────────────────────────────────────────────────┤
│  cgroup v2 (unified)                                         │
│                                                              │
│  /sys/fs/cgroup/                                             │
│  └── (unified tree)                                          │
│      ├── system.slice/                                       │
│      │   └── containerd.service/                             │
│      ├── user.slice/                                         │
│      │   └── user-1000.slice/                                │
│      └── workload.slice/                                     │
│          └── container-abc123/                                │
│              ├── cpu.max     ← bandwidth limit               │
│              ├── memory.max  ← hard memory limit             │
│              ├── io.max      ← I/O bandwidth limit           │
│              └── pids.max    ← process count limit           │
│                                                              │
│  Single unified hierarchy — all controllers in one tree      │
│  Cleaner, better pressure accounting (PSI), eBPF integration │
└─────────────────────────────────────────────────────────────┘
```

### cgroup Namespace Isolation

```bash
# Without cgroup namespace, container sees host cgroup tree:
ls /sys/fs/cgroup/
# blkio  cpu  cpuacct  cpu,cpuacct  cpuset  devices  freezer
# health  hugetlb  memory  net_cls  net_prio  pids  systemd

# With cgroup namespace, container sees itself at the root:
ls /sys/fs/cgroup/
# cgroup.controllers  cgroup.events  cgroup.max.depth
# cgroup.max.descendants  cgroup.procs  cgroup.stat
# cpu.max  memory.current  memory.max  pids.current  ...

# The container thinks its cgroup IS the root of the tree
# But on host, it's actually nested under:
# /sys/fs/cgroup/system.slice/containerd/container-abc123/
```

```bash
# Create a cgroup namespace
sudo unshare --cgroup bash

# View cgroup root
cat /proc/self/cgroup
# 0::/

# Without --cgroup, you'd see the full path:
# 0::/system.slice/containerd.service/container-abc123

# Check cgroup controllers available
cat /proc/self/cgroup.controllers
# cpu cpuset io hugetlb memory pids rdma misc
```

### Setting Resource Limits

```bash
# cgroup v2 resource limits (modern approach)
# Create a cgroup for a workload
sudo mkdir -p /sys/fs/cgroup/workload

# Set memory limit to 256MB
echo "268435456" | sudo tee /sys/fs/cgroup/workload/memory.max

# Set CPU quota (50% of one CPU)
echo "50000 100000" | sudo tee /sys/fs/cgroup/workload/cpu.max

# Set max number of PIDs
echo "100" | sudo tee /sys/fs/cgroup/workload/pids.max

# Move a process into this cgroup
echo $! | sudo tee /sys/fs/cgroup/workload/cgroup.procs

# Verify limits are applied
cat /sys/fs/cgroup/workload/memory.max
cat /sys/fs/cgroup/workload/cpu.max
cat /sys/fs/cgroup/workload/pids.max

# Check current usage
cat /sys/fs/cgroup/workload/memory.current
cat /sys/fs/cgroup/workload/cpu.stat
cat /sys/fs/cgroup/workload/pids.current
```

```bash
# cgroup v1 resource limits (legacy, still common)
# Memory limit
echo 268435456 > /sys/fs/cgroup/memory/workload/memory.limit_in_bytes

# CPU limit (shares-based, not hard cap)
echo 512 > /sys/fs/cgroup/cpu/workload/cpu.shares

# PID limit
echo 100 > /sys/fs/cgroup/pids/workload/pids.max

# List all controllers
mount | grep cgroup
```

> 🔍 **Reverse Engineering Insight:** Docker's `--memory` flag maps directly to `memory.max` in cgroup v2. `--cpus` maps to `cpu.max`. `--pids-limit` maps to `pids.max`. When you set `docker run --memory=512m --cpus=2`, you're writing cgroup files behind the scenes.

---

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

---

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

---

## 9. Namespace Security

### Known Attack Vectors

```
┌─────────────────────────────────────────────────────────────────┐
│  NAMESPACE ESCAPE VECTORS                                        │
│                                                                  │
│  1. Kernel exploits (CVEs in namespace code)                    │
│     → CVE-2022-0185: heap overflow in legacy_parse_param        │
│     → CVE-2022-0492: cgroup escape via write                    │
│     → CVE-2024-1086: nf_tables privilege escalation             │
│                                                                  │
│  2. Misconfigured capabilities                                   │
│     → CAP_SYS_ADMIN allows mounting host filesystem             │
│     → CAP_SYS_PTRACE allows /proc inspection                    │
│     → CAP_NET_ADMIN allows network reconfiguration              │
│                                                                  │
│  3. Dangerous bind mounts                                        │
│     → /var/run/docker.sock: host Docker API access              │
│     → /proc/sysrq-trigger: kernel magic SysRq                   │
│     → /dev: device access escapes namespace                      │
│                                                                  │
│  4. User namespace escapes                                       │
│     → CVE-2021-3493: overlayfs user namespace bypass            │
│     → CVE-2022-25636: nf_tables double-free                    │
│                                                                  │
│  5. Container runtime bugs                                        │
│     → runc CVE-2019-5736: overwrite host runc binary            │
│     → CVE-2024-21626: runc container escape via /proc/self/fd   │
└─────────────────────────────────────────────────────────────────┘
```

### Hardening Checklist

```bash
# 1. Drop ALL capabilities, add only what's needed
docker run --cap-drop=ALL --cap-add=NET_BIND_SERVICE nginx

# 2. Never run as privileged
# BAD:  docker run --privileged ...
# GOOD: docker run --cap-drop=ALL --cap-add=... nginx

# 3. Use read-only rootfs
docker run --read-only --tmpfs /tmp:rw,noexec,nosuid nginx

# 4. Restrict syscalls with seccomp
docker run --security-opt seccomp=default-profile.json nginx

# 5. Use AppArmor or SELinux
docker run --security-opt apparmor=docker-default nginx

# 6. Limit resources
docker run --memory=256m --cpus=1 --pids-limit=100 nginx

# 7. No new privileges
docker run --security-opt no-new-privileges nginx

# 8. Use user namespaces (rootless Docker)
# In /etc/docker/daemon.json:
# { "userns-remap": "default" }

# 9. Drop seccomp with additional restrictions
# 10. Use minimal images (distroless, alpine, scratch)
```

### Securing Namespace Operations

```bash
# Limit who can create namespaces
# /etc/sysctl.conf:
# kernel.unprivileged_userns_clone = 0   ← disable unprivileged user NS
# user.max_user_namespaces = 0           ← disable user NS entirely

# If disabling user namespaces breaks rootless containers:
# user.max_user_namespaces = 28633      ← default

# Check current namespace limits
cat /proc/sys/user/max_user_namespaces
cat /proc/sys/user/max_pid_namespaces
cat /proc/sys/user/max_net_namespaces
cat /proc/sys/user/max_mnt_namespaces
cat /proc/sys/user/max_ipc_namespaces
cat /proc/sys/user/max_uts_namespaces

# Audit namespace creation
sudo auditctl -a always,exit -F arch=b64 -S clone -S unshare -k namespace_creation
sudo ausearch -k namespace_creation
```

### Detecting Container Escape

```bash
# Signs of namespace escape on host:
# 1. Unexpected processes in host PID namespace
ps aux | grep -v "\[" | grep -v systemd | grep -v bash

# 2. Unexpected network connections
ss -tlnp | grep -v -E "systemd|sshd|containerd"

# 3. Container process with host cgroup
cat /proc/<PID>/cgroup   # If root "/" — suspicious

# 4. Container with host PID namespace
ls -la /proc/<PID>/ns/pid  # Compare with host PID 1
readlink /proc/1/ns/pid     # Should differ from container PID

# 5. Unexpected mount points
cat /proc/<PID>/mountinfo | grep -v overlay | grep -v proc | grep -v sys

# 6. Container with CAP_SYS_ADMIN (dangerous)
capsh --decode=$(grep CapPrm /proc/<PID>/status | awk '{print $2}')

# 7. Use Falco for runtime detection
# falco --rule /etc/falco/rules.d/container-escape.yaml
```

> ⚠️ **Warning:** Namespaces alone are NOT security boundaries. The kernel is the security boundary. A kernel exploit can escape any namespace. Always combine namespaces with seccomp, AppArmor/SELinux, capability dropping, and minimal images for defense in depth.

---

## 15 Hands-On Practices

### Practice 1: Create and Explore PID Namespace

```bash
# Create an isolated PID namespace with /proc mounted
sudo unshare --pid --fork --mount-proc bash

# Inside the namespace:
ps aux
# Should show only 1-2 processes (bash + ps)

# Check PID 1
cat /proc/1/cmdline | tr '\0' ' '
# Should be "bash" or your entrypoint

# Check what PID you are on the host (from another terminal)
ps aux | grep "unshare"
# Note the host PID — different from namespace PID

# Verify namespace boundary
readlink /proc/self/ns/pid

# Cleanup
exit
```

✅ **Expected**: PID namespace shows only 2-3 processes. Host PID numbers differ.

### Practice 2: Multi-Level PID Namespace Tree

```bash
# Level 0: Create Level 1
sudo unshare --pid --fork --mount-proc bash
echo "Level 1 PID 1 = $$"

# Level 1: Create Level 2 (from inside Level 1)
unshare --pid --fork --mount-proc bash
echo "Level 2 PID 1 = $$"

# Check /proc/self/status in Level 2
grep NSpid /proc/self/status
# NSpid:  1  1     ← PID 1 in Level 2, PID 1 in Level 1
# (on host this is something like PID 5001)

# Check from Level 0 (another terminal)
lsns -t pid
# Should show 3 PID namespaces

# Cleanup both levels
exit; exit
```

✅ **Expected**: Three PID namespaces visible, with nested PID numbering.

### Practice 3: Network Namespace Isolation

```bash
# Create isolated network namespace
sudo ip netns add test_net

# Verify: no network connectivity inside
sudo ip netns exec test_net ping -c 1 8.8.8.8
# Should fail — no route

# Check interfaces
sudo ip netns exec test_net ip link show
# Only "lo" (loopback) — no eth0

# Bring up loopback
sudo ip netns exec test_net ip link set lo up
sudo ip netns exec test_net ping -c 1 127.0.0.1
# Should work

# Cleanup
sudo ip netns delete test_net
```

✅ **Expected**: Namespace has only loopback, no internet access.

### Practice 4: veth Pair Connectivity

```bash
# Create two namespaces connected by a veth pair
sudo ip netns add left
sudo ip netns add right

# Create veth pair
sudo ip link add veth-l type veth peer name veth-r

# Move ends to respective namespaces
sudo ip link set veth-l netns left
sudo ip link set veth-r netns right

# Configure left
sudo ip netns exec left ip addr add 10.0.0.1/24 dev veth-l
sudo ip netns exec left ip link set veth-l up
sudo ip netns exec left ip link set lo up

# Configure right
sudo ip netns exec right ip addr add 10.0.0.2/24 dev veth-r
sudo ip netns exec right ip link set veth-r up
sudo ip netns exec right ip link set lo up

# Test
sudo ip netns exec left ping -c 3 10.0.0.2
# Should succeed

# Cleanup
sudo ip netns delete left
sudo ip netns delete right
sudo ip link del veth-l 2>/dev/null
```

✅ **Expected**: Bidirectional ping between two isolated network namespaces.

### Practice 5: Bridge Networking with Three Namespaces

```bash
# Create bridge
sudo ip link add br0 type bridge
sudo ip addr add 10.0.0.1/24 dev br0
sudo ip link set br0 up

# Create 3 namespaces and connect to bridge
for i in a b c; do
    sudo ip netns add ns${i}
    sudo ip link add veth${i}-h type veth peer name veth${i}-c
    sudo ip link set veth${i}-c netns ns${i}
    sudo ip link set veth${i}-h master br0
    sudo ip link set veth${i}-h up
    sudo ip netns exec ns${i} ip addr add 10.0.0.${i%a+1}/24 dev veth${i}-c 2>/dev/null
    sudo ip netns exec ns${i} ip link set veth${i}-c up
    sudo ip netns exec ns${i} ip link set lo up
done

# Assign IPs: a=10.0.0.10, b=10.0.0.11, c=10.0.0.12
sudo ip netns exec a ip addr flush dev vetha-c
sudo ip netns exec a ip addr add 10.0.0.10/24 dev vetha-c
sudo ip netns exec b ip addr flush dev vethb-c
sudo ip netns exec b ip addr add 10.0.0.11/24 dev vethb-c
sudo ip netns exec c ip addr flush dev vethc-c
sudo ip netns exec c ip addr add 10.0.0.12/24 dev vethc-c

# Test: all three can communicate
sudo ip netns exec a ping -c 1 10.0.0.11
sudo ip netns exec b ping -c 1 10.0.0.12
sudo ip netns exec a ping -c 1 10.0.0.12

# Cleanup
for i in a b c; do sudo ip netns delete ns${i}; done
sudo ip link del br0
```

✅ **Expected**: Three namespaces communicate through the L2 bridge.

### Practice 6: Mount Namespace Isolation

```bash
# Create mount namespace
sudo unshare --mount bash

# Create a private directory with a secret file
mkdir -p /tmp/private
echo "secret-data" > /tmp/private/secret.txt

# Mount a tmpfs
mount -t tmpfs tmpfs /tmp/private

# Verify inside namespace
cat /tmp/private/secret.txt   # "secret-data"

# From host (another terminal):
cat /tmp/private/secret.txt
# Either "No such file" or shows old content (before tmpfs mount)
# The mount is invisible to host

# Create a read-only mount
mkdir /tmp/readonly
mount -t tmpfs -o ro tmpfs /tmp/readonly
echo "test" > /tmp/readonly/file 2>&1
# Read-only filesystem error

# Cleanup
exit
```

✅ **Expected**: Mount operations invisible from host.

### Practice 7: UTS Namespace Hostname Isolation

```bash
# Original hostname
hostname

# Create UTS namespace
sudo unshare --uts bash

# Change hostname
hostname container-test
hostname
# "container-test"

# From host (another terminal):
hostname
# Original hostname — unchanged

# Verify via syscall
cat /proc/sys/kernel/hostname
# "container-test" (inside namespace)

# Clean up
exit
hostname  # Back to original
```

✅ **Expected**: Hostname changes are contained within the UTS namespace.

### Practice 8: IPC Namespace Isolation

```bash
# Create IPC namespace
sudo unshare --ipc bash

# Create IPC objects
ipcmk -M 1024      # Shared memory
ipcmk -S 1         # Semaphore
ipcmk -Q           # Message queue

# List them
ipcs

# From host (another terminal):
ipcs
# These objects should NOT appear — IPC namespace isolates them

# Cleanup
ipcrm --all=shm
ipcrm --all=msg
ipcrm --all=sem
exit
```

✅ **Expected**: IPC objects are invisible across namespace boundaries.

### Practice 9: User Namespace Rootless Container

```bash
# Create a user namespace with PID and mount
unshare --user --pid --mount --fork --map-root-user bash

# We are root inside
id
# uid=0(root) gid=0(root) groups=0(root)

# Check mapped UIDs
cat /proc/self/uid_map
#          0     100000      65536

# Verify: on host we're still unprivileged
# From another terminal:
ps aux | grep "unshare"
# Shows original user (e.g., tim), NOT root

# Mount proc in PID namespace
mount -t proc proc /proc
ps aux
# Shows only our processes

# Try to access host files (should fail)
ls /root/
# Permission denied — we're not real root

# Exit user namespace
exit
```

✅ **Expected**: UID 0 inside namespace, unprivileged outside.

### Practice 10: cgroup Namespace and Resource Limits

```bash
# Create a cgroup with memory limit
sudo mkdir -p /sys/fs/cgroup/limited_workload

# Set 50MB memory limit
echo 52428800 | sudo tee /sys/fs/cgroup/limited_workload/memory.max

# Set PID limit
echo 20 | sudo tee /sys/fs/cgroup/limited_workload/pids.max

# Run a process inside this cgroup
echo $$ | sudo tee /sys/fs/cgroup/limited_workload/cgroup.procs

# Verify limits
cat /sys/fs/cgroup/limited_workload/memory.max
# 52428800
cat /sys/fs/cgroup/limited_workload/pids.max
# 20

# Check memory pressure events
cat /sys/fs/cgroup/limited_workload/memory.events
# low 0
# high 0
# max 0

# Cleanup
echo $$ | sudo tee /sys/fs/cgroup/cgroup.procs
sudo rmdir /sys/fs/cgroup/limited_workload
```

✅ **Expected**: cgroup limits are enforced on the process.

### Practice 11: nsenter into Container Namespace

```bash
# Start a container
docker run -d --name ns_demo nginx:alpine
sleep 2

# Get container PID
PID=$(docker inspect --format '{{.State.Pid}}' ns_demo)
echo "Container PID on host: $PID"

# View container namespaces
echo "=== Namespaces ==="
for ns in pid net mnt uts ipc; do
    echo "$ns: $(readlink /proc/$PID/ns/$ns)"
done

# Enter the container's PID namespace
sudo nsenter -t $PID -p -- ps aux
# Shows processes INSIDE the container

# Enter the container's network namespace
sudo nsenter -t $PID -n -- ip addr
# Shows container's network interfaces

# Enter the container's mount namespace and inspect filesystem
sudo nsenter -t $PID -m -- ls /usr/share/nginx/html/

# Cleanup
docker rm -f ns_demo
```

✅ **Expected**: Host tools can inspect container internals via nsenter.

### Practice 12: Build a Container from Scratch

```bash
# Create a minimal rootfs
mkdir -p /tmp/mycontainer/{bin,lib,lib64,etc,proc,sys,dev,tmp}

# Copy essential binaries (static)
cp /bin/busybox /tmp/mycontainer/bin/
# Or download: wget https://busybox.net/downloads/binaries/...

# Create minimal /etc files
echo "root:x:0:0:root:/root:/bin/sh" > /tmp/mycontainer/etc/passwd
echo "root:x:0:" > /tmp/mycontainer/etc/group
echo "mycontainer" > /tmp/mycontainer/etc/hostname

# Create the container with namespaces
sudo unshare --pid --net --mount --uts --ipc --fork \
    bash -c "
        # Set hostname
        hostname mycontainer

        # Mount /proc
        mount -t proc proc /tmp/mycontainer/proc

        # Pivot root
        cd /tmp/mycontainer
        mkdir -p old_root
        mount --bind . .
        pivot_root . old_root

        # Unmount old root
        umount -l /old_root 2>/dev/null

        # Verify
        echo '=== Inside Container ==='
        hostname
        ps aux
        ls /
        id

        # Cleanup
        umount /proc 2>/dev/null
    "

# Cleanup
sudo rm -rf /tmp/mycontainer
```

✅ **Expected**: You've built a working container from namespaces alone.

### Practice 13: Network Namespace with NAT

```bash
# Create namespace and connect to host
sudo ip netns add nat_ns
sudo ip link add veth-host type veth peer name veth-ns
sudo ip link set veth-ns netns nat_ns
sudo ip addr add 10.100.0.1/24 dev veth-host
sudo ip link set veth-host up
sudo ip netns exec nat_ns ip addr add 10.100.0.2/24 dev veth-ns
sudo ip netns exec nat_ns ip link set veth-ns up
sudo ip netns exec nat_ns ip link set lo up
sudo ip netns exec nat_ns ip route add default via 10.100.0.1

# Enable forwarding and NAT
sudo sysctl -w net.ipv4.ip_forward=1
sudo iptables -t nat -A POSTROUTING -s 10.100.0.0/24 -o eth0 -j MASQUERADE
sudo iptables -A FORWARD -i veth-host -o eth0 -j ACCEPT
sudo iptables -A FORWARD -i eth0 -o veth-host -m state --state RELATED,ESTABLISHED -j ACCEPT

# Test internet access from namespace
sudo ip netns exec nat_ns ping -c 2 8.8.8.8

# Cleanup
sudo ip netns delete nat_ns
sudo ip link del veth-host
sudo iptables -t nat -D POSTROUTING -s 10.100.0.0/24 -o eth0 -j MASQUERADE
sudo iptables -D FORWARD -i veth-host -o eth0 -j ACCEPT
sudo iptables -D FORWARD -i eth0 -o veth-host -m state --state RELATED,ESTABLISHED -j ACCEPT
```

✅ **Expected**: Namespace reaches internet through host NAT.

### Practice 14: Inspect All Docker Container Namespaces

```bash
# Create several containers
docker run -d --name web nginx:alpine
docker run -d --name db postgres:alpine

# Get their PIDs
WEB_PID=$(docker inspect --format '{{.State.Pid}}' web)
DB_PID=$(docker inspect --format '{{.State.Pid}}' db)

# Compare namespaces
echo "=== Web Container ==="
ls -la /proc/$WEB_PID/ns/

echo ""
echo "=== DB Container ==="
ls -la /proc/$DB_PID/ns/

# Verify they share NO namespaces (all inodes differ)
echo ""
echo "=== Namespace Comparison ==="
for ns in pid net mnt uts ipc user cgroup; do
    WEB_NS=$(readlink /proc/$WEB_PID/ns/$ns)
    DB_NS=$(readlink /proc/$DB_PID/ns/$ns)
    if [ "$WEB_NS" = "$DB_NS" ]; then
        echo "$ns: SHARED ($WEB_NS)"
    else
        echo "$ns: ISOLATED"
    fi
done

# Cleanup
docker rm -f web db
```

✅ **Expected**: All namespaces show "ISOLATED" — complete container isolation.

### Practice 15: Comprehensive Namespace Dashboard Script

```bash
#!/bin/bash
# ns_dashboard.sh — Display all namespace information for a process

PID=${1:-$$}

echo "═══════════════════════════════════════════════════════════"
echo "  NAMESPACE DASHBOARD for PID $PID"
echo "═══════════════════════════════════════════════════════════"

echo ""
echo "Process Info:"
ps -p $PID -o pid,ppid,user,comm,args --no-headers 2>/dev/null || echo "Process not found"

echo ""
echo "Namespaces:"
for ns in pid net mnt uts ipc user cgroup time; do
    LINK=$(readlink /proc/$PID/ns/$ns 2>/dev/null || echo "N/A")
    INODE=$(echo "$LINK" | grep -oP '\d+')
    echo "  $ns: $LINK"
done

echo ""
echo "Caps (hex):"
grep Cap /proc/$PID/status 2>/dev/null

echo ""
echo "Mount Points (top 10):"
head -10 /proc/$PID/mountinfo 2>/dev/null || echo "N/A"

echo ""
echo "Network Interfaces:"
nsenter -t $PID -n ip addr 2>/dev/null || echo "N/A"

echo ""
echo "Cgroup:"
cat /proc/$PID/cgroup 2>/dev/null || echo "N/A"

echo ""
echo "Ulimits:"
grep -E "Max|" /proc/$PID/limits 2>/dev/null

echo "═══════════════════════════════════════════════════════════"
```

```bash
chmod +x ns_dashboard.sh

# Dashboard for current process
./ns_dashboard.sh

# Dashboard for a Docker container
CONTAINER_PID=$(docker inspect --format '{{.State.Pid}}' web)
sudo ./ns_dashboard.sh $CONTAINER_PID
```

✅ **Expected**: Complete namespace overview for any process or container.

---

## Deep Understanding

### Why Containers Are NOT Virtual Machines

```
┌─────────────────────────────────────────────────────────────────┐
│  VIRTUAL MACHINE                                                │
│                                                                  │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐                        │
│  │  App A   │ │  App B   │ │  App C   │                        │
│  │  Libs    │ │  Libs    │ │  Libs    │                        │
│  │  Kernel  │ │  Kernel  │ │  Kernel  │  ← Full kernel copies  │
│  ├──────────┤ ├──────────┤ ├──────────┤                        │
│  │  VM      │ │  VM      │ │  VM      │  ← Hypervisor (KVM)   │
│  │  Monitor │ │  Monitor │ │  Monitor │                        │
│  └──────────┘ └──────────┘ └──────────┘                        │
│  ════════════════════════════════════════                        │
│              Host Kernel + Hardware                              │
├─────────────────────────────────────────────────────────────────┤
│  CONTAINER                                                       │
│                                                                  │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐                        │
│  │  App A   │ │  App B   │ │  App C   │  ← Processes only      │
│  │  Libs    │ │  Libs    │ │  Libs    │                        │
│  └────┬─────┘ └────┬─────┘ └────┬─────┘                        │
│       │             │             │                              │
│  ┌────┴─────────────┴─────────────┴────┐                        │
│  │   Namespaces (PID,NET,MNT,UTS,IPC)  │  ← View isolation     │
│  ├─────────────────────────────────────┤                        │
│  │   Cgroups (CPU, memory, I/O limits) │  ← Resource limits    │
│  ├─────────────────────────────────────┤                        │
│  │   Seccomp (syscall filtering)       │  ← Kernel API filter  │
│  ├─────────────────────────────────────┤                        │
│  │   Capabilities (privilege control)   │  ← Permission control│
│  ════════════════════════════════════════                        │
│              Host Kernel + Hardware                              │
│  (Same kernel — no hardware virtualization)                     │
└─────────────────────────────────────────────────────────────────┘
```

### Complete Namespace Interaction Model

```
Application
    │
    ▼
┌─────────────────────────────────────────────────────────┐
│  Namespace Layer (isolation / visibility)                │
│                                                          │
│  PID NS:    "Which processes can I see?"                │
│  NET NS:    "Which network stack do I use?"             │
│  MNT NS:    "Which filesystem view do I have?"          │
│  UTS NS:    "What is my hostname?"                      │
│  IPC NS:    "Which IPC objects can I access?"           │
│  USER NS:   "Who am I? What can I do?"                  │
│  CGROUP NS: "Which cgroup tree do I see?"               │
└─────────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────┐
│  Security Layer (access control / restriction)           │
│                                                          │
│  Seccomp:       Syscall whitelist/blacklist              │
│  Capabilities:  Fine-grained root privileges             │
│  AppArmor/SELinux: Mandatory access control              │
│  Read-only FS:  Prevent runtime modifications            │
│  No-new-privs:  Prevent privilege escalation via exec   │
└─────────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────┐
│  Resource Layer (limits / accounting)                    │
│                                                          │
│  CPU:     cpu.max (bandwidth), cpuset (affinity)        │
│  Memory:  memory.max (limit), memory.swap.max           │
│  I/O:     io.max (bandwidth), io.weight (shares)        │
│  PIDs:    pids.max (process count)                      │
│  Network: tc qdisc (bandwidth shaping)                  │
└─────────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────┐
│  KERNEL                                                 │
│  Shared: scheduler, VFS, drivers, syscalls              │
│  Isolated: only via namespaces, cgroups, filters        │
└─────────────────────────────────────────────────────────┘
```

### Container Startup Sequence

```
1. docker run nginx
         │
2. containerd receives image + config
         │
3. containerd calls runc with OCI bundle
         │
4. runc: clone() with namespace flags
         │
         ├── CLONE_NEWUSER    → Map UIDs
         ├── CLONE_NEWPID     → PID isolation
         ├── CLONE_NEWNET     → Network stack
         ├── CLONE_NEWNS      → Mount table
         ├── CLONE_NEWUTS     → Hostname
         ├── CLONE_NEWIPC     → IPC objects
         └── CLONE_NEWCGROUP  → Cgroup view
         │
5. runc: setup cgroups (write to /sys/fs/cgroup/)
         │
6. runc: configure network (veth + bridge + iptables)
         │
7. runc: apply seccomp filters
         │
8. runc: apply AppArmor/SELinux profile
         │
9. runc: pivot_root into container filesystem
         │
10. runc: exec entrypoint (nginx) → PID 1
         │
11. nginx serves requests, containerd monitors
```

---

## Command Reference

| Task | Command |
|------|---------|
| List namespaces of a process | `ls -la /proc/<PID>/ns/` |
| List all namespaces on system | `lsns` |
| List namespaces by type | `lsns -t pid` / `lsns -t net` |
| Compare two process namespaces | `readlink /proc/<PID1>/ns/pid /proc/<PID2>/ns/pid` |
| Create PID namespace | `unshare --pid --fork --mount-proc bash` |
| Create network namespace | `ip netns add <name>` |
| Execute in namespace | `ip netns exec <name> <cmd>` |
| Enter all namespaces of process | `nsenter -t <PID> --all` |
| Enter specific namespace | `nsenter -t <PID> -n -m -p bash` |
| Create veth pair | `ip link add <a> type veth peer name <b>` |
| Create bridge | `ip link add <name> type bridge` |
| Set namespace hostname | `hostname <name>` (inside UTS NS) |
| Create user namespace | `unshare --user --map-root-user bash` |
| View user namespace mapping | `cat /proc/<PID>/uid_map` |
| Create cgroup v2 | `mkdir /sys/fs/cgroup/<name>` |
| Set memory limit | `echo <bytes> > /sys/fs/cgroup/<name>/memory.max` |
| Set CPU limit | `echo "<quota> <period>" > /sys/fs/cgroup/<name>/cpu.max` |
| Move process to cgroup | `echo <PID> > /sys/fs/cgroup/<name>/cgroup.procs` |
| View mount propagation | `cat /proc/self/mountinfo \| grep shared` |
| List all PID namespaces | `lsns -t pid` |
| View namespace limits | `cat /proc/sys/user/max_*_namespaces` |
| Container namespace info | `docker inspect --format '{{.State.Pid}}' <container>` |
| Decode capabilities | `capsh --decode=<hex>` |

---

## What's Coming in Part 65

```
┌─────────────────────────────────────────────────────────┐
│   Part 65: PAM & Centralized Authentication             │
├─────────────────────────────────────────────────────────┤
│   • Pluggable Authentication Modules (PAM) architecture │
│   • PAM stack: auth, account, password, session         │
│   • Module types and control flags (required, sufficient│
│   • LDAP and Active Directory integration               │
│   • SSSD (System Security Services Daemon)              │
│   • Kerberos authentication (kinit, klist, ticket mgmt) │
│   • SSH key management and certificate authentication   │
│   • OAuth2 and OIDC for Linux systems                  │
│   • Centralized sudo policies via LDAP                  │
│   • SSSD caching and offline authentication            │
│   • MFA (Multi-Factor Authentication) with PAM          │
│   • Troubleshooting PAM: /var/log/secure, pam_debug     │
│   • Real-world: join Linux server to Active Directory    │
└─────────────────────────────────────────────────────────┘
```

---

## Self-Test

1. What is a Linux namespace and how does it differ from a virtual machine?
2. Which namespaces does `docker run` create by default?
3. Why must a process fork before entering a PID namespace?
4. What is PID 1's special responsibility in a PID namespace?
5. How does a veth pair work for container networking?
6. What is the difference between `chroot` and `pivot_root`?
7. Explain mount propagation types: private vs slave vs shared.
8. What does a USER namespace mapping of `0 100000 65536` mean?
9. What is the purpose of `/etc/subuid`?
10. How does the cgroup namespace differ between v1 and v2?
11. What command enters all namespaces of a running container?
12. What is the security risk of `docker run --privileged`?
13. Name three container escape CVEs and what they exploited.
14. Why is running a shell as PID 1 in a container problematic?
15. How does Docker implement `docker exec` internally?

**Answers:**
1. Namespace = kernel partitioning of global resources into isolated views; VMs use hardware virtualization (hypervisor), containers share the host kernel with resource isolation
2. All seven: PID, Network, Mount, UTS, IPC, User, Cgroup
3. PID namespace requires `CLONE_NEWPID` flag, which only works with `clone()` or `unshare()`; the calling process stays in the parent namespace; only the child enters the new PID namespace
4. PID 1 becomes the parent of all orphaned processes and must call `wait()` to reap zombies; if it doesn't, zombie processes accumulate
5. A veth pair creates two connected virtual network interfaces — packets entering one end exit the other; one end lives in the host, the other in the container namespace
6. `chroot` changes the apparent root directory but shares the mount table; `pivot_root` moves the root mount into a new mount namespace and can unmount the old root completely
7. Private = no propagation (changes invisible), Slave = one-way propagation (master → slave), Shared = bidirectional propagation (both see each other's mounts)
8. Inside the namespace, UID 0 maps to host UID 100000; a range of 65536 UIDs is available (0-65535 inside → 100000-165535 outside)
9. `/etc/subuid` defines subordinate UID ranges for users; tells the kernel which UID range a user can map in user namespaces (for rootless containers)
10. v1: separate hierarchies per controller (cpu, memory, blkio); v2: unified single tree with all controllers in one hierarchy; cgroup namespace hides the full tree, presenting the process's cgroup as root
11. `nsenter -t <PID> --all` enters all namespaces of the specified PID
12. `--privileged` grants ALL capabilities, access to all host devices, disables seccomp and AppArmor — effectively equivalent to root on the host
13. CVE-2019-5736 (runc binary overwrite), CVE-2022-0185 (heap overflow in legacy_parse_param), CVE-2024-21626 (runc /proc/self/fd escape)
14. Bash does not properly reap orphaned child processes; orphans become zombies in the PID namespace; use `tini` or `dumb-init` as PID 1 instead
15. Docker uses `nsenter -t <container_PID> --all` to enter the container's namespaces, then executes the specified command with the user's privileges within those namespaces

**Score:** 12/15 correct = ready for Part 65.

---

*Linux SysAdmin Course | Part 64 of ∞ | Reverse Engineering Approach*
*Previous → Part 63: eBPF & Modern Tracing*
*Next → Part 65: PAM & Centralized Authentication*

[← Previous](part63.md) | [Next →](part65.md)