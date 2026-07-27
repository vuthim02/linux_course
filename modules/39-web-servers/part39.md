# 🐧 Linux System Administrator — Complete Course
## Part 39 of ∞: Web Servers — Apache and Nginx

---

> **Reverse Engineering Approach:** Instead of memorizing config directives, we start from *what a web server actually does* — it receives HTTP requests and returns responses. Every feature (virtual hosts, SSL, reverse proxy, caching) is just a modification of that core loop. Understand the loop, and the config makes sense.

---

## 🎯 What You Will Achieve in Part 39

- Install and configure both Apache and Nginx from scratch
- Host multiple websites on a single server using virtual hosts
- Secure sites with TLS/SSL certificates using Let's Encrypt
- Configure Apache modules — rewrite rules, SSL, proxy, security
- Set up Nginx as a reverse proxy and load balancer
- Tune performance — MPMs, caching, compression
- Understand the architecture differences that matter in production
- Complete **15 real hands-on practices** including a full-stack deployment

---

![Reverse proxy architecture — client requests through proxy to backend servers](https://upload.wikimedia.org/wikipedia/commons/c/c3/Netcat_proxy.svg)

*Reverse proxy pattern used by Nginx and Apache (Sven / Wikimedia Commons / CC-BY-SA-3.0)*

## 🔍 Section 1: Web Server Basics — What Happens When You Visit a Website?

### The Core Loop

Every web server does exactly three things in an infinite loop:

```
1. LISTEN on port 80 (HTTP) or 443 (HTTPS)
2. ACCEPT incoming TCP connection
3. PARSE HTTP request → GENERATE response → SEND response
   │
   └── Repeat for next connection
```

### HTTP/HTTPS

| Protocol | Port | Encryption | Use Case |
|----------|------|------------|----------|
| HTTP | 80 | None | Legacy, redirects to HTTPS |
| HTTPS | 443 | TLS (SSL) | All production traffic |

```
Client → "GET /index.html HTTP/1.1" → Server
Server → "HTTP/1.1 200 OK" + file content → Client
```

### HTTP/2 and HTTP/3

- **HTTP/2** — multiplexes multiple requests over a single TCP connection (solves head-of-line blocking), binary protocol (not text), server push
- **HTTP/3** — uses QUIC (UDP-based) instead of TCP, even faster connection establishment

```
HTTP/1.1:    [──── GET /a ────] [──── GET /b ────]   ← sequential
HTTP/2:      [── GET /a ──][── GET /b ──][── GET /c ──]  ← parallel over one connection
HTTP/3:      UDP-based, no head-of-line blocking even at transport layer
```

### Virtual Hosts

One server, many websites. The server reads the `Host` header from the HTTP request to decide which site to serve.

```
Request: GET / HTTP/1.1
         Host: example.com           ← This header determines the virtual host

Request: GET / HTTP/1.1
         Host: another-site.org      ← Different site, same IP
```

### Reverse Proxy

A server that sits between clients and backend servers. Clients talk to the proxy, which forwards requests to backend apps.

```
Client ──► Nginx (reverse proxy) ──► Backend (Apache, Node.js, Python, etc.)
                                              │
         Client never talks directly ────────┘   to the backend
```

### TLS Termination

The proxy/server handles TLS decryption so backend servers don't have to. This offloads CPU-intensive crypto.

```
Client ── HTTPS ──► Nginx ── HTTP ──► Backend
                     ↑ TLS terminated here
```

### Static vs Dynamic Content

| Type | Examples | How Served |
|------|----------|------------|
| Static | HTML, CSS, JS, images, PDFs | Read file from disk, send as-is |
| Dynamic | PHP pages, API responses, DB queries | Run application (PHP-FPM, uWSGI, etc.), send result |

Apache and Nginx excel at static files. Dynamic content is handed off to application servers (PHP-FPM, Gunicorn, Node.js).

---

## 🔍 Section 2: Apache — Installation and Basics

### Installation

```bash
sudo apt update
sudo apt install apache2 -y

# Verify it's running
sudo systemctl status apache2

# Check the version
apache2 -v
```

### Directory Layout

```
/etc/apache2/
├── apache2.conf              # Main config file
├── ports.conf                # Ports to listen on (80, 443)
├── conf-available/           # Optional config snippets
├── conf-enabled/             # Enabled config snippets (symlinks)
├── mods-available/           # Available modules (.load + .conf files)
├── mods-enabled/             # Enabled modules (symlinks)
├── sites-available/          # Available virtual host configs
└── sites-enabled/            # Enabled virtual hosts (symlinks)
```

### The `a2` Tools

These are symlink managers for sites and modules:

| Command | What It Does |
|---------|--------------|
| `a2ensite site.conf` | Enable a site (create symlink in sites-enabled) |
| `a2dissite site.conf` | Disable a site (remove symlink) |
| `a2enmod module` | Enable a module (create symlink in mods-enabled) |
| `a2dismod module` | Disable a module (remove symlink) |
| `a2enconf config` | Enable a config file |
| `a2disconf config` | Disable a config file |

```bash
# Enable SSL module
sudo a2enmod ssl

# Enable rewrite module
sudo a2enmod rewrite

# Enable a site
sudo a2ensite my-site.conf

# Reload Apache to apply changes
sudo systemctl reload apache2
```

### Default Site

```bash
# The default site config
cat /etc/apache2/sites-available/000-default.conf
```

```apache
<VirtualHost *:80>
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/html
    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
```

The default document root is `/var/www/html/`. Replace the `index.html` there to see your own page.

---

## 🔍 Section 3: Apache Virtual Hosts

### Basic Virtual Host

```apache
# /etc/apache2/sites-available/example.com.conf

<VirtualHost *:80>
    ServerName example.com
    ServerAlias www.example.com
    ServerAdmin admin@example.com
    DocumentRoot /var/www/example.com

    <Directory /var/www/example.com>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog ${APACHE_LOG_DIR}/example.com-error.log
    CustomLog ${APACHE_LOG_DIR}/example.com-access.log combined
</VirtualHost>
```

### `ServerName` and `ServerAlias`

- `ServerName` — the primary domain name Apache matches against the `Host` header
- `ServerAlias` — additional domain names that should resolve to this site

```apache
ServerName example.com
ServerAlias www.example.com shop.example.com
```

### Directory Directives

Inside `<Directory>` blocks you control access and behavior for filesystem paths:

```apache
<Directory /var/www/example.com>
    # Options: Indexes (show dir listing), FollowSymLinks, MultiViews
    Options Indexes FollowSymLinks MultiViews

    # AllowOverride: what .htaccess files can override
    # All = allow everything, None = ignore .htaccess, Limit = limited directives
    AllowOverride All

    # Access control: who can access this directory
    Require all granted          # Everyone
    # Require ip 192.168.1.0/24  # Only local network
    # Require valid-user         # Requires authentication
</Directory>
```

### `.htaccess` Files

`.htaccess` files allow per-directory configuration changes **without editing the main config**. They are checked on every request — Apache walks up the directory tree looking for `.htaccess` files. This is a **performance cost**.

```apache
# To enable .htaccess parsing:
AllowOverride All
```

A typical `.htaccess`:

```apache
# /var/www/example.com/.htaccess

RewriteEngine On
RewriteRule ^old-page$ /new-page [R=301,L]

# Deny access to sensitive files
<FilesMatch "\.(env|config|sql|md)$">
    Require all denied
</FilesMatch>

# Enable caching for static assets
<FilesMatch "\.(css|js|jpg|png)$">
    Header set Cache-Control "max-age=2592000, public"
</FilesMatch>

# Set default charset
AddDefaultCharset UTF-8
```

> **Nginx does not support .htaccess.** This is one of the biggest differences. Nginx evaluates all config at startup — there is no per-request file lookup overhead. Apache's .htaccess is both a feature (easy for users) and a liability (slow under load).

### Name-based vs IP-based Virtual Hosts

| Type | When Used | Config |
|------|-----------|--------|
| Name-based | Single IP, multiple domains (standard) | `<VirtualHost *:80>` |
| IP-based | Multiple IPs, different sites per IP | `<VirtualHost 192.168.1.10:80>` |

The vast majority of setups are name-based.

---

## 🔍 Section 4: Apache Modules

Apache is **modular** — almost every feature is a module you can enable/disable.

### `mod_rewrite` — URL Rewriting

The most commonly used module. It transforms URLs before Apache serves them.

```bash
sudo a2enmod rewrite
```

```apache
RewriteEngine On

# Redirect all HTTP to HTTPS
RewriteCond %{HTTPS} off
RewriteRule ^(.*)$ https://%{HTTP_HOST}/$1 [R=301,L]

# Pretty URLs: /product/123 → /product.php?id=123
RewriteRule ^product/([0-9]+)$ product.php?id=$1 [QSA,L]

# Block hotlinking of images
RewriteCond %{HTTP_REFERER} !^$
RewriteCond %{HTTP_REFERER} !^https://example\.com/.*$ [NC]
RewriteRule \.(jpg|png|gif)$ - [F,L]
```

### `mod_ssl` — TLS/SSL

```bash
sudo a2enmod ssl
```

```apache
<VirtualHost *:443>
    ServerName example.com
    DocumentRoot /var/www/example.com

    SSLEngine on
    SSLCertificateFile      /etc/letsencrypt/live/example.com/fullchain.pem
    SSLCertificateKeyFile   /etc/letsencrypt/live/example.com/privkey.pem

    # Modern TLS config
    SSLProtocol             all -SSLv3 -TLSv1 -TLSv1.1
    SSLCipherSuite          ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256
    SSLHonorCipherOrder     off
    SSLSessionTickets       off
</VirtualHost>
```

### `mod_proxy` — Reverse Proxy

```bash
sudo a2enmod proxy proxy_http proxy_balancer lbmethod_byrequests
```

```apache
<VirtualHost *:80>
    ServerName app.example.com

    ProxyPreserveHost On
    ProxyPass / http://127.0.0.1:8080/
    ProxyPassReverse / http://127.0.0.1:8080/

    # Load balancing across multiple backends
    <Proxy balancer://mycluster>
        BalancerMember http://127.0.0.1:8080
        BalancerMember http://127.0.0.1:8081
        BalancerMember http://127.0.0.1:8082
        ProxySet lbmethod=byrequests
    </Proxy>

    ProxyPass / balancer://mycluster/
    ProxyPassReverse / balancer://mycluster/
</VirtualHost>
```

### `mod_headers` — HTTP Header Manipulation

```bash
sudo a2enmod headers
```

```apache
# Add security headers globally
Header always set X-Content-Type-Options "nosniff"
Header always set X-Frame-Options "DENY"
Header always set X-XSS-Protection "1; mode=block"
Header always set Referrer-Policy "strict-origin-when-cross-origin"

# Enable HSTS (only on HTTPS vhost)
Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
```

### `mod_expires` — Cache Control

```bash
sudo a2enmod expires
```

```apache
ExpiresActive On

# Images: cache for 1 month
ExpiresByType image/jpeg "access plus 1 month"
ExpiresByType image/png "access plus 1 month"
ExpiresByType image/webp "access plus 1 month"
ExpiresByType image/svg+xml "access plus 1 month"

# CSS and JS: cache for 1 year with versioning
ExpiresByType text/css "access plus 1 year"
ExpiresByType application/javascript "access plus 1 year"

# HTML: cache for 10 minutes
ExpiresByType text/html "access plus 10 minutes"
```

### `mod_security` (ModSecurity) — Web Application Firewall

```bash
sudo apt install libapache2-mod-security2 -y
sudo a2enmod security2
```

ModSecurity provides a WAF (Web Application Firewall) with OWASP Core Rule Set (CRS). It inspects every request for SQL injection, XSS, path traversal, etc.

```apache
# /etc/modsecurity/modsecurity.conf
SecRuleEngine On
SecRequestBodyAccess On
SecResponseBodyAccess On
SecResponseBodyMimeType text/plain text/html text/xml
```

### `mod_evasive` — Anti-DoS

```bash
sudo apt install libapache2-mod-evasive -y
sudo a2enmod evasive
```

```apache
# /etc/apache2/mods-available/evasive.conf
<IfModule mod_evasive20.c>
    DOSHashTableSize    3097
    DOSPageCount        5           # Max requests per page per interval
    DOSSiteCount        100         # Max requests per site per interval
    DOSPageInterval     2           # Interval in seconds
    DOSSiteInterval     2
    DOSBlockingPeriod   10          # Seconds to block
</IfModule>
```

---

## 🔍 Section 5: Apache Performance — MPM (Multi-Processing Modules)

Apache has three MPMs that determine how it handles concurrent connections. Choosing the right one is the most important performance decision.

### Prefork MPM (Default for mod_php)

- **Model:** One process per connection
- **Pros:** Stable, thread-safe, each request isolated
- **Cons:** High memory usage per connection, slow under many concurrent connections
- **Use when:** You need mod_php (PHP embedded in Apache) — libphp is not thread-safe

```apache
# /etc/apache2/mods-available/mpm_prefork.conf
<IfModule mpm_prefork_module>
    StartServers             5
    MinSpareServers          5
    MaxSpareServers         10
    MaxRequestWorkers      150
    MaxConnectionsPerChild  3000
</IfModule>
```

### Worker MPM (Threaded, Mixed)

- **Model:** Multiple processes, each with multiple threads. Each thread handles one connection.
- **Pros:** Lower memory than prefork, handles more connections
- **Cons:** Thread-safety issues with non-thread-safe modules
- **Use when:** You need mod_php is not required, you use PHP-FPM instead

```apache
<IfModule mpm_worker_module>
    StartServers             2
    MinSpareThreads         25
    MaxSpareThreads         75
    ThreadLimit             64
    ThreadsPerChild         25
    MaxRequestWorkers      150
    MaxConnectionsPerChild  3000
</IfModule>
```

### Event MPM (Async, Modern)

- **Model:** Dedicated listener threads + worker threads. The listener thread handles keep-alive connections (idle connections) separately.
- **Pros:** Best performance, lowest memory, handles 10K+ concurrent connections
- **Cons:** Requires PHP-FPM (not mod_php)
- **Use when:** Production with PHP-FPM, high-traffic sites

```apache
<IfModule mpm_event_module>
    StartServers             3
    MinSpareThreads         75
    MaxSpareThreads        250
    ThreadLimit             64
    ThreadsPerChild         25
    MaxRequestWorkers      400
    MaxConnectionsPerChild  3000
</IfModule>
```

### MPM Architecture Comparison

```
Prefork:
┌─ Process 1 ──┐  ┌─ Process 2 ──┐  ┌─ Process N ──┐
│ Request A    │  │ Request B    │  │ Request N    │
│ (blocking)   │  │ (blocking)   │  │ (blocking)   │
└──────────────┘  └──────────────┘  └──────────────┘
Memory: O(n) for n concurrent requests

Worker:
┌─ Process 1 ─────────────────┐  ┌─ Process N ─────────────────┐
│ Thread 1 │ Thread 2 │ T...  │  │ Thread 1 │ Thread 2 │ T...  │
│ Req A    │ Req B    │ ...   │  │ Req N    │ ...      │       │
└──────────────────────────────┘  └──────────────────────────────┘
Memory: O(n threads / process) — more efficient

Event:
┌─ Listener Thread ─────┐  ┌─ Worker Thread Pool ────────────┐
│ Accepts connections   │  │ Thread 1 │ Thread 2 │ T...      │
│ Handles keep-alive    │  │ Req A    │ Req B    │ ...       │
│ Passes to workers     │  │ (only while actively processing)│
└────────────────────────┘  └─────────────────────────────────┘
Best for high concurrency, keep-alive doesn't tie up workers
```

### KeepAlive

```apache
KeepAlive On
MaxKeepAliveRequests 100
KeepAliveTimeout 5
```

- `KeepAlive On` — reuse the same TCP connection for multiple requests (critical for HTTP/1.1)
- `MaxKeepAliveRequests` — max requests per connection before closing
- `KeepAliveTimeout` — how long to wait for the next request on an idle keep-alive connection

### `mod_status` — Live Server Metrics

```bash
sudo a2enmod status
```

```apache
# /etc/apache2/mods-available/status.conf
<Location "/server-status">
    SetHandler server-status
    Require local
    # Require ip 192.168.1.0/24  # For remote monitoring
</Location>
```

Visit `http://your-server/server-status` to see:

```
Apache Server Status for localhost (via ::1)
Server Version: Apache/2.4.62 (Ubuntu)
Server MPM: event

Current Time: Wednesday, 24-Jun-2026 12:00:00 UTC
Restart Time: Wednesday, 24-Jun-2026 08:00:00 UTC
Parent Server Config. Generation: 2
Parent Server MPM Generation: 1
Server uptime: 4 hours 0 minutes
Server load: 0.25 0.30 0.20
Total accesses: 15234 - Total Traffic: 234.5 MB
CPU Usage: u.24 s.12 cu0 cs0
Requests/sec: 1.06 - Bytes/sec: 16.7 KB/sec

1 requests currently being processed, 19 idle workers
```

Key fields: `_W_` (waiting/idle), `_S_` (starting), `_R_` (reading request), `_W_` (sending response), `_K_` (keepalive), `_D_` (DNS lookup).

---

## 🔍 Section 6: Apache Logging

### CustomLog and LogFormat

```apache
# /etc/apache2/apache2.conf

LogFormat "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\"" combined
LogFormat "%h %l %u %t \"%r\" %>s %b" common
LogFormat "%{X-Forwarded-For}i %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\"" proxy

CustomLog ${APACHE_LOG_DIR}/access.log combined
ErrorLog ${APACHE_LOG_DIR}/error.log
```

| Format String | Meaning |
|---|---|
| `%h` | Client IP address |
| `%l` | Remote logname (usually `-`) |
| `%u` | Remote user (from auth) |
| `%t` | Time of the request |
| `%r` | Request line (GET /index.html HTTP/1.1) |
| `%>s` | Final status code |
| `%b` | Bytes sent (excludes headers) |
| `%{Header}i` | Value of incoming HTTP header |

### Log Rotation with `logrotate`

```bash
# /etc/logrotate.d/apache2
/var/log/apache2/*.log {
    daily
    missingok
    rotate 14
    compress
    delaycompress
    notifempty
    create 640 root adm
    sharedscripts
    postrotate
        if /etc/init.d/apache2 status > /dev/null ; then
            /etc/init.d/apache2 reload > /dev/null
        fi
    endscript
}
```

What this does:
- Rotates logs daily
- Keeps 14 days of history
- Compresses old logs (gzip)
- Reloads Apache after rotation so it opens new log files
- Without the reload, Apache keeps writing to the old (now renamed) file handle

### Piped Logs

Apache can pipe logs to an external program for processing in real-time:

```apache
CustomLog "|/usr/bin/rotatelogs /var/log/apache2/access.%Y-%m-%d.log 86400" combined
ErrorLog "|/usr/bin/rotatelogs /var/log/apache2/error.%Y-%m-%d.log 86400"
```

### Analyzing Logs

```bash
# Top 10 IPs hitting your server
sudo awk '{print $1}' /var/log/apache2/access.log | sort | uniq -c | sort -rn | head -10

# Top 10 requested pages
sudo awk '{print $7}' /var/log/apache2/access.log | sort | uniq -c | sort -rn | head -10

# HTTP status code distribution
sudo awk '{print $9}' /var/log/apache2/access.log | sort | uniq -c | sort -rn

# Requests per minute
sudo awk '{print $4}' /var/log/apache2/access.log | cut -d: -f1-2 | sort | uniq -c

# Find 404 errors
sudo grep " 404 " /var/log/apache2/access.log | awk '{print $7}' | sort | uniq -c | sort -rn

# Find slow requests (response time > 5 seconds) — requires %D in LogFormat
sudo awk '{if ($NF > 5000000) print $0}' /var/log/apache2/access.log
```

---

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

## 🔍 Section 8: Nginx Server Blocks

### Basic Server Block

```nginx
# /etc/nginx/sites-available/example.com

server {
    listen 80;
    listen [::]:80;                        # IPv6
    server_name example.com www.example.com;

    root /var/www/example.com;
    index index.html index.htm;

    location / {
        try_files $uri $uri/ =404;
    }

    access_log /var/log/nginx/example.com-access.log;
    error_log /var/log/nginx/example.com-error.log;
}
```

### `server_name` Directive

Nginx matches `server_name` against the `Host` header. Multiple names are space-separated.

```nginx
server_name example.com www.example.com *.example.com ~^(www\.)?(?<domain>.+)$;
```

Wildcard: `*.example.com` matches `shop.example.com` but not `example.com`.
Regex: prefix with `~`.

When no server block matches, Nginx uses the **default server** (the first one defined, or the one with `default_server`):

```nginx
listen 80 default_server;
```

### `location` Directive Types

```nginx
location / {                    # Prefix match (matches everything starting with /)
    ...
}

location = /exact {             # Exact match (highest priority)
    ...
}

location ~ \.php$ {             # Regex match (case-sensitive)
    ...
}

location ~* \.(jpg|png)$ {      # Regex match (case-insensitive)
    ...
}

location ^~ /static/ {          # Prefix match, stop regex checking
    ...
}
```

**Nginx location matching order:**
1. `=` exact matches (highest priority)
2. `^~` prefix matches (stop regex search)
3. `~` and `~*` regex matches (in order in config file)
4. Regular prefix matches (longest match wins)

### `try_files`

The most powerful Nginx directive for static file serving:

```nginx
location / {
    try_files $uri $uri/ /index.html;
}
```

This tries:
1. `$uri` — the exact file path (e.g., `/about.html`)
2. `$uri/` — the path as a directory (e.g., `/about/`)
3. `/index.html` — fallback to the index file

This enables SPA (Single Page Application) routing — all paths serve `index.html`:

```nginx
location / {
    try_files $uri $uri/ /index.html;
}
```

### Serving PHP with PHP-FPM

```nginx
server {
    listen 80;
    server_name example.com;
    root /var/www/example.com;
    index index.php index.html;

    location / {
        try_files $uri $uri/ =404;
    }

    location ~ \.php$ {
        fastcgi_pass unix:/run/php/php8.3-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    }
}
```

---

## 🔍 Section 9: Nginx as Reverse Proxy

### Basic Reverse Proxy

```nginx
server {
    listen 80;
    server_name app.example.com;

    location / {
        proxy_pass http://127.0.0.1:3000;          # Backend address
        proxy_set_header Host $host;                # Preserve original Host
        proxy_set_header X-Real-IP $remote_addr;    # Client real IP
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme; # Original protocol (http/https)

        # Timeouts
        proxy_connect_timeout 5s;
        proxy_read_timeout 60s;
        proxy_send_timeout 60s;

        # Buffering
        proxy_buffering on;
        proxy_buffer_size 4k;
        proxy_buffers 8 4k;
    }
}
```

### WebSocket Proxy

```nginx
location /ws/ {
    proxy_pass http://backend:8080;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_set_header Host $host;
    proxy_read_timeout 86400s;   # Long timeout for persistent connections
}
```

### `upstream` Blocks — Load Balancing

```nginx
upstream backend_servers {
    # Load balancing method
    # least_conn;           # Send to server with fewest connections
    # ip_hash;              # Sticky sessions based on client IP
    # hash $request_uri;    # Consistent hashing based on URI

    server 10.0.0.1:8080 weight=3 max_fails=3 fail_timeout=30s;
    server 10.0.0.2:8080 weight=1 max_fails=3 fail_timeout=30s;
    server 10.0.0.3:8080 backup;               # Backup, only used if others fail
    server 10.0.0.4:8080 down;                 # Manually disabled
}

server {
    listen 80;
    server_name app.example.com;

    location / {
        proxy_pass http://backend_servers;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

### Proxy Headers Explained

| Header | Purpose |
|--------|---------|
| `X-Real-IP` | Single client IP address |
| `X-Forwarded-For` | Comma-separated list of IPs in the chain |
| `X-Forwarded-Proto` | Original protocol (http or https) |
| `X-Forwarded-Host` | Original Host header value |

Backend apps need to be configured to trust these headers, otherwise they log Nginx's IP instead of the real client.

---

## 🔍 Section 10: Nginx as Load Balancer

### Load Balancing Methods

| Method | Description | Use Case |
|--------|-------------|----------|
| `round-robin` (default) | Distributes requests evenly across servers | General purpose |
| `least_conn` | Sends to server with fewest active connections | When request processing time varies |
| `ip_hash` | Same client IP always goes to the same server | Session persistence (sticky sessions) |
| `hash` | Custom hash key (URI, query string, etc.) | Cache-friendly routing |
| `random` | Random selection with optional weight | Even distribution |

### Detailed Examples

```nginx
# Round-robin with weights (default)
upstream backend {
    server backend1:8080 weight=3;   # Gets 3x the traffic
    server backend2:8080 weight=1;
    server backend3:8080 weight=1;
}

# least_conn — useful when request times vary widely
upstream backend {
    least_conn;
    server backend1:8080;
    server backend2:8080;
}

# ip_hash — session persistence
upstream backend {
    ip_hash;
    server backend1:8080;
    server backend2:8080;
}

# Custom hash — useful for API caching
upstream backend {
    hash $request_uri consistent;
    server backend1:8080;
    server backend2:8080;
}
```

### Passive Health Checks

Nginx monitors backend health by observing responses. If a server fails, it is temporarily removed from rotation.

```nginx
upstream backend {
    server backend1:8080 max_fails=3 fail_timeout=30s;
    server backend2:8080 max_fails=3 fail_timeout=30s;
}
```

- `max_fails` — number of failed attempts before marking server as down (default: 1)
- `fail_timeout` — time window for max_fails, and time the server stays marked as down (default: 10s)
- A "fail" is a failed connection, timeout, or 5xx response (configurable with `proxy_next_upstream`)

### `proxy_next_upstream`

Controls which conditions cause Nginx to try the next backend server:

```nginx
location / {
    proxy_pass http://backend;
    proxy_next_upstream error timeout invalid_header http_500 http_502 http_503;
    proxy_next_upstream_tries 3;
    proxy_next_upstream_timeout 10s;
}
```

---

## 🔍 Section 11: TLS/SSL — Let's Encrypt and Certbot

### Installation

```bash
sudo apt install certbot python3-certbot-nginx   # For Nginx
sudo apt install certbot python3-certbot-apache  # For Apache
```

### Obtaining a Certificate

```bash
# For Nginx (automatically modifies server blocks)
sudo certbot --nginx -d example.com -d www.example.com

# For Apache
sudo certbot --apache -d example.com -d www.example.com

# Certificate-only mode (no config modification)
sudo certbot certonly --nginx -d example.com

# Standalone mode (stops your web server temporarily)
sudo certbot certonly --standalone -d example.com
```

### Certificate Locations

```
/etc/letsencrypt/live/example.com/
├── cert.pem          # Domain certificate
├── chain.pem         # Intermediate certificate
├── fullchain.pem     # cert.pem + chain.pem (most common to use)
└── privkey.pem       # Private key (keep secret!)
```

### Nginx SSL Configuration

```nginx
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name example.com;

    ssl_certificate     /etc/letsencrypt/live/example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;

    # Modern TLS configuration (Mozilla Intermediate)
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;

    # OCSP Stapling
    ssl_stapling on;
    ssl_stapling_verify on;
    ssl_trusted_certificate /etc/letsencrypt/live/example.com/chain.pem;
    resolver 1.1.1.1 8.8.8.8 valid=300s;
    resolver_timeout 5s;

    # HSTS (HTTP Strict Transport Security)
    add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload" always;

    # Other security headers
    add_header X-Content-Type-Options nosniff always;
    add_header X-Frame-Options SAMEORIGIN always;
    add_header X-XSS-Protection "1; mode=block" always;

    root /var/www/example.com;
    index index.html;
}

