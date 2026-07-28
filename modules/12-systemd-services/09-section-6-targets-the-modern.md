## 🔍 Section 6: Targets — The Modern Runlevel

Systemd targets replace SysV runlevels.

### Runlevel to Target Mapping

| SysV Runlevel | systemd Target | Purpose |
|---|---|---|
| 0 | poweroff.target | Shut down |
| 1 | rescue.target | Single-user mode (maintenance) |
| 2, 3, 4 | multi-user.target | Multi-user, text mode (no GUI) |
| 5 | graphical.target | Multi-user with GUI |
| 6 | reboot.target | Reboot |

### Managing Targets

```bash
# Current default target
systemctl get-default

# Set default target (what boots by default)
sudo systemctl set-default multi-user.target

# Boot into rescue mode next time
sudo systemctl set-default rescue.target

# Change target right now (without reboot)
sudo systemctl isolate multi-user.target

# List all targets and their state
systemctl list-units --type=target
```

### Emergency vs Rescue Mode

```bash
# rescue.target — single user, basic services, file systems mounted
# emergency.target — only a shell, root fs read-only, nothing else

# Boot into rescue:
sudo systemctl rescue

# Boot into emergency:
sudo systemctl emergency
```





[← Previous](08-section-5-viewing-and-managing.md) | [↑ Index](index.md) | [Next →](10-section-7-journald-systemds-logging.md)
