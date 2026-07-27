## 📋 Summary — Complete Command Reference for Part 23

### Level 1: Basic Commands — Virtual Terminals

| Command | Action |
|---------|--------|
| `tty` | Show current terminal device |
| `who` | Show logged-in users |
| `sudo chvt N` | Switch to virtual terminal N |
| `clear` | Clear terminal screen |
| `reset` | Reset terminal settings |
| `dmesg \| tail` | View kernel messages |

### Level 2: Intermediary Commands — Multiplexers and Serial

| Command | Action |
|---------|--------|
| `screen -S name` | Start named screen session |
| `screen -ls` | List screen sessions |
| `screen -r name` | Reattach to screen session |
| `tmux new -s name` | Start named tmux session |
| `tmux ls` | List tmux sessions |
| `tmux attach -t name` | Reattach to tmux session |
| `screen /dev/ttyS0 115200` | Serial console via screen |

### Level 3: Advanced Commands — Recovery

| Command | Action |
|---------|--------|
| `sudo systemctl rescue` | Enter rescue mode |
| `sudo systemctl emergency` | Emergency shell |
| `script session.log` | Record terminal session |

---



---

[← Previous](12-deep-understanding-tty-internals-and.md) | [↑ Index](index.md) | [Next →](14-whats-coming-in-part-24.md)
