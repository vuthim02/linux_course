## 🔍 Section 15: User Services and Environment Management

### User Services — `systemctl --user`

Systemd can manage services per-user, running as a non-root user.

```bash
# Enable lingering (user services survive logout)
sudo loginctl enable-linger $USER

# Manage user services
systemctl --user status
systemctl --user list-units

# Start/enable user services
systemctl --user enable --now my-service
```

```ini
# ~/.config/systemd/user/my-service.service
[Unit]
Description=My personal service

[Service]
Type=simple
ExecStart=/home/user/bin/my-script.sh
Restart=on-failure

[Install]
WantedBy=default.target
```

```bash
# User targets
# default.target  — what starts with your session
# Graphical session has graphical-session.target
# See all user targets:
systemctl --user list-units --type=target
```

### EnvironmentFile — Clean Configuration

```bash
# Separate config from the service unit
```

```ini
# /etc/default/myapp
# This file is sourced by the service
MYAPP_PORT=8080
MYAPP_DEBUG=false
MYAPP_MAX_CONNECTIONS=100
DATA_DIR=/var/lib/myapp
```

```ini
# /etc/systemd/system/myapp.service
[Service]
EnvironmentFile=-/etc/default/myapp
# The '-' means "ignore if file doesn't exist"
ExecStart=/usr/bin/myapp --port ${MYAPP_PORT}
```

### Environment Directives Compared

```bash
# Inline (one variable)
Environment=MYAPP_PORT=8080

# Multiple variables (space-separated, quote if needed)
Environment="MYAPP_PORT=8080" "MYAPP_DEBUG=true"

# From file
EnvironmentFile=/etc/default/myapp

# From file with fallback
EnvironmentFile=-/etc/default/myapp  # '-' = ignore missing

# From directory (all files)
EnvironmentFile=/etc/myapp/env.d/
```

### Passing Credentials Securely

```bash
# systemd 248+ — LoadCredential (avoids env vars in process list)
```

```ini
[Service]
LoadCredential=db-password:/etc/cred/db-pass.txt
ExecStart=/usr/bin/myapp --db-pass "${CREDENTIALS_DIRECTORY}/db-password"
```

### systemd-sysusers — Manage System Users

```bash
# /usr/lib/sysusers.d/myapp.conf
# Creates system users for services at install time
u myapp - "MyApp service user" /var/lib/myapp /sbin/nologin

# Apply
systemd-sysusers
```



[← Previous](23-section-14-path-mount-automount.md) | [↑ Index](index.md) | [Next →](25-section-16-networkd-resolved.md)
