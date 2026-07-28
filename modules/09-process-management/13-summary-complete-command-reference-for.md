## 📋 Summary — Complete Command Reference for Part 9

### Process Listing

| Command | Action |
|---------|--------|
| `ps aux` | All processes (BSD style) |
| `ps -ef` | All processes (standard) |
| `ps -u user` | Processes of a user |
| `ps -p PID` | Specific process |
| `ps -e -o pid,comm --sort=-%cpu` | Custom format, sorted |
| `pstree` | Process tree |
| `top` | Real-time monitor |
| `htop` | Enhanced real-time monitor |

### Signals

| Command | Action |
|---------|--------|
| `kill PID` | Send SIGTERM |
| `kill -9 PID` | Send SIGKILL (force kill) |
| `kill -HUP PID` | Send SIGHUP (reload config) |
| `pkill name` | Kill by process name |
| `pkill -u user` | Kill all processes of user |
| `killall name` | Kill by exact name |
| `kill -l` | List all signals |

### Background Jobs

| Command | Action |
|---------|--------|
| `command &` | Run in background |
| `jobs` | List background jobs |
| `fg %1` | Bring job 1 to foreground |
| `bg %1` | Resume job 1 in background |
| `Ctrl+Z` | Suspend current job |
| `Ctrl+C` | Terminate current job |

### Process Persistence

| Command | Action |
|---------|--------|
| `nohup command &` | Immune to hangups |
| `disown %1` | Detach from shell |
| `screen -S name` | Create screen session |
| `screen -r name` | Reattach to screen |
| `tmux new -s name` | Create tmux session |

### Priority

| Command | Action |
|---------|--------|
| `nice -n 10 command` | Start with low priority |
| `renice 10 -p PID` | Change priority of running process |
| `renice 10 -u user` | Change priority of user's processes |

### Process Information

| Command | Action |
|---------|--------|
| `cat /proc/PID/status` | Process status |
| `cat /proc/PID/cmdline` | Command line |
| `ls -la /proc/PID/fd/` | Open file descriptors |
| `lsof -p PID` | List open files |
| `lsof -i` | List network connections |
| `pidof command` | Find PID of command |





[← Previous](12-deep-understanding-how-the-scheduler.md) | [↑ Index](index.md) | [Next →](14-whats-coming-in-part-10.md)
