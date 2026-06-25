# 🐧 Linux System Administrator — Complete Course
## Part 23 of ∞: Virtual Terminals and Console Management

---

> **Reverse Engineering Approach:** When your SSH connection drops, the network is down, and the server is in a different datacenter, the virtual console (or serial console) is your last lifeline. Understanding how Linux handles virtual terminals, console multiplexing, and serial access is essential for out-of-band management, recovery scenarios, and day-to-day terminal productivity.

---

## 🎯 What You Will Achieve in Part 23

This module is organized into three progressive levels:

| Level | Focus | What You'll Master |
|-------|-------|--------------------|
| ⭐ Level 1: Basic | Virtual Terminal Basics | Understanding Linux ttys, switching between virtual consoles, console configuration |
| ⭐ Level 2: Intermediary | Terminal Multiplexers | Using `screen` and `tmux` for session management, serial console setup |
| ⭐ Level 3: Advanced | Console Internals | Understanding the TTY subsystem, console recovery techniques |

---

## ⭐ Level 1: Basic — Virtual Terminal Basics

![Linux virtual terminal — text console interface](https://upload.wikimedia.org/wikipedia/commons/1/1e/Terminal_icon.svg)

*Linux terminal icon — representing virtual console access (Wikimedia Commons / public domain)*

> **Level 1 Goal:** Understand the Linux virtual terminal system, how to switch between consoles, configure console settings, and manage TTY devices.

## 🔍 Section 1: Virtual Terminals

### What Are Virtual Terminals?

Linux provides multiple virtual consoles (also called virtual terminals or TTYs) accessible via keyboard shortcuts. Each acts like a separate terminal session.

```
Default virtual terminals on Linux:

  tty1  - First virtual console (often used for display manager / GUI)
  tty2  - Second virtual console
  tty3  - Third virtual console
  ...
  tty6  - Sixth virtual console (default max for text login)

On a server without GUI:
  tty1 is a text login prompt by default

On a desktop with GUI:
  tty1 = GUI (display manager / X11 / Wayland)
  tty2 through tty6 = text consoles
```

### Switching Virtual Terminals

```bash
# Keyboard shortcuts
Ctrl + Alt + F1    # Switch to tty1
Ctrl + Alt + F2    # Switch to tty2
Ctrl + Alt + F3    # Switch to tty3
Ctrl + Alt + F7    # Switch to GUI (on many distros, tty7)

# From command line (you need to be on a different TTY)
sudo chvt 1        # Switch to tty1
sudo chvt 2        # Switch to tty2
sudo chvt 3        # Switch to tty3
```

### Checking Which TTY You Are On

```bash
# Show current TTY
tty

# Output: /dev/pts/0 (SSH session)
# Output: /dev/tty1 (virtual console)
# Output: /dev/ttyS0 (serial console)

# Show who is logged in and on which TTY
who

# Check active virtual consoles
ps aux | grep "tty[1-6]"
```

### TTY Device Files

```bash
# Virtual console devices
ls -la /dev/tty[1-6]

# Pseudo terminals (SSH, terminal emulators)
ls /dev/pts/

# Current terminal
ls -la /dev/tty    # Symbolic link to current terminal
```

### Configuring Virtual Consoles

```bash
# Number of virtual consoles
# /etc/systemd/logind.conf
sudo cat /etc/systemd/logind.conf

# Key setting:
# NAutoVTs=6    # Number of virtual consoles to auto-start

# Console font settings
# /etc/default/console-setup
sudo cat /etc/default/console-setup
```

### Console Login

```bash
# On a virtual console, you'll see:
localhost login: username
Password:

# After login, you get a shell
# Exit / log out
exit
# Or: logout
# Or: Ctrl + D

# Force log out a user from a TTY
sudo pkill -t tty2      # Kills all processes on tty2
```

### Clear and Reset Console

```bash
# Clear terminal
clear
# Or: Ctrl + L

# Reset terminal (if it gets garbled)
reset

# Set terminal type
export TERM=xterm-256color   # For SSH sessions
export TERM=linux             # For virtual consoles
```

### Console Messages (Kernel Messages)

```bash
# Kernel messages appear on console by default
# Check kernel ring buffer
dmesg

# Control console logging level
sudo dmesg -n 1          # Only emergency messages to console
sudo dmesg -n 4          # Only warnings and above
sudo dmesg -n 7          # All messages (debug)

# Prevent kernel messages from interrupting your terminal
sudo dmesg -D            # Disable printing to console
sudo dmesg -E            # Enable printing to console
```

---

## ⭐ Level 2: Intermediary — Terminal Multiplexers and Serial Console

![GNU Screen — terminal multiplexer with multiple windows](https://upload.wikimedia.org/wikipedia/commons/5/5a/GNU_Screen_screenshot.png)

*GNU Screen terminal multiplexer (Wikimedia Commons / public domain)*

> **Level 2 Goal:** Master terminal multiplexers (screen and tmux) for persistent remote sessions, and configure serial console access for out-of-band server management.

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

---

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

## 🔍 Section 4: Serial Console

### What is Serial Console?

Serial console allows you to access a server through a serial port (RS-232), which works even when:
- Network is down
- SSH is not running
- System is in single-user mode
- System is booting (you can see BIOS/UEFI output)

### Configuring Serial Console with systemd

```bash
# 1. Configure systemd to start a getty on serial port
sudo systemctl enable serial-getty@ttyS0.service
sudo systemctl start serial-getty@ttyS0.service

# 2. Add console to kernel cmdline (for boot messages)
# Edit /etc/default/grub:
# GRUB_CMDLINE_LINUX="console=tty0 console=ttyS0,115200n8"

# 3. Update GRUB
sudo update-grub   # Debian/Ubuntu
sudo grub-mkconfig -o /boot/grub/grub.cfg   # RHEL

# 4. Connect via serial
# From another machine:
screen /dev/ttyS0 115200
# Or:
minicom -b 115200 -D /dev/ttyS0
```

### GRUB Serial Console

```bash
# /etc/default/grub — Serial console configuration

GRUB_TERMINAL=serial
GRUB_SERIAL_COMMAND="serial --speed=115200 --unit=0 --word=8 --parity=no --stop=1"
GRUB_CMDLINE_LINUX="console=tty0 console=ttyS0,115200n8"
```

### Connecting to Serial Console

```bash
# Using screen as a serial terminal
screen /dev/ttyS0 115200

# Using picocom
picocom -b 115200 /dev/ttyS0

# Using minicom
minicom -b 115200 -D /dev/ttyS0

# Using cu (uucp)
cu -l /dev/ttyS0 -s 115200
```

---

## 🔍 Section 5: Console Management

### System Rescue and Single User Mode

```bash
# Boot into single user mode (can be done via console)
# From GRUB: press 'e' on boot entry, add 'single' to kernel line

# Or from running system:
sudo systemctl rescue        # Rescue mode (single user + network)
sudo systemctl emergency     # Emergency mode (minimal shell)
```

### Console Logging

```bash
# Log console output to file
script session.log          # Start recording
# ... run commands ...
exit                        # Stop recording

# Use screen logging
# Inside screen: Ctrl+A, then H
# Logs to screenlog.0

# Use tmux logging
# Inside tmux:
tmux capture-pane -pS - > tmux.log
```

### Managing Console Fonts

```bash
# List available console fonts
ls /usr/share/consolefonts/

# Set console font
sudo setfont /usr/share/consolefonts/Lat2-Terminus16.psf.gz

# Set font permanently (Debian)
sudo dpkg-reconfigure console-setup

# Set font permanently (manual)
# Edit /etc/default/console-setup
```

### Console Keyboard Layout

```bash
# Show current keyboard layout
localectl status

# Set keyboard layout
sudo localectl set-keymap us              # US keyboard
sudo localectl set-keymap de-latin1       # German keyboard
sudo localectl set-keymap fr              # French keyboard

# Set both console and X11 layout
sudo localectl set-x11-keymap us
sudo localectl set-keymap us
```

---

## ⭐ Level 3: Advanced — Console Internals and Recovery

![Serial port — DB-9 connector for serial console access](https://upload.wikimedia.org/wikipedia/commons/7/7c/Serial_port.jpg)

*Serial port (DB-9 connector) — used for out-of-band console access (Wikimedia Commons / public domain)*

> **Level 3 Goal:** Understand the Linux TTY subsystem internals, master console recovery techniques, and handle emergency access scenarios.

## 🔍 Deep Understanding — TTY Subsystem and Console Internals

### The TTY Subsystem

```
Userspace
  ┌────────────────────────────────────────────┐
  │  pts/0  pts/1  pts/2    tty1  tty2  tty3  │  <-- Devices
  │    │       │       │       │     │     │    │
  └────┼───────┼───────┼───────┼─────┼─────┼────┘
       │       │       │       │     │     │
  ┌────┼───────┼───────┼───────┼─────┼─────┼────┐
  │  pty master devices     │  virtual consoles │  <-- Kernel
  │    (SSH, terminal)      │  (vt/fbcon)       │
  └─────────────────────────┴───────────────────┘
       │                              │
  ┌────┼──────────────────────────────┼──────────┐
  │  TTY layer (n_tty line discipline)          │
  └──────────────────────────────────────────────┘
```

### Key TTY Concepts

```
1. Line Discipline:
   - Transforms raw input/output
   - Handles line editing, echo, signal generation (Ctrl+C)
   - n_tty is the default line discipline

2. Pseudo-terminal (pty):
   - Master side: SSH daemon, terminal emulator
   - Slave side: the application (shell)

3. Virtual Console (vt):
   - Direct hardware access via framebuffer
   - Controlled by keyboard input

4. Serial Console:
   - Physical serial port
   - No display, just TX/RX lines
```

---

## 💻 PRACTICE SECTION — 15 Hands-On Exercises

---

### Level 1 Practices: Virtual Terminal Basics

---

### ✅ Practice 1: Check Your Current TTY

```bash
mkdir -p ~/linux-course/part23
cd ~/linux-course/part23

# Show current terminal
echo "=== Current TTY ==="
tty

# Show terminal device info
echo ""
echo "=== Terminal Info ==="
ls -la /dev/tty
ls -la $(tty)

# Show who is logged in
echo ""
echo "=== Logged in users ==="
who -a

# Show all TTY devices
echo ""
echo "=== TTY devices ==="
ls -la /dev/tty[1-6] 2>/dev/null || echo "No virtual console devices found"
ls /dev/pts/ 2>/dev/null && echo "Pseudo-terminals found (SSH/terminal sessions)"
```

---

### ✅ Practice 2: Explore Virtual Consoles with chvt

```bash
cd ~/linux-course/part23

echo "=== Virtual Console Management ==="
echo "To switch to a virtual console:"
echo ""
echo "  sudo chvt 1   # Switch to tty1"
echo "  sudo chvt 2   # Switch to tty2"
echo "  sudo chvt 3   # Switch to tty3"
echo ""
echo "Note: In a GUI environment:"
echo "  tty1 (or tty7) = Display Manager (GUI)"
echo "  tty2-tty6 = Text consoles"
echo ""
echo "Keyboard shortcuts for virtual consoles:"
echo "  Ctrl+Alt+F1  through  Ctrl+Alt+F6"
echo "  Ctrl+Alt+F7  (GUI, on many systems)"

# Show current VT
echo ""
echo "Current virtual console:"
cat /sys/class/tty/tty0/active 2>/dev/null || echo "Cannot determine"
```

---

### ✅ Practice 3: Configure Console Environment

```bash
cd ~/linux-course/part23

# Check current TERM setting
echo "=== Current Terminal Settings ==="
echo "TERM=$TERM"
echo "SHELL=$SHELL"
echo "USER=$USER"
echo "HOME=$HOME"

# Check keyboard layout
echo ""
echo "=== Keyboard Layout ==="
localectl status 2>/dev/null || echo "localectl not available"

# Check console font
echo ""
echo "=== Console Font ==="
cat /etc/default/console-setup 2>/dev/null || echo "No console-setup config"
```

---

### ✅ Practice 5: Kernel Messages and Console

```bash
cd ~/linux-course/part23

# View dmesg (kernel ring buffer)
echo "=== Recent kernel messages ==="
dmesg | tail -10

# Check if kernel messages are printing to console
echo ""
echo "=== Console log level ==="
cat /proc/sys/kernel/printk
# Values: console_loglevel default_loglevel minimum_loglevel console_loglevel_default

# Suppress kernel messages from console
echo ""
echo "To suppress kernel messages on console:"
echo "  sudo dmesg -D    # Disable"
echo "  sudo dmesg -E    # Enable"

# Show how to read kernel messages without console clutter
echo ""
echo "Kernel messages can be read safely with:"
echo "  dmesg"
echo "  journalctl -k"
```

---

### ✅ Practice 7: Console Login Simulation

```bash
cd ~/linux-course/part23

# Show what a virtual console login looks like
cat << 'EOF'
=== Virtual Console Login Experience ===

When you switch to tty2 (Ctrl+Alt+F2), you'll see:

  Ubuntu 22.04 LTS hostname tty2
  
  hostname login: your_username
  Password: 
  $
  
  (Successful login - you get a shell)
  
To exit: exit or Ctrl+D
To switch back to GUI: Ctrl+Alt+F1 (or F7)

=== Practical Notes ===

- You can log into multiple TTYs simultaneously
- Each TTY has its own shell session
- Background processes continue even when you switch away
- Use 'who' to see all logged-in sessions across TTYs
EOF
```

---

### ✅ Practice 12: Reset a Garbled Terminal

```bash
cd ~/linux-course/part23

cat << 'EOF'
=== Terminal Reset Techniques ===

When a terminal becomes garbled (binary output, wrong encoding):

  1. Try: reset
     This resets terminal settings to defaults
  
  2. Try: stty sane
     Restores saner terminal settings
  
  3. Try: Ctrl+J reset Ctrl+J
     (Ctrl+J sends a newline when Enter doesn't work)
  
  4. Try: echo $TERM
     Make sure TERM is set correctly (xterm-256color, linux, etc.)
  
  5. Try: export TERM=linux
     Force basic terminal mode

=== Prevent garbled terminals ===

  - Don't cat binary files
  - Use 'cat -v' or 'less' for unknown files
  - Use 'file' command to check file type first
  - Set proper locale: export LANG=en_US.UTF-8
EOF
```

---

### Level 2 Practices: Terminal Multiplexers and Serial Console

---

### ✅ Practice 4: Explore screen

```bash
cd ~/linux-course/part23

if command -v screen &>/dev/null; then
    echo "=== screen version ==="
    screen --version
    
    echo ""
    echo "=== screen Usage ==="
    echo "Start a session:  screen -S session_name"
    echo "List sessions:    screen -ls"
    echo "Reattach:         screen -r session_name"
    echo "Detach:           Ctrl+A, then D"
    echo ""
    echo "=== screen Key Reference ==="
    echo "  Ctrl+A C   Create new window"
    echo "  Ctrl+A N   Next window"
    echo "  Ctrl+A P   Previous window"
    echo "  Ctrl+A \"   List windows"
    echo "  Ctrl+A K   Kill window"
    echo "  Ctrl+A D   Detach"
else
    echo "screen not installed"
    echo "Install with: sudo apt install screen  (or sudo dnf install screen)"
fi
```

---

### ✅ Practice 6: Explore tmux

```bash
cd ~/linux-course/part23

if command -v tmux &>/dev/null; then
    echo "=== tmux version ==="
    tmux -V
    
    echo ""
    echo "=== tmux Usage ==="
    echo "Start a session:  tmux new -s session_name"
    echo "List sessions:    tmux ls"
    echo "Reattach:         tmux attach -t session_name"
    echo "Detach:           Ctrl+B, then D"
    echo ""
    echo "=== tmux Key Reference ==="
    echo "  Ctrl+B C   Create new window"
    echo "  Ctrl+B N   Next window"
    echo "  Ctrl+B P   Previous window"
    echo "  Ctrl+B W   List windows"
    echo "  Ctrl+B %   Split vertically"
    echo "  Ctrl+B \"   Split horizontally"
    echo "  Ctrl+B D   Detach"
else
    echo "tmux not installed"
    echo "Install with: sudo apt install tmux  (or sudo dnf install tmux)"
fi
```

---

### ✅ Practice 8: Create a screen Session with Multiple Windows

```bash
cd ~/linux-course/part23

cat << 'EOF' > screen_demo.sh
#!/bin/bash
echo "=== screen Multi-Window Demo ==="
echo ""
echo "This script shows how to work with multiple screen windows."
echo ""
echo "1. Start a new screen session:"
echo "   screen -S demosession"
echo ""
echo "2. Inside screen, create multiple windows:"
echo "   Ctrl+A C   # Create window 1 (shell)"
echo "   Ctrl+A C   # Create window 2 (shell)"
echo "   Ctrl+A C   # Create window 3 (shell)"
echo ""
echo "3. Name each window:"
echo "   Ctrl+A Shift+A   # Rename current window"
echo "   Type: logs, press Enter"
echo ""
echo "4. Switch between windows:"
echo "   Ctrl+A N   # Next window"
echo "   Ctrl+A P   # Previous window"
echo "   Ctrl+A 0   # Window 0"
echo "   Ctrl+A 1   # Window 1"
echo ""
echo "5. Detach and reattach:"
echo "   Ctrl+A D          # Detach"
echo "   screen -r demo    # Reattach"
echo ""
echo "Practical use case:"
echo "  Window 0: tail -f /var/log/syslog (monitoring)"
echo "  Window 1: vim config file (editing)"
echo "  Window 2: command line (running commands)"
EOF

chmod +x screen_demo.sh
./screen_demo.sh
```

---

### ✅ Practice 9: Create a tmux Session with Panes

```bash
cd ~/linux-course/part23

cat << 'EOF' > tmux_demo.sh
#!/bin/bash
echo "=== tmux Multi-Pane Demo ==="
echo ""
echo "tmux allows you to split the terminal into panes."
echo ""
echo "1. Start a new tmux session:"
echo "   tmux new -s demosession"
echo ""
echo "2. Create a horizontal split:"
echo "   Ctrl+B \"   # Top/bottom panes"
echo ""
echo "3. Create a vertical split:"
echo "   Ctrl+B %   # Left/right panes"
echo ""
echo "4. Navigate between panes:"
echo "   Ctrl+B Up/Down/Left/Right arrows"
echo ""
echo "5. Switch to different pane layout:"
echo "   Ctrl+B Space  # Cycle layouts"
echo "   Ctrl+B Z      # Zoom current pane (fullscreen)"
echo ""
echo "6. Resize panes:"
echo "   Ctrl+B Ctrl+Arrows  # Resize by 1 line"
echo "   Ctrl+B Alt+Arrows   # Resize by 5 lines"
echo ""
echo "Practical use case:"
echo "  Left pane:   vim (editing code)"
echo "  Top right:   running program"
echo "  Bottom right: shell for commands"
EOF

chmod +x tmux_demo.sh
./tmux_demo.sh
```

---

### ✅ Practice 10: List Active Sessions and Windows

```bash
cd ~/linux-course/part23

# Show all screen sessions
echo "=== screen sessions ==="
screen -ls 2>/dev/null || echo "No screen sessions or screen not installed"

# Show all tmux sessions
echo ""
echo "=== tmux sessions ==="
tmux ls 2>/dev/null || echo "No tmux sessions or tmux not installed"

# Show all logged-in users with their terminals
echo ""
echo "=== Current sessions ==="
who

# Show all TTY processes
echo ""
echo "=== TTY processes ==="
ps -t tty1,tty2,tty3,tty4,tty5,tty6 2>/dev/null | head -20 || echo "No virtual console processes"
```

---

### ✅ Practice 11: Serial Console Detection

```bash
cd ~/linux-course/part23

# Detect serial ports
echo "=== Serial Port Detection ==="

# Check for common serial device files
for port in ttyS0 ttyS1 ttyS2 ttyS3 ttyUSB0 ttyAMA0; do
    if [ -e "/dev/$port" ]; then
        echo "Found: /dev/$port"
    fi
done

# Check if serial-getty is enabled
echo ""
echo "=== Serial Getty Services ==="
systemctl list-units --type=service --state=running | grep "serial-getty" || echo "No serial getty services running"

# Show serial configuration possibilities
echo ""
echo "=== Serial Console Setup ==="
echo "To enable serial console on ttyS0:"
echo "  sudo systemctl enable serial-getty@ttyS0.service"
echo "  sudo systemctl start serial-getty@ttyS0.service"
```

---

### ✅ Practice 13: Create a Persistent Session

```bash
cd ~/linux-course/part23

echo "=== Persistent Sessions ==="
echo ""
echo "A persistent session survives network disconnects."
echo ""
echo "Workflow:"
echo ""
echo "  1. Connect to server via SSH:"
echo "     ssh user@server"
echo ""
echo "  2. Start a tmux session:"
echo "     tmux new -s important_work"
echo ""
echo "  3. Do your work..."
echo "     (compile code, run long process, edit files)"
echo ""
echo "  4. Network drops! But that's fine..."
echo ""
echo "  5. Reconnect via SSH:"
echo "     ssh user@server"
echo ""
echo "  6. Reattach to the session:"
echo "     tmux attach -t important_work"
echo ""
echo "  Your work is still running. All processes survived."
echo ""
echo "  [Persistence is the #1 reason sysadmins use tmux/screen]"
```

---

### ✅ Practice 14: Log Terminal Output

```bash
cd ~/linux-course/part23

# Using script command (available everywhere)
echo "=== Terminal Logging with 'script' ==="
echo ""
echo "  script session.log     # Start recording"
echo "  ... run commands ..."
echo "  exit                   # Stop recording"
echo ""

# Demo: create a script log
script -q /dev/null -c "echo 'This is a test command'; echo 'All output was logged'" > /dev/null 2>&1 || true

# Using screen logging
echo "=== screen Logging ==="
echo "  Inside screen: Ctrl+A, then H"
echo "  This toggles logging to screenlog.N (N = window number)"

# Using tmux logging
echo ""
echo "=== tmux Logging ==="
echo "  Capture pane content:"
echo "    tmux capture-pane -pS - > tmux_output.log"
echo ""
echo "  Or use pipe:"
echo "    tmux pipe-pane -o 'cat >> tmux_log.txt'"
```

---

### Level 3 Practices: Advanced Console Management

---

### ✅ Practice 15: Console Management Script

```bash
cd ~/linux-course/part23

cat > console_manager.sh << 'EOF'
#!/bin/bash
set -euo pipefail

echo "=========================================="
echo "  CONSOLE MANAGEMENT REPORT"
echo "  $(date)"
echo "=========================================="
echo ""

# Section 1: Current terminal
echo "1. CURRENT TERMINAL"
echo "   TTY: $(tty)"
echo "   TERM: $TERM"
echo ""

# Section 2: Active sessions
echo "2. ACTIVE SESSIONS"
who | awk '{print "   " $1 " on " $2 " since " $3 " " $4}'
echo ""

# Section 3: Virtual consoles
echo "3. VIRTUAL CONSOLES"
for i in 1 2 3 4 5 6; do
    if [ -e "/dev/tty$i" ]; then
        echo "   tty$i: exists"
    fi
done
echo ""

# Section 4: Serial ports
echo "4. SERIAL PORTS"
for port in ttyS0 ttyS1 ttyS2 ttyS3 ttyUSB0; do
    if [ -e "/dev/$port" ]; then
        echo "   /dev/$port: found"
    fi
done
echo ""

# Section 5: Screen/tmux sessions
echo "5. TERMINAL MULTIPLEXERS"
if command -v screen &>/dev/null; then
    echo "   screen: installed"
    screen -ls 2>/dev/null | grep -v "No" | grep -v "^$" | sed 's/^/   /' || echo "   screen: no active sessions"
fi
if command -v tmux &>/dev/null; then
    echo "   tmux: installed"
    tmux ls 2>/dev/null | sed 's/^/   /' || echo "   tmux: no active sessions"
fi
echo ""

# Section 6: Console settings
echo "6. CONSOLE SETTINGS"
echo "   Keyboard: $(localectl status 2>/dev/null | grep "Keymap" | awk '{print $2}')"
echo ""

echo "=========================================="
echo "  REPORT COMPLETE"
echo "=========================================="
EOF

chmod +x console_manager.sh
./console_manager.sh
```

---

## 🧠 Deep Understanding — TTY Internals and Console Recovery

### The TTY Stack

```
Application (shell, editor)
    ↓  writes to stdout (file descriptor 1)
Terminal Emulation (in kernel: n_tty)
    ↓  processes: echo, line buffering, signals
Device Driver (console, serial, pty)
    ↓  hardware-specific
Physical/Logical Device (screen, serial port, SSH socket)
```

### Line Discipline Processing

```
Raw input → Line discipline → Cooked/raw output

In cooked mode (default):
  - Backspace works
  - Ctrl+C sends SIGINT
  - Ctrl+D sends EOF
  - Ctrl+Z sends SIGTSTP
  - Lines are buffered until Enter

In raw mode (used by vim, emacs):
  - Each keystroke is sent immediately
  - No line editing
  - Application handles all input
```

### Console Recovery

```bash
# Scenario: System boots but network is down
# Solution: Walk user through rescue

# 1. Boot from GRUB to single user mode
#    Press 'e' at GRUB, add 'single' to kernel line

# 2. Mount filesystem read-write
mount -o remount,rw /

# 3. Fix the issue (network config, etc.)
vi /etc/netplan/00-installer-config.yaml

# 4. Reboot
reboot

# Scenario: System hangs at boot
# Solution: Use serial console to see kernel messages

# Serial console shows:
# [  OK  ] Started Network Manager
# [FAILED] Failed to mount /data
#         See 'systemctl status data.mount' for details
# [  OK  ] Started SSH

# This tells you exactly which service failed
```

---

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

## 🚀 What's Coming in Part 24

**Part 24: Kernel Modules and Device Drivers**

You will learn:
- Linux kernel module management
- Loading and unloading modules
- Module dependencies and parameters
- Building custom kernel modules
- Troubleshooting device drivers
- 15 hands-on practices

---

## 📝 Self-Test — Can You Answer These?

1. What is a virtual terminal (TTY) in Linux?
2. How do you switch between virtual consoles?
3. What is the difference between `/dev/tty1` and `/dev/pts/0`?
4. What is a terminal multiplexer and why would you use one?
5. What is the key difference between `screen` and `tmux`?
6. How do you detach from a screen session and reattach later?
7. What is the default prefix key for tmux? For screen?
8. How do you split a tmux window vertically?
9. What is serial console and when is it useful?
10. How do you enable a serial getty on ttyS0?
11. How do you reset a garbled terminal?
12. What does the `script` command do?
13. What happens when you press Ctrl+C in a terminal?
14. What is single user mode and how do you enter it?
15. Why do sysadmins use tmux or screen for remote work?

**Score:** 12/15 correct = ready for Part 24.

---

*Linux SysAdmin Course | Part 23 of ∞ | Reverse Engineering Approach*
*Previous → Part 22: Network Services — DHCP, HTTP, SSH*
*Next → Part 24: Kernel Modules and Device Drivers*

[← Previous](part22.md) | [Next →](part24.md)
