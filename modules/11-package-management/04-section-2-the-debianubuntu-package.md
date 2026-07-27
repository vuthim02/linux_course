## 🔍 Section 2: The Debian/Ubuntu Package System — apt

`apt` (Advanced Package Tool) is the primary package manager for Debian-based systems.

### Essential apt Commands

```bash
# Update package list (ALWAYS do this first)
sudo apt update

# Upgrade installed packages
sudo apt upgrade

# Full upgrade (handles changing dependencies)
sudo apt full-upgrade

# Install a package
sudo apt install nginx

# Install multiple packages
sudo apt install nginx mysql-server php-fpm

# Remove a package (keeps config files)
sudo apt remove nginx

# Remove package AND config files
sudo apt purge nginx

# Remove unused dependencies
sudo apt autoremove

# Search for a package
apt search webserver

# Show package information
apt show nginx

# List installed packages
apt list --installed

# List upgradable packages
apt list --upgradable

# Download only (don't install)
apt download nginx
```

### The apt Lifecycle

```bash
# Step 1: Update the package index
# This downloads the list of available packages from repositories
sudo apt update

# Step 2: See what can be upgraded
apt list --upgradable

# Step 3: Install or upgrade
sudo apt install package_name

# Step 4: Clean up
sudo apt autoremove     # Remove orphaned dependencies
sudo apt autoclean      # Remove old .deb files from cache
```

### apt vs apt-get

```bash
# apt-get is the older command
# apt is the newer, user-friendly interface

# apt combines multiple apt-get commands:
apt install       = apt-get install
apt remove        = apt-get remove
apt update        = apt-get update
apt upgrade       = apt-get upgrade
apt search        = apt-cache search
apt show          = apt-cache show
apt list          = dpkg-query --list + apt-cache

# Why apt is better:
# - Progress bar during install
# - More readable output
# - Fewer commands to remember
```

### Answering Yes Automatically

```bash
# For scripting (non-interactive)
sudo apt install -y nginx

# Or set environment variable
DEBIAN_FRONTEND=noninteractive sudo apt install -y nginx
```

---



---

[← Previous](03-section-1-the-two-packaging.md) | [↑ Index](index.md) | [Next →](05-section-3-dpkg-the-low-level.md)
