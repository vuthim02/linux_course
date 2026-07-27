# 🐧 Linux System Administrator — Complete Course
## Part 34 of ∞: Process Management — ps, kill, nice, renice, ulimit, OOM, cgroups

> **Reverse Engineering Approach:** Every running program on Linux is a *process*, and every process is an entry in a kernel-linked list called `task_struct`. Signals are kernel messages delivered via `task_struct`'s signal-pending bitmask. The OOM killer isn't magic — it's `select_bad_process()` iterating `/proc/*/oom_score`. Cgroups are filesystem-backed resource limits. By the end of this part, you will understand process management not as a collection of commands but as a traversal of kernel data structures exposed through `/proc`.

---

## 🎯 What You Will Achieve

| Level | Outcome |
|-------|---------|
| **Basic** | List, view, and terminate processes with `ps`, `pstree`, `kill`; understand process states; use `nice`/`renice`; manage background and foreground jobs; use `screen`/`tmux` |
| **Intermediary** | Find processes with `pgrep`/`pkill`; set resource limits with `ulimit`; understand OOM score basics; explore `/proc/PID/` files; use `nohup`/`disown`/`setsid` for persistent processes |
| **Advanced** | Understand `task_struct` internals, CFS scheduler, signal delivery mechanics; configure cgroups v2; tune OOM killer with `oom_score_adj`; understand zombie reaping, kernel threads, and `pidfd` |

---

## Table of Contents

1. Processes vs Threads — PID, TID, TGID, PPID
2. `ps` — Snapshot of the Process Table
3. `pstree` — Visualizing Process Hierarchy
4. `pgrep` / `pkill` — Finding and Signaling by Pattern
5. Signals — The Kernel's Inter-Process Message System
6. `kill` / `killall` — Sending Signals
7. `nice` / `renice` — Scheduling Priority
8. `ulimit` — Per-Process Resource Limits
9. OOM Killer — Out-of-Memory Resolution
10. `/proc` Filesystem — The Kernel's Process API
11. Cgroups v1 vs v2 — Resource Control Groups
12. Background / Foreground Jobs
13. Cron and Long-Running Processes — `screen`, `tmux`
14. Command Reference
15. 15 Hands-On Practices
16. Deep Understanding
17. Self-Test
18. What's Coming in Part 35

---

## ⭐ Level 1: Basic — Processes, Signals, and Job Control

