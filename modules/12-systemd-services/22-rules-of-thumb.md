## 📏 Rules of Thumb

### The systemd Rules

| Rule | Description | Why |
|------|-------------|-----|
| **Always daemon-reload** | After changing unit files | Reload configuration |
| **Check status first** | `systemctl status` | See what's wrong |
| **Check logs second** | `journalctl -u` | See errors |
| **Use reload not restart** | When possible | Zero downtime |
| **Enable critical services** | `systemctl enable` | Start at boot |

### The Unit File Rules

| Rule | Description | Why |
|------|-------------|-----|
| **Use drop-in files** | `/etc/systemd/system/service.d/` | Don't edit package files |
| **Set Restart=always** | For critical services | Auto-recovery |
| **Set proper timeouts** | Prevent hung services | Resource management |
| **Use After= for ordering** | Start dependencies first | Correct startup |

### The "Service Won't Start" Checklist

```bash
# 1. Check status:
systemctl status service

# 2. Check logs:
journalctl -u service -n 50

# 3. Check syntax:
systemd-analyze verify /etc/systemd/system/service.service

# 4. Check dependencies:
systemctl list-dependencies service

# 5. Check permissions:
ls -la /usr/bin/service
```

### The "Service Keeps Restarting" Checklist

```bash
# 1. Check restart count:
systemctl status service | grep -i restart

# 2. Check logs:
journalctl -u service -f

# 3. Check resource limits:
systemctl show service | grep -E "Memory|CPU"

# 4. Check dependencies:
systemctl list-dependencies service

# 5. Check configuration:
cat /etc/systemd/system/service.service
```

### The Timer vs Cron Rules

| Feature | systemd timer | cron |
|---------|--------------|------|
| Logging | journalctl | /var/log/syslog |
| Dependency | Yes | No |
| Resource control | Yes | No |
| Persistent | Yes (with Persistent=true) | No |
| Accuracy | Better | Minute granularity |

---

**Why these rules matter:** systemd is the backbone of modern Linux. Following these rules ensures your services are reliable and maintainable.

[← Previous](21-self-test-can-you-answer-these.md) | [↑ Index](index.md)