# Redirect HTTP to HTTPS
server {
    listen 80;
    listen [::]:80;
    server_name example.com www.example.com;
    return 301 https://$server_name$request_uri;
}
```

### Apache SSL Configuration

```apache
<VirtualHost *:443>
    ServerName example.com
    DocumentRoot /var/www/example.com

    SSLEngine on
    SSLCertificateFile /etc/letsencrypt/live/example.com/fullchain.pem
    SSLCertificateKeyFile /etc/letsencrypt/live/example.com/privkey.pem

    SSLProtocol all -SSLv3 -TLSv1 -TLSv1.1
    SSLCipherSuite ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384
    SSLHonorCipherOrder off

    # OCSP Stapling
    SSLUseStapling on
    SSLStaplingResponderTimeout 5
    SSLStaplingReturnResponderErrors off

    # HSTS
    Header always set Strict-Transport-Security "max-age=63072000; includeSubDomains; preload"
</VirtualHost>
```

### Auto-Renewal

Certbot installs a systemd timer by default:

```bash
sudo systemctl status certbot.timer
sudo certbot renew --dry-run           # Test renewal
```

To manually renew:

```bash
sudo certbot renew
sudo systemctl reload nginx            # Or: sudo systemctl reload apache2
```

### OCSP Stapling

OCSP (Online Certificate Status Protocol) lets the browser check if a certificate is revoked. With **OCSP stapling**, the server fetches the OCSP response and "staples" it to the TLS handshake — the browser doesn't need to contact the CA separately.

- Without stapling: `Browser → CA (OCSP request)` + extra latency
- With stapling: `Server → CA (OCSP request, cached)` → `Browser receives stapled response in handshake` — zero extra latency

### HSTS (HTTP Strict Transport Security)

Tells browsers to **always** use HTTPS for your domain, even if the user types `http://`:

