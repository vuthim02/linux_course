## 🔍 Section 6: RPM Fusion

RPM Fusion provides packages that Fedora cannot include due to legal reasons.

```bash
# Install RPM Fusion (free and nonfree)
sudo dnf install -y \
  https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
  https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

# RPM Fusion free section:
# - Multimedia codecs
# - Hardware support
# - Gaming libraries

# RPM Fusion nonfree section:
# - NVIDIA drivers
# - Steam
# - DVD playback
```

---



---

[← Previous](08-section-5-epel-extra-packages.md) | [↑ Index](index.md) | [Next →](10-level-3-advanced-third-party-repositories.md)
