## 🔍 Section 2: Terminal Multiplexers — screen

### What is screen?

`screen` is a terminal multiplexer that allows you to:
- Run multiple terminal sessions in one window
- Detach and reattach sessions (persistent across network disconnects)
- Share sessions with other users
- Scroll back through terminal output

### Installing screen

```bash
# Debian/Ubuntu
sudo apt install screen

# Fedora/RHEL
sudo dnf install screen
```

### Getting Started with screen

```bash
# Start a new screen session
screen

# Start a named session
screen -S mysession

# Inside screen:
# Ctrl + A, then ?      # Show help
# Ctrl + A, then D      # Detach session
# Ctrl + A, then C      # Create new window
# Ctrl + A, then N      # Next window
# Ctrl + A, then P      # Previous window
# Ctrl + A, then "      # List windows
# Ctrl + A, then K      # Kill window
```

### Managing screen Sessions

```bash
# List active screen sessions
screen -ls

# Output:
# There are screens on:
#   12345.mysession  (Detached)
#   12346.pts-0.host (Attached)

# Reattach to a session
screen -r                    # Reattach to single detached session
screen -r 12345              # Reattach by PID
screen -r mysession          # Reattach by name

# Reattach to an attached session (force detach others)
screen -d -r mysession       # Detach elsewhere, then reattach here

# Attach to shared session (multi-display mode)
screen -x mysession          # Multiple users see the same session

# Kill a session
screen -XS mysession quit
```

### Screen Configuration (~/.screenrc)

```bash
cat ~/.screenrc
```

```
# Example .screenrc
# Start with a caption line
caption always "%{= kw} %-w%{= wk}%n*%t%{-}%+w %= %{= kw} %H %{= .w} %m/%d %c"

# Scrollback buffer size
defscrollback 10000

# Terminal type
term xterm-256color

# Start in home directory
chdir /

# Key bindings
bindkey -k k1 select 1    # F1 -> window 1
bindkey -k k2 select 2    # F2 -> window 2
```

### Screen Key Reference

| Key | Action |
|-----|--------|
| `Ctrl+A D` | Detach session |
| `Ctrl+A C` | Create new window |
| `Ctrl+A N` | Next window |
| `Ctrl+A P` | Previous window |
| `Ctrl+A "` | List windows |
| `Ctrl+A K` | Kill current window |
| `Ctrl+A S` | Split screen horizontally |
| `Ctrl+A Tab` | Move to next split |
| `Ctrl+A Q` | Remove all splits |
| `Ctrl+A [` | Enter copy/scroll mode |





[← Previous](04-level-2-intermediary-terminal-multiplexers.md) | [↑ Index](index.md) | [Next →](06-section-3-terminal-multiplexers-tmux.md)
