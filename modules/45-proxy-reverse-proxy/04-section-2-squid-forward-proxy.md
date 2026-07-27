## 🔍 Section 2: Squid — Forward Proxy

### 2.1 Installation

```bash
# Debian / Ubuntu
sudo apt update
sudo apt install squid -y

# RHEL / Rocky / Alma
sudo dnf install squid -y

# Verify
squid -v
# Output: Squid Cache: Version 6.x
sudo systemctl status squid
```

### 2.2 Core Configuration File: `/etc/squid/squid.conf`

Squid's configuration is a single large file with directives. Every directive has a default value. You uncomment and modify what you need.

```bash
# See the full default config (hundreds of lines)
sudo less /etc/squid/squid.conf
```

**The minimal running config:**

```apache
# /etc/squid/squid.conf — Minimal forward proxy

# Listen on port 3128 for all interfaces
http_port 3128

# Visible hostname (Squid complains if not set)
visible_hostname proxy.lab.local

# Cache directory: type ufs, path /var/spool/squid, size 100 MB, 16 L1 subdirs, 256 L2
cache_dir ufs /var/spool/squid 100 16 256

# Cache memory limit
cache_mem 64 MB

# Maximum object size in cache (4 MB)
maximum_object_size 4 MB

# Default ACLs
acl all src 0.0.0.0/0
acl localnet src 10.0.0.0/8         # RFC 1918
acl localnet src 172.16.0.0/12
acl localnet src 192.168.0.0/16
acl SSL_ports port 443
acl Safe_ports port 80               # http
acl Safe_ports port 21               # ftp
acl Safe_ports port 443              # https
acl Safe_ports port 1025-65535       # unregistered ports

# Only allow localnet to use this proxy
http_access allow localnet
http_access deny all
```

**Key directives explained:**

| Directive | Purpose |
|-----------|---------|
| `http_port` | IP and port to listen on (e.g., `3128`, `8080`, or `0.0.0.0:8080`) |
| `visible_hostname` | Hostname Squid reports in error pages and headers |
| `cache_dir` | Where and how to store cached objects |
| `cache_mem` | In-memory cache for hot objects |
| `maximum_object_size` | Largest object Squid will cache |
| `http_access` | Access control list rule (allow/deny) |
| `acl` | Define an access control list element |

### 2.3 Testing the Forward Proxy

```bash
# Start Squid
sudo systemctl restart squid
sudo systemctl enable squid

# Test with curl (using proxy)
curl -x http://127.0.0.1:3128 -v http://example.com

# Check that Via header appears
curl -x http://127.0.0.1:3128 -sI http://example.com | grep -i via
# Via: 1.1 proxy.lab.local (squid/6.0)

# Without proxy (direct)
curl -sI http://example.com | grep -i via
# (no Via header)
```

---



---

[← Previous](03-section-1-forward-proxy-vs.md) | [↑ Index](index.md) | [Next →](05-section-3-squid-access-control.md)