```nginx
add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload" always;
```

- `max-age` — seconds to remember (2 years = 63072000)
- `includeSubDomains` — applies to all subdomains
- `preload` — allows submission to browser preload lists (hardcoded HSTS)

> **Warning:** Once you set HSTS with a long `max-age`, browsers will refuse HTTP connections to your domain for that duration. Test with short values first (e.g., 300 seconds).

---

## 🔍 Section 12: Comparison — Apache vs Nginx

### Architecture

| Aspect | Apache | Nginx |
|--------|--------|-------|
| Model | Process/thread per connection | Event-driven, async, non-blocking |
| Concurrency | MPM prefork/worker/event | Single-threaded event loop per worker |
| Static files | Good | Excellent (sendfile, zero-copy) |
| Dynamic content | mod_php (embedded) | PHP-FPM (external process) |
| Memory per connection | High (especially prefork) | Very low (tiny fixed overhead) |
| Max concurrent connections | 1K-10K (event MPM) | 10K-100K+ |

### Configuration Philosophy

| Apache | Nginx |
|--------|-------|
| Per-directory config via `.htaccess` | No `.htaccess` — all config in main files |
| Config evaluated at request time (for .htaccess) | Config compiled at startup, fully static |
| `<Directory>`, `<Files>`, `<Location>` blocks | `location` blocks only |
| Modules loaded dynamically at runtime | Modules compiled or loaded at startup |
| Easy for shared hosting (users edit .htaccess) | Better performance, harder for shared hosting |

