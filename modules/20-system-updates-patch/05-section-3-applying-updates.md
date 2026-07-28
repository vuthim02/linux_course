## 🔍 Section 3: Applying Updates

### Safe Update Practices

```bash
# NEVER run upgrade without first running update
sudo apt update && sudo apt upgrade -y

# ALWAYS review what will be upgraded before confirming
sudo apt upgrade
# Review the list, then type 'y' or 'n'

# For non-interactive scripts:
sudo apt update && sudo apt upgrade -y

# Full-upgrade (handles dependency changes)
sudo apt full-upgrade
# May REMOVE packages if needed to satisfy dependencies
```

### DNF Update Commands

```bash
# Update all packages
sudo dnf update

# Update specific package
sudo dnf update nginx

# Security updates only
sudo dnf update --security

# Download packages but don't install
sudo dnf update --downloadonly

# Skip broken packages
sudo dnf update --skip-broken
```

### Partial Upgrades

```bash
# Update a single package
sudo apt install --only-upgrade nginx

# Hold a package at current version
sudo apt-mark hold nginx

# Show held packages
apt-mark showhold

# Unhold
sudo apt-mark unhold nginx
```





[← Previous](04-section-2-checking-for-updates.md) | [↑ Index](index.md) | [Next →](06-section-5-lts-vs-rolling.md)
