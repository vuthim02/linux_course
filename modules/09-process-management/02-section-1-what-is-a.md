## 🔍 Section 1: What Is a Process?

A **process** is a running instance of a program. When you run `ls`, the kernel loads the `/usr/bin/ls` binary into memory, gives it a unique ID (PID), allocates resources, and starts executing it. That running instance is a process.

### Process vs Program

```
Program (on disk):     /usr/bin/python3
Process (in memory):   PID 1234 — running python3 script.py
```

A single program can have multiple processes. For example, your web browser might have 10+ processes, each handling a different tab.

### The Process ID (PID)

Every process gets a unique number called a **PID** (Process ID).

```bash
# PIDs are assigned sequentially
# PID 1 is always 'init' or 'systemd' — the first process started by the kernel
# PIDs wrap around when they reach the maximum
```

### The Process Tree

Every process except the first has a **parent process** (PPID). This creates a tree:

```
systemd (PID 1)
├── sshd (PID 100)
│   └── sshd (PID 200)
│       └── bash (PID 201)
│           ├── ps (PID 300)
│           └── vim (PID 301)
├── cron (PID 110)
├── nginx (PID 120)
│   ├── nginx (PID 121)
│   └── nginx (PID 122)
└── ...
```

```bash
# See your process tree
ps -ef --forest

# Or use pstree
pstree -p
```





[← Previous](01-what-you-will-achieve-in.md) | [↑ Index](index.md) | [Next →](03-section-2-ps-snapshot-of.md)
