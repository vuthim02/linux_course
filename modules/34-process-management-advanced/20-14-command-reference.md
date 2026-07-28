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





[← Previous](19-16-deep-understanding.md) | [↑ Index](index.md) | [Next →](21-15-15-hands-on-practices.md)
