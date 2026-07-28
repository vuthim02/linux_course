## 🔍 Section 4: Network Service Management

### systemd Service Management

```bash
# List all services
systemctl list-units --type=service

# List running services
systemctl list-units --type=service --state=running

# Start/stop/restart/reload
sudo systemctl start sshd
sudo systemctl stop sshd
sudo systemctl restart sshd
sudo systemctl reload sshd    # Load config without dropping connections

# Enable/disable at boot
sudo systemctl enable sshd
sudo systemctl disable sshd

# Check status
systemctl status sshd         # Shows whether running, recent logs
```

### Service Dependencies

```bash
# Show service dependencies
systemctl list-dependencies sshd

# Show what depends on this service
systemctl list-dependencies sshd --reverse

# Edit service override (don't edit the main unit file)
sudo systemctl edit sshd

# Show service file content
systemctl cat sshd
```

### Checking Ports and Sockets

```bash
# Check listening ports
sudo ss -tlnp     # TCP listening with process info
sudo ss -ulnp     # UDP listening
ss -tlnp | grep :80    # Check if HTTP is listening

# Alternative
sudo netstat -tlnp      # If netstat is installed

# Check socket units
systemctl list-sockets
```





[← Previous](06-section-3-ssh-server.md) | [↑ Index](index.md) | [Next →](08-section-5-securing-network-services.md)
