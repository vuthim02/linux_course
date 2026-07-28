## 📋 Summary — Complete Command Reference for Part 20

### Level 1: Basic Commands — Checking and Applying Updates

| Command | Action |
|---------|--------|
| `sudo apt update` | Update package index |
| `apt list --upgradable` | List upgradable packages |
| `dnf check-update` | Check for updates |
| `dnf updateinfo list --security` | List security updates |
| `sudo apt upgrade` | Upgrade all packages |
| `sudo apt full-upgrade` | Upgrade with dep changes |
| `sudo dnf update` | Update all packages |
| `sudo apt install --only-upgrade PKG` | Upgrade single package |

### Level 2: Intermediary Commands — Holds, Pins, and Automation

| Command | Action |
|---------|--------|
| `sudo apt-mark hold PKG` | Prevent upgrade |
| `sudo apt-mark unhold PKG` | Allow upgrade |
| `apt-mark showhold` | Show held packages |
| `apt-cache policy PKG` | Show version info |
| `less /var/log/unattended-upgrades/` | Auto-update logs |

### Level 3: Advanced Commands — History and Rollback

| Command | Action |
|---------|--------|
| `less /var/log/apt/history.log` | APT history |
| `dnf history` | DNF transaction history |
| `sudo dnf history undo ID` | Rollback transaction |





[← Previous](14-deep-understanding-how-updates-work.md) | [↑ Index](index.md) | [Next →](16-whats-coming-in-part-21.md)
