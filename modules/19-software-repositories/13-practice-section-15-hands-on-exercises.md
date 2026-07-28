## 💻 PRACTICE SECTION — 15 Hands-On Exercises

### Level 1 Practices: Repository Basics


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





[← Previous](12-section-8-gpg-key-management.md) | [↑ Index](index.md) | [Next →](14-deep-understanding-how-repository-security.md)
