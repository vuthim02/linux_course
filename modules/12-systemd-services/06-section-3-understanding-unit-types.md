## 🔍 Section 3: Understanding Unit Types

systemd manages "units" — not just services. Every resource is a unit.

### Common Unit Types

| Type | Extension | Purpose |
|------|-----------|---------|
| Service | `.service` | A daemon or application |
| Socket | `.socket` | IPC or network socket |
| Timer | `.timer` | Scheduled task (cron replacement) |
| Target | `.target` | Group of units (runlevel replacement) |
| Path | `.path` | Trigger action when file changes |
| Mount | `.mount` | Mount a filesystem |
| Automount | `.automount` | Auto-mount on access |
| Device | `.device` | Kernel device |
| Slice | `.slice` | Resource management group |

```bash
# List all units of a specific type
systemctl list-units --type=service
systemctl list-units --type=target
systemctl list-units --type=timer

# List ALL units (all types)
systemctl list-units

# List all unit files (even inactive)
systemctl list-unit-files
```

### Where Unit Files Live

```bash
# System units (shipped by packages)
ls /usr/lib/systemd/system/

# System administrator overrides
ls /etc/systemd/system/

# Runtime units (lost on reboot)
ls /run/systemd/system/
```

**Priority:** `/etc/systemd/system/` overrides `/usr/lib/systemd/system/`. This is how you customize without editing package files.





[← Previous](05-level-2-intermediary-service-creation.md) | [↑ Index](index.md) | [Next →](07-section-4-creating-a-custom.md)