### Module Ecosystem

| Feature | Apache | Nginx |
|---------|--------|-------|
| URL rewriting | `mod_rewrite` | Built-in `rewrite` directive |
| SSL/TLS | `mod_ssl` | Built-in (ngx_http_ssl_module) |
| Reverse proxy | `mod_proxy` | Built-in (ngx_http_proxy_module) |
| Load balancing | `mod_proxy_balancer` | Built-in upstream module |
| Caching | `mod_cache` | `proxy_cache`, `fastcgi_cache` |
| WebSocket | Third-party | Built-in (upgrade header) |
| HTTP/2 | `mod_http2` | Built-in (since nginx 1.9.5) |
| HTTP/3 | mod_http3 (experimental) | Built-in (nginx-plus, or compile from source) |
| WAF | ModSecurity | ModSecurity (nginx-compatible version) |

### Performance Characteristics

```
Apache prefork:   O(n) memory for n connections
Apache event:     O(log n) memory, good for 5K-10K concurrent
Nginx event:      O(1) memory per connection, handles 10K-100K+
                  Only uses RAM when actively processing, not for idle keep-alive
```

### When to Use Which

| Scenario | Best Choice |
|----------|-------------|
| Shared hosting (users need .htaccess) | Apache |
| High-traffic static file serving | Nginx |
| PHP app (WordPress, Laravel) | Nginx + PHP-FPM (or Apache if you prefer) |
| Reverse proxy / load balancer | Nginx (designed for this) |
| Simple single-site server | Either |
| Embedded mod_php required | Apache prefork |
| Microservices API gateway | Nginx |
| Need both .htaccess and high performance | Nginx reverse proxy → Apache backend |

---

## 🔍 Section 13: Static File Serving — Optimization

### sendfile (Zero-Copy)

The `sendfile()` system call copies data directly from disk to network socket **without going through userspace**. This means:

- No copying from kernel → userspace → kernel (2 copies → 0 copies)
- CPU is free to do other work
- Dramatically faster for large static files

```
Without sendfile:
Disk → Kernel buffer → Userspace buffer → Kernel socket buffer → Network
         copy #1          copy #2          copy #3       

With sendfile:
Disk → Kernel buffer → Network (directly DMA)
         zero copies through userspace
```

```nginx
sendfile on;      # Nginx
```

```apache
EnableSendfile on;   # Apache
```

### Direct I/O

For very large files, bypass the page cache entirely to avoid cache pollution:

```nginx
location /videos/ {
    directio 4m;          # Use direct I/O for files > 4MB
    sendfile on;
}
```

### Expires Headers — Cache Control

```nginx
location ~* \.(jpg|jpeg|png|gif|webp|ico)$ {
    expires 30d;
    add_header Cache-Control "public, immutable";
}

location ~* \.(css|js)$ {
    expires 1y;
    add_header Cache-Control "public, immutable";
}

location ~* \.(html|htm)$ {
    expires 10m;
}
```

### Gzip Compression

```nginx
gzip on;
gzip_vary on;
gzip_proxied any;
gzip_comp_level 6;                  # 1-9 (1=fast, 9=max compression)
gzip_min_length 256;                # Don't compress tiny files
gzip_disable "msie6";
gzip_types
    text/plain
    text/css
    text/javascript
    application/javascript
    application/json
    application/xml
    application/rss+xml
    image/svg+xml;
```