![Unix process state transitions — from creation through running, sleeping, and zombie states](https://upload.wikimedia.org/wikipedia/commons/9/9f/Unix_process_states.png)

> *"A process is not a program. A program is inert — a file on disk. A process is a program in execution, complete with memory, file descriptors, a kernel stack, and a place in the scheduler's runqueue. Kill the right process, and you fix the problem; kill the wrong one, and you create one."*

---

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

---

## 2. `ps` — Snapshot of the Process Table

`ps` reads from `/proc` and formats it. Every field comes from `task_struct`.

### Process States

| State | `ps` Code | Meaning |
|---|---|---|
| Runnable | R | Ready to run (in the runqueue) or currently running |
| Sleeping | S | Interruptible sleep — waiting for an event |
| D Sleep | D | Uninterruptible sleep — usually I/O (cannot be killed) |
| Stopped | T | Stopped by signal (SIGSTOP) or trace (ptrace) |
| Zombie | Z | Dead; waiting for parent to `wait()` |
| Idle | I | Idle kernel thread (kernel 5.x+) |

### BSD vs UNIX Syntax

`ps` supports three syntax styles:

| Style | Example | Behavior |
|---|---|---|
| BSD | `ps aux` | Lists all processes with BSD-style columns |
| UNIX | `ps -ef` | Lists all processes with standard columns |
| GNU long | `ps --forest -eo pid,cmd` | Uses long options, custom output |

**Always use** `ps -eo` (explicit output specification) in scripts — it is portable and unambiguous.

```
$ ps -eo pid,ppid,tid,state,comm,nice,etime,args
```

### Custom Output Format

| Specifier | Field | Source |
|---|---|---|
| `pid` | Process ID | `task->pid` |
| `ppid` | Parent PID | `task->real_parent->pid` |
| `tid` | Thread ID (LWP) | same as pid for main thread |
| `nlwp` | Number of threads | `task->signal->nr_threads` |
| `state` | State code | `task->__state` |
| `comm` | Executable name | `task->comm` (16 chars) |
| `args` | Full command line | `task->mm->arg_start` |
| `nice` | Niceness value | `task->prio - 120` |
| `pri` | Kernel priority | `task->prio` |
| `psr` | Currently assigned CPU | `task->cpu` |
| `etime` | Elapsed time since start | calculated from `task->start_time` |
| `time` | Cumulative CPU time | `task->utime + task->stime` |
| `vsz` | Virtual memory size (KB) | `task->mm->total_vm * PAGE_SIZE` |
| `rss` | Resident set size (KB) | `task->mm->resident_vm * PAGE_SIZE` |

```
$ ps -eo pid,ppid,state,comm,nice,psr,etime,args --sort=-pcpu | head -20
```

### `--ppid` — Filter by Parent

```
$ ps -eo pid,ppid,state,comm --ppid 1
  PID  PPID S COMMAND
  420     1 S systemd-journal
  450     1 S systemd-udevd
  540     1 S cron
  550     1 S rsyslogd
```

### Forest View

```
$ ps -ef --forest
  PID  PPID  CMD
    1     0  /sbin/init
  540     1  \_ cron
  550     1  \_ rsyslogd
  900     1  \_ sshd
  950   900      \_ sshd: tim [priv]
  951   950          \_ sshd: tim@pts/0
  952   951              \_ -bash
 1200   952                  \_ ps -ef --forest
```

### Thread View

```
$ ps -eLf | grep httpd
apache   1234     1  1234  0   10    5   ... /usr/sbin/httpd
apache   1235  1234  1235  0   10    5   ... /usr/sbin/httpd
```

The fourth column is the LWP (TID).

### Real-World: Top CPU Consumers

```
$ ps -eo pid,ppid,%cpu,%mem,comm,user --sort=-%cpu | head -10
```

### Real-World: Zombie Detection

```
$ ps -eo pid,state,comm | grep -w Z
$ ps -eo pid,ppid,user,stat,comm --stat Z
```

---

## 3. `pstree` — Visualizing Process Hierarchy

```
$ pstree
systemd─┬─ModemManager───2*[{ModemManager}]
        ├─NetworkManager───2*[{NetworkManager}]
        ├─sshd───sshd───sshd───bash───pstree
        └─systemd-journald
```

### Useful Options

| Option | Effect |
|---|---|
| `-p` | Show PIDs |
| `-T` | Hide threads (show only processes) |
| `-a` | Show command line arguments |
| `-u` | Show UID transitions |
| `-s <pid>` | Show only ancestors of the given PID |
| `-n` | Sort by PID (numeric) |

```
$ pstree -p -s $$
systemd(1)───sshd(900)───sshd(950)───sshd(951)───bash(952)───pstree(1300)
```

---

## 5. Signals — The Kernel's Inter-Process Message System

Signals are software interrupts. The kernel sets a bit in `task_struct->pending.signal` (for unblocked signals) or `task_struct->blocked` (for blocked ones).

### Standard Signal Table (1-31)

| # | Name | Default Action | Usual Use |
|---|---|---|---|
| 1 | SIGHUP | Terminate | Hangup (terminal closed, reload config) |
| 2 | SIGINT | Terminate | Interrupt (Ctrl+C) |
| 3 | SIGQUIT | Core dump | Quit (Ctrl+\\) |
| 6 | SIGABRT | Core dump | Abort (abort()) |
| 8 | SIGFPE | Core dump | Floating-point exception |
| 9 | SIGKILL | Terminate | **Uncatchable kill** |
| 10 | SIGUSR1 | Terminate | User-defined |
| 11 | SIGSEGV | Core dump | Segmentation fault |
| 13 | SIGPIPE | Terminate | Broken pipe |
| 15 | SIGTERM | Terminate | **Graceful termination** (default for kill) |
| 17 | SIGCHLD | Ignore | Child stopped/exited |
| 18 | SIGCONT | Continue / Ignore | Resume stopped process |
| 19 | SIGSTOP | Stop | **Uncatchable stop** |
| 20 | SIGTSTP | Stop | Terminal stop (Ctrl+Z) |
| 24 | SIGXCPU | Core dump | CPU time limit exceeded |
| 25 | SIGXFSZ | Core dump | File size limit exceeded |

### Real-Time Signals (32-64)

Signals 32-63 are **real-time signals**: guaranteed ordering, multiple instances queued (unlike standard signals which are bitmasked).

```
$ kill -l   # list all signals on this system
```

---

## 6. `kill` / `killall` — Sending Signals

### `kill` — Signal by PID

```
$ kill <PID>                 # SIGTERM (15) — ask nicely
$ kill -9 <PID>              # SIGKILL — forcible
$ kill -SIGSTOP <PID>        # SIGSTOP — freeze
$ kill -SIGCONT <PID>        # resume
$ kill -1 <PID>              # SIGHUP — often reload config
$ kill -0 <PID>              # 0 = test if process exists (no signal sent)
```

`kill -0` is a zero-cost existence check:

```
if kill -0 "$PID" 2>/dev/null; then
    echo "Process $PID is alive"
fi
```

### `killall` — Signal by Name

```
$ killall nginx               # SIGTERM all 'nginx' processes
$ killall -9 java             # SIGKILL all java processes
$ killall -u tim              # kill everything owned by tim
$ killall -w nginx            # wait for processes to die
```

`killall` matches **process names** (`task->comm`), not command-line args. For that use `pkill -f`.

---

## 7. `nice` / `renice` — Scheduling Priority

### Niceness (−20 to 19)

Niceness maps to the `task_struct->prio` field. The kernel's CFS uses this to weight time slices:

| Nice | Kernel Priority | Effect |
|---|---|---|
| -20 | 100 | Highest user priority (fastest CPU share) |
| 0 | 120 | Default |
| 19 | 139 | Lowest priority (minimal CPU share) |

### `nice` — Start with Given Niceness

```
$ nice -n 10 ./cpu_hog.sh        # start with nice 10
$ nice --20 ./urgent_task.sh     # start with nice -20 (needs root)
```

### `renice` — Change Niceness of Running Process

```
$ renice -n 10 -p 1234           # set PID 1234 to nice 10
$ renice -n -5 -u tim            # set all tim's processes to nice -5
$ renice -n 15 -g 500            # set all processes in group 500
```

Only root can set **negative** (higher priority) niceness. Regular users can only increase their own niceness.

### Real-World: Lower Priority for Backup

```
$ nice -n 19 tar czf backup.tar.gz /data
```

### Real-World: Boost Database Priority

```
$ sudo renice -n -5 -u postgres
```

---

## 12. Background / Foreground Jobs

### Job Control Basics

```
$ sleep 100 &
[1] 12345
$ sleep 200 &
[2] 12346
```

### `jobs` — List Background Jobs

```
$ jobs
[1]-  Running                 sleep 100 &
[2]+  Running                 sleep 200 &
```

### `fg` — Bring to Foreground

```
$ fg %1
sleep 100
```

### `bg` — Continue Stopped Job in Background

```
$ sleep 300
^Z
[1]+  Stopped                 sleep 300
$ bg %1
[1]+ sleep 300 &
```

### `nohup` — Immune to HUP Signal

```
$ nohup long_running_script.sh &
[1] 12400
$ exit
```

After logout, output goes to `nohup.out`.

### `disown` — Remove Job From Shell's Job Table

```
$ long_running_script.sh &
[1] 12500
$ disown %1
```

The process is now disconnected from the shell. SIGHUP on logout will NOT reach it.

### `setsid` — Create New Session

```
$ setsid long_running_script.sh
```

The new process is not part of the current terminal's session, so it survives logout without needing `nohup`.

### Foreground vs Background — What Actually Happens

```
Foreground:
  PID   PGID   SID   CMD
  952   952    952   bash
 1300   952    952   sleep 100    ← same PGID, same SID as shell

Background &:
  PID   PGID   SID   CMD
 1301  1301    952   sleep 100    ← different PGID, same SID

nohup / setsid:
  PID   PGID   SID   CMD
 1302  1302   1302   sleep 100    ← different PGID, different SID (immune)
```

---

## 13. Cron and Long-Running Processes — `screen`, `tmux`

### `screen` — Terminal Multiplexer

```
$ screen -S mywork        # create named session
$ screen -ls              # list sessions
$ screen -r mywork        # reattach
$ screen -d -r mywork     # detach elsewhere, reattach here
```

Inside screen:
- `Ctrl+A d` — detach
- `Ctrl+A c` — new window
- `Ctrl+A n` / `Ctrl+A p` — next/previous window
- `Ctrl+A k` — kill window

### `tmux` — Modern Terminal Multiplexer

```
$ tmux new -s mywork        # create named session
$ tmux ls                   # list sessions
$ tmux attach -t mywork     # reattach
$ tmux new -s backup -d     # create session in background
```

Inside tmux:
- `Ctrl+B d` — detach
- `Ctrl+B c` — new window
- `Ctrl+B n` / `Ctrl+B p` — next/previous window
- `Ctrl+B ,` — rename window
- `Ctrl+B %` — split vertical
- `Ctrl+B "` — split horizontal

### Use Case: Long Data Migration

```
$ tmux new -s migration
$ ./migrate_data.sh   # runs for 6 hours
# Ctrl+B d to detach
# Go home, SSH in later
$ tmux attach -t migration
# Check progress
```

### `screen` vs `tmux`

| Feature | screen | tmux |
|---|---|---|
| Split panes | Yes (complex) | Yes (easy) |
| Config file | `~/.screenrc` | `~/.tmux.conf` |
| Scriptable | Minimal | `send-keys`, `new-window` |
| Copy mode | `Ctrl+A [` | `Ctrl+B [` |
| Mouse support | `:termcapinfo xterm*` | `set -g mouse on` |

---

## ⭐ Level 2: Intermediary — Finding Processes, Limits, and OOM

![Linux process state diagram showing transitions between states](https://upload.wikimedia.org/wikipedia/commons/e/e4/Linux_kernel_process_states.png)

> *"When servers crash at 3 AM, you don't have time to browse through a forest view. You need `pgrep`, `pkill`, and `ulimit` memorized. The OOM killer isn't random — it's math. Learn the formula, and you can control who survives."*

---

## 4. `pgrep` / `pkill` — Finding and Signaling by Pattern

These tools search `/proc/*/comm` or the full command line for a pattern.

### `pgrep`

```
$ pgrep -u root sshd
900
950

$ pgrep -x bash
952

$ pgrep -f "python.*server"
1200
```

| Option | Meaning |
|---|---|
| `-u <user>` | Match only processes owned by user |
| `-x` | Exact name match |
| `-f` | Match full command line (not just comm) |
| `-n` | Newest match only |
| `-o` | Oldest match only |
| `-l` | Show PID and process name |
| `-a` | Show PID and full command line |
| `-c` | Count matches |

### `pkill`

Same matching as `pgrep`, but sends a signal (default SIGTERM).

```
$ pkill -x bash                # kill all bash shells (careful!)
$ pkill -f "python server.py"  # kill by full cmdline match
$ pkill -u tim -9              # SIGKILL everything owned by tim
$ pkill -SIGSTOP -f "make"     # STOP all make processes
```

**The pattern is a regex** by default. `pkill -x bash` matches exactly `bash`. `pkill bash` matches `bash`, `bashful`, `bash-4.4`.

### Safe Usage

`pkill -f` is powerful and dangerous — it matches the entire command line. Always test with `pgrep -l -f <pattern>` first.

---

## 8. `ulimit` — Per-Process Resource Limits

`ulimit` controls resource limits stored in `task_struct->signal->rlim`. Each resource has a soft limit (current boundary) and a hard limit (ceiling that only root can raise).

### Viewing Limits

```
$ ulimit -a
core file size          (blocks, -c) 0
data seg size           (kbytes, -d) unlimited
open files                      (-n) 1024
stack size              (kbytes, -s) 8192
cpu time               (seconds, -t) unlimited
max user processes              (-u) 15497
virtual memory          (kbytes, -v) unlimited
```

### Key Limits

| Limit | Flag | Typical Default | Why It Matters |
|---|---|---|---|
| `open files` | `-n` | 1024 | Web servers/DBs need far more |
| `stack size` | `-s` | 8192 KB | Deep recursion overflows it |
| `core file size` | `-c` | 0 | Must be > 0 to get core dumps |
| `max user processes` | `-u` | ~15000 | Prevents fork bombs |
| `file size` | `-f` | unlimited | Prevent runaway log fills |

### Setting Limits

```
$ ulimit -n 4096                  # set open file limit (soft)
$ ulimit -c unlimited             # enable core dumps
$ ulimit -u 500                   # max 500 processes for this shell
```

### `/etc/security/limits.conf`

```
# /etc/security/limits.conf
*           soft    nproc          4096
*           hard    nproc          16384
@admins     soft    nofile         16384
@admins     hard    nofile         65536
```

### systemd Limits

```
[Service]
LimitNOFILE=65536
LimitNPROC=4096
LimitCORE=infinity
```

### Why `nofile` Matters

Every socket, open file, pipe, and epoll FD consumes a slot in `task->files->fdt->fd[]`. The default 1024 is too low for databases and web servers.

```
$ sudo cat /proc/$(pgrep -x mysqld)/limits
```

### Fork Bomb Protection

```
$ ulimit -u 500
$ :(){ :|:& };:     # fork bomb at 500 processes → EAGAIN
```

---

## 9. OOM Killer — Out-of-Memory Resolution

When the kernel runs out of memory and swap, `__alloc_pages_slowpath()` fails to find a page. The kernel invokes the OOM killer via `out_of_memory()` → `select_bad_process()`.

### `oom_score`

Every task has an `oom_score` (0-1000) visible in `/proc/PID/oom_score`. The higher the number, the more likely the process gets killed.

```
$ cat /proc/1/oom_score
0
$ cat /proc/$$/oom_score
1
```

### How `select_bad_process()` Works

One `oom_badness()` function assigns a score:

```
oom_score = (total_rss + total_swap + page_table_pages) * 1000 / total_memory
          - oom_score_adj
```

Factors that increase the score: large RSS, large swap usage, many page table pages.
Factors that reduce the score: being root, being init (PID 1 is immune — `oom_score_adj` of -1000).

### `oom_score_adj`

Ranges from -1000 (OOM immune) to +1000 (always kill me first).

```
$ cat /proc/$$/oom_score_adj
0
$ sudo bash -c 'echo -1000 > /proc/1/oom_score_adj'   # already set for init
$ sudo bash -c 'echo 1000 > /proc/$$/oom_score_adj'    # this shell dies first
```

### `oom_adj` (Legacy)

Older interface; range -17 (immune) to +15 (highest kill priority). Maps internally to `oom_score_adj * 8`.

### OOM Killer Message

```
[pid]   uid  total_vm   rss  pgtables_bytes oom_score_adj name
[ 4567] 1000   131072  65000   500K             0         stress

Tasks: 28 total, 1 running, 27 sleeping, 0 stopped, 0 zombie
Memory: 1024000K total, 1024000K used, 0K free, 0K swap used
Killed process 4567 (stress) total-vm:524288kB, rss:260000kB, pgtables:500kB
```

### Systemd `OOMScoreAdjust`

```
[Service]
OOMScoreAdjust=-500
```

### Safe Guard: `vm.overcommit_memory`

```
sysctl vm.overcommit_memory
0 = heuristic overcommit (default)
1 = always overcommit
2 = don't overcommit (sum of RSS + swap)
```

---

## 10. `/proc` Filesystem — The Kernel's Process API

Every process has `/proc/PID/`. This is a virtual filesystem — reading it triggers kernel code that reads `task_struct` fields in real time.

```
/proc/PID/
 ├── cmdline         → task->mm->arg_start (null-separated)
 ├── cwd             → symlink to task->fs->pwd
 ├── environ         → task->mm->env_start (null-separated)
 ├── exe             → symlink to the executable
 ├── root            → symlink to the process root
 ├── fd/             → directory of symlinks to open FDs
 ├── limits          → ulimit values
 ├── maps            → memory mappings (shared libs, heap, stack)
 ├── mem             → raw process memory
 ├── ns/             → namespace inodes
 ├── oom_score       → badness score (0-1000)
 ├── oom_score_adj   → bias (-1000 to +1000)
 ├── sched           → scheduler statistics
 ├── smaps           → detailed memory maps (RSS, PSS, swap)
 ├── stat            → task_struct fields in a single line
 ├── status          → human-readable stat
 ├── task/           → directory of threads (subdirs by TID)
 └── wchan           → kernel function the process is blocked in
```

### Key Files

**`/proc/PID/status`** — Human-readable summary:
```
$ cat /proc/$$/status
Name:   bash
State:  S (sleeping)
Tgid:   3200
Pid:    3200
PPid:   3199
VmRSS:  50000 kB
Threads: 1
```

**`/proc/PID/fd/`** — Open file descriptors:
```
$ ls -la /proc/$$/fd/
lrwx------ 1 tim tim 64 Jun 24 09:30 0 -> /dev/pts/0
lrwx------ 1 tim tim 64 Jun 24 09:30 1 -> /dev/pts/0
lrwx------ 1 tim tim 64 Jun 24 09:30 2 -> /dev/pts/0
```

**`/proc/PID/maps`** — Memory mappings:
```
$ cat /proc/$$/maps
55e4a2c00000-55e4a2e00000 r-xp 00000000 08:01 1234567    /usr/bin/bash
...
7ffe92e00000-7ffe92f00000 rw-p 00000000 00:00 0          [stack]
```

**`/proc/PID/environ`** — Environment variables:
```
$ cat /proc/$$/environ | tr '\0' '\n'
PATH=/usr/local/bin:/usr/bin:/bin
HOME=/home/tim
```

**`/proc/PID/limits`** — Effective ulimits for this PID:
```
$ cat /proc/$$/limits
Limit                     Soft Limit           Hard Limit           Units
Max open files            1024                 4096                 files
Max processes             15497                15497                processes
```

**`/proc/PID/sched`** — Scheduler details:
```
$ cat /proc/$$/sched
bash (3200, #threads: 1)
--------------------------------------------------
se.vruntime                        :     98765432.123456
se.sum_exec_runtime                :        54321.123456
nr_switches                        :              12345
prio                               :                  120
```

---

## ⭐ Level 3: Advanced — Cgroups, CFS Internals, and Deep Understanding

![Control groups v2 hierarchy diagram showing the unified cgroup tree](https://upload.wikimedia.org/wikipedia/commons/9/9d/Cgroup_v2_hierarchy.svg)

> *"Limits are not for normal operation — they're for when things go wrong. `ulimit` stops a fork bomb. Cgroups prevent a noisy neighbor from taking down production. The OOM killer is your last line of defense, not your first. Understanding these internals separates a sysadmin from a firefighter."*

---

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

---

## 14. Command Reference

### Level 1: Basic Process Commands

| Command | Syntax | Purpose |
|---|---|---|
| `ps` | `ps aux` | BSD-style full list |
| `ps` | `ps -ef` | UNIX-style full list |
| `ps` | `ps -eo pid,ppid,state,comm,nice` | Custom output |
| `ps` | `ps --ppid 1` | Children of PID 1 |
| `ps` | `ps -eLf` | Thread view (show TIDs) |
| `pstree` | `pstree -p` | Process tree with PIDs |
| `pstree` | `pstree -s $$` | Ancestors of current shell |
| `kill` | `kill -15 1234` | Default graceful kill |
| `kill` | `kill -9 1234` | Force kill (uncatchable) |
| `kill` | `kill -0 1234` | Test existence |
| `killall` | `killall nginx` | Kill all by process name |
| `nice` | `nice -n 10 ./script` | Start with lowered priority |
| `renice` | `renice -n -5 -p 1234` | Change priority of running PID |
| `jobs` | `jobs` | List background jobs |
| `fg` | `fg %1` | Bring job 1 to foreground |
| `bg` | `bg %2` | Continue job 2 in background |
| `nohup` | `nohup cmd &` | Immune to SIGHUP on logout |
| `disown` | `disown %1` | Remove job from shell table |
| `setsid` | `setsid cmd` | New session, immortal process |
| `screen` | `screen -S name` | Create named screen session |
| `tmux` | `tmux new -s name` | Create named tmux session |

### Level 2: Intermediary Process Commands

| Command | Syntax | Purpose |
|---|---|---|
| `pgrep` | `pgrep -u nginx` | Find PIDs by name/user |
| `pgrep` | `pgrep -f "python.*server"` | Full cmdline match |
| `pkill` | `pkill -9 -f "badscript"` | Kill by pattern |
| `ulimit` | `ulimit -a` | View all limits |
| `ulimit` | `ulimit -n 4096` | Set max open files |
| `ulimit` | `ulimit -c unlimited` | Enable core dumps |
| `systemctl` | `systemctl show -p LimitNOFILE svc` | Check service limits |
| `stress` | `stress --vm 1 --vm-bytes 512M` | Load test (OOM trigger) |

### Level 3: Advanced Process Management

| Command | Description |
|---|---|
| cgroups v2 | `mkdir /sys/fs/cgroup/mygroup` → `echo 100M > memory.max` |
| `systemd-cgls` | Show cgroup tree |
| `/proc/PID/sched` | Read CFS vruntime and scheduling stats |

---

## 15. 15 Hands-On Practices

### Level 1 Practices: Basic Process Management

#### Practice 1: Explore the Process Tree

```
$ pstree -p -u
$ ps -eo pid,ppid,state,comm --sort=pid
$ ps -ef --forest
```

Answer: How many processes are direct children of PID 1 (init/systemd)?

#### Practice 2: Thread View

```
$ ps -eLf | head -20
$ cat /proc/$(pgrep -x systemd-journald)/status | grep Threads
```

Answer: Which processes have more than 10 threads?

#### Practice 3: Find Zombie Processes

```
$ ps -eo pid,stat,comm | grep -w Z
$ top -b -n1 | grep zombie
$ bash -c 'sleep 1 & exec sleep 10' &
$ ps -eo pid,ppid,stat,comm | grep -E "S|Z"
```

Answer: What state are zombie processes in? Can a zombie be killed with SIGKILL?

#### Practice 4: Send Signals

```
$ sleep 300 &
$ kill -SIGSTOP %1
$ ps -o pid,stat,comm $(pgrep -x sleep)
$ kill -SIGCONT %1
$ ps -o pid,stat,comm $(pgrep -x sleep)
$ kill %1
```

Question: What state does a STOPped process show? What about a running process?

#### Practice 5: Custom `ps` Output

```
$ ps -eo pid,ppid,user,%cpu,%mem,comm,etime,lstart,nice,rss,vsz,args \
       --sort=-%mem | head -15
```

Question: Which three processes consume the most memory on your system?

### Level 2 Practices: Intermediary Process Management

#### Practice 6: Change Niceness

```
$ nice -n 19 bash -c 'while true; do :; done' &
$ sudo nice --20 bash -c 'while true; do :; done' &
$ ps -eo pid,comm,nice,%cpu --sort=nice | head -10
$ kill $(pgrep -x bash)
```

Question: How much more CPU does the -20 process get than the +19 process on a single-core machine running only these two?

#### Practice 7: Set File Descriptor Limit

```
$ ulimit -n 30
$ bash -c 'for i in $(seq 1 40); do exec 3<>/dev/null; echo "FD $i opened"; done'
$ ulimit -n 1024
```

Question: What error do you get when exceeding the file descriptor limit?

#### Practice 8: Examine `/proc/PID` in Depth

```
$ echo $$
$ ls -la /proc/$$/fd/
$ cat /proc/$$/status | grep -E "VmRSS|Threads|SigQ"
$ cat /proc/$$/maps | head -10
$ cat /proc/$$/limits | grep "Max open files"
$ cat /proc/$$/sched | head -15
```

Question: How many file descriptors does your current shell have open? How many threads?

#### Practice 9: Trace Process Start Time

```
$ ps -eo pid,comm,lstart,etime --sort=start_time | tail -20
```

Question: Which process has been running the longest (other than PID 1)?

#### Practice 10: Enable and Read a Core Dump

```
$ ulimit -c unlimited
$ python3 -c 'import ctypes; ctypes.string_at(0)' &
$ sleep 2
$ ls -la core.*
```

Question: What's in a core file? (Answer with `file core.PID`)

### Level 3 Practices: Advanced Process Management

#### Practice 11: OOM Score Exploration

```
$ cat /proc/$$/oom_score
$ cat /proc/$$/oom_score_adj
$ sudo bash -c 'echo 500 > /proc/$$/oom_score_adj'
$ cat /proc/$$/oom_score
```

Question: What happens to `oom_score` when you set `oom_score_adj` to 500?

#### Practice 12: Create a cgroup v2 Memory Limit

```
# Only if cgroups v2 is active:
$ sudo mkdir /sys/fs/cgroup/demo
$ echo 50000000 | sudo tee /sys/fs/cgroup/demo/memory.max   # 50 MB limit
$ echo $$ | sudo tee /sys/fs/cgroup/demo/cgroup.procs
$ bash -c 'x=""; while true; do x="$x $(head -c 1M /dev/zero)"; done' &
$ sleep 5 ; dmesg | tail -5
$ sudo rmdir /sys/fs/cgroup/demo
```

Question: What does the kernel do when the process exceeds the cgroup memory limit?

#### Practice 13: Background Job Survival

```
$ ssh localhost
$ nohup sleep 60 &
$ disown
$ exit  # SSH back in
$ ps aux | grep sleep   # still there
```

Then repeat without `nohup` and `disown`:
```
$ ssh localhost
$ sleep 60 &
$ exit  # SSH back in
$ ps aux | grep sleep   # should be gone
```

Question: Why does `nohup` make a difference?

#### Practice 14: tmux Persistent Session

```
$ tmux new -s testwork
  # Inside tmux: run a long command
  $ while true; do date >> /tmp/tmux_test; sleep 5; done
  # Press Ctrl+B d to detach
$ tmux ls
# Close the terminal, open a new one
$ tmux attach -t testwork
$ cat /tmp/tmux_test
```

Question: Did the process continue running while detached?

#### Practice 15: Real-World Integration — Process Audit and Resource Report Script

```bash
#!/bin/bash
# process_audit.sh — Generate a system process resource report

REPORT="/tmp/process_audit_$(date +%Y%m%d_%H%M%S).txt"

{
  echo "=============================================="
  echo "  PROCESS AUDIT REPORT"
  echo "  Generated: $(date)"
  echo "=============================================="
  echo ""

  echo "--- 1. Top 10 Memory Consumers ---"
  ps -eo pid,ppid,user,%mem,%cpu,rss,comm --sort=-%mem \
      --width 120 | head -11
  echo ""

  echo "--- 2. Top 10 CPU Consumers ---"
  ps -eo pid,ppid,user,%cpu,%mem,rss,comm --sort=-%cpu \
      --width 120 | head -11
  echo ""

  echo "--- 3. Process Count by User ---"
  ps -eo user --no-headers | sort | uniq -c | sort -rn
  echo ""

  echo "--- 4. Total Process Count ---"
  echo "  Total processes : $(ps -e --no-headers | wc -l)"
  echo "  Running         : $(ps -e --no-headers -o state | grep -c '^R$')"
  echo "  Sleeping        : $(ps -e --no-headers -o state | grep -c '^S$')"
  echo "  Zombie          : $(ps -e --no-headers -o state | grep -c '^Z$')"
  echo "  Stopped         : $(ps -e --no-headers -o state | grep -c '^T$')"
  echo "  D-state         : $(ps -e --no-headers -o state | grep -c '^D$')"
  echo ""

  echo "--- 5. Zombie Processes (if any) ---"
  ZOMBIES=$(ps -eo pid,ppid,user,comm --state Z)
  if [ -z "$ZOMBIES" ]; then
    echo "  No zombie processes."
  else
    echo "$ZOMBIES"
  fi
  echo ""

  echo "--- 6. Processes with Open Sockets ---"
  for pid in $(ls /proc/ 2>/dev/null | grep -E '^[0-9]+$'); do
    if [ -d "/proc/$pid/fd" ] 2>/dev/null; then
      sockets=$(ls -la /proc/$pid/fd 2>/dev/null | grep -c socket)
      if [ "$sockets" -gt 0 ]; then
        comm=$(cat /proc/$pid/comm 2>/dev/null)
        echo "  PID $pid ($comm): $sockets socket(s)"
      fi
    fi
  done | head -20
  echo ""

  echo "--- 7. Processes with Open File Limits Near Exhaustion ---"
  for pid in $(ls /proc/ 2>/dev/null | grep -E '^[0-9]+$'); do
    if [ -d "/proc/$pid/fd" ] 2>/dev/null && [ -r "/proc/$pid/limits" ] 2>/dev/null; then
      open_fds=$(ls /proc/$pid/fd 2>/dev/null | wc -l)
      max_fds=$(grep "Max open files" /proc/$pid/limits 2>/dev/null | awk '{print $4}')
      if [ -n "$max_fds" ] && [ "$max_fds" -gt 0 ] 2>/dev/null; then
        pct=$(( open_fds * 100 / max_fds ))
        if [ "$pct" -ge 80 ]; then
          comm=$(cat /proc/$pid/comm 2>/dev/null)
          echo "  PID $pid ($comm): ${open_fds}/${max_fds} FDs (${pct}% full)"
        fi
      fi
    fi
  done
  echo ""

  echo "--- 8. Process Tree (Root) ---"
  pstree -h 2>/dev/null || pstree
  echo ""

  echo "--- 9. OOM Scores of Top Memory Consumers ---"
  ps -eo pid,comm,%mem --sort=-%mem --no-headers | head -10 | while read pid comm mem; do
    if [ -r "/proc/$pid/oom_score" ]; then
      score=$(cat /proc/$pid/oom_score)
      echo "  PID $pid ($comm): oom_score=$score, RSS=${mem}%"
    fi
  done
  echo ""

  echo "--- 10. System-wide ulimit Impact ---"
  echo "  File handle limit (system-wide): $(cat /proc/sys/fs/file-max)"
  echo "  File handles used: $(cat /proc/sys/fs/file-nr | cut -f1)"
  echo "  Max PID: $(cat /proc/sys/kernel/pid_max)"
  echo "  Threads max: $(cat /proc/sys/kernel/threads-max)"
  echo ""

  echo "=============================================="
  echo "  END OF REPORT"
  echo "=============================================="
} | tee "$REPORT"

echo ""
echo "Report saved to: $REPORT"
```

Identify:
- Which user owns the most processes
- Any zombie processes
- Any processes close to their FD limit
- The highest OOM score and what process has it

---

## 17. Self-Test

**Instructions:** Answer each question. Score 12/15 correct = ready for Part 35.

### Question 1
What field in `task_struct` distinguishes a process from a thread?
a) `pid`  b) `tgid`  c) `ppid`  d) `__state`

