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





[← Previous](06-section-3-terminal-multiplexers-tmux.md) | [↑ Index](index.md) | [Next →](08-section-5-console-management.md)
