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



---

[← Previous](14-deep-understanding-how-repository-security.md) | [↑ Index](index.md) | [Next →](16-whats-coming-in-part-20.md)
