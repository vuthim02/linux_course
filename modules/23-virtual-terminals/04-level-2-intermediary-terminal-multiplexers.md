## ⭐ Level 2: Intermediary — Terminal Multiplexers and Serial Console

![GNU Screen — terminal multiplexer with multiple windows](https://upload.wikimedia.org/wikipedia/commons/5/5a/GNU_Screen_screenshot.png)

*GNU Screen terminal multiplexer (Wikimedia Commons / public domain)*

> **Level 2 Goal:** Master terminal multiplexers (screen and tmux) for persistent remote sessions, and configure serial console access for out-of-band server management.

### What You'll Cover
- GNU Screen basics: creating sessions, detaching, reattaching
- Screen window management: splits, regions, and navigation
- tmux fundamentals: sessions, windows, and panes
- tmux status bar customization and key bindings
- Serial console setup with `minicom` and systemd-logind

Terminal multiplexers solve a critical problem: SSH sessions die when your connection drops. With `screen` or `tmux`, you detach your session before disconnecting and reattach later — your work is still running exactly where you left off.

At this level you will learn two essential tools:

- **GNU Screen**: The classic multiplexer. Create a session with `screen -S name`, detach with Ctrl+A then D, and reattach with `screen -r name`. Screen supports split regions (`Ctrl+A S` for horizontal, `Ctrl+A |` for vertical) and named windows.
- **tmux**: The modern alternative. `tmux new -s name` creates a session, `tmux detach` detaches it, `tmux attach -t name` reattaches. tmux uses a consistent prefix key (Ctrl+B by default) and offers a status bar showing session name, window list, and system load.
- **Serial console**: For headless servers or embedded devices, `minicom` provides serial terminal access. Configure `systemd-logind` to spawn a `getty` on a serial device like `/dev/ttyS0` for out-of-band management.


[← Previous](03-section-1-virtual-terminals.md) | [↑ Index](index.md) | [Next →](05-section-2-terminal-multiplexers-screen.md)
