## 🔍 Section 3: dpkg — The Low-Level Debian Tool

`dpkg` works with individual .deb files. It does NOT resolve dependencies.

```bash
# Install a .deb file
sudo dpkg -i package.deb

# Remove a package
sudo dpkg -r package_name

# Purge (remove config too)
sudo dpkg -P package_name

# List installed packages
dpkg -l

# List files installed by a package
dpkg -L nginx

# Find which package owns a file
dpkg -S /etc/nginx/nginx.conf

# Check if a package is installed
dpkg -l | grep nginx

# Reconfigure an installed package
sudo dpkg-reconfigure nginx-common

# Fix broken dependencies after dpkg -i
sudo apt install -f
```

### When to Use dpkg Instead of apt

```bash
# 1. Installing a .deb file downloaded from the internet
sudo dpkg -i google-chrome-stable_current_amd64.deb

# 2. When apt is broken and you need to fix it manually
# 3. Querying package information without internet
# 4. Extracting files from a .deb without installing
dpkg-deb -x package.deb /tmp/extracted
```





[← Previous](04-section-2-the-debianubuntu-package.md) | [↑ Index](index.md) | [Next →](06-section-4-understanding-debian-repositories.md)
