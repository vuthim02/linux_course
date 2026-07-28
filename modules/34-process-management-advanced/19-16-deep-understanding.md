## 16. Deep Understanding

### The `task_struct` — The Kernel's Process Object

Defined in `include/linux/sched.h` (kernel source), `task_struct` is the center of process management. Key fields:

```c
struct task_struct {
    volatile long                   __state;
    unsigned int                    flags;
    pid_t                           pid;
    pid_t                           tgid;
    struct task_struct __rcu        *real_parent;
    struct task_struct __rcu        *parent;
    struct list_head                children;
    struct list_head                sibling;
    struct nsproxy                  *nsproxy;
    struct sched_entity             se;
    struct sched_rt_entity          rt;
    struct sched_dl_entity          dl;
    unsigned int                    policy;
    int                             prio;
    struct signal_struct            *signal;
    struct sighand_struct __rcu     *sighand;
    sigset_t                        blocked;
    struct sigpending               pending;
    struct mm_struct                *mm;
    struct fs_struct                *fs;
    struct files_struct             *files;
    struct css_set __rcu            *cgroups;
    int                             oom_score_adj;
    struct thread_struct            thread;
};
```

### CFS — Completely Fair Scheduler

Since kernel 2.6.23, the default scheduler is CFS.

**vruntime** — Each runnable task has a virtual runtime, stored in `task_struct->se.vruntime`. CFS always picks the task with the smallest `vruntime` (leftmost node in the red-black tree).

**Weight** — Niceness maps to weight via a table:

```c
static const int prio_to_weight[40] = {
 /* -20 */ 88761, 71755, 56483, 46273, 36291,
 /* -15 */ 29154, 23254, 18705, 14949, 11916,
 /* -10 */  9548,  7620,  6100,  4904,  3906,
 /*  -5 */  3121,  2501,  1991,  1586,  1277,
 /*   0 */  1024,   820,   655,   526,   423,
 /*   5 */   335,   272,   215,   172,   137,
 /*  10 */   110,    87,    70,    56,    45,
 /*  15 */    36,    29,    23,    18,    15,
};
```

After each scheduling tick:
```
vruntime += (delta_exec * NICE_0_LOAD) / se.load.weight
```

A process with nice -20 (weight 88761) accumulates vruntime ~87x slower than nice 19 (weight 15). So it gets ~87x more CPU time.

**Scheduling classes** (linked list):
1. `stop_sched_class` — highest priority (stop CPUs)
2. `dl_sched_class` — deadline scheduling
3. `rt_sched_class` — real-time (SCHED_FIFO, SCHED_RR)
4. `fair_sched_class` — CFS (SCHED_NORMAL, SCHED_BATCH)
5. `idle_sched_class` — idle task

### How Signals Are Delivered

1. **Signal generation**: Kernel or another process calls `__send_signal()` which sets a bit in `task->pending.signal` and, for real-time signals, appends to `task->pending.list`.

2. **Signal wake-up**: If the target is in interruptible sleep, `signal_wake_up()` sets `TIF_SIGPENDING` and wakes the task.

3. **Delivery**: On return to user space (via `ret_from_fork`, `ret_to_user`, or after a syscall), `do_signal()` is called:
   - Reads `task->pending`
   - For each signal not in `task->blocked`:
     - If user handler exists: sets up user stack with signal frame and returns to handler
     - If default: performs default action (terminate, stop, core dump, or ignore)

4. **User handler**: The kernel pushes a `sigframe` (including saved registers and signal info) onto the user stack. When the handler returns (via `sigreturn()`), the kernel restores the saved context.

5. **SIGKILL and SIGSTOP**: Handled directly in `__send_signal()` — they cannot be caught or ignored.

### Signal Delivery Flow

```
           │ Process is running in user mode
           ▼
  ┌─────────────────┐
  │ System call,     │
  │ timer, or return │ ◄─── Kernel checks task->pending
  │ from interrupt   │      while (sig) {
  └────────┬────────┘          find highest-priority pending
           ▼                   if not blocked, deliver
  ┌─────────────────┐
  │ Check pending    │
  │ signals          │
  └────────┬────────┘
           ▼
  ┌─────────────────┐
  │ Is signal        │
  │ blocked?         │──── Yes ──► Wait until unblocked
  └────────┬────────┘
           │ No
           ▼
  ┌─────────────────┐
  │ Dispatch action  │
  └────────┬────────┘
           │
      ┌────┴────┐
      ▼         ▼
   Terminate  User handler
   (default)  (sigaction())
```

### Zombie Reaping

When a process exits:
1. The kernel calls `exit_mm()`, `exit_files()`, `exit_fs()`, releasing most resources.
2. The task's state becomes `EXIT_ZOMBIE` (state Z).
3. The `task_struct` is NOT freed — it retains `pid`, `exit_code`, `signal_struct` (for status).
4. SIGCHLD is sent to the parent.
5. When the parent calls `wait()`, `waitpid()`, or `waitid()`, the kernel copies `exit_code`, calls `release_task()` which frees `task_struct` and releases the PID.

### Init as Reaper

PID 1 (init/systemd) is the reaper for orphaned processes. Any process whose parent dies before calling `wait()` is reparented to init:

```c
// kernel/exit.c: forget_original_parent()
struct task_struct *reaper = find_alive_thread(task->real_parent);
if (!reaper)
    reaper = task->signal->pids[PIDTYPE_PID].pid->tasks.next;
```

### Container Signals and `pid_namespace`

In container contexts, each container has its own PID namespace. PIDs are scoped:

```
Host PID:  1234  5678
Container:    1     2
```

- A host process can signal any container process
- A container process cannot signal a host process
- Container PID 1 does NOT get default signal handlers for SIGTERM/SIGINT
- When PID 1 in a container exits, the kernel terminates all processes in that PID namespace

### `pidfd` — Modern Process Handle

Since kernel 5.3, you can open a file descriptor to a process via `pidfd_open()` and use it for polling (`POLLIN` = process exited) or signaling (`pidfd_send_signal()`). This avoids PID reuse races.

Used by systemd for reliable service management and by container runtimes.





[← Previous](18-11-cgroups-v1-vs-v2.md) | [↑ Index](index.md) | [Next →](20-14-command-reference.md)
