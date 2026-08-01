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
| `sudo apt install --only-upgrade PKG` | Upgrade a single package |
| `less /var/log/unattended-upgrades/` | Auto-update logs |
| `sudo unattended-upgrades --dry-run --debug` | Simulate unattended upgrades |
| `sudo systemctl enable --now dnf-automatic.timer` | Enable DNF auto updates |
| `systemctl list-timers dnf-automatic*` | Check DNF timer schedule |
| `sudo apt install linux-image-VERSION` | Install a specific kernel version |
| `uname -r` | Show running kernel version |
| `dpkg -l \| grep linux-image` | List installed kernels (Debian) |
| `rpm -qa \| grep kernel` | List installed kernels (RHEL) |

### Level 3: Advanced Commands — History and Rollback

| Command | Action |
|---------|--------|
| `less /var/log/apt/history.log` | APT history |
| `dnf history` | DNF transaction history |
| `sudo dnf history undo ID` | Rollback a single transaction |
| `sudo dnf history rollback ID` | Rollback to a specific transaction |
| `sudo apt install PACKAGE=VERSION` | Install a specific version (downgrade) |
| `sudo lvcreate -L 5G -s -n snap /dev/vg/root` | Create LVM snapshot before update |
| `sudo lvconvert --merge /dev/vg/snap` | Restore LVM snapshot |
| `zfs snapshot -r pool@pre-update` | Create ZFS snapshot |
| `zfs rollback -r pool@pre-update` | Restore ZFS snapshot |
| `sudo snapper -c root create -d "desc"` | Create btrfs snapshot pair |
| `sudo snapper -c root undochange X..Y` | Rollback btrfs snapshot |
| `sudo canonical-livepatch status` | Check live patching status |





[← Previous](14-deep-understanding-how-updates-work.md) | [↑ Index](index.md) | [Next →](16-whats-coming-in-part-21.md)
