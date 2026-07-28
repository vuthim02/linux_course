## 🔍 Section 4: Unattended-Upgrades

Automatic security updates for Debian/Ubuntu.

### Installation and Configuration

```bash
# Install
sudo apt install unattended-upgrades apt-listchanges

# Configuration file
sudo dpkg-reconfigure --priority=low unattended-upgrades

# Or edit the config directly:
sudo cat /etc/apt/apt.conf.d/50unattended-upgrades
```

### Configuration Options

```
// Enable security updates
Unattended-Upgrade::Allowed-Origins {
    "${distro_id}:${distro_codename}-security";
//  "${distro_id}:${distro_codename}-updates";
//  "${distro_id}:${distro_codename}-proposed";
};

// Auto-fix broken packages
Unattended-Upgrade::AutoFixInterruptedDpkg "true";

// Clean unused dependencies
Unattended-Upgrade::Remove-Unused-Dependencies "true";

// Automatically reboot if needed (for kernel updates)
Unattended-Upgrade::Automatic-Reboot "true";
Unattended-Upgrade::Automatic-Reboot-Time "03:00";

// Send email on errors
Unattended-Upgrade::Mail "admin@example.com";
```

### Checking Unattended-Upgrade Status

```bash
# Check the log
less /var/log/unattended-upgrades/unattended-upgrades.log

# Simulate a run (dry-run)
sudo unattended-upgrades --dry-run --debug

# Check if it's running
systemctl status unattended-upgrades
```

### DNF Automatic (Fedora/RHEL)

```bash
# Install
sudo dnf install dnf-automatic

# Configure
sudo cat /etc/dnf/automatic.conf

# Enable timer
sudo systemctl enable --now dnf-automatic.timer

# Check status
systemctl status dnf-automatic.timer
```





[← Previous](07-level-2-intermediary-automation-and.md) | [↑ Index](index.md) | [Next →](09-section-6-update-strategies-for.md)
