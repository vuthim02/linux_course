## 🔍 Section 7: Third-Party Repositories

### Docker Repository

```bash
# Add Docker's official GPG key
sudo apt update
sudo apt install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
  https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list

sudo apt update
```

### Google Chrome Repository

```bash
# Add Google's GPG key (modern signed-by method)
sudo curl -fsSL https://dl.google.com/linux/linux_signing_key.pub \
  -o /etc/apt/keyrings/google-chrome.asc
sudo chmod a+r /etc/apt/keyrings/google-chrome.asc

# Add the repository
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/google-chrome.asc] \
  http://dl.google.com/linux/chrome/deb/ stable main" | \
  sudo tee /etc/apt/sources.list.d/google-chrome.list

sudo apt update
sudo apt install google-chrome-stable
```

### Microsoft (code, SQL Server, etc.)

```bash
# Visual Studio Code
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
sudo install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/
sudo sh -c 'echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/packages.microsoft.gpg] \
  https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'

sudo apt update
sudo apt install code
```

### COPR (Fedora's Equivalent of PPAs)

Fedora has COPR (Cool Other Package Repo), similar to Ubuntu PPAs:

```bash
# Enable a COPR repository
sudo dnf copr enable user/project

# Example: newer PHP versions
sudo dnf copr enable remi/php-8.3

# Disable a COPR
sudo dnf copr remove user/project

# Search COPR repos
dnf copr search php

# List enabled COPR repos
dnf copr list

# COPR repos appear in /etc/yum.repos.d/_copr_*.repo
ls /etc/yum.repos.d/_copr_*.repo 2>/dev/null
```





[← Previous](10-level-3-advanced-third-party-repositories.md) | [↑ Index](index.md) | [Next →](12-section-8-gpg-key-management.md)
