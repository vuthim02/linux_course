## 🔍 Section 8: GPG Key Management

### Why GPG Keys Matter

Every repository should be cryptographically signed. This ensures:
- **Authenticity** — packages come from the real repository owner
- **Integrity** — packages haven't been modified in transit
- **Non-repudiation** — repository maintainer cannot deny publishing

### Old Method (apt-key — Deprecated)

```bash
# apt-key is deprecated on Debian/Ubuntu 22.04+
# It added keys to a global keyring
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys KEY_ID
sudo apt-key list

# Problem: Trusts ANY package signed with this key
# Solution: Use signed-by in sources.list
```

### Modern Method (signed-by)

```bash
# 1. Download and dearmor the key
sudo curl -fsSL https://example.com/repo/key.gpg \
  -o /etc/apt/keyrings/example.asc
sudo chmod a+r /etc/apt/keyrings/example.asc

# 2. Reference it in sources.list with signed-by
echo "deb [signed-by=/etc/apt/keyrings/example.asc] \
  https://example.com/repo $(lsb_release -cs) main" | \
  sudo tee /etc/apt/sources.list.d/example.list
```

### GPG Key Management Commands

```bash
# List imported keys (old method)
sudo apt-key list

# Manage keys in /etc/apt/trusted.gpg.d/
ls /etc/apt/trusted.gpg.d/

# For RPM:
# Keys are in /etc/pki/rpm-gpg/
ls /etc/pki/rpm-gpg/

# Import RPM key
sudo rpm --import https://example.com/key.gpg

# List imported RPM keys
rpm -q gpg-pubkey
```

---



---

[← Previous](11-section-7-third-party-repositories.md) | [↑ Index](index.md) | [Next →](13-practice-section-15-hands-on-exercises.md)
