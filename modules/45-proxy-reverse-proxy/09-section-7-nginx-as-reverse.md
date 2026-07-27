## 🔍 Section 7: Nginx as Reverse Proxy

### 7.1 Installation

```bash
# Debian / Ubuntu
sudo apt update
sudo apt install nginx -y

# RHEL / Rocky / Alma
sudo dnf install nginx -y

# Verify
nginx -v
sudo systemctl status nginx
```

### 7.2 Basic Reverse Proxy Configuration

```nginx
# /etc/nginx/sites-available/reverse-proxy

server {
    listen 80;
    server_name app.example.com;

    # Pass all requests to the backend
    location / {
        proxy_pass http://10.0.0.10:8080;

        # Standard proxy headers
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout    60s;
        proxy_read_timeout    60s;

        # Buffer settings
        proxy_buffering    on;
        proxy_buffer_size  4k;
        proxy_buffers      8 4k;
        proxy_busy_buffers_size 8k;
    }
}
```

### 7.3 Proxy Headers Explained

```nginx
location / {
    proxy_pass http://backend;

    # Host header — MUST match the backend's expected hostname
    proxy_set_header Host $host;

    # Real client IP (Nginx-specific)
    proxy_set_header X-Real-IP $remote_addr;

    # Chain of IPs that proxied the request
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;

    # Original protocol (http/https)
    proxy_set_header X-Forwarded-Proto $scheme;

    # Original port
    proxy_set_header X-Forwarded-Port $server_port;

    # Modern standard (RFC 7239)
    proxy_set_header Forwarded "for=$remote_addr;proto=$scheme;host=$host";
}
```

### 7.4 Load Balancing with upstream

```nginx
# /etc/nginx/nginx.conf — inside http block
upstream backend_pool {
    # Default: round-robin
    server 10.0.0.10:8080 weight=3;
    server 10.0.0.11:8080 weight=2;
    server 10.0.0.12:8080 backup;    # Backup — only used if others fail
    server 10.0.0.13:8080 down;      # Removed from rotation (manual)
}

server {
    listen 80;
    server_name app.example.com;

    location / {
        proxy_pass http://backend_pool;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

### 7.5 Upstream Load Balancing Methods

| Method | Directive | Description |
|--------|-----------|-------------|
| Round-Robin | *(default)* | Distributes evenly across all servers |
| Least Connections | `least_conn;` | Sends to server with fewest active connections |
| IP Hash | `ip_hash;` | Consistent hash of client IP (sticky sessions) |
| Generic Hash | `hash $request_uri consistent;` | Hash of any variable (e.g., URI, cookie) |
| Random | `random two least_conn;` | Random pick, then pick least-conn of two |

```nginx
# Sticky sessions via IP hash
upstream sticky_pool {
    ip_hash;
    server 10.0.0.10:8080;
    server 10.0.0.11:8080;
    server 10.0.0.12:8080;
}

# Hash by cookie
upstream cookie_hash {
    hash $cookie_session_id consistent;
    server 10.0.0.10:8080;
    server 10.0.0.11:8080;
}

# Least connections
upstream leastconn_pool {
    least_conn;
    server 10.0.0.10:8080;
    server 10.0.0.11:8080;
    server 10.0.0.12:8080;
}
```

### 7.6 Health Checks

Nginx **passive** health checks are built-in (no extra module):

```nginx
upstream backend {
    server 10.0.0.10:8080 max_fails=3 fail_timeout=30s;
    server 10.0.0.11:8080 max_fails=3 fail_timeout=30s;
    server 10.0.0.12:8080 max_fails=3 fail_timeout=30s;
}
```

**Active health checks** require the `nginx-plus` (commercial) module or the open-source `nginx_upstream_check_module`.

---



---

[← Previous](08-section-6-squid-reverse-proxy.md) | [↑ Index](index.md) | [Next →](10-section-8-nginx-caching.md)
