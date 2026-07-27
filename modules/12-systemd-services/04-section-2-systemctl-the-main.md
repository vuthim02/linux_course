## 🔍 Section 2: systemctl — The Main Control Tool

`systemctl` is THE command for interacting with systemd.

### Service Lifecycle Commands

```bash
# Check status of a service
systemctl status nginx

# Start a service
sudo systemctl start nginx

# Stop a service
sudo systemctl stop nginx

# Restart a service
sudo systemctl restart nginx

# Reload configuration (without restarting)
sudo systemctl reload nginx

# Reload or restart (reload if possible, else restart)
sudo systemctl reload-or-restart nginx
```

### Status Output Explained

```bash
systemctl status nginx
```

```
● nginx.service - A high performance web server and a reverse proxy server
     Loaded: loaded (/usr/lib/systemd/system/nginx.service; enabled; vendor preset: enabled)
     Active: active (running) since Tue 2024-01-15 10:23:45 UTC; 2h 3min ago
    Process: 1234 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=0/SUCCESS)
    Process: 1235 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
   Main PID: 1236 (nginx)
      Tasks: 3 (limit: 2345)
     Memory: 8.2M
        CPU: 50ms
     CGroup: /system.slice/nginx.service
              ├─1236 nginx: master process /usr/sbin/nginx
              └─1237 nginx: worker process
```

| Field | Meaning |
|-------|---------|
| Loaded | Is the unit loaded? Is it enabled to start at boot? |
| Active | Running, exited, failed, etc. |
| Main PID | The main process ID |
| Tasks | Number of processes in this service |
| Memory | Memory usage |
| CGroup | Control group hierarchy |

### Enabling and Disabling Services

```bash
# Enable — service starts automatically at boot
sudo systemctl enable nginx

# Disable — service will NOT start at boot
sudo systemctl disable nginx

# Enable and start right now (combines both)
sudo systemctl enable --now nginx

# Check if a service is enabled
systemctl is-enabled nginx

# Check if a service is active (running)
systemctl is-active nginx
```

### The Four States of a Service

```bash
# 1. enabled + active = running now, starts on boot (normal)
# 2. enabled + inactive = starts on boot but not running now (unusual)
# 3. disabled + active = running now but won't start on boot
# 4. disabled + inactive = not running, won't start on boot

# Check both
systemctl status nginx
# Shows: Loaded: ... enabled ... Active: active (running)
```

### Masking and Unmasking

```bash
# Mask — PREVENTS a service from ever starting (even manually)
sudo systemctl mask nginx
sudo systemctl start nginx  # Fails: "Unit nginx.service is masked."

# Unmask — restore normal behavior
sudo systemctl unmask nginx
```

Masking is stronger than disabling:
- Disable: prevents auto-start, but can still be started manually
- Mask: creates symlink to /dev/null — cannot be started at all

---



---

[← Previous](03-section-1-what-is-systemd.md) | [↑ Index](index.md) | [Next →](05-level-2-intermediary-service-creation.md)
