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



---

[← Previous](07-section-4-serial-console.md) | [↑ Index](index.md) | [Next →](09-level-3-advanced-console-internals.md)
