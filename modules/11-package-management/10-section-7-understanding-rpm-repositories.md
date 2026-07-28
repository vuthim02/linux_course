## 🔍 Section 7: Understanding RPM Repositories

### Repository Configuration

```bash
# Repositories are in /etc/yum.repos.d/
ls /etc/yum.repos.d/

# View a repo file
cat /etc/yum.repos.d/fedora.repo
```

```
[fedora]
name=Fedora $releasever - $basearch
metalink=https://mirrors.fedoraproject.org/metalink?repo=fedora-$releasever&arch=$basearch
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch
```

| Field | Meaning |
|-------|---------|
| [fedora] | Repository ID (must be unique) |
| name | Human-readable name |
| metalink/baseurl | Where to find packages |
| enabled | 1 = enabled, 0 = disabled |
| gpgcheck | 1 = verify GPG signatures |
| gpgkey | Location of GPG key file |

### Adding an RPM Repository

```bash
# Install RPM Fusion (popular extra repository)
sudo dnf install \
  https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm

# Or add manually:
sudo dnf config-manager --add-repo https://example.com/repo.repo
```

### EPEL — Extra Packages for Enterprise Linux

```bash
# EPEL is the most important repository for RHEL/CentOS/Rocky
sudo dnf install epel-release

# This adds packages that are not in the base RHEL repos
```





[← Previous](09-section-6-rpm-the-low-level.md) | [↑ Index](index.md) | [Next →](11-section-8-snap-universal-linux.md)
