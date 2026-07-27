## 11. Cgroups v1 vs v2 — Resource Control Groups

Cgroups (control groups) allow organizing processes hierarchically and distributing resources (CPU, memory, I/O) among them.

### cgroups v1 (Legacy)

Multiple separate hierarchies per resource:
```
/sys/fs/cgroup/
 ├── cpu/
 ├── cpuacct/
 ├── cpuset/
 ├── memory/
 └── blkio/
```

A process could be in different groups across hierarchies, leading to complexity.

### cgroups v2 (Unified)

Single hierarchy — all resources under `/sys/fs/cgroup/`. Default since kernel 5.x.

```
/sys/fs/cgroup/
 ├── cgroup.controllers      # what controllers are available
 ├── cgroup.subtree_control  # controllers enabled for children
 ├── system.slice/           # systemd services
 └── user.slice/             # user sessions
```

#### Check if v2 is active:
```
$ grep cgroup /proc/filesystems
nodev   cgroup2
$ stat -f /sys/fs/cgroup/
Filesystem type: cgroup2_fs
```

#### Create a cgroup v2 Memory Limit

```
# Create group
$ sudo mkdir /sys/fs/cgroup/mygroup

# Set memory limit (in bytes)
$ echo 100000000 | sudo tee /sys/fs/cgroup/mygroup/memory.max

# Add a process
$ echo $$ | sudo tee /sys/fs/cgroup/mygroup/cgroup.procs

# Check usage
$ cat /sys/fs/cgroup/mygroup/memory.current
```

#### CPU Limits in cgroups v2

```
# Set CPU weight (relative share, like nice)
$ echo 100 | sudo tee /sys/fs/cgroup/mygroup/cpu.weight
# Default is 100. Range 1-10000.
```

`cpu.weight` replaces v1's `cpu.shares` (range 2-262144, default 1024).

#### I/O Limits

```
# Limit write bandwidth to 10 MB/s on device 8:0
$ echo "8:0 wbps=10485760" | sudo tee /sys/fs/cgroup/mygroup/io.max
```

### systemd Slices

Every systemd service is a cgroup:
```
$ systemd-cgls
Control group /:
-.slice
├─init.scope
├─system.slice
│ ├─sshd.service
│ └─nginx.service
└─user.slice
  └─user-1000.slice
    └─session-1.scope
```

Resource limits via systemd unit:
```
[Service]
MemoryMax=500M
CPUWeight=200
IOWeight=100
TasksMax=500
```

### Cgroup v2 Comparison

| Resource | v1 file | v2 file |
|---|---|---|
| CPU | `cpu.shares` | `cpu.weight` |
| CPU quota | `cpu.cfs_quota_us` | `cpu.max` |
| Memory limit | `memory.limit_in_bytes` | `memory.max` |
| Memory + swap | `memory.memsw.limit_in_bytes` | `memory.swap.max` |
| I/O bandwidth | `blkio.throttle.write_bps_device` | `io.max` |
| I/O weight | `blkio.weight` | `io.weight` |
| PID limit | — | `pids.max` |

---



---

[← Previous](17-level-3-advanced-cgroups-cfs.md) | [↑ Index](index.md) | [Next →](19-16-deep-understanding.md)
