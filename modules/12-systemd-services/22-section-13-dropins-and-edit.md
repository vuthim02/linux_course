## 🔍 Section 13: Drop-in Overrides and systemctl edit

### Why Drop-ins?

Never edit `/usr/lib/systemd/system/` files directly — package updates overwrite them. Use drop-ins in `/etc/systemd/system/` to override only what you need.

### Using `systemctl edit`

```bash
# Opens an override file for the service
sudo systemctl edit nginx

# Creates /etc/systemd/system/nginx.service.d/override.conf
# Only the directives you set here override the original
```

Example override:

```ini
# /etc/systemd/system/nginx.service.d/override.conf
[Service]
Restart=always
RestartSec=10
MemoryMax=512M
```

### Manual Drop-in Structure

```bash
# Directory structure
/etc/systemd/system/
└── nginx.service.d/
    ├── override.conf          # Main overrides
    ├── resource-limits.conf   # Separate concern
    └── custom-port.conf       # Another concern

# systemd merges ALL .conf files in alphabetical order
# Later files override earlier ones
```

### Common Override Patterns

```bash
# Add extra dependencies (without replacing existing ones)
sudo systemctl edit nginx --drop-in=extra-deps
```

```ini
# extra-deps.conf
[Unit]
# These APPEND to existing dependencies, not replace them
Requires=network-online.target
After=network-online.target
```

### Viewing the Merged Configuration

```bash
# See the final merged unit (original + all drop-ins)
systemctl cat nginx

# Example output shows source comments:
# /usr/lib/systemd/system/nginx.service
# /etc/systemd/system/nginx.service.d/override.conf
```

### `systemd-delta` — See All Overrides

```bash
# Show ALL differences between /usr/lib and /etc
systemd-delta

# Overridden files show as [OVERRIDES]
# New files show as [EXTENDED]
# Masked files show as [MASKED]

# Filter by type
systemd-delta --type=overridden
systemd-delta --type=masked
```

### Reverting an Override

```bash
# Remove your override
sudo rm /etc/systemd/system/nginx.service.d/override.conf
sudo systemctl daemon-reload

# Or use:
sudo systemctl revert nginx   # Removes ALL drop-ins for this unit
```

### Preset Files — Managing Default Enable State

```bash
# /usr/lib/systemd/system-preset/99-default.preset
# Controls which services are enabled by default at install
# Used by distributions to set policies

# Check preset state
systemctl preset nginx
systemctl preset-all

# List presets
systemd-preset-list
```



[← Previous](21-self-test-can-you-answer-these.md) | [↑ Index](index.md) | [Next →](23-section-14-path-mount-automount.md)
