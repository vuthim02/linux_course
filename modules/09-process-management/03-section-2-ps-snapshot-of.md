## 🔍 Section 2: ps — Snapshot of Running Processes

`ps` shows a snapshot of processes at a given moment. It has dozens of options, but most sysadmins use only a few combinations.

### Essential ps Combinations

```bash
# All processes, full format (BSD style)
ps aux

# All processes, full format (standard style)
ps -ef

# All processes with user-defined format
ps -e -o pid,ppid,cmd,%mem,%cpu --sort=-%mem

# Your processes only
ps -u $(whoami)

# Processes of a specific user
ps -u alice

# Processes connected to a terminal
ps -t pts/0
```

### Understanding ps aux Output

```bash
ps aux
```

```
USER       PID  %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root         1  0.0  0.4 168272 13956 ?        Ss   Jan15   0:03 /sbin/init
root       100  0.0  0.1  72340  4568 ?        Ss   Jan15   0:00 sshd: /usr/sbin...
alice     1568  0.1  2.1 584324 67820 ?        Sl   10:00   0:15 /usr/bin/gnome-shell
alice     3201  0.0  0.2  28548  8764 pts/0    Ss   10:05   0:00 -bash
alice     4567  2.5  0.8 485632 25612 ?        Rl   10:30   1:20 /usr/bin/firefox
```

| Column | Meaning |
|--------|---------|
| USER | Owner of the process |
| PID | Process ID |
| %CPU | CPU usage percentage |
| %MEM | Memory usage percentage |
| VSZ | Virtual memory size (KB) |
| RSS | Resident Set Size (physical memory, KB) |
| TTY | Terminal connected to (or `?` for none) |
| STAT | Process state code |
| START | When process started |
| TIME | Total CPU time used |
| COMMAND | The command that started the process |

### Process States (STAT column)

| Code | State | Meaning |
|------|-------|---------|
| R | Running | Actively using CPU or in run queue |
| S | Sleeping | Waiting for something (most processes) |
| D | Uninterruptible Sleep | Waiting for I/O (disk). Cannot be killed easily |
| Z | Zombie | Child process that finished but parent hasn't collected it |
| T | Stopped | Paused by a signal (SIGSTOP or SIGTSTP) |
| X | Dead | Should never be seen |

Additional characters:
- `<` — High priority (not nice to others)
- `N` — Low priority (nice to others)
- `s` — Session leader (contains child processes)
- `l` — Multi-threaded (CLONE_THREAD)
- `+` — In the foreground process group

### Custom ps Output

```bash
# Show only specific columns
ps -e -o pid,user,%cpu,%mem,comm --sort=-%cpu

# Top 5 memory consumers
ps -e -o pid,user,%mem,comm --sort=-%mem | head -6

# Find processes using more than 10% CPU
ps -e -o pid,user,%cpu,comm --sort=-%cpu | awk '$3 > 10'

# Script-friendly output (no headers)
ps -e -o pid --no-headers
```

---



---

[← Previous](02-section-1-what-is-a.md) | [↑ Index](index.md) | [Next →](04-section-3-top-real-time-process.md)
