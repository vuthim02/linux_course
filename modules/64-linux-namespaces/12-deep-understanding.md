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



---

[← Previous](11-15-hands-on-practices.md) | [↑ Index](index.md) | [Next →](13-command-reference.md)
