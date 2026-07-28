## 1. Processes vs Threads — PID, TID, TGID, PPID

### The `task_struct`

Every execution context in Linux — whether a heavyweight process or a lightweight thread — is represented internally by a single C struct: `task_struct` (defined in `include/linux/sched.h`). This struct is ~8-10 KB and contains:

```
task_struct
 ├── pid              (Process ID — unique in the PID namespace)
 ├── tgid             (Thread Group ID — same for all threads in a process)
 ├── real_parent      (who spawned this task)
 ├── parent           (who receives SIGCHLD — usually the same)
 ├── children         (list_head of child tasks)
 ├── sibling          (linked list of peer tasks)
 ├── signal           (struct signal_struct — shared by threads)
 ├── sighand          (signal handlers — shared by threads)
 ├── pending          (pending signals bitmask)
 ├── block            (blocked signals mask)
 ├── sched_info       (scheduler data, vruntime, prio)
 ├── mm               (memory descriptor — shared by threads)
 ├── fs               (filesystem context — cwd, root)
 ├── files            (open file descriptor table)
 ├── nsproxy          (namespace pointers)
 ├── cgroups          (control group membership)
 └── oom_score_adj    (OOM bias)
```

### PID vs TID vs TGID

| Identifier | Meaning | syscall to get it |
|---|---|---|
| PID (task->pid) | Unique ID for this task | `gettid()` |
| TID | Thread ID — same as PID for the main thread | `gettid()` |
| TGID | Thread Group ID — PID of the main thread | `getpid()` |
| PPID | Parent PID — `task->real_parent->pid` | `getppid()` |

A **process** is a thread group: all tasks sharing the same TGID. The main thread has `pid == tgid`. Worker threads have `pid != tgid`.

```
PID: 3100 (main thread, tgid=3100)
PID: 3101 (worker thread, tgid=3100)
PID: 3102 (worker thread, tgid=3100)
```

You can see this with `ps -eLf`:

```
$ ps -eLf | head -5
UID          PID    PPID     LWP  C NLWP STIME TTY          TIME CMD
root           1       0       1  0    1 19:09 ?        00:00:05 /usr/lib/systemd/systemd
tim        3200    3199    3200  0    4 09:16 pts/0    00:00:00 bash
tim        3200    3199    3201  0    4 09:16 pts/0    00:00:00 bash
```

### Kernel Threads vs User-Space Threads

**Kernel threads** are processes created by `kernel_thread()` that run only in kernel space, have no user-space `mm` (memory descriptor is NULL), and are visible in `ps` with names in brackets:

```
$ ps aux | grep '\[.*\]'
root         2  0.0  0.0      0     0 ?        S    09:15   0:00 [kthreadd]
root         3  0.0  0.0      0     0 ?        I<   09:15   0:00 [rcu_gp]
root        12  0.0  0.0      0     0 ?        S    09:15   0:00 [ksoftirqd/0]
root        14  0.0  0.0      0     0 ?        S    09:15   0:00 [migration/0]
```

**User-space threads** are implemented via `clone(CLONE_THREAD)` (usually called by `pthread_create()`). They share `mm`, `files`, `signal`, and `sighand`.

### Process Lifecycle

```
        fork() / clone()
              │
              ▼
         ┌──────────┐
         │   Ready   │ ←─────────────────┐
         │ (runnable)│                   │
         └────┬─────┘                   │
              │ schedule()              │
              ▼                         │
         ┌──────────┐    I/O wait      ┌──────────┐
         │  Running  │ ──────────────▶  │  Waiting │
         │ (on CPU)  │                  │ (blocked)│
         └────┬─────┘ ◀─────────────── └──────────┘
              │                        I/O complete
              │ exit()
              ▼
         ┌──────────┐
         │   Zombie │ ← waiting for parent to call wait()
         └──────────┘
```





[← Previous](03-level-1-basic-processes-signals.md) | [↑ Index](index.md) | [Next →](05-2-ps-snapshot-of-the.md)
