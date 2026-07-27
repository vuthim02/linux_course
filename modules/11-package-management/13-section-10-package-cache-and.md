## 🔍 Section 10: Package Cache and Cleanup

Package managers cache downloaded packages. Over time, this can take gigabytes.

```bash
# APT cache location
ls /var/cache/apt/archives/

# Show cache size
du -sh /var/cache/apt/archives/

# Clean ALL cached .deb files
sudo apt clean

# Remove only obsolete .deb files
sudo apt autoclean

# DNF cache
sudo dnf clean all

# Remove unused packages
sudo apt autoremove
sudo dnf autoremove
```

### Checking Disk Usage by Packages

```bash
# Show largest installed packages (Debian)
dpkg-query -W --showformat='${Installed-Size} ${Package}\n' | sort -rn | head -20

# Show largest installed packages (RHEL)
rpm -qa --queryformat '%{SIZE} %{NAME}\n' | sort -rn | head -20
```

---



---

[← Previous](12-section-9-flatpak-universal-desktop.md) | [↑ Index](index.md) | [Next →](14-level-3-advanced-package-troubleshooting.md)
