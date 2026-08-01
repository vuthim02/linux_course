## 📏 Rules of Thumb

### The Package Management Rules

| Rule | Description | Why |
|------|-------------|-----|
| **ALWAYS run apt update first** | Download package lists | Prevents stale data |
| **Never force dpkg --force** | It breaks dependencies | System stability |
| **Use apt, not dpkg** | apt handles dependencies | Easier, safer |
| **Test in staging** | Try updates first | Prevent outages |
| **Keep config files** | `apt remove` not `purge` | Preserve settings |

### The Package Selection Rules

| Situation | Use | Why |
|-----------|-----|-----|
| System packages | apt/dnf | Proper dependency management |
| Desktop apps | snap/flatpak | Sandboxed, updated |
| Custom software | source build | Full control |
| Containers | apk (Alpine) | Minimal image size |

### The "Package Won't Install" Checklist

```bash
# 1. Update package lists:
sudo apt update

# 2. Check if package exists:
apt search package

# 3. Check dependencies:
apt-cache depends package

# 4. Fix broken dependencies:
sudo apt --fix-broken install

# 5. Force reinstall:
sudo apt install --reinstall package
```

### The "System Won't Upgrade" Checklist

```bash
# 1. Check held packages:
dpkg --get-selections | grep hold

# 2. Unhold if needed:
sudo apt-mark unhold package

# 3. Fix broken installs:
sudo dpkg --configure -a

# 4. Fix broken dependencies:
sudo apt --fix-broken install

# 5. Clean cache:
sudo apt clean
sudo apt autoclean
```

### The security Update Rules

```bash
# Enable automatic security updates:
sudo apt install unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades

# Manual security update:
sudo apt update && sudo apt upgrade -y

# Check security updates only:
sudo apt list --upgradable | grep security
```

---

**Why these rules matter:** Package management is how you keep your system secure and up-to-date. Following these rules prevents broken dependencies and security vulnerabilities.

[← Previous](20-self-test-can-you-answer-these.md) | [↑ Index](index.md)
