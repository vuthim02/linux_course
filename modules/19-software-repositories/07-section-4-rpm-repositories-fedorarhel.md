## 🔍 Section 4: RPM Repositories — Fedora/RHEL

### Repository Configuration Files

```bash
# Repository files are in /etc/yum.repos.d/
ls /etc/yum.repos.d/

# View a repository file
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

### Repository File Syntax

```
[repository-id]          ← Unique identifier (no spaces)
name=Repository Name     ← Human-readable name
baseurl=http://...       ← URL to repository (alternative to metalink)
metalink=https://...     ← Dynamic mirror list
mirrorlist=http://...    ← Mirror list (older format)
enabled=1                ← 1 = active, 0 = inactive
gpgcheck=1               ← Verify GPG signatures
gpgkey=file:///path      ← GPG key location
repo_gpgcheck=1          ← Verify repository metadata signature
```

### Using Repository Variables

```bash
# Dynamic variables in repo URLs:
# $releasever  — Distribution version (39, 8, 9, etc.)
# $basearch    — Architecture (x86_64, aarch64, etc.)

# Example:
baseurl=https://example.com/repo/$releasever/$basearch/
# Resolves to: https://example.com/repo/39/x86_64/
```

### Managing Repositories

```bash
# List all enabled repos
dnf repolist

# List all repos (including disabled)
dnf repolist --all

# Enable/disable a repo
sudo dnf config-manager --set-enabled epel
sudo dnf config-manager --set-disabled epel

# Add a repo from a URL
sudo dnf config-manager --add-repo https://example.com/repo.repo

# Add a repo from a file
sudo dnf install -y epel-release
```





[← Previous](06-section-3-ppas-personal-package.md) | [↑ Index](index.md) | [Next →](08-section-5-epel-extra-packages.md)
