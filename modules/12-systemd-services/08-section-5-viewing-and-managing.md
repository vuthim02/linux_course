## 🔍 Section 5: Viewing and Managing Services

### Listing and Filtering Services

```bash
# All running services
systemctl list-units --type=service --state=running

# All failed services
systemctl list-units --type=service --state=failed

# All enabled services
systemctl list-unit-files --type=service --state=enabled

# All disabled services
systemctl list-unit-files --type=service --state=disabled

# Services that failed recently
systemctl --failed
```

### Service Dependencies

```bash
# Show what a service depends on
systemctl list-dependencies nginx

# Show what depends on a service
systemctl list-dependencies --reverse nginx
```

### Editing Service Files Safely

```bash
# Method 1: Full override (creates a new file in /etc)
sudo systemctl edit --full nginx
# Opens an editor with the full service file
# Saves to /etc/systemd/system/nginx.service

# Method 2: Drop-in override (adds to existing)
sudo systemctl edit nginx
# Creates /etc/systemd/system/nginx.service.d/override.conf
# Only the directives you specify override the original

# View drop-in overrides
systemctl cat nginx
```

### Using Drop-in Overrides

```bash
# Instead of editing the system unit file:
# 1. Create a drop-in directory and file
sudo mkdir -p /etc/systemd/system/nginx.service.d/
sudo tee /etc/systemd/system/nginx.service.d/custom.conf << 'EOF'
[Service]
Restart=always
RestartSec=10
EOF

# 2. Reload
sudo systemctl daemon-reload

# 3. Check the merged configuration
systemctl cat nginx
```

---



---

[← Previous](07-section-4-creating-a-custom.md) | [↑ Index](index.md) | [Next →](09-section-6-targets-the-modern.md)
