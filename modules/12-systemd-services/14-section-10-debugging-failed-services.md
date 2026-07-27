## 🔍 Section 10: Debugging Failed Services

### Finding Failed Services

```bash
# Show ALL failed units
systemctl --failed

# Show only failed services
systemctl list-units --type=service --state=failed
```

### Investigating a Failure

```bash
# 1. Check status
systemctl status nginx

# 2. Check journal for the service
journalctl -u nginx -n 50 --no-pager

# 3. Check journal since last boot
journalctl -u nginx -b

# 4. Follow the journal while trying to start
sudo systemctl start nginx
journalctl -u nginx -f
```

### Common Failure Reasons

```bash
# 1. Permission denied
# Check: ExecStart path has correct permissions
# Fix: chmod +x /path/to/executable

# 2. Port already in use
# Check: journalctl -u nginx
# Fix: Change port or stop conflicting service

# 3. Missing dependency
# Check: systemctl list-dependencies nginx

# 4. Timeout (service didn't start in time)
# Fix: Add TimeoutStartSec= in [Service] section
```

### Service Restart Policies

```ini
[Service]
Restart=on-failure    # Restart only on failure (exit code != 0)
Restart=always        # Restart even on clean exit
Restart=on-abnormal   # Restart on signal, timeout, watchdog
Restart=on-abort      # Restart on uncaught signal
Restart=no            # Never restart (default)

# Controls how often to retry
StartLimitBurst=5     # Max failures in interval
StartLimitIntervalSec=10  # Interval in seconds
```

### Manual Reset After Limit

```bash
# If a service hits the start limit:
# "start-limit-hit" — service won't try again
# Reset with:
sudo systemctl reset-failed nginx
```

---



---

[← Previous](13-level-3-advanced-debugging-and.md) | [↑ Index](index.md) | [Next →](15-section-11-systemd-sockets-activation.md)
