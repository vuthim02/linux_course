## 🔍 Section 6: rpm — The Low-Level Red Hat Tool

`rpm` works with individual .rpm files. Like dpkg, it does NOT resolve dependencies.

```bash
# Install a .rpm file
sudo rpm -ivh package.rpm

# Upgrade a package
sudo rpm -Uvh package.rpm

# Remove a package
sudo rpm -e package_name

# List installed packages
rpm -qa

# List files installed by a package
rpm -ql nginx

# Find which package owns a file
rpm -qf /etc/nginx/nginx.conf

# Package information
rpm -qi nginx

# Verify package integrity
rpm -V nginx

# Extract files from .rpm without installing
rpm2cpio package.rpm | cpio -idmv
```

---



---

[← Previous](08-section-5-the-fedorarhel-package.md) | [↑ Index](index.md) | [Next →](10-section-7-understanding-rpm-repositories.md)
