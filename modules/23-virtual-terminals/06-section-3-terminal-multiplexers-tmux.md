## 🔍 Section 3: Terminal Multiplexers — tmux

### What is tmux?

`tmux` is a modern terminal multiplexer (successor to screen) with:
- Client-server architecture
- Better window/session management
- Vertical and horizontal splits
- Scriptable and configurable
- Clipboard integration

### Installing tmux

```bash
# Debian/Ubuntu
sudo apt install tmux

# Fedora/RHEL
sudo dnf install tmux
```

### Getting Started with tmux

```bash
# Start a new tmux session
tmux

# Start a named session
tmux new -s mysession

# Inside tmux:
# Ctrl + B, then ?      # Show help
# Ctrl + B, then D      # Detach session
# Ctrl + B, then C      # Create new window
# Ctrl + B, then ,      # Rename window
# Ctrl + B, then N      # Next window
# Ctrl + B, then P      # Previous window
# Ctrl + B, then W      # List windows
# Ctrl + B, then %      # Split vertically
# Ctrl + B, then "      # Split horizontally
# Ctrl + B, then arrows # Navigate splits
```

### Managing tmux Sessions

```bash
# List sessions
tmux ls

# Output:
# mysession: 2 windows (created Mon Jan 15 10:30:45 2024)

# Reattach to session
tmux attach -t mysession

# Reattach to most recent
tmux attach

# Kill session
tmux kill-session -t mysession

# List all sessions
tmux list-sessions
```

### tmux Configuration (~/.tmux.conf)

```bash
cat ~/.tmux.conf
```

```
# Use Ctrl+A instead of Ctrl+B (like screen)
set -g prefix C-a
unbind C-b
bind C-a send-prefix

# Increase scrollback
set -g history-limit 10000

# Mouse support
set -g mouse on

# Status bar
set -g status-bg black
set -g status-fg white
set -g status-left '#[fg=green]#S '
set -g status-right '#[fg=yellow]%m/%d %H:%M'

# Split panes
bind | split-window -h
bind - split-window -v
```

### tmux Key Reference

| Key | Action |
|-----|--------|
| `Ctrl+B D` | Detach session |
| `Ctrl+B C` | Create new window |
| `Ctrl+B N` | Next window |
| `Ctrl+B P` | Previous window |
| `Ctrl+B W` | List windows |
| `Ctrl+B %` | Split vertically |
| `Ctrl+B "` | Split horizontally |
| `Ctrl+B Arrows` | Navigate splits |
| `Ctrl+B Z` | Zoom pane (fullscreen) |
| `Ctrl+B [` | Enter copy/scroll mode |
| `Ctrl+B ,` | Rename window |

---



---

[← Previous](05-section-2-terminal-multiplexers-screen.md) | [↑ Index](index.md) | [Next →](07-section-4-serial-console.md)
