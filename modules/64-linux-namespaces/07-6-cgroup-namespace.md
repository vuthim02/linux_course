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





[← Previous](06-5-uts-ipc-and-user.md) | [↑ Index](index.md) | [Next →](08-7-unshare-and-nsenter.md)
