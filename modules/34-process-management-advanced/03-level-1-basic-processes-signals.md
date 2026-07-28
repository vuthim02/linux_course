## ⭐ Level 1: Basic — Processes, Signals, and Job Control

![Unix process state transitions — from creation through running, sleeping, and zombie states](https://upload.wikimedia.org/wikipedia/commons/9/9f/Unix_process_states.png)

> *"A process is not a program. A program is inert — a file on disk. A process is a program in execution, complete with memory, file descriptors, a kernel stack, and a place in the scheduler's runqueue. Kill the right process, and you fix the problem; kill the wrong one, and you create one."*

### What You'll Cover
- The process lifecycle: fork, exec, exit, wait
- Process states: Running (R), Sleeping (S), Disk-sleep (D), Stopped (T), Zombie (Z)
- Viewing processes: `ps aux`, `pstree`, `ps --forest`
- Signals: SIGHUP, SIGTERM, SIGKILL, SIGSTOP — when to use each
- `kill`, `killall`, and sending signals to processes
- Job control: `&`, `jobs`, `fg`, `bg`, `Ctrl+Z`
- `nice`/`renice` for priority manipulation

Processes are the active instances of running programs. Every command you type spawns a process, and understanding their lifecycle is fundamental to system administration.

At this level you will learn:

- **Process lifecycle**: `fork()` creates a child process (copy of parent). `exec()` replaces the child with a new program. `exit()` terminates the process. `wait()` lets the parent collect the child's exit status. Every shell command follows this pattern.
- **Process states**: `R` = running or runnable. `S` = sleeping (waiting for an event). `D` = uninterruptible sleep (waiting for I/O — cannot be killed). `T` = stopped (Ctrl+Z). `Z` = zombie (exited but parent hasn't collected exit status).
- **Signals**: `SIGHUP` (1) = hangup, often used to reload config. `SIGTERM` (15) = graceful termination (default for `kill`). `SIGKILL` (9) = forced kill (cannot be caught). `SIGSTOP` (19) = pause. `SIGCONT` (18) = resume a stopped process.
- **Job control**: `command &` runs it in the background. `jobs` lists background jobs. `fg %1` brings job 1 to foreground. `Ctrl+Z` suspends the current job. `bg %1` resumes it in the background. Essential for managing long-running tasks in a terminal.
- **nice/renice**: `nice -n 10 command` starts a process with lower priority (higher nice value = lower priority). `renice -5 -p PID` changes priority of a running process. Range is -20 (highest priority) to 19 (lowest).


[← Previous](02-table-of-contents.md) | [↑ Index](index.md) | [Next →](04-1-processes-vs-threads-pid.md)
