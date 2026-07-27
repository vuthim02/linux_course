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



---

[← Previous](17-practice-section-20-hands-on-exercises.md) | [↑ Index](index.md) | [Next →](19-whats-coming-in-part-12.md)
