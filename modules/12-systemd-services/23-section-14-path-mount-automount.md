## 🔍 Section 14: Path, Mount, and Automount Units

### Path Units — Trigger on File Changes

Run a service when a file or directory changes.

```ini
# /etc/systemd/system/watch-config.path
[Unit]
Description=Watch config directory

[Path]
PathModified=/etc/myapp/config.d
Unit=reload-myapp.service

[Install]
WantedBy=multi-user.target
```

```ini
# /etc/systemd/system/reload-myapp.service
[Unit]
Description=Reload myapp configuration

[Service]
Type=oneshot
ExecStart=/usr/bin/systemctl reload myapp
```

```bash
# Enable the path unit (not the service!)
sudo systemctl enable --now watch-config.path

# Other Path directives:
# PathExists=/path         — trigger when path exists
# PathExistsGlob=/glob     — trigger when glob matches
# PathChanged=/path        — trigger on write close
# DirectoryNotEmpty=/dir   — trigger when dir has entries
```

### Mount Units — systemd-Managed Mounts

Replace `/etc/fstab` entries with systemd `.mount` units.

```bash
# Mount unit naming: the path must be escaped
# /mnt/data → mnt-data.mount
# /var/lib/docker → var-lib-docker.mount
```

```ini
# /etc/systemd/system/mnt-data.mount
[Unit]
Description=Data partition

[Mount]
What=/dev/sdb1
Where=/mnt/data
Type=ext4
Options=defaults,noatime

[Install]
WantedBy=multi-user.target
```

```bash
# Manage like any unit
sudo systemctl enable --now mnt-data.mount
systemctl status mnt-data.mount

# List active mounts
systemctl list-units --type=mount
```

### Automount Units — Mount on Demand

```ini
# /etc/systemd/system/mnt-data.automount
[Unit]
Description=Auto-mount data partition

[Automount]
Where=/mnt/data
TimeoutIdleSec=300     # Unmount after 5 min of inactivity

[Install]
WantedBy=multi-user.target
```

```bash
# Enable the automount (not the mount unit directly)
sudo systemctl enable --now mnt-data.automount

# The filesystem is mounted on first access
ls /mnt/data             # Triggers mount automatically

# After 5min of no access, systemd auto-unmounts
```

### fstab Integration

```bash
# systemd generates .mount and .automount units from /etc/fstab
# Every fstab entry becomes a systemd unit

# Convert fstab entries to systemd units
systemctl list-units --type=mount --all

# systemd-fstab-generator creates these at boot
# View generated units:
ls /run/systemd/generator/
```



[← Previous](22-section-13-dropins-and-edit.md) | [↑ Index](index.md) | [Next →](24-section-15-user-services.md)
