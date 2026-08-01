## Section 14: Pacman and AUR — Arch Linux Packaging

### Pacman — Package Manager for Arch Linux

```bash
# Basic usage
pacman -Syu                    # Full system update
pacman -S package              # Install package
pacman -Rs package             # Remove package + dependencies
pacman -Q                      # List installed packages
pacman -Qi package             # Query info
pacman -Qo /path/to/file       # Which package owns file
pacman -Fl package             # List files in package

# Search
pacman -Ss keyword             # Search repositories
pacman -Qs keyword             # Search installed packages

# Cache management
pacman -Sc                     # Remove old packages from cache
pacman -Scc                    # Clear entire cache

# Package files
# Packages: .pkg.tar.zst
# Repos: core, extra, community, multilib
# Config: /etc/pacman.conf
```

### AUR — Arch User Repository

Community-driven repository. Use an AUR helper (e.g., `yay`, `paru`).

```bash
# Install yay (AUR helper)
sudo pacman -S --needed git base-devel
git clone https://aur.archlinux.org/yay.git
cd yay && makepkg -si

# Use yay
yay -S package                 # Install from AUR
yay -Syu                       # Update AUR + official packages
yay -Ps                        # Print system stats
```

### PKGBUILD — How Arch Packages Are Built

```bash
# PKGBUILD example
pkgname=myapp
pkgver=1.0.0
pkgrel=1
arch=('x86_64')
depends=('glibc' 'openssl')
source=("https://example.com/$pkgname-$pkgver.tar.gz")

build() {
  cd "$srcdir/$pkgname-$pkgver"
  ./configure --prefix=/usr
  make
}

package() {
  cd "$srcdir/$pkgname-$pkgver"
  make DESTDIR="$pkgdir" install
}
```