For Apache:

```apache
AddOutputFilterByType DEFLATE text/html text/plain text/css application/javascript
```

### Brotli Compression (Better than Gzip)

Brotli typically achieves 20-30% better compression than gzip.

```bash
# Install brotli module for nginx
sudo apt install nginx-extras
```

```nginx
brotli on;
brotli_comp_level 6;
brotli_types text/plain text/css application/javascript application/json image/svg+xml;
```

### Caching Headers Explained

| Header | Meaning | Value |
|--------|---------|-------|
| `Cache-Control: public` | Any cache (CDN, browser) may cache | Public content |
| `Cache-Control: private` | Only browser may cache (not CDN) | User-specific content |
| `Cache-Control: no-cache` | Must revalidate with server | Dynamic content |
| `Cache-Control: no-store` | Never cache | Sensitive data |
| `Cache-Control: immutable` | Never revalidate within max-age | Versioned assets |
| `Expires: ...` | HTTP/1.0 fallback for Cache-Control | Date in future |
| `ETag: "abc123"` | Content hash for conditional requests | Hash value |
| `Last-Modified: ...` | Date-based revalidation | Date |

---

## 💻 PRACTICE SECTION — 15 Hands-On Exercises

---

### ✅ Practice 1: Install and Configure Apache

```bash
# Install Apache
sudo apt update
sudo apt install apache2 -y

# Verify it's running
sudo systemctl status apache2

# Check what ports it's listening on
sudo ss -tlnp | grep 80

# Create a custom index page
echo "<h1>Apache is working!</h1>" | sudo tee /var/www/html/index.html

# Test with curl
curl -I http://localhost
curl http://localhost
```

---

### ✅ Practice 2: Create Apache Virtual Hosts

Create two virtual hosts on the same server:

```bash
# Create directories
sudo mkdir -p /var/www/site1.com
sudo mkdir -p /var/www/site2.org

# Create index pages
echo "<h1>Site 1 - example.com</h1>" | sudo tee /var/www/site1.com/index.html
echo "<h1>Site 2 - another.org</h1>" | sudo tee /var/www/site2.org/index.html
```

Create `/etc/apache2/sites-available/site1.com.conf`:

```apache
<VirtualHost *:80>
    ServerName site1.com
    ServerAlias www.site1.com
    DocumentRoot /var/www/site1.com

    <Directory /var/www/site1.com>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog ${APACHE_LOG_DIR}/site1-error.log
    CustomLog ${APACHE_LOG_DIR}/site1-access.log combined
</VirtualHost>
```

Create `/etc/apache2/sites-available/site2.org.conf` similarly.

```bash
# Enable both sites
sudo a2ensite site1.com.conf
sudo a2ensite site2.org.conf

# Disable default site
sudo a2dissite 000-default.conf

# Reload Apache
sudo systemctl reload apache2

# Test (add entries to /etc/hosts for testing)
echo "127.0.0.1 site1.com www.site1.com site2.org" | sudo tee -a /etc/hosts

curl -H "Host: site1.com" http://localhost
curl -H "Host: site2.org" http://localhost
```

---

### ✅ Practice 3: Enable SSL with Certbot

```bash
# Install Certbot with Apache plugin
sudo apt install certbot python3-certbot-apache -y

# Obtain certificate (requires a real domain pointing to your server)
sudo certbot --apache -d example.com -d www.example.com

# Test auto-renewal
sudo certbot renew --dry-run

# Verify SSL configuration
curl -I https://example.com
```

If you don't have a real domain, create a self-signed certificate for testing:

```bash
sudo mkdir -p /etc/ssl/local
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/ssl/local/selfsigned.key \
    -out /etc/ssl/local/selfsigned.crt \
    -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost"

# Enable SSL module
sudo a2enmod ssl
sudo systemctl reload apache2
```

Create a self-signed SSL vhost:

```apache
<VirtualHost *:443>
    ServerName localhost
    DocumentRoot /var/www/html

    SSLEngine on
    SSLCertificateFile /etc/ssl/local/selfsigned.crt
    SSLCertificateKeyFile /etc/ssl/local/selfsigned.key
</VirtualHost>
```

---

### ✅ Practice 4: Configure mod_rewrite Rules

```bash
sudo a2enmod rewrite
sudo systemctl reload apache2
```

Add to `/var/www/site1.com/.htaccess`:

```apache
RewriteEngine On

# Force HTTPS
RewriteCond %{HTTPS} off
RewriteRule ^(.*)$ https://%{HTTP_HOST}/$1 [R=301,L]

# Pretty URLs: /user/john → /profile.php?username=john
RewriteRule ^user/([a-zA-Z0-9_-]+)$ profile.php?username=$1 [L]

# Block access to hidden files (starting with .)
RewriteRule (^|/)\. - [F]

# Redirect old URLs to new
RewriteRule ^old-article\.html$ /new-article [R=301,L]
```

Test with curl:

```bash
curl -I http://site1.com/old-article.html  # Should see 301 redirect
curl -I http://site1.com/.git/config        # Should see 403 Forbidden
```

---

### ✅ Practice 5: Install and Configure Nginx

```bash
# Stop Apache first (they both can't use port 80 simultaneously)
sudo systemctl stop apache2
sudo systemctl disable apache2

# Install Nginx
sudo apt install nginx -y
sudo systemctl enable --now nginx

# Verify
sudo ss -tlnp | grep 80
curl http://localhost
```

---

### ✅ Practice 6: Create Nginx Server Blocks

```bash
# Create directories
sudo mkdir -p /var/www/app1.example
sudo mkdir -p /var/www/app2.example

# Create index pages
echo "<h1>App 1</h1>" | sudo tee /var/www/app1.example/index.html
echo "<h1>App 2</h1>" | sudo tee /var/www/app2.example/index.html
```

Create `/etc/nginx/sites-available/app1.example`:

```nginx
server {
    listen 80;
    server_name app1.example;

    root /var/www/app1.example;
    index index.html;

    location / {
        try_files $uri $uri/ =404;
    }

    access_log /var/log/nginx/app1-access.log;
    error_log /var/log/nginx/app1-error.log;
}
```

Create `/etc/nginx/sites-available/app2.example` similarly.

```bash
# Enable sites
sudo ln -s /etc/nginx/sites-available/app1.example /etc/nginx/sites-enabled/
sudo ln -s /etc/nginx/sites-available/app2.example /etc/nginx/sites-enabled/

# Remove default
sudo rm /etc/nginx/sites-enabled/default

# Test config and reload
sudo nginx -t
sudo systemctl reload nginx

# Test
echo "127.0.0.1 app1.example app2.example" | sudo tee -a /etc/hosts
curl -H "Host: app1.example" http://localhost
curl -H "Host: app2.example" http://localhost
```

---

### ✅ Practice 7: Configure Nginx Reverse Proxy for a Backend App

Start a simple test backend (using Python):

```bash
# Simple Python HTTP server as a "backend" on port 3000
mkdir -p ~/backend && cd ~/backend
cat > app.py << 'EOF'
from http.server import HTTPServer, BaseHTTPRequestHandler

class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header('Content-Type', 'text/plain')
        self.end_headers()
        self.wfile.write(f'Backend response for {self.path}\n'.encode())

HTTPServer(('127.0.0.1', 3000), Handler).serve_forever()
EOF

python3 app.py &
```

Create `/etc/nginx/sites-available/proxy-test`:

```nginx
server {
    listen 80;
    server_name proxy.example;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }

    location /status {
        return 200 "Nginx reverse proxy is running\n";
    }
}
```

```bash
sudo ln -s /etc/nginx/sites-available/proxy-test /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx

echo "127.0.0.1 proxy.example" | sudo tee -a /etc/hosts
curl -H "Host: proxy.example" http://localhost/hello
```

Expected: `Backend response for /hello`

---

### ✅ Practice 8: Load Balancing with upstream

Stop the first backend, start three:

```bash
pkill -f "python3 app.py" || true

# Start 3 backend instances on different ports
for port in 3001 3002 3003; do
    mkdir -p ~/backend-$port
    cat > ~/backend-$port/app.py << EOF
from http.server import HTTPServer, BaseHTTPRequestHandler
class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header('Content-Type', 'text/plain')
        self.end_headers()
        self.wfile.write(b'Backend on port $port\n')
HTTPServer(('127.0.0.1', $port), Handler).serve_forever()
EOF
    python3 ~/backend-$port/app.py &
done
```

Create `/etc/nginx/sites-available/loadbalance`:

