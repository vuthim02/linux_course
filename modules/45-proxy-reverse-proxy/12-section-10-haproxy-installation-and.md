## 🔍 Section 10: HAProxy — Installation and Basic Configuration

### 10.1 Installation

```bash
# Debian / Ubuntu
sudo apt update
sudo apt install haproxy -y

# RHEL / Rocky / Alma
sudo dnf install haproxy -y

# Verify
haproxy -v
# HAProxy version 2.8.x

# Check config syntax
sudo haproxy -f /etc/haproxy/haproxy.cfg -c
```

### 10.2 Basic Configuration Structure

HAProxy config has **5 main sections**:

| Section | Purpose |
|---------|---------|
| `global` | Process-wide settings (maxconn, user, group, logging) |
| `defaults` | Default values for all frontends/backends |
| `frontend` | Incoming traffic listener |
| `backend` | Server pool definitions |
| `listen` | Combined frontend+backend (for simple setups) |

### 10.3 Minimal TCP Load Balancer

```cfg
# /etc/haproxy/haproxy.cfg

global
    log /dev/log local0
    log /dev/log local1 notice
    chroot /var/lib/haproxy
    stats socket /run/haproxy/admin.sock mode 660 level admin expose-fd listeners
    stats timeout 30s
    user haproxy
    group haproxy
    daemon

defaults
    log     global
    mode    tcp
    option  tcplog
    option  dontlognull
    timeout connect 5000
    timeout client  50000
    timeout server  50000

frontend mysql_front
    bind *:3306
    default_backend mysql_back

backend mysql_back
    server db1 10.0.0.10:3306 check
    server db2 10.0.0.11:3306 check
    server db3 10.0.0.12:3306 check backup
```

### 10.4 Minimal HTTP Load Balancer

```cfg
global
    log /dev/log local0
    log /dev/log local1 notice
    chroot /var/lib/haproxy
    stats socket /run/haproxy/admin.sock mode 660 level admin
    stats timeout 30s
    user haproxy
    group haproxy
    daemon

defaults
    log     global
    mode    http
    option  httplog
    option  dontlognull
    option  forwardfor       # Add X-Forwarded-For
    option  http-server-close # Connection: close after response
    timeout connect 5000
    timeout client  50000
    timeout server  50000

frontend web_front
    bind *:80
    bind *:443 ssl crt /etc/ssl/haproxy.pem
    default_backend web_back

backend web_back
    balance roundrobin
    server web1 10.0.0.10:80 check
    server web2 10.0.0.11:80 check
    server web3 10.0.0.12:80 check
```

---



---

[← Previous](11-section-9-nginx-as-load.md) | [↑ Index](index.md) | [Next →](13-section-11-haproxy-load-balancing.md)
