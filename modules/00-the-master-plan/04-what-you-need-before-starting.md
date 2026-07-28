## 🛠️ What You Need Before Starting

### Hardware Requirements

| Requirement | Minimum | Recommended |
|-------------|---------|-------------|
| **CPU** | Any x86_64 processor | 4+ cores |
| **RAM** | 2 GB | 8+ GB |
| **Disk** | 20 GB free | 50+ GB free |
| **Internet** | Required for package downloads | Broadband |

### You Have Two Setup Options

#### Option A: Install Linux Natively (Best)
Install Ubuntu or Fedora as your main OS. You will learn 10x faster when Linux is your daily driver.

#### Option B: Use a Virtual Machine (Good)
```bash
# Install VirtualBox or VMware, then:
# Download Ubuntu Server ISO
# Create a VM with: 2 CPU cores, 4 GB RAM, 25 GB disk
# Install and follow along
```

#### Option C: Use WSL on Windows (Quick Start)
```powershell
# Open PowerShell as Administrator
wsl --install
wsl --set-default-version 2
wsl --install -d Ubuntu-24.04
```

> 💡 **Recommendation:** Use Option A or B. WSL is convenient but will not teach you systemd, boot processes, or real server management.





[← Previous](03-the-reverse-engineering-method-how.md) | [↑ Index](index.md) | [Next →](05-how-to-read-each-part.md)
