## 🔍 Section 9: Flatpak — Universal Desktop Packages

Flatpak focuses on desktop applications. It is sandboxed using Bubblewrap and OSTree.

```bash
# Install flatpak
sudo apt install flatpak

# Add Flathub (main repository)
sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# Search
flatpak search gimp

# Install
flatpak install flathub org.gimp.GIMP

# Run
flatpak run org.gimp.GIMP

# List installed
flatpak list

# Update
flatpak update

# Remove
flatpak uninstall org.gimp.GIMP
```

### Snap vs Flatpak

| Feature | Snap | Flatpak |
|---------|------|---------|
| Creator | Canonical (Ubuntu) | Red Hat / community |
| Focus | Server, CLI, IoT, desktop | Desktop applications |
| Repository | Snap Store | Flathub |
| Sandboxing | AppArmor | Bubblewrap |
| Auto-update | Yes (mandatory) | Configurable |
| CLI support | Excellent | Desktop only |

---



---

[← Previous](11-section-8-snap-universal-linux.md) | [↑ Index](index.md) | [Next →](13-section-10-package-cache-and.md)
