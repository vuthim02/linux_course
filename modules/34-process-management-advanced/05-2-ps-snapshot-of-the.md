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





[← Previous](04-1-processes-vs-threads-pid.md) | [↑ Index](index.md) | [Next →](06-3-pstree-visualizing-process-hierarchy.md)
