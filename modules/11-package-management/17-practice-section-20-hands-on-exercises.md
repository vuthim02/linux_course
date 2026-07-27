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



---

[← Previous](16-deep-understanding-how-package-management.md) | [↑ Index](index.md) | [Next →](18-summary-complete-command-reference-for.md)
