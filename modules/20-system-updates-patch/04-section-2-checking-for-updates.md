## 🔍 Section 2: Checking for Updates

### APT (Debian/Ubuntu)

```bash
# Update the package index
sudo apt update

# List upgradable packages
apt list --upgradable

# Count available updates
apt list --upgradable 2>/dev/null | grep -v "^Listing" | wc -l

# Show upgradable packages with more detail
apt list --upgradable 2>/dev/null

# Check if there are security updates specifically
apt list --upgradable 2>/dev/null | grep -i security || echo "No security updates"

# Show package changelog before updating
apt changelog nginx
```

### DNF (Fedora/RHEL)

```bash
# Check for updates (does NOT download them)
dnf check-update

# List available updates
dnf list updates

# Count updates
dnf check-update 2>/dev/null | wc -l

# Check for security updates
dnf updateinfo list

# Check for security updates only
dnf updateinfo list --security
```

### Keeping Track of Update History

```bash
# Debian/Ubuntu: update history
less /var/log/apt/history.log

# Fedora/RHEL
less /var/log/dnf.log

# Last update time
grep "Start-Date" /var/log/apt/history.log | tail -1
```

---



---

[← Previous](03-section-1-the-update-lifecycle.md) | [↑ Index](index.md) | [Next →](05-section-3-applying-updates.md)
