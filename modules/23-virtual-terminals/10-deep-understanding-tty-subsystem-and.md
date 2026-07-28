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





[← Previous](09-level-3-advanced-console-internals.md) | [↑ Index](index.md) | [Next →](11-practice-section-15-hands-on-exercises.md)
