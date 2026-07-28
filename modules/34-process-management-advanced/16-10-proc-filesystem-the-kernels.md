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





[← Previous](15-9-oom-killer-out-of-memory-resolution.md) | [↑ Index](index.md) | [Next →](17-level-3-advanced-cgroups-cfs.md)
