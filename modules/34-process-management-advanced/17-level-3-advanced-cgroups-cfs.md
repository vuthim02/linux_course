## ⭐ Level 3: Advanced — Cgroups, CFS Internals, and Deep Understanding

![Control groups v2 hierarchy diagram showing the unified cgroup tree](https://upload.wikimedia.org/wikipedia/commons/9/9d/Cgroup_v2_hierarchy.svg)

> *"Limits are not for normal operation — they're for when things go wrong. `ulimit` stops a fork bomb. Cgroups prevent a noisy neighbor from taking down production. The OOM killer is your last line of defense, not your first. Understanding these internals separates a sysadmin from a firefighter."*

### What You'll Cover
- Cgroups v1 vs v2: unified hierarchy, controller delegation
- Setting CPU, memory, and I/O limits with cgroups v2
- Pressure Stall Information (PSI): measuring resource contention
- The CFS scheduler: virtual runtime, time slices, nice values
- Signal delivery mechanics: how the kernel delivers signals to processes
- `task_struct` internals: the kernel's process descriptor
- `pidfd`: race-free process identification and signals

At the deepest level, process management is a kernel function. Understanding cgroups, schedulers, and signal delivery lets you control resources with precision impossible through userspace tools alone.

At this level you will master:

- **Cgroups v2**: Create a group: `mkdir /sys/fs/cgroup/mygroup`. Set limits: `echo "50000 100000" > mygroup/cpu.max` (50% of one CPU). `echo "1G" > mygroup/memory.max` limits memory. Move a process: `echo $PID > mygroup/cgroup.procs`. Cgroups v2 uses a unified hierarchy — all controllers in one tree.
- **PSI (Pressure Stall Information)**: `cat /proc/pressure/cpu` shows CPU pressure. `some` = at least one task was runnable but waiting. `full` = all tasks were waiting. This is more meaningful than load average for measuring resource contention.
- **CFS scheduler**: Completely Fair Scheduler allocates CPU time based on virtual runtime. Nice values weight the time slice — nice 0 gets 1024 weight, nice 19 gets 15 weight. The scheduler guarantees that a process with weight W gets at least W/(total weight) of CPU.
- **Signal delivery**: The kernel queues signals in `task_struct->pending`. When returning to userspace, the kernel checks for pending signals and invokes the handler. `sigaction()` registers handlers. Unhandled signals use the default action (terminate, stop, or ignore).
- **`pidfd`**: `pidfd_open()` returns a file descriptor referring to a process. Unlike PIDs, pidfds are race-free — the process cannot be reused while the fd is open. `pidfd_send_signal()` sends signals safely. This is the modern API for process management.


[← Previous](16-10-proc-filesystem-the-kernels.md) | [↑ Index](index.md) | [Next →](18-11-cgroups-v1-vs-v2.md)
