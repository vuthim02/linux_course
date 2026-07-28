## 🔍 Section 5: The Fedora/RHEL Package System — dnf

`dnf` (Dandified YUM) is the next-generation package manager for Red Hat-based systems.

### Essential dnf Commands

```bash
# Search for a package
dnf search nginx

# Install a package
sudo dnf install nginx

# Remove a package
sudo dnf remove nginx

# Update all packages
sudo dnf update

# Update a specific package
sudo dnf update nginx

# List installed packages
dnf list installed

# List available packages
dnf list available

# Package information
dnf info nginx

# List files in a package
dnf repoquery -l nginx

# Which package owns a file
dnf provides /etc/nginx/nginx.conf

# Clean cache
sudo dnf clean all

# Show package groups
dnf group list

# Install a group
sudo dnf group install "Development Tools"
```

### dnf vs yum

```bash
# yum was the old package manager
# dnf is the modern replacement (faster, better dependency resolution)

# dnf is backward-compatible — most yum commands work as dnf
# On RHEL 8+, 'yum' is actually a symlink to dnf
which yum    # /usr/bin/dnf
```

### Answering Yes Automatically

```bash
sudo dnf install -y nginx
```





[← Previous](07-level-2-intermediary-rpm-and.md) | [↑ Index](index.md) | [Next →](09-section-6-rpm-the-low-level.md)