```nginx
upstream backend_pool {
    least_conn;
    server 127.0.0.1:3001 max_fails=3 fail_timeout=10s;
    server 127.0.0.1:3002 max_fails=3 fail_timeout=10s;
    server 127.0.0.1:3003 max_fails=3 fail_timeout=10s;
}

server {
    listen 80;
    server_name lb.example;

    location / {
        proxy_pass http://backend_pool;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

```bash
sudo ln -s /etc/nginx/sites-available/loadbalance /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx
echo "127.0.0.1 lb.example" | sudo tee -a /etc/hosts

# Send multiple requests to see load balancing
for i in $(seq 1 6); do curl -s http://lb.example; done
```

You should see requests distributed across the three backends.

---

### ✅ Practice 9: Configure Gzip/Brotli Compression

```bash
# Enable gzip in nginx.conf
sudo nano /etc/nginx/nginx.conf
```

Edit the `http` block:

```nginx
gzip on;
gzip_vary on;
gzip_proxied any;
gzip_comp_level 6;
gzip_min_length 256;
gzip_types text/plain text/css application/json application/javascript text/xml application/xml image/svg+xml;
```

```bash
sudo nginx -t && sudo systemctl reload nginx

# Test gzip
curl -H "Accept-Encoding: gzip" -I http://localhost

# Check Content-Encoding header in response
```

For Apache:

```bash
sudo a2enmod deflate
sudo systemctl reload apache2
```

```apache
# /etc/apache2/mods-available/deflate.conf
AddOutputFilterByType DEFLATE text/html text/plain text/css application/javascript application/json
```

---

### ✅ Practice 10: Apache MPM Tuning

```bash
# Check which MPM is active
sudo apache2ctl -M | grep mpm

# Switch to event MPM (preferred for production)
sudo a2dismod mpm_prefork
sudo a2enmod mpm_event
sudo systemctl restart apache2

# Verify
sudo apache2ctl -M | grep mpm

# Tune event MPM
sudo nano /etc/apache2/mods-available/mpm_event.conf
```

```apache
<IfModule mpm_event_module>
    StartServers             3
    MinSpareThreads         75
    MaxSpareThreads        250
    ThreadLimit             64
    ThreadsPerChild         25
    MaxRequestWorkers      400
    MaxConnectionsPerChild  3000
</IfModule>
```

```bash
sudo systemctl restart apache2

# Monitor performance
curl http://localhost/server-status

# Stress test (install apache2-utils first)
sudo apt install apache2-utils -y
ab -n 10000 -c 100 http://localhost/
```

---

### ✅ Practice 11: Log Analysis

```bash
# Generate some traffic
for i in $(seq 1 100); do curl -s http://localhost > /dev/null; done

# Analyze Apache/Nginx logs
# Top 10 IPs
awk '{print $1}' /var/log/nginx/access.log | sort | uniq -c | sort -rn | head -10

# Top requested URLs
awk '{print $7}' /var/log/nginx/access.log | sort | uniq -c | sort -rn | head -10

# Status code counts
awk '{print $9}' /var/log/nginx/access.log | sort | uniq -c | sort -rn

# Find errors
grep " 404 " /var/log/nginx/access.log

# Watch logs in real-time
sudo tail -f /var/log/nginx/access.log

# Set up log rotation if not already configured
cat /etc/logrotate.d/nginx
```

Configure custom log format:

```nginx
# In nginx.conf http block
log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                '$status $body_bytes_sent "$http_referer" '
                '"$http_user_agent" $request_time';

access_log /var/log/nginx/access.log main;
```

---

### ✅ Practice 12: Set Up PHP-FPM with Nginx

```bash
sudo apt install php-fpm php-mysql php-curl php-gd php-mbstring php-xml -y

# Check PHP-FPM socket
ls /run/php/php*.sock
```

Create `/etc/nginx/sites-available/php-app`:

```nginx
server {
    listen 80;
    server_name php.example;
    root /var/www/php-app;
    index index.php index.html;

    location / {
        try_files $uri $uri/ =404;
    }

    location ~ \.php$ {
        include fastcgi_params;
        fastcgi_pass unix:/run/php/php8.3-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    }

    # Deny access to hidden files
    location ~ /\. {
        deny all;
    }

    # Cache static files
    location ~* \.(jpg|jpeg|png|gif|ico|css|js)$ {
        expires 30d;
        add_header Cache-Control "public, immutable";
    }
}
```

```bash
# Create PHP test file
sudo mkdir -p /var/www/php-app
echo "<?php phpinfo(); ?>" | sudo tee /var/www/php-app/index.php

sudo ln -s /etc/nginx/sites-available/php-app /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx

echo "127.0.0.1 php.example" | sudo tee -a /etc/hosts
curl http://php.example
```

---

### ✅ Practice 13: Nginx Caching (FastCGI Cache)

```bash
sudo mkdir -p /var/cache/nginx
```

Add to `nginx.conf` `http` block:

```nginx
fastcgi_cache_path /var/cache/nginx levels=1:2 keys_zone=PHP_CACHE:10m inactive=60m;
fastcgi_cache_key "$scheme$request_method$host$request_uri";
```

Add to the PHP server block from Practice 12:

```nginx
location ~ \.php$ {
    include fastcgi_params;
    fastcgi_pass unix:/run/php/php8.3-fpm.sock;
    fastcgi_index index.php;
    fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;

    # Caching
    fastcgi_cache PHP_CACHE;
    fastcgi_cache_valid 200 1m;       # Cache 200 responses for 1 minute
    fastcgi_cache_valid 404 1m;
    fastcgi_cache_use_stale error timeout updating;
    fastcgi_cache_bypass $no_cache;
    fastcgi_no_cache $no_cache;

    # Add header to show cache status
    add_header X-Cache $upstream_cache_status;
}
```

```bash
sudo nginx -t && sudo systemctl reload nginx

# First request (MISS)
curl -I http://php.example/ | grep X-Cache

# Second request (HIT if not bypassed)
curl -I http://php.example/ | grep X-Cache
```

---

### ✅ Practice 14: Security Hardening

```bash
# Apache security headers
sudo a2enmod headers
```

Add to Apache vhost:

```apache
Header always set X-Content-Type-Options "nosniff"
Header always set X-Frame-Options "DENY"
Header always set X-XSS-Protection "1; mode=block"
Header always set Referrer-Policy "strict-origin-when-cross-origin"
Header always set Permissions-Policy "geolocation=(), microphone=(), camera=()"
```

For Nginx, add to server block:

```nginx
add_header X-Content-Type-Options nosniff always;
add_header X-Frame-Options DENY always;
add_header X-XSS-Protection "1; mode=block" always;
add_header Referrer-Policy "strict-origin-when-cross-origin" always;
add_header Permissions-Policy "geolocation=(), microphone=(), camera=()" always;
```

```bash
# Hide server version
echo "ServerTokens Prod" | sudo tee -a /etc/apache2/conf-available/security.conf
echo "ServerSignature Off" | sudo tee -a /etc/apache2/conf-available/security.conf
sudo a2enconf security

# Nginx: hide version
sudo sed -i 's/# server_tokens off;/server_tokens off;/' /etc/nginx/nginx.conf

# Restart both
sudo systemctl restart apache2
sudo systemctl restart nginx

# Test
curl -I http://localhost | grep Server
```

---

### ✅ Practice 15: Real-World Integration — Nginx → Apache Backend

Deploy a full stack with Nginx as reverse proxy, Apache as backend:

```bash
# Stop nginx and start apache on port 8080
sudo systemctl stop nginx
sudo systemctl start apache2
```

Edit `/etc/apache2/ports.conf`:

```apache
Listen 8080
```

Edit Apache default site to listen on 8080:

```apache
<VirtualHost *:8080>
    DocumentRoot /var/www/html
    ...
</VirtualHost>
```

```bash
sudo systemctl restart apache2

# Verify Apache is on 8080
sudo ss -tlnp | grep 8080

# Start Nginx on port 80
sudo systemctl start nginx
```

Create `/etc/nginx/sites-available/full-stack`:

```nginx
upstream apache_backend {
    server 127.0.0.1:8080 max_fails=3 fail_timeout=10s;
}

