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





[← Previous](01-what-you-will-achieve.md) | [↑ Index](index.md) | [Next →](03-2-pid-namespace.md)
