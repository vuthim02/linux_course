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



---

[← Previous](10-deep-understanding-tty-subsystem-and.md) | [↑ Index](index.md) | [Next →](12-deep-understanding-tty-internals-and.md)
