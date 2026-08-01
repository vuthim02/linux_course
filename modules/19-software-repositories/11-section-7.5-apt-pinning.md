## 🔍 Section 7.5: APT Pinning — Controlling Package Sources

When multiple repositories provide the same package, APT pinning determines which version wins.

### How APT Pinning Works

```bash
# Every repository has a "priority" (default: 500)
# Higher priority = chosen first
# Pin files go in /etc/apt/preferences.d/

# Default priorities:
#   990 — Packages in /etc/apt/preferences.d/ with Pin-Priority >= 990
#   500 — Normal repositories
#   100 — Installed packages (the "keep" priority)
#   -1  — Never install
```

### Creating a Pin File

```
# /etc/apt/preferences.d/my-pinning
Package: *
Pin: release o=Debian
Pin-Priority: 900

Package: nginx
Pin: version 1.24.*
Pin-Priority: 1001
```

Common pin scenarios:

```bash
# Scenario 1: Prefer Debian backports for specific packages
cat << 'EOF' | sudo tee /etc/apt/preferences.d/backports
Package: *
Pin: release a=bookworm-backports
Pin-Priority: 100   # Only install if no other version
EOF

# Scenario 2: Prefer a specific repo for a specific package
cat << 'EOF' | sudo tee /etc/apt/preferences.d/docker
Package: docker-ce docker-ce-cli
Pin: origin download.docker.com
Pin-Priority: 1001   # Force install from Docker's repo
EOF

# Scenario 3: Never install from a repo
cat << 'EOF' | sudo tee /etc/apt/preferences.d/never
Package: *
Pin: release o=SomeUntrustedRepo
Pin-Priority: -1
EOF
```

### Checking Priorities

```bash
# Check which version will be installed and from where
apt-cache policy nginx

# Example output:
# nginx:
#   Installed: (none)
#   Candidate: 1.24.0-1ubuntu1
#   Version table:
#      1.24.0-1ubuntu1 500
#         500 http://archive.ubuntu.com/ubuntu jammy/universe amd64 Packages
#      1.18.0-6ubuntu14 500
#         500 http://security.ubuntu.com/ubuntu jammy-security/universe amd64 Packages
```

### Holding Packages at a Specific Version

```bash
# Prevent a package from being updated
sudo apt-mark hold nginx

# Remove the hold
sudo apt-mark unhold nginx

# List held packages
apt-mark showhold

# For DNF:
sudo dnf versionlock add nginx
sudo dnf versionlock list
sudo dnf versionlock delete nginx
```
