## 🔍 Section 5: EPEL — Extra Packages for Enterprise Linux

EPEL is the most important third-party repository for RHEL/CentOS/Rocky/Alma.

```bash
# What EPEL provides:
# - Packages not in the base RHEL repositories
# - Maintained by Fedora community
# - High quality, well-tested
# - Compatible with RHEL's support policy

# Install EPEL (RHEL 9 / Rocky 9 / Alma 9):
sudo dnf install -y epel-release

# Install EPEL (older versions):
sudo dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm

# Enable EPEL
sudo dnf config-manager --set-enabled epel

# Verify
dnf repolist | grep epel
```

### EPEL Next (for RHEL 9+)

```bash
# EPEL Next provides packages built against newer library versions
sudo dnf install -y epel-next-release
```





[← Previous](07-section-4-rpm-repositories-fedorarhel.md) | [↑ Index](index.md) | [Next →](09-section-6-rpm-fusion.md)
