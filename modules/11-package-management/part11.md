# 🐧 Linux System Administrator — Complete Course
## Part 11 of ∞: Package Management — apt, dnf, yum, snap

---

> **Reverse Engineering Approach:** Software installation on Linux is not a matter of downloading .exe files from websites. Every distribution has a central nervous system — the package manager. It tracks every file, every dependency, every version. When you understand the package manager, you understand how the entire operating system is assembled from thousands of individual components.

---

## 🎯 What You Will Achieve in Part 11

| Level | Focus | What You'll Master |
|-------|-------|-------------------|
| ⭐ **Level 1: Basic** | Debian packaging fundamentals | Two packaging worlds, apt commands, dpkg basics, Debian repositories |
| ⭐ **Level 2: Intermediary** | RPM and universal packaging | dnf/yum, rpm, RPM repositories, Snap, Flatpak, cache management |
| ⭐ **Level 3: Advanced** | Troubleshooting and internals | Fixing broken packages, dependency resolution, package database internals |

---

## ⭐ Level 1: Basic — Debian Packaging Fundamentals

![Package Management Systems Comparison](https://upload.wikimedia.org/wikipedia/en/1/13/Pms.png)
*Overview of package management systems in the Linux ecosystem. Source: Wikimedia Commons*

> **Level 1 Goal:** Understand the two major packaging families (deb vs rpm), master essential apt commands, use dpkg for low-level operations, and understand how Debian repositories work.

---

## 🔍 Section 1: The Two Packaging Worlds

Linux distributions divide into two packaging families:

```
┌─────────────────────────────────────────────────────────────┐
│                     PACKAGE MANAGEMENT                       │
├──────────────────────────┬──────────────────────────────────┤
│       .deb (Debian)       │       .rpm (Red Hat)            │
│                          │                                  │
│  Distributions:          │  Distributions:                  │
│  • Debian                │  • Fedora                        │
│  • Ubuntu                │  • RHEL (Red Hat Enterprise)     │
│  • Linux Mint            │  • CentOS / Rocky / Alma         │
│  • Kali                  │  • openSUSE                      │
│  • Pop!_OS               │  • Amazon Linux                  │
│                          │                                  │
│  Low-level: dpkg         │  Low-level: rpm                  │
│  High-level: apt         │  High-level: dnf (yum legacy)    │
└──────────────────────────┴──────────────────────────────────┘
```

### What Is a Package?

A **package** is a compressed archive containing:
- Binary files (programs, libraries)
- Configuration files
- Metadata (name, version, description, dependencies)
- Installation scripts (pre-install, post-install)
- Checksums and digital signatures

```bash
# A package is like a .zip with intelligence:
# - It knows what else it needs (dependencies)
# - It runs setup scripts automatically
# - It registers itself in a database
# - It can be removed cleanly
```

### The Dependency Problem

```
Package A depends on Library B
Library B depends on Library C
Package D depends on Library B (same library, different package)

Without a package manager, you would manually track all these.
With a package manager, it handles everything automatically.
Install A → automatically installs B and C
Remove A → automatically removes B and C (if nothing else needs them)
```

---

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

---

## 🔍 Section 4: Understanding Debian Repositories

Repositories are servers that host packages. APT downloads from them.

### The sources.list File

```bash
cat /etc/apt/sources.list
```

```
deb http://archive.ubuntu.com/ubuntu jammy main restricted universe multiverse
deb http://security.ubuntu.com/ubuntu jammy-security main restricted
deb http://archive.ubuntu.com/ubuntu jammy-updates main restricted
```

### Repository Line Syntax

```
deb  http://archive.ubuntu.com/ubuntu  jammy         main restricted
│    │                                  │             │
│    │                                  │             └── Components (main, universe...)
│    │                                  └── Distribution (codename)
│    └── Repository URL
└── Type (deb = binary, deb-src = source)
```

### Ubuntu Repository Components

| Component | Contents | Support |
|-----------|----------|---------|
| main | Officially supported by Canonical | Free, full support |
| universe | Community-maintained packages | Free, community support |
| restricted | Proprietary drivers | Supported by Canonical |
| multiverse | Non-free, legally restricted | No official support |

### Adding PPAs (Personal Package Archives)

```bash
# Add a PPA
sudo add-apt-repository ppa:deadsnakes/ppa

# This adds a file to /etc/apt/sources.list.d/
ls /etc/apt/sources.list.d/

# Update and install
sudo apt update
sudo apt install python3.11
```

### Finding Your Distribution Codename

```bash
# Ubuntu codenames: jammy (22.04), noble (24.04), etc.
lsb_release -cs

# Or:
cat /etc/os-release
```

### Adding a Repository Manually

```bash
# Method 1: Using add-apt-repository
sudo add-apt-repository "deb https://example.com/ubuntu jammy main"

# Method 2: Manually create a .list file
echo "deb https://example.com/ubuntu jammy main" | sudo tee /etc/apt/sources.list.d/example.list

# Always add the GPG key for secure repositories
wget -O- https://example.com/key.gpg | sudo apt-key add -
```

---

## ⭐ Level 2: Intermediary — RPM and Universal Packaging

![Debian APT](https://upload.wikimedia.org/wikipedia/commons/d/df/Debian-apt-get.svg)
*Debian Advanced Package Tool (APT) logo and packaging workflow. Source: Wikimedia Commons*

> **Level 2 Goal:** Master dnf/yum for Red Hat-based systems, use rpm for low-level operations, configure RPM repositories, and work with universal package formats (Snap, Flatpak) and cache management.

---

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

---

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

---

## 🔍 Section 8: Snap — Universal Linux Packages

Snap is Canonical's universal package format. Snaps are confined (sandboxed) and auto-update.

### Essential Snap Commands

```bash
# Install snap support
sudo apt install snapd

# Find a snap
snap find nginx

# Install a snap
sudo snap install nginx

# List installed snaps
snap list

# Update snaps
sudo snap refresh

# Update a specific snap
sudo snap refresh nginx

# Revert to previous version
sudo snap revert nginx

# Remove a snap
sudo snap remove nginx

# Show snap info
snap info nginx

# Run snap commands (they're in /snap/bin/)
/snap/bin/nginx
```

### Snap Channels (Versions)

```bash
# Stable (default) — production-ready
sudo snap install nginx

# Candidate — pre-release testing
sudo snap install nginx --channel=candidate

# Beta — unstable testing
sudo snap install nginx --channel=beta

# Edge — latest development
sudo snap install nginx --channel=edge
```

### Snap Advantages and Disadvantages

| Aspect | Advantage | Disadvantage |
|--------|-----------|-------------|
| Installation | One command works on ALL distros | Large download (includes all deps) |
| Updates | Automatic, atomic updates | You cannot disable updates easily |
| Security | Confined by AppArmor | Some apps break due to confinement |
| Size | No dependency conflicts | Each snap is 100MB+ |

---

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

## ⭐ Level 3: Advanced — Package Troubleshooting and Internals

![Linux Kernel and System Layers](https://upload.wikimedia.org/wikipedia/commons/thumb/9/9f/Linux_kernel_and_Computer_layers.png/1024px-Linux_kernel_and_Computer_layers.png)
*Linux kernel and system layers illustrating how packages integrate with the OS. Source: Wikimedia Commons*

> **Level 3 Goal:** Diagnose and fix common package management failures, understand the package database architecture, and master dependency resolution and security verification.

---

## 🔍 Section 11: Fixing Common Package Problems

### Problem 1: Lock File (Could not get lock /var/lib/dpkg/lock)

```bash
# Another apt process is running
# Solution: Wait for it, or if sure it's stuck:
sudo rm /var/lib/dpkg/lock-frontend
sudo rm /var/lib/apt/lists/lock
sudo rm /var/cache/apt/archives/lock
sudo dpkg --configure -a
```

### Problem 2: Broken Dependencies

```bash
# Debian/Ubuntu:
sudo apt install -f     # Fix broken packages

# Fedora/RHEL:
sudo dnf --best --allowerasing update
```

### Problem 3: Package Database Corrupted

```bash
# Debian/Ubuntu:
sudo dpkg --configure -a
sudo apt update --fix-missing

# If that fails:
sudo rm /var/lib/dpkg/available
sudo apt update
```

### Problem 4: Held/Broken Packages

```bash
# Prevent a package from being updated
sudo apt-mark hold nginx

# Show held packages
apt-mark showhold

# Unhold
sudo apt-mark unhold nginx
```

### Problem 5: GPG Key Error

```bash
# When adding repositories, you may get GPG errors
# Solution: Import the correct key
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys KEY_ID
```

### Problem 6: Package Not Found

```bash
# First: update package list
sudo apt update

# Second: check if package exists under a different name
apt search package_name

# Third: enable additional repositories
# Debian: /etc/apt/sources.list
# Ubuntu: add-apt-repository
# Fedora: dnf config-manager --set-enabled
```

---

## 🧠 Deep Understanding — How Package Management Works

### The Database

Every package manager maintains a database of installed packages:

```bash
# Debian/Ubuntu:
ls /var/lib/dpkg/
# available    — List of available packages
# info/        — Per-package control files
# status       — Status of every package on the system

# Fedora/RHEL:
ls /var/lib/rpm/
# Packages     — Berkeley DB or sqlite database
# RPM stores everything in a single database file
```

### Package Installation Process

```
1. apt reads /etc/apt/sources.list
2. Downloads package index (Packages.gz or Packages.xz)
3. Resolves dependencies (solves the dependency graph)
4. Downloads all required .deb files to /var/cache/apt/archives/
5. Verifies GPG signatures
6. Runs pre-installation scripts
7. Extracts files to the filesystem
8. Runs post-installation scripts
9. Updates the package database
10. Removes .deb files (unless instructed to keep them)
```

### Why `sudo apt update` Is Necessary

```bash
# The package list is a snapshot of what was in the repository
# when you last ran 'apt update'

# Without updating:
# - New packages won't appear in search results
# - System won't know about available security updates
# - Install may fail with "404 Not Found" (if repo changed)

# Always run update before install or upgrade:
sudo apt update && sudo apt upgrade
```

### Checksums and Security

```bash
# Every package has cryptographic checksums:
# - MD5, SHA1, SHA256 hashes of the package contents
# - GPG signature from the repository maintainer

# APT verifies ALL of these before installing:
# 1. GPG signature of the Release file
# 2. Checksums of the Packages file
# 3. Checksums of the .deb file
# 4. Integrity of the unpacked files

# This makes it extremely hard to:
# - Tamper with packages in transit (MITM attack)
# - Install malicious packages from compromised repos
```

---

## 💻 PRACTICE SECTION — 20 Hands-On Exercises

### ✅ Level 1: Basic Practices

---

### ✅ Practice 1: Explore Your Package System

```bash
mkdir -p ~/linux-course/part11
cd ~/linux-course/part11

# Determine your package system
if command -v apt &>/dev/null; then
    echo "Package system: apt (Debian/Ubuntu)"
elif command -v dnf &>/dev/null; then
    echo "Package system: dnf (Fedora/RHEL)"
elif command -v yum &>/dev/null; then
    echo "Package system: yum (CentOS/RHEL 7)"
else
    echo "Unknown package system"
fi

# Show distribution info
cat /etc/os-release
```

---

### ✅ Practice 2: Update Package List (Safe)

```bash
# Update package list (never causes harm)
sudo apt update 2>/dev/null || sudo dnf makecache 2>/dev/null

# Count available packages
if command -v apt &>/dev/null; then
    apt list --upgradable 2>/dev/null | wc -l
fi
```

---

### ✅ Practice 3: Search and Install

```bash
# Search for a package
apt search tree 2>/dev/null || dnf search tree

# Install tree (directory listing tool)
sudo apt install -y tree 2>/dev/null || sudo dnf install -y tree

# Verify installation
which tree
tree ~/linux-course
```

---

### ✅ Practice 4: Package Information

```bash
# Show detailed info about an installed package
apt show tree 2>/dev/null || dnf info tree

# Show version
tree --version

# Show install date (Debian)
ls -la /var/lib/dpkg/info/tree.list 2>/dev/null
```

---

### ✅ Practice 5: List Installed Packages

```bash
# Count installed packages
echo "Installed packages:"
if command -v dpkg &>/dev/null; then
    dpkg -l | wc -l
elif command -v rpm &>/dev/null; then
    rpm -qa | wc -l
fi
```

---

### ✅ Practice 6: Find Files From a Package

```bash
# List all files installed by the tree package
dpkg -L tree 2>/dev/null || rpm -ql tree 2>/dev/null
```

---

### ✅ Practice 7: Find Which Package Owns a File

```bash
# Find which package installed /usr/bin/tree
dpkg -S /usr/bin/tree 2>/dev/null || rpm -qf /usr/bin/tree 2>/dev/null
```

---

### ✅ Level 2: Intermediary Practices

---

### ✅ Practice 8: Install Multiple Packages

```bash
# Install essential sysadmin tools
sudo apt install -y htop curl wget git nmap net-tools 2>/dev/null || \
sudo dnf install -y htop curl wget git nmap net-tools 2>/dev/null

# Verify
for cmd in htop curl wget git nmap; do
    if command -v $cmd &>/dev/null; then
        echo "$cmd: installed"
    else
        echo "$cmd: NOT installed"
    fi
done
```

---

### ✅ Practice 9: Remove a Package

```bash
# Install a harmless package
sudo apt install -y cowsay 2>/dev/null || sudo dnf install -y cowsay 2>/dev/null

# Use it
cowsay "Hello, Linux!"

# Remove it
sudo apt remove -y cowsay 2>/dev/null || sudo dnf remove -y cowsay 2>/dev/null

# Verify removed
which cowsay 2>/dev/null || echo "cowsay removed successfully"
```

---

### ✅ Practice 10: Purge vs Remove (Debian Specific)

```bash
# Install nano (if not installed)
sudo apt install -y nano 2>/dev/null

# Check config files exist
ls -la /etc/nano/ 2>/dev/null || echo "No nano config directory"

# Remove (keeps config)
sudo apt remove -y nano 2>/dev/null

# Config files remain
ls -la /etc/nano/ 2>/dev/null || echo "No config remains"

# Purge removes config too
sudo apt purge -y nano 2>/dev/null

# Config gone
ls -la /etc/nano/ 2>/dev/null || echo "Config directory purged"

# Reinstall nano
sudo apt install -y nano 2>/dev/null
```

---

### ✅ Practice 11: Hold a Package

```bash
# Hold a package (prevent updates)
sudo apt-mark hold nano 2>/dev/null

# Verify
apt-mark showhold 2>/dev/null

# Unhold
sudo apt-mark unhold nano 2>/dev/null
```

---

### ✅ Practice 12: Clean Package Cache

```bash
# Check cache size
echo "APT cache size:"
du -sh /var/cache/apt/archives/ 2>/dev/null || echo "N/A"

echo "DNF cache size:"
du -sh /var/cache/dnf/ 2>/dev/null || echo "N/A"

# Clean (safe)
sudo apt clean 2>/dev/null || sudo dnf clean all 2>/dev/null

echo "Cache cleaned"
```

---

### ✅ Practice 13: Simulate an Installation

```bash
# See what WOULD happen without actually installing
apt install -s nginx 2>/dev/null | head -20

# Or for dnf:
dnf install --assumeno nginx 2>/dev/null | head -20
```

---

### ✅ Practice 14: Download Without Installing

```bash
# Download a .deb or .rpm file without installing
apt download hello 2>/dev/null

# Or for dnf:
dnf download hello 2>/dev/null

# What you downloaded:
ls -la *.deb *.rpm 2>/dev/null || echo "No .deb/.rpm files"

# Clean up
rm -f *.deb *.rpm 2>/dev/null
```

---

### ✅ Practice 15: Explore Repositories

```bash
# List configured repositories
if [ -d /etc/apt/sources.list.d ]; then
    echo "=== APT Repositories ==="
    ls /etc/apt/sources.list.d/
    cat /etc/apt/sources.list 2>/dev/null | head -10
elif [ -d /etc/yum.repos.d ]; then
    echo "=== DNF/YUM Repositories ==="
    ls /etc/yum.repos.d/
    head -10 /etc/yum.repos.d/*.repo
fi
```

---

### ✅ Practice 16: Explore Snap

```bash
# Install snap if not present
if ! command -v snap &>/dev/null; then
    sudo apt install -y snapd 2>/dev/null || echo "Snap not available on this system"
fi

# Wait for snapd to initialize
sudo systemctl enable --now snapd.socket 2>/dev/null
sleep 2

# Find snaps
snap find hello 2>/dev/null | head -10

# List installed snaps
snap list 2>/dev/null || echo "No snaps installed"

# Install a snap (small, safe)
sudo snap install hello-world 2>/dev/null

# Run it
hello-world

# Remove it
sudo snap remove hello-world 2>/dev/null
```

---

### ✅ Practice 17: Explore Flatpak

```bash
# Install flatpak
sudo apt install -y flatpak 2>/dev/null || sudo dnf install -y flatpak 2>/dev/null

# Add Flathub
sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo 2>/dev/null

# Search
flatpak search org.gnome.Logs 2>/dev/null | head -5

# Or skip if no desktop (server)
echo "Flatpak ready (primarily for desktop apps)"
```

---

### ✅ Practice 18: Package Dependency Tree

```bash
# Show dependencies of a package
# Debian:
apt depends bash 2>/dev/null | head -20

# What depends on bash?
apt rdepends bash 2>/dev/null | head -20

# Fedora:
dnf repoquery --requires bash 2>/dev/null | head -20
dnf repoquery --whatrequires bash 2>/dev/null | head -20
```

---

### ✅ Level 3: Advanced Practices

---

### ✅ Practice 19: Check System for Orphaned Packages

```bash
# Find packages installed as dependencies but no longer needed
# Debian/Ubuntu:
sudo apt autoremove --dry-run 2>/dev/null

# Fedora/RHEL:
sudo dnf autoremove --dry-run 2>/dev/null
```

---

### ✅ Practice 20: Real SysAdmin Scenario — Package Audit Report

```bash
cd ~/linux-course/part11

cat > package_audit.sh << 'EOF'
#!/bin/bash
set -euo pipefail

echo "========================================"
echo "  PACKAGE AUDIT REPORT"
echo "  Hostname: $(hostname)"
echo "  Date:     $(date)"
echo "========================================"
echo ""

# Distribution info
cat /etc/os-release 2>/dev/null | head -5
echo ""

# Total packages
echo "1. PACKAGE COUNTS"
echo "-----------------"
if command -v dpkg &>/dev/null; then
    total=$(dpkg -l | wc -l)
    echo "Total installed (Debian): $total"
elif command -v rpm &>/dev/null; then
    total=$(rpm -qa | wc -l)
    echo "Total installed (RPM): $total"
fi
echo ""

# Upgradable packages
echo "2. UPDATES AVAILABLE"
echo "-------------------"
if command -v apt &>/dev/null; then
    apt list --upgradable 2>/dev/null | grep -v "^Listing" | wc -l
elif command -v dnf &>/dev/null; then
    dnf check-update 2>/dev/null | wc -l
fi | awk '{print $1 " updates available"}'
echo ""

# Largest packages
echo "3. LARGEST INSTALLED PACKAGES (top 10)"
echo "--------------------------------------"
if command -v dpkg-query &>/dev/null; then
    dpkg-query -W --showformat='${Installed-Size} ${Package}\n' 2>/dev/null | \
    sort -rn | head -10 | awk '{printf "  %6d KB  %s\n", $1, $2}'
elif command -v rpm &>/dev/null; then
    rpm -qa --queryformat '%{SIZE} %{NAME}\n' 2>/dev/null | \
    sort -rn | head -10 | awk '{
        size=$1/1024
        printf "  %6.0f KB  ", size
        for(i=2;i<=NF;i++) printf "%s", $i
        printf "\n"
    }'
fi
echo ""

# Recent installations
echo "4. RECENTLY INSTALLED (last 10)"
echo "-------------------------------"
if [ -f /var/log/dpkg.log ]; then
    grep " install " /var/log/dpkg.log 2>/dev/null | tail -10
elif [ -f /var/log/dnf.log ]; then
    grep "Installed" /var/log/dnf.log 2>/dev/null | tail -10
fi
echo ""

echo "========================================"
echo "  END OF REPORT"
echo "========================================"
EOF

chmod +x package_audit.sh
./package_audit.sh
```

---

## 📋 Summary — Complete Command Reference for Part 11

### Level 1: Basic Commands — APT and dpkg

**APT (Debian/Ubuntu)**

| Command | Action |
|---------|--------|
| `sudo apt update` | Update package index |
| `sudo apt upgrade` | Upgrade all packages |
| `sudo apt install pkg` | Install package |
| `sudo apt remove pkg` | Remove (keep config) |
| `sudo apt purge pkg` | Remove (delete config) |
| `sudo apt autoremove` | Remove orphans |
| `apt search pattern` | Search packages |
| `apt show pkg` | Package details |
| `apt list --installed` | List installed packages |
| `apt list --upgradable` | List upgradable packages |
| `sudo apt clean` | Clear cache |

**dpkg (Debian low-level)**

| Command | Action |
|---------|--------|
| `sudo dpkg -i file.deb` | Install .deb file |
| `sudo dpkg -r pkg` | Remove package |
| `sudo dpkg -P pkg` | Purge package |
| `dpkg -l` | List installed |
| `dpkg -L pkg` | List package files |
| `dpkg -S file` | Find package owner |

### Level 2: Intermediary Commands — DNF, RPM, Snap, Flatpak

**DNF (Fedora/RHEL)**

| Command | Action |
|---------|--------|
| `sudo dnf install pkg` | Install package |
| `sudo dnf remove pkg` | Remove package |
| `sudo dnf update` | Update all packages |
| `dnf search pattern` | Search packages |
| `dnf info pkg` | Package details |
| `dnf list installed` | List installed |
| `dnf list available` | List available |
| `dnf provides file` | Find package owner |
| `dnf group list` | List package groups |

**rpm (RHEL low-level)**

| Command | Action |
|---------|--------|
| `sudo rpm -ivh file.rpm` | Install .rpm file |
| `sudo rpm -e pkg` | Remove package |
| `rpm -qa` | List all installed |
| `rpm -ql pkg` | List package files |
| `rpm -qf file` | Find package owner |
| `rpm -qi pkg` | Package info |

**Snap**

| Command | Action |
|---------|--------|
| `snap find name` | Search snaps |
| `sudo snap install name` | Install snap |
| `sudo snap refresh` | Update snaps |
| `snap list` | List installed snaps |
| `sudo snap remove name` | Remove snap |

**Flatpak**

| Command | Action |
|---------|--------|
| `flatpak search name` | Search flatpaks |
| `flatpak install remote name` | Install |
| `flatpak update` | Update all |
| `flatpak list` | List installed |
| `flatpak uninstall name` | Remove |

### Level 3: Advanced Commands (No additional commands — see troubleshooting section above)

---

## 🚀 What's Coming in Part 12

**Part 12: Systemd and Services — Managing the Modern Linux**

You will learn:
- Understanding systemd units (services, sockets, timers, targets)
- Starting, stopping, enabling, and disabling services
- Creating custom systemd service files
- Journald — systemd's logging system
- Analyzing boot performance
- Systemd timers (modern cron replacement)
- Troubleshooting failed services
- 15 hands-on practices

---

## 📝 Self-Test — Can You Answer These?

1. What are the two major Linux packaging systems?
2. What is the difference between `apt install` and `dpkg -i`?
3. What does `sudo apt update` do and why must you run it before install?
4. What is the difference between `apt remove` and `apt purge`?
5. What does `sudo apt autoremove` do?
6. How do you find which package installed a specific file?
7. What is a PPA and how do you add one?
8. What is the difference between snap and flatpak?
9. How do you prevent a package from being updated?
10. What does `rpm -ql nginx` show?
11. How do you clean the apt package cache?
12. What is EPEL and when would you use it?
13. How do you simulate an installation to see what would happen?
14. What is the difference between .deb and .rpm?
15. How does a package manager verify package integrity?

**Score:** 12/15 correct = ready for Part 12.

---

*Linux SysAdmin Course | Part 11 of ∞ | Reverse Engineering Approach*
*Previous → Part 10: The Linux Boot Process*
*Next → Part 12: Systemd and Services — Managing the Modern Linux*

[← Previous](part10.md) | [Next →](part12.md)
