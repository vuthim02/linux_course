## 🔍 Section 4: Creating a Custom Service

A systemd service file has three main sections: `[Unit]`, `[Service]`, and `[Install]`.

### Anatomy of a Service File

```bash
# Example: Create a simple "hello-server" service
sudo cat /etc/systemd/system/hello.service
```

```ini
[Unit]
Description=Hello World Service
After=network.target
Wants=network-online.target

[Service]
Type=simple
User=nobody
Group=nogroup
WorkingDirectory=/opt/hello
ExecStart=/usr/local/bin/hello-server
ExecReload=/bin/kill -HUP $MAINPID
Restart=on-failure
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

### Explanation of Key Directives

**`[Unit]` section:**

| Directive | Purpose |
|-----------|---------|
| Description | Human-readable name |
| After | Ordering: start AFTER this unit |
| Before | Ordering: start BEFORE this unit |
| Requires | Hard dependency (if this fails, unit fails) |
| Wants | Soft dependency (best-effort) |
| Conflicts | Cannot run with this unit |

**`[Service]` section:**

| Directive | Purpose |
|-----------|---------|
| Type | simple, forking, oneshot, notify, dbus, idle |
| ExecStart | Command to start the service (full path) |
| ExecStop | Command to stop the service |
| ExecReload | Command to reload config |
| User | Run as this user (security!) |
| Group | Run with this group |
| WorkingDirectory | CD to this directory before running |
| Restart | When to restart: always, on-failure, on-abnormal, no |
| RestartSec | Seconds to wait before restart |
| Environment | Set environment variable (KEY=value) |
| StandardOutput | Where stdout goes (journal, syslog, file) |
| StandardError | Where stderr goes |

**`[Install]` section:**

| Directive | Purpose |
|-----------|---------|
| WantedBy | Creates a symlink in `.wants/` directory |
| RequiredBy | Creates a symlink in `.requires/` directory |
| Alias | Alternative name for the unit |

### Service Types Explained

```bash
# Type=simple (default)
# - ExecStart starts the main process
# - systemd considers the service started immediately

# Type=forking
# - The process forks (child continues, parent exits)
# - systemd waits for the parent to exit
# - Required for traditional daemons (sshd, httpd)
# - MUST specify PIDFile so systemd can track the child

# Type=oneshot
# - Runs once and exits
# - systemd considers it active while running, then inactive
# - Used for setup/cleanup tasks
# - Add RemainAfterExit=yes to keep it "active"

# Type=notify
# - The process sends sd_notify() when ready
# - Most modern, precise
```

### Complete Example: A Script That Runs Once at Boot

```ini
[Unit]
Description=Custom initialization script
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/custom-init.sh
RemainAfterExit=yes
StandardOutput=journal

[Install]
WantedBy=multi-user.target
```

### Creating the Service Step by Step

```bash
# 1. Create the script
sudo tee /usr/local/bin/hello-server << 'EOF'
#!/bin/bash
while true; do
    echo "Hello from systemd service at $(date)"
    sleep 60
done
EOF

sudo chmod +x /usr/local/bin/hello-server

# 2. Create the service file
sudo tee /etc/systemd/system/hello.service << 'EOF'
[Unit]
Description=Hello World Service

[Service]
Type=simple
ExecStart=/usr/local/bin/hello-server
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# 3. Reload systemd (required after creating/editing unit files)
sudo systemctl daemon-reload

# 4. Enable and start
sudo systemctl enable --now hello

# 5. Verify
systemctl status hello
journalctl -u hello -n 5
```





[← Previous](06-section-3-understanding-unit-types.md) | [↑ Index](index.md) | [Next →](08-section-5-viewing-and-managing.md)
