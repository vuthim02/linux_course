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



---

[← Previous](02-level-1-basic-virtual-terminal.md) | [↑ Index](index.md) | [Next →](04-level-2-intermediary-terminal-multiplexers.md)