server {
    listen 80;
    server_name fullstack.example;

    # Static files served directly by Nginx (fast)
    root /var/www/html;
    index index.html index.php;

    location / {
        try_files $uri $uri/ @backend;
    }

    # Static assets with caching
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|woff2|svg)$ {
        expires 30d;
        add_header Cache-Control "public, immutable";
        access_log off;
    }

    # Everything else goes to Apache
    location @backend {
        proxy_pass http://apache_backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # Buffering
        proxy_buffering on;
        proxy_buffer_size 4k;
        proxy_buffers 8 4k;

        # Timeouts
        proxy_connect_timeout 5s;
        proxy_read_timeout 30s;
    }

    # Security headers
    add_header X-Content-Type-Options nosniff always;
    add_header X-Frame-Options DENY always;
    add_header X-XSS-Protection "1; mode=block" always;

    access_log /var/log/nginx/fullstack-access.log;
    error_log /var/log/nginx/fullstack-error.log;
}
```

```bash
sudo ln -s /etc/nginx/sites-available/full-stack /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t && sudo systemctl reload nginx

echo "127.0.0.1 fullstack.example" | sudo tee -a /etc/hosts

# Test
curl -I http://fullstack.example
```

What's happening:

```
Client ── HTTP:80 ──► Nginx ── proxy_pass ──► Apache:8080
                         │                          │
                         │ Static files:             │ PHP, dynamic
                         │ served directly           │ content,
                         │ (fast, no Apache          │ .htaccess
                         │ overhead)                 │ processing
```

This architecture gives you the best of both: Nginx's fast static serving and connection handling, with Apache's .htaccess and mod_php compatibility for dynamic content.

---

## 🧠 Deep Understanding

### Apache MPM Architectures

#### Prefork (Process per Request)

```
Connection arrives
    ↓
Parent process accepts connection
    ↓
Child process spawned (or reused from pool)
    ↓
Child handles entire request lifecycle
    ↓   (read request → process → send response)
Child returns to idle pool
```

**Why prefork exists:** The original Apache model. Each process has its own memory space, so a crash in one request doesn't affect others. Crucially, `mod_php` (libphp) is **not thread-safe** — it cannot run in a threaded MPM. Prefork is the only choice when using `mod_php`.

**Memory cost:** Each child process loads the full PHP interpreter, even when serving a static file. For 200 concurrent connections with prefork, you might use 200 × ~20MB = 4GB just for Apache children.

#### Worker (Threaded within Processes)

```
Connection arrives
    ↓
Process with available thread handles it
    ↓
Thread executes: read → process → send
    ↓
Thread returns to thread pool
```

**Why worker exists:** Reduces memory overhead by sharing memory across threads within a process. But threads share the same address space — a crash in one thread kills all threads in that process.

**Limitation:** Thread-safety issues. `mod_php` cannot be used. PHP-FPM (external FastCGI process manager) is required.

#### Event (Async-Ready)

```
Connection arrives
    ↓
Listener thread accepts, categorizes:
    ├── Idle keep-alive → handled by listener (no worker thread tied up)
    └── Active request  → passed to a worker thread
                            ↓
                         Worker processes, returns to pool
```

**The key insight:** With HTTP keep-alive, a connection can stay open for seconds or minutes while the client sends no data. In prefork/worker, that connection **holds a process/thread hostage** doing nothing. The event MPM's listener thread handles all idle connections, and only passes active requests to workers.

**Scaling:** Event MPM can handle 10,000+ concurrent connections with modest memory because only actively-processing requests occupy threads.

### Nginx Event Loop

Nginx uses a completely different architecture: **single-threaded event loop** per worker process.

```
Nginx Worker Process:
┌──────────────────────────────────────────────────┐
│   while (1) {                                    │
│       events = epoll_wait()  ← Block until I/O   │
│       for each event:                            │
│           if new connection:                     │
│               accept() → add to epoll            │
│           if readable:                           │
│               read request → process → queue response│
│           if writable:                           │
│               send response data                 │
│   }                                              │
└──────────────────────────────────────────────────┘
```

This is the **reactor pattern**:
1. Register file descriptors (connections) with epoll
2. Call `epoll_wait()` — kernel tells you which fds are ready
3. Process only ready fds
4. Repeat

**Why this is fast:**
- No thread/process per connection overhead
- No context switching between threads
- No memory wasted on idle connections
- A single worker can handle 10,000+ connections because most connections are idle (waiting for client data) and cost almost nothing
- Only CPU cache working set of one thread matters (no cache thrashing from multiple threads)

### Linux I/O Multiplexing: epoll vs select vs poll

| Mechanism | Complexity | Scaling | Key Limitation |
|-----------|-----------|---------|----------------|
| `select()` | O(n) | Poor | Max 1024 fds, scans all fds every call |
| `poll()` | O(n) | Poor | Scans all fds every call |
| `epoll` | O(1) | Excellent | Linux-only, returns only ready fds |

**How epoll works:**

```c
// 1. Create epoll instance
int epfd = epoll_create1(0);

// 2. Add file descriptors to monitor
struct epoll_event ev;
ev.events = EPOLLIN | EPOLLET;  // Edge-triggered
ev.data.fd = client_socket;
epoll_ctl(epfd, EPOLL_CTL_ADD, client_socket, &ev);

// 3. Wait for events (efficient!)
struct epoll_event events[1024];
int n = epoll_wait(epfd, events, 1024, -1);

// 4. Process only ready fds
for (int i = 0; i < n; i++) {
    handle_event(events[i].data.fd);
}
```

With `select()`, the kernel scans all 10,000 fds to find the 3 that are ready. With `epoll`, the kernel returns only the 3 ready ones. This is O(1) vs O(n) — the difference between handling 10 connections and 100,000 connections.

Nginx uses **edge-triggered epoll** (`EPOLLET`) — it gets notified only when new data arrives, not repeatedly for existing data.

### PHP-FPM Integration

PHP-FPM (FastCGI Process Manager) is a separate process manager for PHP that runs **outside** the web server.

```
Apache (event MPM)          Nginx (event loop)
       │                           │
       │  FastCGI protocol          │  FastCGI protocol
       ▼                           ▼
┌──────────────── PHP-FPM ──────────────────┐
│  Master process                            │
│  ├── Pool: www                             │
│  │   ├── child 1 (PHP process, idle)       │
│  │   ├── child 2 (PHP process, busy)       │
│  │   ├── child 3 (PHP process, busy)       │
│  │   └── ... (pm.max_children)             │
│  ├── Pool: admin                           │
│  │   └── ...                               │
│  └── Pool: custom pools                    │
└────────────────────────────────────────────┘
```

**How a PHP request flows:**

```
1. Nginx receives HTTP request
2. Nginx matches location ~ \.php$
3. Nginx sends FastCGI request to PHP-FPM socket
4. PHP-FPM master picks an idle child process
5. PHP child sets SCRIPT_FILENAME, runs the PHP file
6. PHP child returns response via FastCGI to Nginx
7. Nginx sends HTTP response to client
8. PHP child returns to idle pool
```

**PHP-FPM pool configuration** (`/etc/php/8.3/fpm/pool.d/www.conf`):

```ini
[www]
pm = dynamic                        # dynamic, static, ondemand
pm.max_children = 50                # Max PHP processes
pm.start_servers = 5                # Number to start
pm.min_spare_servers = 5            # Keep at least this many idle
pm.max_spare_servers = 35           # Keep at most this many idle
pm.max_requests = 500               # Restart after N requests (memory leak protection)