### Question 2
Which process state is uninterruptible and cannot be killed even with SIGKILL?
a) S  b) R  c) D  d) T

### Question 3
What does `ps -eLf` show that `ps -ef` does not?
a) Full command lines  b) Thread IDs (LWP)  c) Memory maps  d) CPU affinity

### Question 4
Which signal is uncatchable and terminates a process immediately?
a) SIGTERM  b) SIGHUP  c) SIGSTOP  d) SIGKILL

### Question 5
How do you check if a process with PID 1234 exists without sending a signal?
a) `kill -1 1234`  b) `kill -0 1234`  c) `kill -15 1234`  d) `kill -9 1234`

### Question 6
What is the range of niceness values?
a) -100 to 100  b) 0 to 139  c) -20 to 19  d) 0 to 1000

### Question 7
A process started with `nice -n 19` will get ____________ CPU compared to a default process.
a) More  b) Less  c) The same  d) No

### Question 8
What does `ulimit -n` control?
a) Maximum number of processes  b) Maximum number of open file descriptors
c) Maximum stack size  d) Maximum core file size

### Question 9
What file in `/proc/PID/` shows the process's current resource limits?
a) `status`  b) `limits`  c) `rlimit`  d) `ulimit`

### Question 10
Which `oom_score_adj` value makes a process completely immune to the OOM killer?
a) 0  b) -500  c) -1000  d) 1000

