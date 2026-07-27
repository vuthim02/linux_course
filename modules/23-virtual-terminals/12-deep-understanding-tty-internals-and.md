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



---

[← Previous](11-practice-section-15-hands-on-exercises.md) | [↑ Index](index.md) | [Next →](13-summary-complete-command-reference-for.md)
