## 🔧 Section 2: Installation

### 2.1 Installing BIND9 on Ubuntu/Debian

```bash
sudo apt update && sudo apt install -y bind9 bind9utils bind9-doc dnsutils
```

| Package | Purpose |
|---------|---------|
| `bind9` | The named daemon |
| `bind9utils` | Tools: named-checkconf, named-checkzone, rndc, tsig-keygen |
| `bind9-doc` | HTML documentation in `/usr/share/doc/bind9/` |
| `dnsutils` | dig, nslookup, delv, nsupdate |

### 2.2 Check Installation

```bash
named -v
# BIND 9.18.28-1~deb12u1-Ubuntu (Extended Support Version)
```

### 2.3 The `/etc/bind/` Directory

```bash
tree /etc/bind/
```

```
/etc/bind/
├── bind.keys              # DNSSEC root trust anchor
├── db.0                   # Reverse delegation for broadcast
├── db.127                 # Reverse zone for 127.0.0.1
├── db.255                 # Reverse delegation for broadcast
├── db.empty               # Template for empty zones
├── db.local               # Forward zone for localhost
├── db.root                # Root hints
├── named.conf             # Main config (includes others)
├── named.conf.default-zones  # Default zones (localhost, root hints)
├── named.conf.local       # User-defined zones (edit this)
├── named.conf.options     # Options block (edit this)
└── zones.rfc1918          # Reverse zones for RFC 1918 IPs
```

### 2.4 Service Management

```bash
sudo systemctl status named    # Check status
sudo systemctl start named     # Start
sudo systemctl stop named      # Stop
sudo systemctl restart named   # Restart
sudo systemctl reload named    # Reload config (no downtime)
sudo systemctl enable named    # Enable at boot
```

**Always run syntax check before reload:**

```bash
sudo named-checkconf
sudo systemctl reload named
```

### 2.5 AppArmor Profile

Ubuntu installs an AppArmor profile restricting named to read `/etc/bind/`, write `/var/cache/bind/`, and read `/var/lib/bind/`.

```bash
sudo aa-status | grep named
sudo grep named /var/log/syslog | grep -i denied
```

Place zone files in `/var/cache/bind/` to avoid AppArmor issues, or update the profile.

---



---

[← Previous](03-section-1-bind-overview.md) | [↑ Index](index.md) | [Next →](05-level-2-intermediary-configuration-zones.md)
