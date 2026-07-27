## 🔍 Section 6: nohup, disown, and screen

When you close a terminal, all processes started from it receive SIGHUP and terminate. These tools prevent that.

### nohup — No Hang Up

```bash
# Run a command immune to hangups
nohup long_running_script.sh &

# Output goes to nohup.out (unless redirected)
nohup backup.sh > backup.log 2>&1 &

# If you log out and back in, the process continues running
```

### disown — Detach From Shell

```bash
# Start a job
long_running_script &

# Remove it from the shell's job table
disown %1

# Now closing the terminal won't kill it
# The process is orphaned and re-parented to init/systemd
```

### screen — Terminal Multiplexer

```bash
# Install
sudo apt install screen

# Start a screen session
screen -S mysession

# Inside screen:
# Run your long command
# Detach: Ctrl+A, then d

# Re-attach:
screen -r mysession

# List sessions
screen -ls

# Re-attach to a detached session
screen -r

# Kill a session
screen -S mysession -X quit
```

### tmux — Modern Alternative

```bash
# Install
sudo apt install tmux

# Start
tmux new -s mysession

# Detach: Ctrl+B, then d
# Re-attach: tmux attach -t mysession
# List: tmux ls
```

---



---

[← Previous](06-section-5-managing-background-and.md) | [↑ Index](index.md) | [Next →](08-section-7-nice-and-renice.md)
