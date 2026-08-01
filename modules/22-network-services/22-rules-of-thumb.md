## 📏 Rules of Thumb

### The Service Management Rules

| Rule | Description | Why |
|------|-------------|-----|
| **Check status first** | `systemctl status` | See what's wrong |
| **Check logs second** | `journalctl -u` | See errors |
| **Use enable --now** | Start + at boot | Efficiency |
| **Use reload not restart** | When possible | Zero downtime |

### The "Service Not Working" Checklist

```bash
# 1. Check if running:
systemctl status service

# 2. Check if listening:
ss -tlnp | grep :PORT

# 3. Check firewall:
sudo ufw status                    # Debian/Ubuntu
sudo firewall-cmd --list-all       # RHEL/Fedora

# 4. Check logs:
journalctl -u service -n 50

# 5. Check dependencies:
systemctl list-dependencies service
```

---

**Why these rules matter:** Following these rules helps you diagnose and fix service issues quickly.

[← Previous](16-self-test-can-you-answer-these.md) | [↑ Index](index.md)