; Listen on Unix socket (faster) or TCP
listen = /run/php/php8.3-fpm.sock
; listen = 127.0.0.1:9000
```

**pm = dynamic** (most common): FPM adjusts children based on demand.
**pm = static**: Fixed number of children always running.
**pm = ondemand**: Spawn children only when needed, kill idle ones (memory saving).

### sendfile and Zero-Copy

Normal file serving without sendfile:

```
Userspace (nginx)                 Kernel
┌─────────────┐            ┌──────────────┐
│ read()      │ ◄───────  │ Disk → Page  │ ← Copy 1: disk to kernel buffer
│ buffer      │            │ Cache        │
│             │            │              │
│ write()     │ ────────► │ Socket       │ ← Copy 2: kernel buffer to socket
└─────────────┘            └──────────────┘
```

Data goes: `Disk → Kernel buffer → Userspace buffer → Kernel socket buffer → Network`

Two copies through memory, one through userspace that the CPU must handle.

With `sendfile()`:

```
Userspace (nginx)                 Kernel
┌─────────────┐            ┌──────────────┐
│ sendfile()  │ ────────► │ Disk → Socket │ ← Zero copies through userspace
│ (tells      │            │ (DMA transfer)│    Data goes directly from
│  kernel to  │            │               │    disk page cache to NIC
│  send file) │            │               │
└─────────────┘            └──────────────┘
```

Data goes: `Disk Page Cache → NIC (via DMA)` — CPU never touches the data.

**What about the page cache?** The file is first read from disk into the kernel's page cache (if not already there). But this happens via DMA (Direct Memory Access) — the disk controller writes data to RAM directly without CPU involvement. Then `sendfile()` sends that cached data to the network, again via DMA if possible.

For large files, `sendfile()` with `directio` can bypass the page cache entirely to avoid evicting hot cache entries.

### Apache mod_php vs PHP-FPM

| Aspect | mod_php (prefork) | PHP-FPM |
|--------|-------------------|---------|
| Architecture | PHP interpreter embedded in Apache child | Separate PHP process pool |
| Memory | Each Apache child loads PHP (20-40MB each) | PHP processes shared via pool |
| Concurrency | One process per request (prefork only) | Reusable PHP pool, handles many requests |
| File permissions | Runs as www-data (Apache user) | Can run as different user per pool |
| Configuration | PHP config in apache (`php_flag`, `php_value`) | Separate php.ini per pool |
| Performance | Slower, higher memory | Faster, lower memory, scalable |
| Compatibility | Widest (all PHP apps work) | Nearly all PHP apps work |

---

## 📋 Command Reference

### Apache Commands

| Command | Purpose |
|---------|---------|
| `sudo systemctl status apache2` | Check if Apache is running |
| `sudo systemctl start/stop/restart apache2` | Control Apache service |
| `sudo systemctl reload apache2` | Reload config without dropping connections |
| `apache2 -v` | Show version |
| `apache2ctl -M` | List loaded modules |
| `apache2ctl -S` | Show virtual host configuration |
| `apache2ctl configtest` | Test config syntax (`-t`) |
| `sudo a2ensite site.conf` | Enable a site |
| `sudo a2dissite site.conf` | Disable a site |
| `sudo a2enmod module` | Enable a module |
| `sudo a2dismod module` | Disable a module |
| `sudo a2enconf conf` | Enable a config snippet |
| `sudo a2disconf conf` | Disable a config snippet |
| `sudo tail -f /var/log/apache2/access.log` | Watch access log in real-time |
| `sudo tail -f /var/log/apache2/error.log` | Watch error log in real-time |
| `ab -n 1000 -c 50 http://localhost/` | Benchmark (apache2-utils) |
| `htpasswd -c /etc/apache2/.htpasswd user` | Create htpasswd file |

### Apache Config Directives

| Directive | Purpose |
|-----------|---------|
| `<VirtualHost *:80>` | Define a virtual host |
| `ServerName example.com` | Primary domain name |
| `ServerAlias www.example.com` | Additional domain names |
| `DocumentRoot /var/www/html` | Root directory for files |
| `<Directory /path>...</Directory>` | Directory-level configuration |
| `AllowOverride All/None` | Enable/disable .htaccess |
| `Options Indexes FollowSymLinks` | Directory options |
| `Require all granted/denied` | Access control |
| `ErrorLog /path/to/log` | Error log location |
| `CustomLog /path/to/log format` | Access log location and format |
| `LogFormat "format" name` | Define log format |
| `SSLEngine on` | Enable TLS |
| `SSLCertificateFile /path` | TLS certificate |
| `SSLCertificateKeyFile /path` | TLS private key |
| `ProxyPass / http://backend/` | Reverse proxy |
| `ProxyPassReverse / http://backend/` | Rewrite redirect headers |
| `RewriteRule pattern target [flags]` | URL rewriting |
| `RewriteCond test pattern` | Rewrite condition |
| `Header set name value` | Set HTTP response header |
| `ExpiresActive On` | Enable expiration caching |
| `ExpiresByType type time` | Set cache duration by MIME type |
| `AddOutputFilterByType DEFLATE type` | Enable compression |
| `KeepAlive On/Off` | Enable persistent connections |
| `MaxRequestWorkers number` | Max concurrent requests |

### Nginx Commands

| Command | Purpose |
|---------|---------|
| `sudo systemctl status nginx` | Check if Nginx is running |
| `sudo systemctl start/stop/restart nginx` | Control Nginx service |
| `sudo systemctl reload nginx` | Reload config without dropping connections |
| `nginx -v` | Show version |
| `nginx -V` | Show version + compile flags |
| `nginx -t` | Test config syntax |
| `nginx -T` | Test and print full config |
| `sudo tail -f /var/log/nginx/access.log` | Watch access log |
| `sudo tail -f /var/log/nginx/error.log` | Watch error log |
| `sudo ln -s /etc/nginx/sites-available/X /etc/nginx/sites-enabled/` | Enable a site |
| `sudo rm /etc/nginx/sites-enabled/X` | Disable a site |

### Nginx Config Directives

| Directive | Purpose |
|-----------|---------|
| `server { ... }` | Define a server block (virtual host) |
| `listen 80;` | Port to listen on |
| `server_name example.com;` | Domain name matching |
| `root /var/www/html;` | Document root |
| `index index.html index.php;` | Default index files |
| `location / { ... }` | URL path matching block |
| `try_files $uri $uri/ =404;` | Try paths in order |
| `proxy_pass http://backend;` | Reverse proxy target |
| `proxy_set_header Header value;` | Set proxy request headers |
| `upstream name { ... }` | Define backend server group |
| `server address weight=N;` | Backend server in upstream |
| `fastcgi_pass unix:/path.sock;` | Pass to PHP-FPM |
| `fastcgi_param NAME value;` | FastCGI parameter |
| `sendfile on/off;` | Enable zero-copy file serving |
| `gzip on/off;` | Enable compression |
| `gzip_types text/plain ...;` | Compress these MIME types |
| `expires 30d;` | Set Cache-Control max age |
| `add_header Name value;` | Add HTTP response header |
| `ssl_certificate /path;` | TLS certificate |
| `ssl_certificate_key /path;` | TLS private key |
| `ssl_protocols TLSv1.2 TLSv1.3;` | Allowed TLS versions |
| `return 301 https://$host$request_uri;` | Redirect |
| `rewrite ^/old$ /new permanent;` | URL rewrite |
| `error_page 404 /404.html;` | Custom error pages |
| `client_max_body_size 10m;` | Max upload size |
| `keepalive_timeout 65;` | Keep-alive timeout |
| `worker_processes auto;` | Number of worker processes |
| `worker_connections 1024;` | Max connections per worker |

### Certbot Commands

| Command | Purpose |
|---------|---------|
| `sudo certbot --nginx -d example.com` | Get cert and configure Nginx |
| `sudo certbot --apache -d example.com` | Get cert and configure Apache |
| `sudo certbot certonly --nginx -d example.com` | Get cert only, no config |
| `sudo certbot renew` | Renew all certificates |
| `sudo certbot renew --dry-run` | Test renewal process |
| `sudo certbot certificates` | List all certificates |
| `sudo certbot delete --cert-name example.com` | Delete a certificate |
| `sudo systemctl status certbot.timer` | Check auto-renewal timer |

---

## 🚀 What's Coming in Part 40

**Part 40: Databases — MariaDB and PostgreSQL**

You will learn:
- Installing and securing MariaDB and PostgreSQL
- Creating databases, users, and permissions
- SQL basics — SELECT, INSERT, UPDATE, DELETE, JOINs
- Database backup and restore (mysqldump, pg_dump)
- Query optimization and indexing
- Connecting databases to web applications
- Replication and clustering basics
- 10 hands-on practices
- Deep understanding: ACID, MVCC, indexing internals, query planning

---

## 📝 Self-Test — Can You Answer These?

1. What is the difference between Apache prefork, worker, and event MPM? Which one supports mod_php?
2. What does the `sendfile()` system call do and why is it faster than standard file serving?
3. How does Nginx handle thousands of concurrent connections with so few processes?
4. In Nginx, what is the difference between `location /`, `location = /`, and `location ~ \.php$`?
5. What does the `try_files $uri $uri/ /index.html` directive do?
6. Name three load balancing methods in Nginx's upstream module.
7. What is OCSP stapling and why does it matter for TLS performance?
8. How does `.htaccess` work in Apache, and why doesn't Nginx support it?
9. What is the difference between `proxy_pass` in Nginx and `ProxyPass` in Apache?
10. How would you configure HSTS and what does the `preload` directive do?
11. What is `epoll` and how does it differ from `select()`?
12. How does PHP-FPM integrate with Nginx? Why can't you use `mod_php` with Nginx?
13. What is the purpose of `MaxRequestWorkers` in Apache and `worker_connections` in Nginx?
14. You deploy Nginx → Apache reverse proxy. Nginx serves static files directly. Why is this architecture beneficial?
15. What log format would you use to capture response times in Apache? How do you find the slowest requests?

**Score:** 12/15 correct = ready for Part 40.

---

*Previous → Part 38: Container Basics*
*Next → Part 40: Databases — MariaDB and PostgreSQL*

[← Previous](part38.md) | [Next →](part40.md)
