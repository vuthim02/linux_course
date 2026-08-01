## 📏 Rules of Thumb

### The Time Sync Rules

| Rule | Description | Why |
|------|-------------|-----|
| **Use Chrony** | Better than ntpd for VMs | Accuracy |
| **Check chronyc sources** | `*` = synced | Status |
| **Force sync if needed** | `chronyc makestep` | Quick fix |
| **Enable NTP at boot** | `timedatectl set-ntp true` | Persistence |

### The "Time Wrong" Checklist

```bash
# 1. Check current time:
timedatectl

# 2. Check NTP status:
chronyc tracking

# 3. Check sync sources:
chronyc sources

# 4. Force sync:
sudo chronyc makestep

# 5. Check timezone:
timedatectl | grep "Time zone"
```

---

**Why these rules matter:** Time synchronization is foundational for security, logging, and distributed systems.

[← Previous](16-self-test-can-you-answer-these.md) | [↑ Index](index.md)
