# 🐧 Linux System Administrator — Complete Course
## Part 19 of ∞: Software Repositories and PPAs — Package Sources

---

> **Reverse Engineering Approach:** When you run `apt install nginx`, your system doesn't magically know where to find nginx. It reads a list of URLs — repositories — that tell it where to look. Understanding repositories means understanding where software REALLY comes from, how to add new sources, and how to verify that what you're downloading hasn't been tampered with.

---

## 🎯 What You Will Achieve in Part 19

This module is organized into three progressive levels:

| Level | You Will Learn |
|-------|---------------|
| **⭐ Basic** | Repository architecture, Debian/Ubuntu repository components and sources.list |
| **⭐ Intermediary** | PPAs, RPM repositories (Fedora/RHEL), EPEL, RPM Fusion, repository priorities |
| **⭐ Advanced** | Third-party repositories, GPG key management, troubleshooting repository issues |

---

## ⭐ Level 1: Basic — Repository Architecture and Debian Repositories

![APT Repository Structure](https://upload.wikimedia.org/wikipedia/commons/thumb/4/4a/Ubuntu_Logo.svg/800px-Ubuntu_Logo.svg.png)
*Ubuntu logo — the most widely used Debian-based distribution, via Wikimedia Commons*

> **Level 1 Goal:** Understand the repository architecture, how packages are indexed, and configure basic Debian/Ubuntu repositories.

---

## 🔍 Section 1: Repository Architecture

### What Is a Repository?

A repository is a server (or directory) containing:
- **Packages** — .deb or .rpm files
- **Metadata** — index of what packages, versions, and dependencies are available
- **Release files** — signed checksums of the metadata
- **GPG keys** — for verifying authenticity

### The Repository Workflow

```
1. Repository maintainer builds packages
2. Creates metadata (Packages.gz, Packages.xz)
3. Signs the Release file with GPG
4. Uploads everything to a server
5. You run: apt update
6. Your system downloads the metadata
7. Verifies the GPG signature
8. Now apt knows what's available
9. You run: apt install nginx
10. apt downloads, verifies, and installs
```

### Repository Structure

```
Debian repository layout:
http://archive.ubuntu.com/ubuntu/
    ├── dists/
    │   └── jammy/                    ← Distribution codename
    │       ├── Release              ← Signed metadata index
    │       ├── Release.gpg          ← GPG signature
    │       ├── main/
    │       │   ├── binary-amd64/
    │       │   │   ├── Packages.gz  ← Package index (compressed)
    │       │   │   └── Packages.xz  ← Package index (more compressed)
    │       │   └── source/          ← Source packages
    │       ├── universe/
    │       ├── restricted/
    │       └── multiverse/
    └── pool/
        └── main/                    ← Actual .deb files
            └── n/
                └── nginx/
                    └── nginx_1.18.0-0ubuntu1_amd64.deb
```

---

## 🔍 Section 2: Debian/Ubuntu Repositories — sources.list

### The sources.list File

```bash
cat /etc/apt/sources.list
```

```
deb http://archive.ubuntu.com/ubuntu jammy main restricted universe multiverse
deb http://security.ubuntu.com/ubuntu jammy-security main restricted
deb http://archive.ubuntu.com/ubuntu jammy-updates main restricted universe multiverse
```

### Anatomy of a Repository Line

```
deb  http://archive.ubuntu.com/ubuntu  jammy         main restricted
│    │                                  │             │
│    │                                  │             └── Components
│    │                                  └── Suite/Codename
│    └── Repository URL
└── Type (deb = binary, deb-src = source)
```

### Repository Types

| Type | Contents |
|------|----------|
| `deb` | Binary packages (.deb) |
| `deb-src` | Source packages (.dsc, .tar.gz) |

### Distribution Suites

```bash
# For Ubuntu:
# jammy (22.04) — Codename for a release
# jammy-security — Security updates
# jammy-updates — Bug fixes and updates
# jammy-backports — Backported software from newer releases
# jammy-proposed — Pre-release testing (use with caution)

# For Debian:
# stable — Current stable release
# testing — Next release (rolling)
# unstable (sid) — Development, always rolling
# stable-updates — Updates for stable
# stable-security — Security updates
```

### Components

```bash
# Ubuntu:
# main        — Canonical-supported free software
# universe    — Community-maintained free software
# restricted  — Proprietary drivers (supported)
# multiverse  — Non-free, legally restricted

# Debian:
# main        — DFSG-free software
# contrib     — Free software that depends on non-free
# non-free    — Non-free software
# non-free-firmware — Non-free firmware (Debian 12+)
```

### The sources.list.d Directory

Modern systems use separate files in `/etc/apt/sources.list.d/`:

```bash
# View repository files
ls /etc/apt/sources.list.d/

# Each file follows the same syntax as sources.list
cat /etc/apt/sources.list.d/docker.list
```

---

## ⭐ Level 2: Intermediary — PPAs, RPM Repositories, and EPEL

![Fedora Logo](https://upload.wikimedia.org/wikipedia/commons/thumb/3/3f/Fedora_logo.svg/800px-Fedora_logo.svg.png)
*Fedora logo — upstream for Red Hat Enterprise Linux, via Wikimedia Commons*

> **Level 2 Goal:** Add and manage PPAs on Ubuntu, configure RPM repositories on Fedora/RHEL, and enable EPEL and RPM Fusion for additional packages.

---

## 🔍 Section 3: PPAs — Personal Package Archives

PPAs are Ubuntu-specific repositories hosted on Launchpad.

### How PPAs Work

```bash
# A PPA is a user/team repository on Launchpad.net
# Format: ppa:OWNER/NAME

# Example: deadsnakes provides newer Python versions
sudo add-apt-repository ppa:deadsnakes/ppa
sudo apt update
sudo apt install python3.12
```

### What add-apt-repository Does

```bash
# The command does three things:
# 1. Downloads the GPG key
# 2. Creates a .list file in /etc/apt/sources.list.d/
# 3. Runs apt update

# Equivalent manual steps:
# 1. Add to sources.list.d/
echo "deb http://ppa.launchpad.net/deadsnakes/ppa/ubuntu $(lsb_release -cs) main" | \
  sudo tee /etc/apt/sources.list.d/deadsnakes.list

# 2. Add GPG key
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys KEY_ID
# (Note: apt-key is deprecated — use signed-by instead)

# 3. Update
sudo apt update
```

### Finding PPAs

```bash
# Search for PPAs on Launchpad:
# https://launchpad.net/ubuntu/+ppas

# Or from command line:
# (requires add-apt-repository with -s flag)
sudo add-apt-repository -s ppa:deadsnakes/ppa | head -20
```

### Risks of PPAs

| Risk | Description |
|------|-------------|
| Security | PPAs are not vetted by Canonical |
| Stability | May conflict with system packages |
| Updates | May not be maintained |
| Dependencies | Can pull in incompatible libraries |

**Best practice:** Only use well-known PPAs (deadsnakes, ondrej/php, etc.)

---

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

---

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

---

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

## ⭐ Level 3: Advanced — Third-Party Repositories and GPG Security

![GPG Key Management](https://upload.wikimedia.org/wikipedia/commons/thumb/9/9b/Gnupg_logo.svg/800px-Gnupg_logo.svg.png)
*GNU Privacy Guard logo — used for package signing verification, via Wikimedia Commons*

> **Level 3 Goal:** Add and verify third-party repositories securely, manage GPG keys for package authenticity, and troubleshoot common repository issues.

---

## 🔍 Section 7: Third-Party Repositories

### Docker Repository

```bash
# Add Docker's official GPG key
sudo apt update
sudo apt install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
  https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list

sudo apt update
```

### Google Chrome Repository

```bash
# Add Google's GPG key
wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | sudo apt-key add -

# Add the repository
sudo sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" \
  >> /etc/apt/sources.list.d/google-chrome.list'

sudo apt update
sudo apt install google-chrome-stable
```

### Microsoft (code, SQL Server, etc.)

```bash
# Visual Studio Code
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
sudo install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/
sudo sh -c 'echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/packages.microsoft.gpg] \
  https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'

sudo apt update
sudo apt install code
```

---

## 🔍 Section 8: GPG Key Management

### Why GPG Keys Matter

Every repository should be cryptographically signed. This ensures:
- **Authenticity** — packages come from the real repository owner
- **Integrity** — packages haven't been modified in transit
- **Non-repudiation** — repository maintainer cannot deny publishing

### Old Method (apt-key — Deprecated)

```bash
# apt-key is deprecated on Debian/Ubuntu 22.04+
# It added keys to a global keyring
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys KEY_ID
sudo apt-key list

# Problem: Trusts ANY package signed with this key
# Solution: Use signed-by in sources.list
```

### Modern Method (signed-by)

```bash
# 1. Download and dearmor the key
sudo curl -fsSL https://example.com/repo/key.gpg \
  -o /etc/apt/keyrings/example.asc
sudo chmod a+r /etc/apt/keyrings/example.asc

# 2. Reference it in sources.list with signed-by
echo "deb [signed-by=/etc/apt/keyrings/example.asc] \
  https://example.com/repo $(lsb_release -cs) main" | \
  sudo tee /etc/apt/sources.list.d/example.list
```

### GPG Key Management Commands

```bash
# List imported keys (old method)
sudo apt-key list

# Manage keys in /etc/apt/trusted.gpg.d/
ls /etc/apt/trusted.gpg.d/

# For RPM:
# Keys are in /etc/pki/rpm-gpg/
ls /etc/pki/rpm-gpg/

# Import RPM key
sudo rpm --import https://example.com/key.gpg

# List imported RPM keys
rpm -q gpg-pubkey
```

---

## 💻 PRACTICE SECTION — 15 Hands-On Exercises

### Level 1 Practices: Repository Basics

---

### ✅ Practice 1: Explore Your Current Repositories

```bash
mkdir -p ~/linux-course/part19
cd ~/linux-course/part19

# Debian/Ubuntu:
if [ -d /etc/apt ]; then
    echo "=== sources.list ==="
    cat /etc/apt/sources.list 2>/dev/null | grep -v "^#" | grep -v "^$"
    
    echo ""
    echo "=== sources.list.d ==="
    ls /etc/apt/sources.list.d/ 2>/dev/null
    for f in /etc/apt/sources.list.d/*.list; do
        if [ -f "$f" ]; then
            echo "--- $(basename "$f") ---"
            cat "$f"
        fi
    done
fi

# Fedora/RHEL:
if [ -d /etc/yum.repos.d ]; then
    echo "=== yum.repos.d ==="
    ls /etc/yum.repos.d/
    
    echo ""
    echo "=== Active repos ==="
    dnf repolist 2>/dev/null || yum repolist 2>/dev/null
fi
```

---

### ✅ Practice 2: Count Available Packages

```bash
cd ~/linux-course/part19

if command -v apt &>/dev/null; then
    echo "Updating package list..."
    sudo apt update 2>/dev/null | tail -5
    
    echo ""
    echo "=== Package counts ==="
    apt list --all-versions 2>/dev/null | wc -l
    
    echo ""
    echo "=== Available kernel versions ==="
    apt list --all-versions 2>/dev/null | grep "^linux-image" | head -10
elif command -v dnf &>/dev/null; then
    echo "=== Package counts ==="
    dnf list available 2>/dev/null | wc -l
fi
```

---

### ✅ Practice 3: Find Your Distribution Codename

```bash
cd ~/linux-course/part19

# Codename is critical for repository configuration
echo "=== Distribution info ==="
cat /etc/os-release | head -5

echo ""
echo "=== Codename ==="
lsb_release -cs

echo ""
echo "=== Release version ==="
lsb_release -rs
```

---

### Level 2 Practices: PPAs, RPM Repos, and EPEL

### ✅ Practice 4: Check GPG Keys

```bash
cd ~/linux-course/part19

if [ -d /etc/apt ]; then
    echo "=== APT trusted keys ==="
    sudo apt-key list 2>/dev/null | head -30 || echo "apt-key unavailable (deprecated)"
    
    echo ""
    echo "=== Key files ==="
    ls -la /etc/apt/trusted.gpg.d/ 2>/dev/null || echo "Directory not found"
    
    echo ""
    echo "=== Keyrings ==="
    ls -la /etc/apt/keyrings/ 2>/dev/null || echo "No custom keyrings"
elif [ -d /etc/pki/rpm-gpg ]; then
    echo "=== RPM GPG keys ==="
    ls /etc/pki/rpm-gpg/
    
    echo ""
    echo "=== Imported GPG keys ==="
    rpm -q gpg-pubkey 2>/dev/null
fi
```

---

### ✅ Practice 5: Add a Test Repository Entry (Dry Run)

```bash
cd ~/linux-course/part19

# This is informational — we won't actually add repos in this course
cat << 'EOF'
Adding a repository (safe example — creating a .list file):
  echo "deb https://example.com/ubuntu $(lsb_release -cs) main" | \
    sudo tee /etc/apt/sources.list.d/example.list

Then update:
  sudo apt update

To remove:
  sudo rm /etc/apt/sources.list.d/example.list
  sudo apt update
EOF
```

---

### ✅ Practice 6: Simulate a PPA Addition

```bash
cd ~/linux-course/part19

# Show what add-apt-repository does under the hood
cat << 'EOF'
Adding ppa:deadsnakes/ppa:

1. Downloads GPG key from keyserver.ubuntu.com
2. Creates: /etc/apt/sources.list.d/deadsnakes-ppa-$(lsb_release -cs).list
   Content: deb http://ppa.launchpad.net/deadsnakes/ppa/ubuntu CODENAME main
3. Runs: sudo apt update

Manual equivalent:
  sudo add-apt-repository ppa:deadsnakes/ppa

To remove:
  sudo add-apt-repository --remove ppa:deadsnakes/ppa
  # OR
  sudo rm /etc/apt/sources.list.d/deadsnakes-*.list
  sudo apt update
EOF
```

---

### ✅ Practice 7: Check RPM Repository Variables

```bash
cd ~/linux-course/part19

if command -v rpm &>/dev/null; then
    echo "=== RPM variables ==="
    echo "Release version: $(rpm -E %fedora 2>/dev/null || rpm -E %rhel 2>/dev/null || echo 'Not Fedora/RHEL')"
    echo "Architecture: $(rpm -E %_arch)"
fi

if command -v dnf &>/dev/null; then
    echo ""
    echo "=== DNF variables ==="
    dnf variables 2>/dev/null | head -10 || echo "Not available"
fi
```

---

### ✅ Practice 8: Repository Priority and Pinning (APT)

```bash
cd ~/linux-course/part19

# APT pinning — control which repo takes priority
cat << 'EOF'
APT package pinning (/etc/apt/preferences.d/):

Example: Prefer packages from example.com over Ubuntu repos:
  Package: *
  Pin: origin "example.com"
  Pin-Priority: 1001

Priority values:
  > 1000   — Force install from this source
  990-1000 — Prefer this source
  500-989  — Normal priority
  100-499  — Less preferred
  < 100    — Only install if no other version exists

Check pinning:
  apt-cache policy nginx
EOF
```

---

### ✅ Practice 9: Mock EPEL Installation

```bash
cd ~/linux-course/part19

# Show EPEL installation for various distros
cat << 'EOF'
EPEL Installation:

RHEL 9 / Rocky 9 / Alma 9:
  sudo dnf install -y epel-release

RHEL 8:
  sudo dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm

RHEL 7:
  sudo yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm

Verify:
  dnf repolist
  # Should show: epel

Search EPEL packages:
  dnf --enablerepo=epel search nginx
EOF
```

---

### ✅ Practice 10: Check Repository Cache

```bash
cd ~/linux-course/part19

# Debian/Ubuntu:
if [ -d /var/lib/apt/lists ]; then
    echo "=== APT cache ==="
    du -sh /var/lib/apt/lists/
    ls /var/lib/apt/lists/ | head -10
fi

if [ -d /var/cache/dnf ]; then
    echo ""
    echo "=== DNF cache ==="
    du -sh /var/cache/dnf/
fi

# Number of packages in cache
if command -v apt-cache &>/dev/null; then
    echo ""
    echo "=== Cached package count ==="
    apt-cache stats | grep "Total package names"
fi
```

---

### ✅ Practice 11: Check for Unused Dependencies

```bash
cd ~/linux-course/part19

# Check for packages installed as dependencies but no longer needed
if command -v apt &>/dev/null; then
    echo "=== Orphaned packages (Debian) ==="
    sudo apt --dry-run autoremove 2>/dev/null | tail -5
elif command -v dnf &>/dev/null; then
    echo "=== Orphaned packages (RHEL) ==="
    sudo dnf autoremove --dry-run 2>/dev/null | head -10
fi
```

---

### ✅ Practice 12: Repository Mirror Selection

```bash
cd ~/linux-course/part19

# Find your current mirror
cat << 'EOF'
Finding the best mirror:

Ubuntu:
  sudo apt update
  # apt selects the best mirror automatically

  Manual mirror selection:
  sudo sed -i 's/us.archive/archive/g' /etc/apt/sources.list

  Or use mirror selection tool:
  sudo apt install netselect-apt
  sudo netselect-apt

Fedora:
  # DNF automatically uses metalink (dynamic mirror list)
  cat /etc/yum.repos.d/fedora.repo
  # Look for metalink= URL
EOF
```

---

### ✅ Practice 13: Check Repository File Format

```bash
cd ~/linux-course/part19

# Check for common syntax errors
cat << 'EOF'
Common repository syntax errors:

APT (.list files):
  ✗ Missing 'deb ' at start
  ✗ Wrong codename
  ✗ Missing components (main, universe, etc.)
  ✗ Incorrect URL (http vs https)
  ✗ No spaces between components
  ✓ sudo apt update  # Will show errors

RPM (.repo files):
  ✗ Missing [repository-id]
  ✗ Space in repository-id
  ✗ Missing baseurl or metalink
  ✗ gpgcheck=1 but no gpgkey
EOF
```

---

### Level 3 Practices: Troubleshooting and Auditing

### ✅ Practice 14: Disable a Repository Temporarily

```bash
cd ~/linux-course/part19

# APT: Use --no-check or flags
cat << 'EOF'
Temporarily disable a repository:

APT:
  # Disable during a single apt command:
  sudo apt install -o Dir::Etc::SourceList=/dev/null package_name

  # OR: move the .list file temporarily
  sudo mv /etc/apt/sources.list.d/example.list /etc/apt/sources.list.d/example.list.disabled

RPM:
  # Disable during a single dnf command:
  sudo dnf --disablerepo=epel install package_name

  # OR: edit the .repo file and set enabled=0
  # OR: use dnf config-manager
  sudo dnf config-manager --set-disabled epel
EOF
```

---

### ✅ Practice 15: Real SysAdmin Scenario — Repository Audit

```bash
cd ~/linux-course/part19

cat > repository_audit.sh << 'EOF'
#!/bin/bash
set -euo pipefail

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
HOSTNAME=$(hostname)
REPORT="repository_audit_report.txt"

echo "============================================" > "$REPORT"
echo "  REPOSITORY AUDIT REPORT" >> "$REPORT"
echo "  Hostname: $HOSTNAME" >> "$REPORT"
echo "  Date:     $TIMESTAMP" >> "$REPORT"
echo "============================================" >> "$REPORT"
echo "" >> "$REPORT"

# Section 1: Distribution info
echo "1. DISTRIBUTION" >> "$REPORT"
cat /etc/os-release | head -5 >> "$REPORT"
echo "" >> "$REPORT"

# Section 2: Repository sources
echo "2. APT SOURCES" >> "$REPORT"
if [ -f /etc/apt/sources.list ]; then
    grep -v "^#" /etc/apt/sources.list | grep -v "^$" | sed 's/^/  /' >> "$REPORT"
fi
if [ -d /etc/apt/sources.list.d ]; then
    for f in /etc/apt/sources.list.d/*.list; do
        if [ -f "$f" ]; then
            echo "  File: $(basename "$f")" >> "$REPORT"
            grep -v "^#" "$f" | grep -v "^$" | sed 's/^/    /' >> "$REPORT"
        fi
    done
fi
echo "" >> "$REPORT"

# Section 3: RPM repos
echo "3. RPM REPOSITORIES" >> "$REPORT"
if [ -d /etc/yum.repos.d ]; then
    for f in /etc/yum.repos.d/*.repo; do
        if [ -f "$f" ]; then
            echo "  File: $(basename "$f")" >> "$REPORT"
            grep -E "^\[|enabled=" "$f" | sed 's/^/    /' >> "$REPORT"
        fi
    done
fi
echo "" >> "$REPORT"

# Section 4: GPG keys
echo "4. GPG KEYS" >> "$REPORT"
if command -v apt-key &>/dev/null; then
    sudo apt-key list 2>/dev/null | grep -E "^pub|uid" | head -20 | sed 's/^/  /' >> "$REPORT" || true
fi
if [ -d /etc/apt/keyrings ]; then
    ls /etc/apt/keyrings/ | sed 's/^/  /' >> "$REPORT"
fi
if [ -d /etc/pki/rpm-gpg ]; then
    ls /etc/pki/rpm-gpg/ | sed 's/^/  /' >> "$REPORT"
fi
echo "" >> "$REPORT"

# Section 5: Last update time
echo "5. LAST APT UPDATE" >> "$REPORT"
if [ -d /var/lib/apt/lists ]; then
    last_update=$(stat -c '%Y' /var/lib/apt/lists/ 2>/dev/null || echo 0)
    if [ "$last_update" -gt 0 ]; then
        last_update_str=$(date -d @"$last_update" '+%Y-%m-%d %H:%M:%S')
        days_ago=$(( ($(date +%s) - last_update) / 86400 ))
        echo "  Last update: $last_update_str ($days_ago days ago)" >> "$REPORT"
    fi
fi
echo "" >> "$REPORT"

# Section 6: Available updates
echo "6. AVAILABLE UPDATES" >> "$REPORT"
if command -v apt &>/dev/null; then
    apt list --upgradable 2>/dev/null | grep -c "^" | \
      awk '{print "  " $1 " upgradable packages"}' >> "$REPORT"
fi
echo "" >> "$REPORT"

echo "============================================" >> "$REPORT"
echo "  END OF REPORT" >> "$REPORT"
echo "============================================" >> "$REPORT"

cat "$REPORT"
EOF

chmod +x repository_audit.sh
./repository_audit.sh
```

---

## 🧠 Deep Understanding — How Repository Security Works

### The Chain of Trust

```
YOU (trust)
    ↓
Repository GPG key (trust the key)
    ↓
Repository Release file (signed by the GPG key)
    ↓
Packages.gz checksum (verified against Release file)
    ↓
.deb / .rpm packages (verified against Packages.gz checksum)
    ↓
Package signature (optional, maintained by packager)
```

### GPG Key Types

```bash
# Two types of signatures:
# 1. Release file signature — ensures metadata is authentic
# 2. Package signature — ensures individual .deb is authentic

# APT verifies the Release file signature
# The Release file contains checksums of Packages.gz
# Packages.gz contains checksums of individual .deb files
# So verifying Release → verifies everything

# Repository signing with signed-by (modern):
# The key is scoped to ONLY the repository that references it
# Even if the key is compromised, only that repo is affected
```

### Mirror Selection

```bash
# How APT selects a mirror:
# 1. Reads the base URL from sources.list
# 2. If mirror:// is used, queries a mirror database
# 3. Tests latency to available mirrors
# 4. Picks the fastest one

# How DNF selects a mirror:
# 1. Reads metalink= URL
# 2. Metalink returns a list of mirrors + checksums
# 3. DNF picks one and verifies the content
```

---

## 📋 Summary — Command Reference for Part 19

### Level 1 — Basic Repository Commands

| Command | Action |
|---------|--------|
| `cat /etc/apt/sources.list` | View main repository config |
| `ls /etc/apt/sources.list.d/` | List additional repo files |
| `lsb_release -cs` | Get distribution codename |
| `lsb_release -a` | Show full distribution info |
| `sudo apt update` | Update package index from all repos |

### Level 2 — Intermediary Repository Management

| Command | Action |
|---------|--------|
| `sudo add-apt-repository ppa:user/name` | Add a PPA |
| `sudo add-apt-repository --remove ppa:user/name` | Remove a PPA |
| `ls /etc/yum.repos.d/` | List RPM repo files |
| `dnf repolist` | List enabled RPM repos |
| `dnf repolist --all` | List all RPM repos (enabled + disabled) |
| `dnf config-manager --add-repo URL` | Add a new RPM repo |
| `dnf config-manager --set-enabled NAME` | Enable an RPM repo |
| `dnf config-manager --set-disabled NAME` | Disable an RPM repo |
| `sudo apt-cache policy` | Show repository priorities |
| `apt-cache showpkg PACKAGE` | Show available versions from repos |

### Level 3 — Advanced GPG and Third-Party Repositories

| Command | Action |
|---------|--------|
| `sudo apt-key list` | List trusted GPG keys (deprecated) |
| `ls /etc/apt/trusted.gpg.d/` | List trusted GPG key files |
| `ls /etc/apt/keyrings/` | Custom keyrings directory |
| `gpg --show-keys KEY_FILE` | Inspect GPG key details |
| `rpm -q gpg-pubkey` | List imported RPM GPG keys |
| `ls /etc/pki/rpm-gpg/` | RPM GPG key files |
| `sudo dnf install epel-release` | Install EPEL repository |
| `sudo dnf install rpmfusion-free-release` | Install RPM Fusion free repo |
| `sudo apt-add-repository "deb [signed-by=/path/keyring] URL dist components"` | Add repo with signed-by |

### Common Third-Party Repositories

| Repository | Install Method | Purpose |
|------------|---------------|---------|
| EPEL | `dnf install epel-release` | Extra packages for Enterprise Linux |
| RPM Fusion | `dnf install rpmfusion-free-release` | Multimedia packages for Fedora/RHEL |
| Docker CE | Add repo + GPG key via script | Container runtime |
| Google Chrome | Add repo + GPG key via script | Web browser |
| Microsoft VSCode | Add repo + GPG key via script | Code editor |
| NodeSource | curl script or manual `sources.list.d` | Latest Node.js |

---

## 🚀 What's Coming in Part 20

**Part 20: System Updates and Patch Management**

You will learn:
- Understanding the update lifecycle
- Security updates vs feature updates
- Configuring unattended-upgrades
- LTS vs rolling release strategies
- Testing updates in staging
- Rollback strategies for failed updates
- 15 hands-on practices

---

## 📝 Self-Test — Can You Answer These?

1. What is a Linux software repository?
2. What are the four Ubuntu repository components?
3. What is a PPA and how do you add one?
4. What is EPEL and why is it important for RHEL-based systems?
5. What does `sudo apt update` actually do (what is downloaded)?
6. What is the difference between `deb` and `deb-src` in sources.list?
7. How do modern APT configurations use GPG keys?
8. Name three third-party repositories and what they provide.
9. How do you list enabled repositories on Fedora/RHEL?
10. What is the `signed-by` option in sources.list?
11. How does a repository verify package authenticity?
12. What is a Release file and what does it contain?
13. How do you temporarily disable a repository?
14. What is RPM Fusion and what does it provide?
15. How do you find your distribution's codename?

**Score:** 12/15 correct = ready for Part 20.

---

*Linux SysAdmin Course | Part 19 of ∞ | Reverse Engineering Approach*
*Previous → Part 18: Environment Variables and Shell Configuration*
*Next → Part 20: System Updates and Patch Management*

[← Previous](part18.md) | [Next →](part20.md)
