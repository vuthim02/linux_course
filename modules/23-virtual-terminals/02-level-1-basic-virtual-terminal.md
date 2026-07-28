## ⭐ Level 1: Basic — Virtual Terminal Basics

![Linux virtual terminal — text console interface](https://upload.wikimedia.org/wikipedia/commons/1/1e/Terminal_icon.svg)

*Linux terminal icon — representing virtual console access (Wikimedia Commons / public domain)*

> **Level 1 Goal:** Understand the Linux virtual terminal system, how to switch between consoles, configure console settings, and manage TTY devices.

### What You'll Cover
- What virtual terminals (TTYS) are and how they differ from pseudo-terminals
- Switching between consoles with Ctrl+Alt+F1 through F6
- Identifying your current TTY with `tty` and `who`
- Configuring console fonts and keymaps with `setupcon`
- Understanding `/dev/tty` and `/dev/console` device files

Virtual terminals give you direct access to the kernel console, independent of any graphical environment or SSH session. When a system boots into multi-user mode, the kernel spawns multiple TTY devices (`/dev/tty1` through `/dev/tty6`), each running a `getty` process that waits for a login prompt. This is your fallback when X11 crashes or the network goes down.

Key concepts to internalize at this level:

- **TTY vs PTY**: A TTY is a real hardware or virtual console device. A PTY (pseudo-terminal) is what SSH sessions and terminal emulators use. The `tty` command tells you which one you are on.
- **Switching**: Ctrl+Alt+F1 through F6 cycle through virtual consoles. In graphical mode, Ctrl+Alt+F7 (or F1 on some distros) returns to the desktop.
- **Device files**: `/dev/console` is the system console (where kernel messages go). `/dev/tty` is an alias for your current terminal. `/dev/tty0` is the current active virtual console.


[← Previous](01-what-you-will-achieve-in.md) | [↑ Index](index.md) | [Next →](03-section-1-virtual-terminals.md)