### Question 11
In cgroups v2, which file sets the memory limit?
a) `memory.limit_in_bytes`  b) `memory.max`  c) `memory.high`  d) `memory.swap.max`

### Question 12
What is the difference between `nohup cmd &` and `cmd &` alone?
a) `nohup` redirects output to `nohup.out`  b) `nohup` ignores SIGHUP
c) Both a and b  d) There is no difference

### Question 13
What happens to a zombie process that has been reparented to init and init calls wait()?
a) It becomes a running process again  b) It is reaped (freed from the process table)
c) It stays a zombie forever  d) It is killed with SIGKILL

### Question 14
Which CFS data structure is used to pick the next task to run?
a) A linked list  b) A red-black tree keyed by vruntime
c) A priority bitmap  d) A hash table keyed by PID

### Question 15
Which scheduling class has the highest priority?
a) `idle_sched_class`  b) `fair_sched_class`  c) `rt_sched_class`  d) `stop_sched_class`

---

### Answer Key

| Q | Answer | Explanation |
|---|---|---|
| 1 | **b)** `tgid` | Main threads have `pid == tgid`, worker threads have `pid != tgid`. |
| 2 | **c)** D | Uninterruptible sleep (D state) blocks all signals, including SIGKILL. |
| 3 | **b)** Thread IDs (LWP) | `ps -eLf` adds the LWP (TID) column and shows one line per thread. |
| 4 | **d)** SIGKILL | Signal 9 is uncatchable, unblockable, and immediately kills the process. |
| 5 | **b)** `kill -0 1234` | Signal 0 performs error checking only — no signal is actually sent. |
| 6 | **c)** -20 to 19 | Lower is nicer to the process (more CPU priority), higher is less nice. |
| 7 | **b)** Less | Nice 19 is the lowest priority — CFS gives this process minimal CPU. |
| 8 | **b)** Maximum number of open file descriptors | `ulimit -n` controls `RLIMIT_NOFILE`. |
| 9 | **b)** `limits` | `/proc/PID/limits` shows soft and hard limits for all resources. |
| 10 | **c)** -1000 | `oom_score_adj = -1000` subtracts 1000 from the badness score, making it 0 or negative. |
| 11 | **b)** `memory.max` | In cgroups v2, `memory.max` replaces v1's `memory.limit_in_bytes`. |
| 12 | **c)** Both a and b | `nohup` both ignores SIGHUP and redirects output to `nohup.out`. |
| 13 | **b)** It is reaped | Init's `wait()` call collects the exit status and frees the zombie's `task_struct`. |
| 14 | **b)** A red-black tree keyed by vruntime | CFS stores tasks in an rbtree; the leftmost node (smallest vruntime) runs next. |
| 15 | **d)** `stop_sched_class` | Stop class is the highest priority (for CPU hotplug and stop-machine). |

**Score:** ___/15 correct

- 14-15: Ready for Part 35. Excellent.
- 12-13: Ready for Part 35. Good foundation.
- 10-11: Review the Deep Understanding section before proceeding.
- 0-9: Re-read Part 34 and redo the hands-on practices.

---

## 18. What's Coming in Part 35

**Part 35: Shell Scripting for System Administrators**

We shift from process management to automation: writing robust shell scripts that automate administration tasks.

Topics covered:
- Bash scripting essentials: variables, arrays, arithmetic
- Conditionals: `if`, `test`, `[[ ]]`, `case`
- Loops: `for`, `while`, `until`
- Functions and scope
- Process substitution, here-docs, here-strings
- Parsing command-line arguments with `getopts`
- Error handling: `set -e`, `trap`, exit codes
- Sourcing vs executing scripts
- `read`, `mapfile`, IFS manipulation
- Real-world script templates: backup, log rotator, health check
- ShellCheck and best practices

---

*Previous → [Part 33: System Monitoring](part33.md)*
*Next → [Part 35: Shell Scripting for System Administrators](part35.md)*

[← Previous](part33.md) | [Next →](part35.md)
