## 📏 Rules of Thumb

### The Update Rules

| Rule | Description | Why |
|------|-------------|-----|
| **Update lists first** | `apt update` before `upgrade` | Prevent stale data |
| **Test in staging** | Try updates first | Prevent outages |
| **Read changelogs** | Know what changed | Avoid surprises |
| **Keep rollback plan** | Be ready to revert | Safety net |
| **Document updates** | Track what you did | Maintainability |

### The "Update Broke Something" Checklist

```bash
# 1. Check what changed:
apt list --upgradable

# 2. Check package logs:
cat /var/log/dpkg.log | grep upgrade

# 3. Revert package:
sudo apt install package=old_version

# 4. Hold package:
sudo apt-mark hold package

# 5. Check for dependency issues:
sudo apt --fix-broken install
```

---

**Why these rules matter:** Following these rules prevents update-related outages and helps you recover quickly when problems occur.

[← Previous](17-self-test-can-you-answer-these.md) | [↑ Index](index.md)
