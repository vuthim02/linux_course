## 🎯 What You Will Achieve

| Level | Outcome |
|-------|---------|
| **Basic** | List, view, and terminate processes with `ps`, `pstree`, `kill`; understand process states; use `nice`/`renice`; manage background and foreground jobs; use `screen`/`tmux` |
| **Intermediary** | Find processes with `pgrep`/`pkill`; set resource limits with `ulimit`; understand OOM score basics; explore `/proc/PID/` files; use `nohup`/`disown`/`setsid` for persistent processes |
| **Advanced** | Understand `task_struct` internals, CFS scheduler, signal delivery mechanics; configure cgroups v2; tune OOM killer with `oom_score_adj`; understand zombie reaping, kernel threads, and `pidfd` |

### Why This Part Matters
Processes are the living entities on your system. Understanding how to find, control, limit, and debug them is what separates someone who runs commands from someone who manages systems. This part takes you from basic `ps` output to cgroups v2 resource control.

> **Real-world perspective**: When a runaway process eats all the CPU, when an application leaks memory until the OOM killer strikes, or when a zombie process clutters your process table — these are not theoretical problems. They happen in production, often at 3 AM, and knowing how to diagnose and fix them quickly is what makes a sysadmin effective.

**Skills progression in this part**:
- **Basic**: List and view processes with `ps`, `pstree`. Send signals with `kill`, `killall`. Manage background jobs with `&`, `jobs`, `fg`, `bg`. Adjust priority with `nice`/`renice`.
- **Intermediary**: Find processes by pattern with `pgrep`/`pkill`. Set resource limits with `ulimit` and `/etc/security/limits.conf`. Understand OOM scoring. Explore `/proc/<pid>/` for detailed process info.
- **Advanced**: Configure cgroups v2 for CPU, memory, and I/O limits. Understand the CFS scheduler's virtual runtime model. Tune the OOM killer with `oom_score_adj`. Use `pidfd` for race-free process management.


[↑ Index](index.md) | [Next →](02-table-of-contents.md)
