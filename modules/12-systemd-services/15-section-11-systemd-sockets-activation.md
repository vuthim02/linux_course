## 🔍 Section 11: Systemd Sockets — Activation on Demand

Socket activation means a service starts only when something connects to its socket.

### How It Works

```
1. systemd creates and listens on the socket
2. Client connects
3. systemd starts the service
4. systemd passes the socket to the service
5. Service handles the client
6. After inactivity, systemd stops the service (optional)
```

### Example: SSH Socket Activation

```bash
# SSH has both sshd.service and sshd.socket
# With socket activation:
# - sshd.socket listens on port 22 at boot
# - sshd.service starts only when someone connects

# Enable socket activation
sudo systemctl disable sshd.service
sudo systemctl enable --now sshd.socket
```

### Creating a Socket-Activated Service

```ini
# /etc/systemd/system/echo.socket
[Unit]
Description=Echo socket

[Socket]
ListenStream=2000
Accept=yes

[Install]
WantedBy=sockets.target
```

```ini
# /etc/systemd/system/echo@.service
[Unit]
Description=Echo service for %i

[Service]
Type=simple
ExecStart=/usr/local/bin/echo-server
StandardInput=socket
StandardOutput=socket
```

---



---

[← Previous](14-section-10-debugging-failed-services.md) | [↑ Index](index.md) | [Next →](16-section-12-resource-control-with.md)
