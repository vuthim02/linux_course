## 🔍 Section 8: Snap — Universal Linux Packages

Snap is Canonical's universal package format. Snaps are confined (sandboxed) and auto-update.

### Essential Snap Commands

```bash
# Install snap support
sudo apt install snapd

# Find a snap
snap find nginx

# Install a snap
sudo snap install nginx

# List installed snaps
snap list

# Update snaps
sudo snap refresh

# Update a specific snap
sudo snap refresh nginx

# Revert to previous version
sudo snap revert nginx

# Remove a snap
sudo snap remove nginx

# Show snap info
snap info nginx

# Run snap commands (they're in /snap/bin/)
/snap/bin/nginx
```

### Snap Channels (Versions)

```bash
# Stable (default) — production-ready
sudo snap install nginx

# Candidate — pre-release testing
sudo snap install nginx --channel=candidate

# Beta — unstable testing
sudo snap install nginx --channel=beta

# Edge — latest development
sudo snap install nginx --channel=edge
```

### Snap Advantages and Disadvantages

| Aspect | Advantage | Disadvantage |
|--------|-----------|-------------|
| Installation | One command works on ALL distros | Large download (includes all deps) |
| Updates | Automatic, atomic updates | You cannot disable updates easily |
| Security | Confined by AppArmor | Some apps break due to confinement |
| Size | No dependency conflicts | Each snap is 100MB+ |





[← Previous](10-section-7-understanding-rpm-repositories.md) | [↑ Index](index.md) | [Next →](12-section-9-flatpak-universal-desktop.md)
