## 🔍 Section 7: Nginx — Installation and Basics

### Installation

```bash
sudo apt update
sudo apt install nginx -y

# Verify
sudo systemctl status nginx
nginx -v
```

### Directory Layout

```
/etc/nginx/
├── nginx.conf                # Main config file
├── conf.d/                   # Additional config snippets
├── sites-available/          # Available server block configs (Debian-style)
├── sites-enabled/            # Enabled server blocks (symlinks)
├── modules-available/        # Dynamic modules
├── modules-enabled/          # Enabled dynamic modules
├── snippets/                 # Reusable config fragments
├── mime.types                # MIME type mappings
├── fastcgi.conf              # FastCGI parameters
├── proxy_params              # Default proxy headers
└── sites-enabled/
```

### `nginx.conf` Structure

```nginx
# /etc/nginx/nginx.conf

user www-data;
worker_processes auto;          # One worker per CPU core
pid /run/nginx.pid;

events {
    worker_connections 1024;    # Max connections per worker
    multi_accept on;            # Accept all new connections at once
    use epoll;                  # Linux-specific async I/O
}

http {
    # MIME types
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    # Basic settings
    sendfile on;                # Use sendfile() for zero-copy
    tcp_nopush on;              # Optimize sendfile packet delivery
    tcp_nodelay on;             # Disable Nagle's algorithm
    keepalive_timeout 65;       # Keep-alive timeout
    types_hash_max_size 2048;

    # Logging
    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types text/plain text/css application/json application/javascript text/xml;

    # Include server blocks
    include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/sites-enabled/*;
}
```

### The Three Block Types

```
http {                         # Global HTTP configuration
    server {                   # Virtual host (like Apache VirtualHost)
        listen 80;
        server_name example.com;

        location / {           # URL path matching
            root /var/www/example.com;
            index index.html;
        }

        location /api/ {       # Different location = different handling
            proxy_pass http://backend:3000;
        }
    }
}
```

Nginx inheritance: `http` → `server` → `location`. Directives in inner blocks override outer ones.

---



---

[← Previous](07-section-6-apache-logging.md) | [↑ Index](index.md) | [Next →](09-section-8-nginx-server-blocks.md)
