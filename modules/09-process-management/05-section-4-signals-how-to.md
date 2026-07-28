## 🔍 Section 4: Signals — How to Talk to Processes

A **signal** is a notification sent to a process. It can tell it to terminate, stop, continue, reload config, etc.

### Common Signals

| Signal | Number | Action | Default Behavior |
|--------|--------|--------|------------------|
| SIGHUP | 1 | Hang up | Terminate (often reloads config) |
| SIGINT | 2 | Interrupt | Terminate (Ctrl+C sends this) |
| SIGQUIT | 3 | Quit | Terminate with core dump |
| SIGKILL | 9 | Kill | Force terminate (cannot be caught/ignored) |
| SIGTERM | 15 | Terminate | Terminate gracefully (default for `kill`) |
| SIGCONT | 18 | Continue | Resume a stopped process |
| SIGSTOP | 19 | Stop | Pause (cannot be caught/ignored) |
| SIGTSTP | 20 | Terminal stop | Pause (Ctrl+Z sends this) |

### Sending Signals With kill

```bash
# Basic kill — sends SIGTERM (15)
kill 1234

# Send specific signal by name
kill -SIGTERM 1234
kill -TERM 1234
kill -15 1234

# Force kill (SIGKILL) — last resort
kill -SIGKILL 1234
kill -KILL 1234
kill -9 1234

# Reload config (SIGHUP) — no restart needed
kill -HUP 1234
```

### pkill — Kill by Name

```bash
# Kill all processes named "firefox"
pkill firefox

# Kill all processes of a user
pkill -u alice

# Send specific signal
pkill -9 firefox

# Kill by full command
pkill -f "python3 server.py"

# Show what would be killed (safe test)
pkill -f "python3" --echo
```

### killall — Kill by Name (Exact Match)

```bash
# Kill all processes named exactly "nginx"
sudo killall nginx

# Send specific signal
sudo killall -9 nginx

# Interactive mode (ask before each kill)
sudo killall -i nginx
```

### Which Signal to Use When

```
1. Try SIGTERM (kill PID)          Graceful shutdown, allows cleanup
2. Wait 5 seconds
3. If still running: SIGKILL (kill -9 PID)   Force kill, no cleanup

NEVER start with kill -9 unless absolutely necessary.
SIGKILL doesn't let the process save files or close connections.
```





[← Previous](04-section-3-top-real-time-process.md) | [↑ Index](index.md) | [Next →](06-section-5-managing-background-and.md)
