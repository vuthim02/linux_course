# 🐧 Linux System Administrator — Complete Course
## Part 45 of ∞: Proxy and Reverse Proxy — Squid, Nginx, HAProxy

---

> **Reverse Engineering Approach:** Instead of memorizing proxy configuration syntax, we start from the problem — *"How does a client reach a server when they cannot (or should not) talk directly?"*. We trace the packet through each hop, examine what each proxy does at the HTTP/TCP level, and then configure it properly.

---

## 🎯 What You Will Achieve in Part 45

By the end of this part, you will:

- Understand the **fundamental difference** between forward proxy and reverse proxy at the HTTP protocol level
- **Install and configure Squid** as a forward proxy with ACLs, caching, and authentication
- **Deploy Nginx as a reverse proxy** with caching, load balancing, and TLS termination
- **Configure HAProxy** for TCP and HTTP load balancing with health checks, stick-tables, and SSL
- **Chain proxies** together (HAProxy → Nginx → Backends) using PROXY protocol
- **Secure** your proxy infrastructure against common attacks

---

## 📋 Prerequisites

| Requirement | Details |
|-------------|---------|
| OS | Ubuntu 22.04 / Debian 12 (or RHEL-equivalent with `dnf`) |
| Access | Root or `sudo` on at least 2 servers (or VMs/containers) |
| Services | A test web server (e.g., `python3 -m http.server 8000`) |
| Tools | `curl`, `netstat`, `tcpdump`, `systemctl` |
| Time | 3–4 hours of hands-on lab work |

---

## 🔍 Section 1: Forward Proxy vs Reverse Proxy — Understanding the Difference

### The Core Question

When a client makes an HTTP request, who does it talk to? In the simplest case, the client connects **directly** to the origin server:

```
Client ──► Origin Server
```

But real networks add intermediaries. A **proxy** is that intermediary.

### Forward Proxy (Client-Side Proxy)

A forward proxy sits **in front of the client**. The client is configured to use the proxy; the origin server does not know the client exists.

```
Client ──► Forward Proxy ──► Internet ──► Origin Server
```

**Use cases:**

| Use Case | What it does |
|----------|-------------|
| **Caching** | Store frequently accessed content locally to save bandwidth |
| **Anonymity** | Hide the client's real IP from the origin server |
| **Content filtering** | Block access to malicious or inappropriate sites |
| **Bypass geo-restrictions** | Appear from a different geographic location |
| **Authentication** | Require users to log in before accessing the internet |

**Who configures it?** The **client** (or client's network admin) configures the browser/OS to use the forward proxy.

### Reverse Proxy (Server-Side Proxy)

A reverse proxy sits **in front of the origin server**. The client thinks it is talking directly to the origin server, but the reverse proxy intercepts the request.

```
Client ──► Reverse Proxy ──► Origin Server (hidden)
```

**Use cases:**

| Use Case | What it does |
|----------|-------------|
| **Load balancing** | Distribute traffic across multiple backend servers |
| **TLS termination** | Handle HTTPS encryption, pass plain HTTP to backends |
| **API gateway** | Route requests to different microservices based on path/headers |
| **Web Application Firewall (WAF)** | Inspect and filter malicious traffic |
| **Caching** | Serve cached responses without hitting the backends |
| **Compression** | Compress responses before sending to clients |
| **SSL offloading** | Move expensive crypto operations off the web server |

**Who configures it?** The **server administrator** deploys and manages the reverse proxy.

### The Key Difference at the HTTP Level

```
Forward Proxy:
  Client → CONNECT proxy:443 HTTP/1.1 → Proxy → Server
  Client does NOT know the server's real address resolution path
  Server sees the PROXY's IP, not the client's

Reverse Proxy:
  Client → Server's public IP → Reverse Proxy → Backend
  Client does NOT know which backend handled the request
  Client sees the REVERSE PROXY as the server
```

### HTTP/1.1 Headers that Matter

| Header | Forward Proxy | Reverse Proxy |
|--------|---------------|---------------|
| `X-Forwarded-For` | Added by proxy with real client IP | Added by proxy with real client IP |
| `X-Real-IP` | Nginx convention for client IP | Same |
| `Via` | Added by proxies (RFC 7230) | Added by proxies |
| `Forwarded` | Modern standardized header (RFC 7239) | Same |

---

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

## 🔍 Section 3: Squid Access Control

### 3.1 ACL Types

Squid ACLs follow this pattern:

```apache
acl NAME TYPE ARGUMENT
```

| ACL Type | Matches | Example |
|----------|---------|---------|
| `src` | Client source IP | `acl home_network src 192.168.1.0/24` |
| `dst` | Destination IP | `acl corp_server dst 10.0.0.50` |
| `dstdomain` | Domain name in the URL | `acl banned_sites dstdomain .facebook.com` |
| `method` | HTTP method (GET, POST, CONNECT) | `acl connect_method method CONNECT` |
| `port` | Destination port | `acl SSL_ports port 443` |
| `time` | Day and time | `acl work_hours time MTWHF 09:00-17:00` |
| `url_regex` | Regex match against URL | `acl torrent_url url_regex -i torrent` |
| `urlpath_regex` | Regex match URL path only | `acl admin_path urlpath_regex ^/admin` |
| `maxconn` | Max concurrent connections | `acl too_many maxconn 20` |
| `random` | Random probability | `acl test_users random 0.1` |

### 3.2 http_access Rules

Rules are evaluated top-to-bottom. **Last matching rule wins.** If no rule matches, the default is `deny`.

```apache
# Order matters!
acl work_hours time MTWHF 09:00-17:00
acl banned_sites dstdomain .facebook.com .twitter.com .youtube.com
acl localnet src 192.168.0.0/16

# Block banned sites during work hours
http_access deny banned_sites work_hours

# Allow local network always
http_access allow localnet

# Block everything else
http_access deny all
```

### 3.3 Authentication

Squid supports multiple authentication schemes via `auth_param`.

**Basic authentication (plaintext — use only over TLS or in lab):**

```apache
# Generate passwords
sudo apt install apache2-utils -y
sudo htpasswd -c /etc/squid/passwd user1
sudo htpasswd /etc/squid/passwd user2

# In squid.conf
auth_param basic program /usr/lib/squid/basic_ncsa_auth /etc/squid/passwd
auth_param basic children 5
auth_param basic realm Squid Proxy Authentication
auth_param basic credentialsttl 2 hours

acl authenticated proxy_auth REQUIRED
http_access allow authenticated
http_access deny all
```

**Digest authentication (more secure):**

```apache
auth_param digest program /usr/lib/squid/digest_file_auth /etc/squid/digest_passwd
auth_param digest children 5
auth_param digest realm Squid Digest Realm
auth_param digest nonce_garbage_interval 5 minutes

acl auth_users proxy_auth REQUIRED
http_access allow auth_users
http_access deny all
```

**NTLM / Negotiate (Kerberos) — Active Directory integration:**

```apache
auth_param ntlm program /usr/lib/squid/negotiate_ntlm_auth -d
auth_param ntlm children 10
auth_param negotiate program /usr/lib/squid/negotiate_kerberos_auth -d
auth_param negotiate children 10

acl ad_users proxy_auth REQUIRED
http_access allow ad_users
http_access deny all
```

### 3.4 Practical ACL Configuration

```apache
# /etc/squid/squid.conf — Comprehensive ACL setup

# Network ACLs
acl all src 0.0.0.0/0
acl management src 10.0.0.100-10.0.0.120
acl guests src 192.168.100.0/24

# Time ACLs
acl work_hours time MTWHF 08:00-18:00
acl weekend time SA 00:00-23:59

# Destination ACLs
acl social_media dstdomain .facebook.com .instagram.com .twitter.com
acl streaming dstdomain .netflix.com .hulu.com .youtube.com
acl malware dstdom_regex (phishing|malware|cryptominer)\.*
acl allowed_ssl_ports port 443 563
acl allowed_ports port 80 443 21 22 8080 8443

# Protocol ACLs
acl CONNECT method CONNECT
acl SSL method GET method POST

# Restrictions
acl max_download maxconn 10

# Block malware regardless of user
http_access deny malware

# Block social media during work hours for everyone
http_access deny social_media work_hours

# Guests: no streaming, no social media (even on weekends)
http_access deny guests streaming
http_access deny guests social_media

# Management: unrestricted
http_access allow management

# Allow CONNECT only to SSL ports
http_access deny CONNECT !allowed_ssl_ports

# Allow only safe ports
http_access deny !allowed_ports

# Default deny
http_access deny all
```

---

## 🔍 Section 4: Squid Caching

### 4.1 Cache Directives

Squid caches HTTP responses (GET requests) to serve them faster on subsequent requests.

```apache
# /etc/squid/squid.conf — Caching directives

# Cache directory: UFS filesystem, 10 GB, 16 L1 x 256 L2 subdirectories
cache_dir ufs /var/spool/squid 10240 16 256

# In-memory cache for hot objects
cache_mem 256 MB

# Maximum object size for caching (20 MB)
maximum_object_size 20 MB

# Minimum object size for caching (0 = any)
minimum_object_size 0 bytes

# Objects larger than this are NOT cached (0 = no limit)
maximum_object_size_in_memory 512 KB

# How long to keep an object in cache without access (in days)
cache_swap_low 90
cache_swap_high 95

# Refresh patterns control freshness
refresh_pattern ^ftp:           1440    20%     10080
refresh_pattern ^gopher:        1440    0%      1440
refresh_pattern -i (/cgi-bin/|\?) 0     0%      0
refresh_pattern .               0       20%     4320
```

### 4.2 Cache Storage Types

| Type | Description | Pros | Cons |
|------|-------------|------|------|
| `ufs` | Traditional Unix File System cache | Mature, stable | Slow with many files, uses many inodes |
| `rock` | Fixed-block storage in a single file | Fast, low disk overhead | All blocks same size (wasteful for small files) |
| `aufs` | Async UFS (threaded I/O) | Better I/O performance | Still uses many files |

**Rock cache configuration:**

```apache
cache_dir rock /var/spool/squid 10240 max-size=16384
# max-size = objects larger than 16KB stored in rock; smaller objects go to memory
```

### 4.3 refresh_pattern — Controlling Freshness

The `refresh_pattern` directive tells Squid how to determine if a cached object is still fresh:

```
refresh_pattern REGEX MIN PERCENT MAX [options]
```

```apache
# Static content: cache for 1 day (1440 min), allow 20% variance, max 7 days (10080 min)
refresh_pattern -i \.(jpg|png|gif|css|js|ico)$ 1440 20% 10080

# HTML: shorter cache
refresh_pattern -i \.html$ 60 20% 1440

# API responses: never cache
refresh_pattern -i /api/ 0 0% 0

# Default: 0 min, 20% LM factor, max 4320 min (3 days)
refresh_pattern . 0 20% 4320
```

### 4.4 Measuring Cache Performance

```bash
# Restart Squid
sudo systemctl restart squid

# Generate traffic
for i in $(seq 1 100); do
  curl -x http://127.0.0.1:3128 -s http://example.com > /dev/null
done

# Check cache statistics via squidclient
sudo squidclient -h 127.0.0.1 -p 3128 mgr:info

# Extract cache hit ratio
sudo squidclient -h 127.0.0.1 -p 3128 mgr:info | grep -i "hit ratio"
# Request Hit Ratios: 5min: 89.4%, 60min: 78.2%

# Memory usage
sudo squidclient -h 127.0.0.1 -p 3128 mgr:info | grep -i "memory"
# Memory accounted for: 185928 KB

# Check stored objects count
sudo squidclient -h 127.0.0.1 -p 3128 mgr:store_digest | head -20

# Storage report
sudo squidclient -h 127.0.0.1 -p 3128 mgr:storedir | grep -E "(Files|Space)"
```

### 4.5 Cache Hit Ratio Interpretation

| Ratio | Meaning | Action |
|-------|---------|--------|
| 0–20% | Poor — cache miss most of the time | Increase cache size, check refresh_pattern, warm up cache |
| 20–50% | Fair — some benefit | Tune refresh_pattern, increase cache_mem |
| 50–80% | Good — effective caching | Monitor for drop-off |
| 80–100% | Excellent — cache working well | Ensure freshness policies are correct |

---

## 🔍 Section 5: Squid Logging

### 5.1 Log Files

| Log File | Path | Contents |
|----------|------|----------|
| Access log | `/var/log/squid/access.log` | Every request: timestamp, client IP, method, URL, status, bytes, hierarchy |
| Cache log | `/var/log/squid/cache.log` | Squid daemon messages: startup, errors, cache events |
| Store log | `/var/log/squid/store.log` | Cache object add/remove events (debugging) |

### 5.2 Access Log Format

```bash
sudo tail -f /var/log/squid/access.log
```

Default format (squid native):
```
1718995200.482    123 192.168.1.10 TCP_MISS/200 592 GET http://example.com/ - DIRECT/93.184.216.34 text/html
```

| Field | Meaning |
|-------|---------|
| `1718995200.482` | Unix timestamp (seconds.microseconds) |
| `123` | Response time (milliseconds) |
| `192.168.1.10` | Client IP |
| `TCP_MISS/200` | Cache result / HTTP status |
| `592` | Bytes transferred |
| `GET` | HTTP method |
| `http://example.com/` | Full URL |
| `-` | User identity (if authenticated) |
| `DIRECT/93.184.216.34` | Hierarchy code / server IP |
| `text/html` | Content type |

### 5.3 Custom Log Format

```apache
# Define a custom log format
logformat combined %tl %6tr %>a %Ss/%03>Hs %<st %rm %ru %un %Sh/%<A %mt

# Use it
access_log /var/log/squid/access.log combined

# Apache Common Log Format (for log analyzers)
logformat common %>a %[ui %[un [%tl] "%rm %ru HTTP/%rv" %>Hs %<st
access_log /var/log/squid/access.log common
```

### 5.4 Log Rotation

Squid handles log rotation natively:

```apache
# Rotate logs daily and keep 10 rotated versions
logfile_rotate 10
```

Rotation command:

```bash
# Manual rotation
sudo squid -k rotate

# Cron-based rotation (daily)
echo "0 0 * * * root /usr/sbin/squid -k rotate" | sudo tee /etc/cron.d/squid-rotate
```

### 5.5 Log Analysis

```bash
# Install SquidAnalyzer
sudo apt install squidanalyzer -y

# Configure
sudo nano /etc/squidanalyzer/squidanalyzer.conf

# Generate report
sudo squidanalyzer -f /var/log/squid/access.log

# View report (served via web)
sudo systemctl start squidanalyzer
# http://your-server:8080/squidanalyzer

# Quick stats with command line
echo "Top 10 requested URLs:"
awk '{print $7}' /var/log/squid/access.log | sort | uniq -c | sort -rn | head -10

echo "Cache hit/miss ratio:"
awk '{print $4}' /var/log/squid/access.log | cut -d'/' -f1 | sort | uniq -c | sort -rn

echo "Top 10 users by bandwidth:"
awk '{print $3, $6, $8}' /var/log/squid/access.log | awk '{sum[$1]+=$3} END {for (u in sum) print sum[u], u}' | sort -rn | head -10
```

---

## 🔍 Section 6: Squid Reverse Proxy (HTTP Acceleration)

Squid can also operate as a **reverse proxy** (HTTP accelerator). In this mode, it sits in front of web servers and caches their responses.

### 6.1 HTTP Acceleration Mode

```apache
# /etc/squid/squid.conf — Reverse proxy mode

# Listen on port 80 in accelerator mode
http_port 80 accel defaultsite=www.example.com

# Also listen on 443 with SSL (if Squid compiled with SSL support)
http_port 443 accel defaultsite=www.example.com \
  cert=/etc/ssl/certs/squid.pem \
  key=/etc/ssl/private/squid.key

# Backend server(s)
cache_peer 10.0.0.10 parent 80 0 no-query originserver name=web1
cache_peer 10.0.0.11 parent 80 0 no-query originserver name=web2

# Map domain name to backend
cache_peer_access web1 allow all
cache_peer_access web2 allow all

# Caching for acceleration
cache_dir ufs /var/spool/squid 1024 16 256
cache_mem 128 MB

# Cache static content aggressively
refresh_pattern -i \.(jpg|png|gif|css|js)$ 1440 90% 28800 override-expire

# ACL for our domain
acl our_sites dstdomain www.example.com
http_access allow our_sites
http_access deny all
```

### 6.2 cache_peer Directives

```apache
cache_peer HOSTNAME TYPE HTTP_PORT ICP_PORT [options]

# TYPE: parent (reverse proxy), sibling (other proxy), multicast
# 
# Options:
#   originserver      — This peer is the origin server (not another proxy)
#   no-query          — Don't query this peer with ICP (Internet Cache Protocol)
#   name=NAME         — A name for this peer (used in cache_peer_access)
#   round-robin       — Distribute requests across peers
#   weight=N          — Weight for load distribution (higher = more traffic)
#   connect-timeout=N — Timeout for connecting
#   login=USER:PASS   — Credentials for the origin

# Load balancing between 3 backends
cache_peer 10.0.0.10 parent 80 0 no-query originserver name=app1 weight=3
cache_peer 10.0.0.11 parent 80 0 no-query originserver name=app2 weight=2
cache_peer 10.0.0.12 parent 80 0 no-query originserver name=app3 weight=1
```

### 6.3 Testing Squid Reverse Proxy

```bash
# Setup a test backend
python3 -m http.server 8000 --bind 127.0.0.1 &
echo "Test page" > /tmp/index.html

# Squid config for this test
# http_port 80 accel defaultsite=localhost
# cache_peer 127.0.0.1 parent 8000 0 no-query originserver name=local

# Test
curl -sI http://localhost/index.html
# Via: 1.1 proxy.lab.local (squid/6.0)
```

---

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

## 🔍 Section 8: Nginx Caching

### 8.1 Cache Configuration

```nginx
# /etc/nginx/nginx.conf — inside http block

# Define cache zone
proxy_cache_path /var/cache/nginx levels=1:2 keys_zone=mycache:10m
                 max_size=1g inactive=60m use_temp_path=off;

# levels=1:2       — Directory structure (1 char + 2 chars subdir)
# keys_zone=10m    — 10 MB shared memory for cache keys (~80K keys)
# max_size=1g      — Maximum disk space for cache
# inactive=60m     — Remove objects not accessed for 60 min
# use_temp_path=off— Store temp files in cache dir (faster)

server {
    listen 80;
    server_name app.example.com;

    # Enable caching for this server
    proxy_cache mycache;
    proxy_cache_key "$scheme$request_method$host$request_uri";
    proxy_cache_valid 200 302 60m;
    proxy_cache_valid 404 1m;
    proxy_cache_valid any 10m;
    proxy_cache_use_stale error timeout updating http_500 http_502 http_503 http_504;

    # Bypass cache for specific conditions
    proxy_cache_bypass $http_cache_control;
    proxy_no_cache $http_pragma $http_authorization;

    # Add cache status header
    add_header X-Cache-Status $upstream_cache_status;

    location / {
        proxy_pass http://backend_pool;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

### 8.2 Cache Bypass

```nginx
# Conditionally bypass cache
set $bypass 0;

# Bypass for logged-in users (cookie check)
if ($http_cookie ~* "session_id") {
    set $bypass 1;
}

# Bypass for admin paths
if ($request_uri ~ ^/admin) {
    set $bypass 1;
}

# Bypass for POST/PUT/DELETE
if ($request_method !~ ^(GET|HEAD)$) {
    set $bypass 1;
}

proxy_cache_bypass $bypass;
proxy_no_cache $bypass;
```

### 8.3 Cache Purging

**Method 1: Using ngx_cache_purge module (open source)**

```bash
# Build Nginx with ngx_cache_purge
# https://github.com/FRiCKLE/ngx_cache_purge

# Or use the commercial Nginx Plus which includes purge

# Configuration
location ~ /purge(/.*) {
    allow 127.0.0.1;
    allow 10.0.0.0/8;
    deny all;
    proxy_cache_purge mycache "$scheme$request_method$host$1";
}
```

**Method 2: Manual cache clearing**

```bash
# Find and delete cache files
grep -l -r "example.com/api/users" /var/cache/nginx/ | xargs rm -f

# Or just nuke the entire cache
sudo rm -rf /var/cache/nginx/*
sudo systemctl reload nginx
```

### 8.4 Testing Cache

```bash
# Enable cache status header (see config above)

# First request — MISS
curl -sI http://app.example.com/ | grep X-Cache-Status
# X-Cache-Status: MISS

# Second request — HIT
curl -sI http://app.example.com/ | grep X-Cache-Status
# X-Cache-Status: HIT

# Bypass with Cache-Control: no-cache
curl -sI -H "Cache-Control: no-cache" http://app.example.com/ | grep X-Cache-Status
# X-Cache-Status: BYPASS
```

---

## 🔍 Section 9: Nginx as Load Balancer

### 9.1 Basic TCP/UDP Load Balancing (Stream Module)

```nginx
# /etc/nginx/nginx.conf

# In the main context, load the stream module
# (usually baked in by default)

stream {
    upstream mysql_backend {
        least_conn;
        server 10.0.0.10:3306;
        server 10.0.0.11:3306;
        server 10.0.0.12:3306 backup;
    }

    server {
        listen 3306;
        proxy_pass mysql_backend;
        proxy_connect_timeout 10s;
        proxy_timeout 30s;
    }
}
```

### 9.2 HTTP Load Balancing with Health Checks

```nginx
upstream web_servers {
    # Passive health checks
    server 10.0.0.10:80 max_fails=3 fail_timeout=30s;
    server 10.0.0.11:80 max_fails=3 fail_timeout=30s;
    server 10.0.0.12:80 max_fails=3 fail_timeout=30s;

    # Slow start — gradually increase traffic to recovering server
    server 10.0.0.13:80 slow_start=30s;
}

server {
    listen 80;
    server_name lb.example.com;

    # Health check endpoint (simulate)
    location /health {
        proxy_pass http://web_servers;
        health_check interval=5s fails=3 passes=2;
    }

    location / {
        proxy_pass http://web_servers;
    }
}
```

### 9.3 Zone Sync (Nginx Plus)

```nginx
# Shared state across Nginx instances (commercial)
upstream backend {
    zone backend 64k;
    server 10.0.0.10:80;
    server 10.0.0.11:80;
}

server {
    listen 80;
    server_name lb.example.com;
    status_zone lb.example.com;

    location / {
        proxy_pass http://backend;
    }
}
```

---

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

## 🔍 Section 11: HAProxy Load Balancing Algorithms

### 11.1 Balance Methods

```cfg
# Round Robin (default) — distributes evenly
balance roundrobin

# Least Connections — sends to server with fewest active connections
balance leastconn

# Source IP hash — consistent hash of client IP (sticky)
balance source

# URI hash — same URI always goes to same server (good for cache)
balance uri

# URL Parameter — hash of a specific URL parameter
balance url_param user_id

# Header value — hash of an HTTP header
balance hdr(X-Session-ID)

# Random — pick a random server, weighted
balance random
```

### 11.2 Server Configuration

```cfg
backend web_back
    balance leastconn

    # Main servers
    server web1 10.0.0.10:80 weight 10 check inter 2s fall 3 rise 2
    server web2 10.0.0.11:80 weight 20 check inter 2s fall 3 rise 2
    server web3 10.0.0.12:80 weight 10 check inter 2s fall 3 rise 2

    # Backup server — only used when all main servers are down
    server backup1 10.0.0.99:80 backup

    # Disabled server (manual maintenance)
    server web4 10.0.0.13:80 disabled
```

| Server Option | Description |
|---------------|-------------|
| `weight N` | Relative weight for load distribution (default: 1) |
| `check` | Enable health checks |
| `inter N` | Health check interval in milliseconds |
| `fall N` | Number of failed checks before marking server DOWN |
| `rise N` | Number of successful checks before marking server UP |
| `backup` | Only used when all non-backup servers are down |
| `disabled` | Manually disabled |
| `slowstart N` | Gradually increase weight after coming up |

### 11.3 Stick-Table Persistence

```cfg
backend web_back
    balance roundrobin

    # Stick table stores mapping of client IP → selected server
    stick-table type ip size 200k expire 30m
    stick on src

    server web1 10.0.0.10:80 check
    server web2 10.0.0.11:80 check
    server web3 10.0.0.12:80 check
```

**Stick by cookie:**

```cfg
backend web_back
    balance roundrobin

    # Insert a cookie to track which server
    cookie SERVERID insert indirect nocache

    server web1 10.0.0.10:80 check cookie srv1
    server web2 10.0.0.11:80 check cookie srv2
    server web3 10.0.0.12:80 check cookie srv3
```

### 11.4 Health Check Tuning

```cfg
backend web_back
    # HTTP health check (expects 200 status)
    option httpchk GET /health HTTP/1.1\r\nHost:\ example.com

    # Or TCP health check (just test port is open)
    # option tcp-check

    server web1 10.0.0.10:80 check inter 1s fall 2 rise 2
    server web2 10.0.0.11:80 check inter 1s fall 2 rise 2
```

---

## 🔍 Section 12: HAProxy Advanced Features

### 12.1 ACLs and Content Switching

```cfg
frontend web_front
    bind *:80
    bind *:443 ssl crt /etc/ssl/haproxy.pem

    # ACLs — define conditions
    acl is_api        path_beg /api/
    acl is_static     path_end .jpg .png .css .js .ico
    acl is_admin      path_beg /admin
    acl is_mobile     hdr_sub(User-Agent) -i mobile
    acl is_websocket  hdr(Upgrade) -i websocket
    acl is_internal   src 10.0.0.0/8
    acl is_secure     ssl_fc  # Connection is over TLS

    # Content switching — route based on ACLs
    use_backend api_servers      if is_api
    use_backend static_servers   if is_static
    use_backend admin_servers    if is_admin is_internal
    use_backend ws_servers       if is_websocket

    # Default backend
    default_backend web_servers
```

### 12.2 SSL Termination

```cfg
global
    # Tune SSL parameters
    tune.ssl.default-dh-param 2048
    ssl-default-bind-ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM...
    ssl-default-bind-options no-sslv3 no-tlsv10 no-tlsv11

frontend https_front
    # Single PEM file (cert + key + CA chain)
    bind *:443 ssl crt /etc/ssl/haproxy.pem

    # Multiple certificates (SNI)
    bind *:443 ssl crt /etc/ssl/certs/ crt-list /etc/ssl/haproxy_crtlist.txt

    # OCSP stapling
    bind *:443 ssl crt /etc/ssl/haproxy.pem ca-file /etc/ssl/ca.crt crt-ignore-err all

    # Redirect HTTP to HTTPS
    redirect scheme https code 301 if !{ ssl_fc }

    default_backend web_servers
```

### 12.3 Stats Page

```cfg
frontend stats_front
    bind *:8404
    stats enable
    stats uri /haproxy-stats
    stats refresh 5s
    stats admin if LOCALHOST
    stats auth admin:SecurePass1!

# Or in a listen section (commonly used)
listen stats
    bind *:8404
    stats enable
    stats uri /stats
    stats auth admin:changeme
    stats refresh 10s
    stats admin if TRUE

# Access it: http://server:8404/stats
```

### 12.4 Logging

```cfg
global
    log /dev/log local0 info
    log /dev/log local1 notice

defaults
    log global
    option httplog
    log-format "%ci:%cp [%t] %ft %b/%s %Tq/%Tw/%Tc/%Tr/%Ta %ST %B %CC %CS %tsc %ac/%fc/%bc/%sc/%rc %sq/%bq %hr %hs %{+Q}r"

# Syslog setup
# /etc/rsyslog.d/haproxy.conf
# local0.*  /var/log/haproxy.log
# local1.*  /var/log/haproxy-error.log

# Then restart rsyslog
sudo systemctl restart rsyslog
```

---

## 🔍 Section 13: Proxy Chaining and Forwarding

### 13.1 Transparent Proxy

A transparent proxy intercepts traffic **without client configuration**. The client thinks it is talking directly to the server.

```
Client ──► Router/Gateway ──► Transparent Proxy ──► Internet
                 │                    │
          (iptables redirect)   (proxy processes)
```

### 13.2 Squid Transparent Proxy with iptables

```bash
# 1. Configure Squid to accept transparent requests
# In squid.conf:
# http_port 3128 intercept

# 2. Redirect HTTP traffic (port 80) to Squid
sudo iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 80 -j REDIRECT --to-port 3128

# 3. For HTTPS, you can either:
#    a) Redirect to Squid in transparent mode (CONNECT)
#    b) Use SSL bump (man-in-the-middle)
sudo iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 443 -j REDIRECT --to-port 3128

# 4. Enable IP forwarding
sudo sysctl -w net.ipv4.ip_forward=1
```

### 13.3 TPROXY (Transparent Proxy)

TPROXY preserves the original client IP without requiring NAT. It works at the routing level.

```bash
# Requirements: Linux kernel ≥ 2.6.28, iptables with TPROXY module

# 1. Add a routing rule for the proxy
sudo ip rule add fwmark 1 lookup 100
sudo ip route add local 0.0.0.0/0 dev lo table 100

# 2. iptables TPROXY rule
sudo iptables -t mangle -A PREROUTING -p tcp --dport 80 \
    -j TPROXY --tproxy-mark 0x1/0x1 --on-port 3129

# 3. Squid config for TPROXY
# http_port 3129 tproxy
```

### 13.4 Chaining Proxies

```
Client ──► Squid (forward) ──► HAProxy (reverse) ──► Nginx (reverse) ──► Backend
```

**Squid config (forward proxy):**

```apache
# Forward proxy sends to upstream proxy
cache_peer 10.0.0.5 parent 3128 0 no-query
never_direct allow all
```

**HAProxy config (intermediate):**

```cfg
frontend intermediate
    bind *:3128
    default_backend nginx_proxy

backend nginx_proxy
    server nginx 10.0.0.6:80 check
```

**Nginx config (last hop before backend):**

```nginx
server {
    listen 80;
    location / {
        proxy_pass http://10.0.0.10:8080;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

---

## 🔍 Section 14: PROXY Protocol

### 14.1 The Problem

When proxies are chained, the original client IP is typically passed via the `X-Forwarded-For` header. But this header can be **spoofed** by the client. For TCP-based protocols (HTTPS, SMTP, MySQL), there is no HTTP header at all.

### 14.2 PROXY Protocol v1 and v2

**PROXY protocol** inserts a small header before the actual stream data, preserving the original client IP and port. It works for TCP connections regardless of the application protocol.

**PROXY v1 (human-readable):**

```
PROXY TCP4 192.168.1.10 10.0.0.5 53456 443\r\n
```

**PROXY v2 (binary — more efficient, supports IPv6):**

```
\x0D\x0A\x0D\x0A\x00\x0D\x0A\x51\x55\x49\x54\x0A\x21\x11\x00\x0C
\xC0\xA8\x01\x0A\x0A\x00\x00\x05\xD0\xC8\x01\xBB
```

### 14.3 Enabling PROXY Protocol

**HAProxy (sender):**

```cfg
backend web_servers
    server web1 10.0.0.10:80 send-proxy-v2 check
```

**Nginx (receiver):**

```nginx
server {
    listen 80 proxy_protocol;
    listen 443 ssl proxy_protocol;

    real_ip_header proxy_protocol;
    set_real_ip_from 10.0.0.0/8;

    location / {
        proxy_pass http://backend;
    }
}
```

**HAProxy (receiver):**

```cfg
frontend web_front
    bind *:80 accept-proxy
    bind *:443 accept-proxy ssl crt /etc/ssl/haproxy.pem
```

### 14.4 Full Proxy Chain with PROXY Protocol

```
Client ──► HAProxy (edge) ──► Nginx ──► Backend

HAProxy (edge) — sends PROXY to Nginx:
  bind *:443 ssl crt /etc/ssl/haproxy.pem
  server nginx 10.0.0.5:80 send-proxy-v2

Nginx — receives PROXY, forwards to backend:
  listen 80 proxy_protocol;
  set_real_ip_from 10.0.0.0/8;
  proxy_set_header X-Real-IP $proxy_protocol_addr;
  proxy_pass http://10.0.0.10:8080;

Result: Backend sees real client IP via X-Real-IP header.
```

---

## 🔍 Section 15: Security

### 15.1 Hiding Server Version

**Squid:**

```apache
# Hide Squid version in HTTP headers
httpd_suppress_version_string on

# Custom error pages
error_directory /usr/share/squid/errors/Custom
```

**Nginx:**

```nginx
# /etc/nginx/nginx.conf
http {
    server_tokens off;
    proxy_hide_header X-Powered-By;
    proxy_hide_header Server;
}
```

**HAProxy:**

```cfg
defaults
    # Remove server header from backend responses
    option httpchk
    rspidel ^Server:.*
    rspadd Server:\ HAProxy\ (custom)
```

### 15.2 Rate Limiting with HAProxy

```cfg
frontend web_front
    bind *:80

    # Define stick table for rate limiting
    stick-table type ip size 200k expire 1m store http_req_rate(10s)

    # Track requests per client
    http-request track-sc0 src

    # Block clients exceeding 100 requests in 10 seconds
    http-request deny deny_status 429 if { sc_http_req_rate(0) gt 100 }

    default_backend web_servers
```

### 15.3 ACL Whitelist/Blacklist

**Squid:**

```apache
# Blacklist
acl bad_sites dstdomain .example.com .badplace.com
http_access deny bad_sites

# Whitelist (deny all except whitelisted)
acl allowed_sites dstdomain .work.com .internal.tools
http_access allow allowed_sites
http_access deny all
```

**HAProxy:**

```cfg
frontend web_front
    bind *:80

    # Country-based blocking (requires GeoIP database)
    acl blocked_country src 1.2.3.0/24 4.5.6.0/24
    http-request deny if blocked_country

    # IP whitelist for admin
    acl admin_network src 10.0.0.0/8 192.168.0.0/16
    acl admin_path path_beg /admin
    http-request allow if admin_path admin_network
    http-request deny if admin_path
```

### 15.4 X-Forwarded-For Spoofing Prevention

```nginx
# Nginx — trust only known proxy IPs
set_real_ip_from 10.0.0.0/8;
set_real_ip_from 172.16.0.0/12;
set_real_ip_from 192.168.0.0/16;
real_ip_header X-Forwarded-For;
real_ip_recursive on;
```

```cfg
# HAProxy
option forwardfor header X-Forwarded-For

# Only if the connecting IP is trusted
# (not built-in HAProxy; use accept-proxy with proxy protocol instead)
```

---

## 🛠️ 15 Hands-On Practices

### Practice 1: Install and Configure Squid as a Forward Proxy

```bash
# 1. Install Squid
sudo apt update && sudo apt install squid -y

# 2. Configure /etc/squid/squid.conf
sudo tee -a /etc/squid/squid.conf << 'EOF'
http_port 3128
visible_hostname squid-forward-proxy
acl localnet src 192.168.0.0/16
http_access allow localnet
http_access deny all
EOF

# 3. Restart and enable
sudo systemctl restart squid
sudo systemctl enable squid

# 4. Test
curl -x http://127.0.0.1:3128 -v http://example.com
```

### Practice 2: Configure ACL to Block Specific Sites

```bash
# In squid.conf, add:
sudo tee -a /etc/squid/squid.conf << 'EOF'
acl blocked_sites dstdomain .facebook.com .twitter.com .instagram.com
http_access deny blocked_sites
http_access allow localnet
http_access deny all
EOF

sudo systemctl reload squid

# Test blocking
curl -x http://127.0.0.1:3128 http://facebook.com
# Should return 403 Forbidden
```

### Practice 3: Enable Caching and Measure Hit Ratio

```bash
# In squid.conf:
# cache_dir ufs /var/spool/squid 500 16 256
# cache_mem 64 MB
# refresh_pattern . 0 20% 4320

sudo systemctl restart squid

# Generate traffic
for i in $(seq 1 100); do
  curl -x http://127.0.0.1:3128 -s http://example.com > /dev/null
done

# Check hit ratio
sudo squidclient -h 127.0.0.1 -p 3128 mgr:info | grep -i "hit ratio"
```

### Practice 4: Squid with Authentication

```bash
sudo apt install apache2-utils -y
sudo htpasswd -c /etc/squid/passwd proxyuser

sudo tee -a /etc/squid/squid.conf << 'EOF'
auth_param basic program /usr/lib/squid/basic_ncsa_auth /etc/squid/passwd
auth_param basic children 5
auth_param basic realm Squid Proxy
auth_param basic credentialsttl 2 hours
acl authenticated proxy_auth REQUIRED
http_access allow authenticated
http_access deny all
EOF

sudo systemctl restart squid
curl -x http://proxyuser:password@127.0.0.1:3128 http://example.com
```

### Practice 5: Squid Log Analysis

```bash
# Enable custom log format
sudo tee -a /etc/squid/squid.conf << 'EOF'
logformat combined %tl %6tr %>a %Ss/%03>Hs %<st %rm %ru %un %Sh/%<A %mt
access_log /var/log/squid/access.log combined
EOF

sudo systemctl reload squid

# Analyze
echo "Top 10 destinations:"
awk '{print $7}' /var/log/squid/access.log | sort | uniq -c | sort -rn | head -10
```

### Practice 6: Squid Reverse Proxy for a Web App

```bash
# Start a test web server
mkdir -p /tmp/webapp
echo "<h1>Hello from backend</h1>" | sudo tee /tmp/webapp/index.html
cd /tmp/webapp && python3 -m http.server 8080 --bind 0.0.0.0 &

# In squid.conf:
sudo tee -a /etc/squid/squid.conf << 'EOF'
http_port 80 accel defaultsite=webapp.local
cache_peer 127.0.0.1 parent 8080 0 no-query originserver name=localapp
cache_peer_access localapp allow all
acl app_site dstdomain webapp.local
http_access allow app_site
http_access deny all
EOF

sudo systemctl restart squid
curl -s -H "Host: webapp.local" http://127.0.0.1/
```

### Practice 7: Nginx Reverse Proxy for a Web Application

```bash
# Create Nginx config
sudo tee /etc/nginx/sites-available/app-proxy << 'EOF'
server {
    listen 80;
    server_name app.example.com;

    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
EOF

sudo ln -s /etc/nginx/sites-available/app-proxy /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx

curl -s -H "Host: app.example.com" http://127.0.0.1/
```

### Practice 8: Nginx Cache + Purge

```bash
# Add to nginx.conf (inside http block):
# proxy_cache_path /var/cache/nginx levels=1:2 keys_zone=mycache:10m max_size=1g inactive=60m;

# In the server block:
# proxy_cache mycache;
# proxy_cache_valid 200 302 60m;
# add_header X-Cache-Status $upstream_cache_status;

sudo nginx -t && sudo systemctl reload nginx

# Test
curl -sI http://app.example.com/ | grep X-Cache-Status  # MISS
curl -sI http://app.example.com/ | grep X-Cache-Status  # HIT

# Purge (using ngx_cache_purge or manual):
sudo find /var/cache/nginx -type f -delete
sudo systemctl reload nginx
```

### Practice 9: Nginx Load Balancer with upstream

```bash
# Simulate 3 backends
for port in 8001 8002 8003; do
    mkdir -p /tmp/web$port
    echo "Server $port" | sudo tee /tmp/web$port/index.html
    cd /tmp/web$port && python3 -m http.server $port --bind 0.0.0.0 &
done

# Nginx config
sudo tee /etc/nginx/sites-available/lb << 'EOF'
upstream backend {
    least_conn;
    server 127.0.0.1:8001;
    server 127.0.0.1:8002;
    server 127.0.0.1:8003;
}

server {
    listen 80;
    server_name lb.example.com;

    location / {
        proxy_pass http://backend;
        proxy_set_header Host $host;
    }
}
EOF

sudo ln -sf /etc/nginx/sites-available/lb /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx

# Test — should see different servers
for i in $(seq 1 10); do
    curl -s http://lb.example.com/
done
```

### Practice 10: HAProxy TCP Load Balancing

```bash
# Install HAProxy
sudo apt install haproxy -y

# Config
sudo tee /etc/haproxy/haproxy.cfg << 'EOF'
global
    log /dev/log local0
    chroot /var/lib/haproxy
    stats socket /run/haproxy/admin.sock mode 660 level admin
    stats timeout 30s
    user haproxy
    group haproxy
    daemon

defaults
    log     global
    mode    tcp
    option  tcplog
    timeout connect 5000
    timeout client  50000
    timeout server  50000

frontend mysql_front
    bind *:3306
    default_backend mysql_back

backend mysql_back
    balance roundrobin
    server db1 10.0.0.10:3306 check
    server db2 10.0.0.11:3306 check
    server db3 10.0.0.12:3306 check backup
EOF

sudo haproxy -f /etc/haproxy/haproxy.cfg -c && sudo systemctl restart haproxy
```

### Practice 11: HAProxy HTTP Load Balancing with ACLs

```cfg
global
    log /dev/log local0
    chroot /var/lib/haproxy
    stats socket /run/haproxy/admin.sock mode 660 level admin
    user haproxy
    group haproxy
    daemon

defaults
    log     global
    mode    http
    option  httplog
    option  forwardfor
    timeout connect 5000
    timeout client  50000
    timeout server  50000

frontend web_front
    bind *:80

    acl is_api     path_beg /api/
    acl is_static  path_end .jpg .png .css .js .ico

    use_backend api_servers    if is_api
    use_backend static_servers if is_static
    default_backend web_servers

backend api_servers
    balance leastconn
    server api1 10.0.0.10:3000 check
    server api2 10.0.0.11:3000 check

backend static_servers
    balance source
    server static1 10.0.0.10:80 check

backend web_servers
    balance roundrobin
    server web1 10.0.0.10:8080 check
    server web2 10.0.0.11:8080 check
```

### Practice 12: Enable HAProxy Statistics Page

```cfg
# Add to the config above
frontend stats
    bind *:8404
    stats enable
    stats uri /haproxy-stats
    stats refresh 10s
    stats auth admin:S3cur3P@ss!

sudo haproxy -f /etc/haproxy/haproxy.cfg -c && sudo systemctl reload haproxy
# Visit http://server:8404/haproxy-stats
```

### Practice 13: Transparent Proxy with iptables TPROXY

```bash
# 1. Configure Squid for transparent mode
echo "http_port 3128 intercept" | sudo tee -a /etc/squid/squid.conf
sudo systemctl restart squid

# 2. Redirect port 80 traffic to Squid
sudo iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 80 -j REDIRECT --to-port 3128

# 3. Enable IP forwarding
sudo sysctl -w net.ipv4.ip_forward=1

# 4. Test (from another client on the network)
curl http://example.com  # Should go through Squid transparently
```

### Practice 14: HAProxy SSL Termination

```bash
# Generate self-signed cert
sudo openssl req -x509 -newkey rsa:2048 -keyout /etc/ssl/haproxy.key \
    -out /etc/ssl/haproxy.crt -days 365 -nodes \
    -subj "/CN=haproxy.example.com"
sudo cat /etc/ssl/haproxy.crt /etc/ssl/haproxy.key > /etc/ssl/haproxy.pem

# HAProxy config
frontend https_front
    bind *:443 ssl crt /etc/ssl/haproxy.pem
    default_backend web_servers

    # Redirect HTTP to HTTPS
frontend http_front
    bind *:80
    redirect scheme https code 301

backend web_servers
    server web1 10.0.0.10:80 check
    server web2 10.0.0.11:80 check
```

### Practice 15: Real-World Integration — HAProxy → Nginx → Backends

This is the capstone practice. You build a 3-tier proxy architecture:

```
Internet ──► HAProxy (edge LB, SSL, rate-limit) ──► Nginx (cache/reverse) ──► Backend Web Servers
```

**Layer 1 — HAProxy (Edge):**

```cfg
# /etc/haproxy/haproxy.cfg
global
    log /dev/log local0
    chroot /var/lib/haproxy
    stats socket /run/haproxy/admin.sock mode 660 level admin
    user haproxy
    group haproxy
    daemon

defaults
    log     global
    mode    http
    option  httplog
    option  forwardfor
    timeout connect 5000
    timeout client  50000
    timeout server  50000

frontend edge
    bind *:80
    bind *:443 ssl crt /etc/ssl/haproxy.pem

    # Rate limiting
    stick-table type ip size 200k expire 1m store http_req_rate(10s)
    http-request track-sc0 src
    http-request deny deny_status 429 if { sc_http_req_rate(0) gt 200 }

    # ACLs
    acl is_static  path_end .jpg .png .css .js .ico .svg

    # Static goes directly to Nginx cache layer
    use_backend nginx_cache if is_static
    default_backend nginx_cache

backend nginx_cache
    balance roundrobin
    option httpchk GET /health
    server nginx1 10.0.0.5:80 check send-proxy-v2
    server nginx2 10.0.0.6:80 check send-proxy-v2
```

**Layer 2 — Nginx (Cache / Reverse Proxy):**

```nginx
# /etc/nginx/nginx.conf
user www-data;
worker_processes auto;
pid /run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    # Cache configuration (Layer 2 cache)
    proxy_cache_path /var/cache/nginx levels=1:2 keys_zone=l2cache:10g
                     max_size=50g inactive=60m use_temp_path=off;

    # Upstream web servers (Layer 3)
    upstream web_backends {
        least_conn;
        server 10.0.0.10:8080 max_fails=3 fail_timeout=30s;
        server 10.0.0.11:8080 max_fails=3 fail_timeout=30s;
        server 10.0.0.12:8080 max_fails=3 fail_timeout=30s;
    }

    server {
        listen 80 proxy_protocol;
        set_real_ip_from 10.0.0.0/8;
        real_ip_header proxy_protocol;

        # Health check endpoint for HAProxy
        location /health {
            return 200 "OK\n";
            add_header Content-Type text/plain;
        }

        location / {
            proxy_pass http://web_backends;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $proxy_protocol_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;

            # Caching
            proxy_cache l2cache;
            proxy_cache_key "$scheme$request_method$host$request_uri";
            proxy_cache_valid 200 302 10m;
            proxy_cache_valid 404 1m;
            proxy_cache_use_stale error timeout updating;
            add_header X-Cache-Status $upstream_cache_status;
        }

        # Bypass cache for admin
        location /admin/ {
            proxy_pass http://web_backends;
            proxy_no_cache 1;
            proxy_cache_bypass 1;
        }
    }
}
```

**Layer 3 — Backend servers:**

```bash
# On each backend server (10.0.0.10-12):
sudo apt install apache2 -y
echo "Backend $(hostname)" | sudo tee /var/www/html/index.html
```

**Testing the full chain:**

```bash
# From internet client
curl -sI https://app.example.com/ | grep -E "(X-Cache|Server)"
# X-Cache-Status: HIT   (from Nginx)
# Server: HAProxy        (edge stripped backend server)

# Rate limit test
for i in $(seq 1 300); do
  curl -s -o /dev/null -w "%{http_code}\n" https://app.example.com/ &
done
# After ~200 requests, you should see 429 Too Many Requests

# Verify PROXY protocol preserves client IP
# On Nginx: check $proxy_protocol_addr
tail -f /var/log/nginx/access.log | grep -v health
# Should show real client IP, not HAProxy IP
```

---

## 🧠 Deep Understanding

### Forward Proxy vs Reverse Proxy at the HTTP Level

**Forward proxy** changes the HTTP request fundamentally. When a client uses a forward proxy, it sends requests like:

```
GET http://example.com/path HTTP/1.1
Host: example.com
```

Note the **absolute URI** in the request line (`http://example.com/path` instead of `/path`). This is required by RFC 7230 for proxy requests. The proxy then:
1. Parses the absolute URI to determine the origin server
2. Resolves DNS for the server (on behalf of the client)
3. Opens a new TCP connection to the server
4. Forwards the request (possibly modified)
5. Returns the response to the client

For HTTPS, the client sends a `CONNECT` request to establish a tunnel:

```
CONNECT example.com:443 HTTP/1.1
Host: example.com
```

The proxy opens the TCP connection to the target and then proxies raw bytes bidirectionally. The proxy **cannot inspect** HTTPS traffic (unless it does SSL bump/MITM).

**Reverse proxy** receives standard HTTP requests:

```
GET /path HTTP/1.1
Host: example.com
```

The reverse proxy:
1. Accepts the TCP connection from the client
2. Terminates TLS (if HTTPS)
3. Looks at the `Host` header and/or URL path
4. Selects a backend server based on its routing rules
5. Opens a new TCP connection to the backend (possibly with different protocol)
6. Forwards the request (adding X-Forwarded-For, modifying Host, etc.)
7. Optionally caches the response
8. Returns the response to the client

**Key architectural difference:** A forward proxy requires **client cooperation** (explicit proxy config or transparent interception). A reverse proxy is **transparent to the client** — the client does not know it exists.

### How Squid Processes a Request

```
1. TCP accept
       │
2. Parse request (absolute URI or CONNECT)
       │
3. ACL chain evaluation (top to bottom)
       │
       ├──► DENY: Send error response (403), log, close
       │
4. Authentication (if configured)
       │
       ├──► 407 Proxy Authentication Required → client retries with credentials
       │
5. DNS resolution of the destination
       │
6. Connection to origin server (or cache_peer / parent proxy)
       │
7. Cache lookup
       │
       ├──► HIT (fresh): Serve from cache
       │
       ├──► STALE: Conditional GET (If-Modified-Since / ETag)
       │         ├──► 304 Not Modified → refresh TTL, serve cached
       │         └──► 200 → replace cache, serve new
       │
       └──► MISS: Forward to origin
       │
8. Receive response from origin
       │
9. Cache decision (cacheable? → store in cache_dir + cache_mem)
       │
10. Log the transaction (access.log)
       │
11. Send response to client
```

**ACL evaluation order:** Squid evaluates ACLs in the order they appear in the config. The **first matching `http_access allow` or `http_access deny`** wins. If no rule matches, Squid defaults to **deny**.

### How HAProxy's Event Loop Works

HAProxy uses a **single-threaded event-driven architecture** (multi-threading was introduced in v1.8+ but the event loop concept remains).

```
main loop:
  while (1):
    1. epoll_wait() / kqueue() / poll()
       └─► Returns list of ready file descriptors (FDs)
    
    2. For each ready FD:
       a. Accept new connection (if listener socket)
          ├─► Allocate task (stream interface)
          ├─► Insert into run queue
          └─► Set up connection structure
    
       b. Process incoming data (if client/server socket)
          ├─► Read data into buffer
          ├─► Parse protocol (HTTP/tcp)
          ├─► Apply ACLs / rules
          └─► Queue outgoing data
    
    3. Run task scheduler:
       └─► Process tasks from run queue:
           ├─► Health checks (check timers)
           ├─► Stick-table maintenance (expire entries)
           ├─► Stats page updates
           └─► Connection retries
    
    4. Send pending data:
       └─► splice() / sendfile() for zero-copy forwarding
```

**Zero-copy forwarding:** HAProxy uses `splice()` (Linux) or `sendfile()` to move data between file descriptors **without copying to userspace**:

```
Client socket ──splice()──► Backend socket (or vice versa)
```

This means HAProxy can forward traffic at **near line rate** with minimal CPU usage. The data never touches HAProxy's application buffers — it goes directly from the network card's DMA buffer to the outgoing socket.

**Multi-threading (HAProxy 1.8+):**

```
Thread 0 (main):
    ├─► epoll FD
    ├─► Accept incoming connections
    └─► Distribute across threads (via queue)

Thread 1..N (workers):
    ├─► Run their own epoll instance
    ├─► Process their own connections (no lock contention)
    └─► Share stick-tables via atomic operations
```

HAProxy uses **lock-free data structures** for most shared state (stick-tables, server state). Each connection is pinned to a single thread after accept, so there is no contention on connection processing.

### How PROXY Protocol Preserves Client IP Through Multiple Hops

Without PROXY protocol, each proxy in a chain would see the IP of the **previous hop**:

```
Client (1.2.3.4) ──► HAProxy1 ──► HAProxy2 ──► Backend
   conn src: 1.2.3.4    conn src: 10.0.0.1    conn src: 10.0.0.2
```

The backend sees 10.0.0.2 as the client IP, not 1.2.3.4.

With PROXY protocol:

```
Client (1.2.3.4) ──► HAProxy1 ──► HAProxy2 ──► Backend

TCP connect:           PROXY header:           PROXY header:
  src: 1.2.3.4          "1.2.3.4, 53456,       "1.2.3.4, 53456,
                        10.0.0.1, 443"         10.0.0.1, 443"

After receiving PROXY header:
  HAProxy1 stores client IP: 1.2.3.4
  HAProxy2 replaces connection source with client IP from header
  Backend sees source IP: 1.2.3.4
```

**The process:**

1. **HAProxy1** accepts client TCP connection (src=1.2.3.4, dst=10.0.0.1:443)
2. **HAProxy1** opens connection to HAProxy2 and prepends PROXY v2 header:
   ```
   \x0D\x0A\x0D\x0A\x00\x0D\x0A\x51\x55\x49\x54\x0A...
   src_addr=1.2.3.4 src_port=53456 dst_addr=10.0.0.1 dst_port=443
   ```
3. **HAProxy2** receives the connection, reads the PROXY header, and **replaces** the transport-level source address with the address from the PROXY header
4. **HAProxy2** then forwards the actual TLS/HTTP data without further modification

This works because PROXY protocol is at the **transport layer** — there is no concept of "HTTP request" in PROXY v1/v2. It is simply a preamble before the real connection data, regardless of whether the connection carries HTTP, SMTP, MySQL, or raw TCP.

---

## 📋 Command Reference

### Squid Commands

| Command | Purpose |
|---------|---------|
| `sudo apt install squid` | Install Squid |
| `sudo systemctl {start\|stop\|restart\|reload\|status} squid` | Service management |
| `squid -v` | Show version |
| `squid -k parse` | Validate config |
| `squid -k check` | Check config (same as parse) |
| `squid -k reconfigure` | Reload config without restart |
| `squid -k rotate` | Rotate logs |
| `squid -k shutdown` | Graceful shutdown |
| `squidclient -h HOST -p PORT mgr:info` | Get cache statistics |
| `squidclient -h HOST -p PORT mgr:objects` | List cached objects |
| `squidclient -h HOST -p PORT mgr:storedir` | Storage directory info |
| `sudo tail -f /var/log/squid/access.log` | Watch live requests |
| `sudo tail -f /var/log/squid/cache.log` | Watch daemon messages |
| `squidanalyzer -f /var/log/squid/access.log` | Generate analysis report |

### Nginx Commands

| Command | Purpose |
|---------|---------|
| `sudo apt install nginx` | Install Nginx |
| `sudo systemctl {start\|stop\|restart\|reload\|status} nginx` | Service management |
| `nginx -v` | Show version |
| `nginx -V` | Show version + compile flags |
| `nginx -t` | Validate config syntax |
| `sudo nginx -s reload` | Reload config (graceful) |
| `sudo nginx -s quit` | Graceful shutdown |
| `sudo tail -f /var/log/nginx/access.log` | Watch access log |
| `sudo tail -f /var/log/nginx/error.log` | Watch error log |
| `sudo rm -rf /var/cache/nginx/*` | Clear all cache |
| `sudo find /var/cache/nginx -type f -delete` | Clear cache files |

### HAProxy Commands

| Command | Purpose |
|---------|---------|
| `sudo apt install haproxy` | Install HAProxy |
| `sudo systemctl {start\|stop\|restart\|reload\|status} haproxy` | Service management |
| `haproxy -v` | Show version |
| `haproxy -f /etc/haproxy/haproxy.cfg -c` | Validate config |
| `haproxy -f /etc/haproxy/haproxy.cfg -d` | Start in debug mode (foreground) |
| `sudo haproxy -f /etc/haproxy/haproxy.cfg -sf $PID` | Graceful reload with existing PID |
| `echo "show info" \| sudo socat stdio /run/haproxy/admin.sock` | Show runtime info |
| `echo "show stat" \| sudo socat stdio /run/haproxy/admin.sock` | Show statistics |
| `echo "show table" \| sudo socat stdio /run/haproxy/admin.sock` | Show stick-tables |
| `echo "disable server web_back/web1" \| sudo socat stdio /run/haproxy/admin.sock` | Disable a server |
| `echo "enable server web_back/web1" \| sudo socat stdio /run/haproxy/admin.sock` | Enable a server |
| `echo "set weight web_back/web1 50" \| sudo socat stdio /run/haproxy/admin.sock` | Change server weight |
| `echo "clear table web_back" \| sudo socat stdio /run/haproxy/admin.sock` | Clear stick-table |

### Network Testing Commands

| Command | Purpose |
|---------|---------|
| `curl -x http://proxy:3128 -v http://example.com` | Test forward proxy |
| `curl -sI http://example.com \| grep -i via` | Check Via header |
| `curl -sI http://example.com \| grep -i x-cache` | Check X-Cache header |
| `curl -s -H "Host: app.test" http://127.0.0.1/` | Test reverse proxy with Host header |
| `for i in $(seq 1 10); do curl -s http://lb/ \| grep Server; done` | Test load distribution |
| `tcpdump -i eth0 port 3128 -X` | Capture proxy traffic |
| `ss -tlnp \| grep -E "(squid|nginx|haproxy)"` | Check listening ports |
| `nc -vz 127.0.0.1 3128` | Test TCP connectivity to proxy |

---

## 🔮 What's Coming in Part 46

**Part 46: Monitoring and Alerting** — We build a complete monitoring stack from the ground up. Topics include:

- **Prometheus** — Time-series metrics collection, exporters, service discovery
- **Grafana** — Dashboards, alerting rules, notification channels
- **Node Exporter** — Server metrics (CPU, memory, disk, network)
- **Blackbox Exporter** — External endpoint monitoring (HTTP, TCP, ICMP)
- **Alertmanager** — Alert routing, grouping, inhibition, and silencing
- **Loki + Promtail** — Log aggregation and querying
- **Synthetic monitoring** — Browser-based checks with Grafana k6
- **Integration** — Set up alerts for: disk > 90%, CPU > 80%, service down, certificate expiry

The monitoring stack you build in Part 46 will watch over the proxy infrastructure you built today.

---

## ✅ Self-Test

Answer these 15 questions. **Score:** 12/15 correct = ready for Part 46.

### Question 1
Which HTTP method does a forward proxy use to establish an HTTPS tunnel?
```
A) GET
B) POST
C) CONNECT
D) TUNNEL
```

### Question 2
What is the key difference between a forward proxy and a reverse proxy?
```
A) Forward proxy uses TCP; reverse proxy uses UDP
B) Forward proxy is configured on the client side; reverse proxy is deployed on the server side
C) Forward proxy can only cache; reverse proxy can only load balance
D) There is no difference — they are the same thing
```

### Question 3
In Squid, which directive defines the storage location and size of the disk cache?
```
A) cache_mem
B) cache_dir
C) cache_storage
D) disk_cache
```

### Question 4
What does the `visible_hostname` directive do in Squid?
```
A) Sets the hostname that Squid binds to
B) Sets the hostname Squid reports in error pages and Via headers
C) Sets the DNS hostname of the origin server
D) Sets the admin contact email
```

### Question 5
In Nginx, what does `proxy_set_header X-Real-IP $remote_addr;` do?
```
A) Sets the real IP of the backend server
B) Passes the client's real IP to the backend
C) Sets the proxy's own IP address
D) Verifies the client's IP against a whitelist
```

### Question 6
Which Nginx upstream directive provides consistent session persistence based on the client IP?
```
A) least_conn
B) ip_hash
C) random
D) round_robin
```

### Question 7
In HAProxy, what is the purpose of the `stick-table` directive?
```
A) To define which servers are available
B) To create a table mapping client attributes to backend servers for session persistence
C) To stick a server to a specific port
D) To configure sticky timeouts for health checks
```

### Question 8
What does `option forwardfor` do in HAProxy?
```
A) Forwards the request to a different backend
B) Adds the X-Forwarded-For header with the client IP
C) Forwards the connection immediately without buffering
D) Enables fast-forward mode for TCP
```

### Question 9
Which of the following is NOT a valid cache status in Nginx?
```
A) HIT
B) MISS
C) STALE
D) FORWARD
```

### Question 10
What is the PROXY protocol used for?
```
A) To encrypt traffic between proxies
B) To preserve the original client IP across multiple proxy hops
C) To proxy FTP connections through HTTP
D) To authenticate clients to the proxy
```

### Question 11
In Squid, what is the purpose of `refresh_pattern`?
```
A) To automatically refresh the Squid configuration file
B) To control how Squid determines if a cached object is fresh enough to serve
C) To refresh the DNS cache
D) To periodically rotate the log files
```

### Question 12
Which HAProxy algorithm sends requests to the server with the fewest active connections?
```
A) roundrobin
B) leastconn
C) source
D) uri
```

### Question 13
How does a transparent proxy differ from a standard forward proxy?
```
A) Transparent proxy does not cache content
B) Transparent proxy operates without client-side configuration using network interception
C) Transparent proxy only works with HTTPS
D) Transparent proxy requires authentication by default
```

### Question 14
What Linux syscall does HAProxy use for zero-copy data forwarding?
```
A) recv()
B) send()
C) splice()
D) mmap()
```

### Question 15
In a multi-tier proxy architecture (HAProxy → Nginx → Backend), how should backend servers retrieve the true client IP?
```
A) From $remote_addr (Nginx) and src IP (HAProxy)
B) From the X-Forwarded-For header added by HAProxy, with set_real_ip_from configured on Nginx
C) Randomly guess from the available headers
D) The true client IP is lost and cannot be recovered
```

---

**Score:** 12/15 correct = ready for Part 46.

**Answers:** 1-C, 2-B, 3-B, 4-B, 5-B, 6-B, 7-B, 8-B, 9-D, 10-B, 11-B, 12-B, 13-B, 14-C, 15-B

---

*Previous → Part 44: Mail Servers — Postfix*
*Next → Part 46: Monitoring and Alerting*

[← Previous](part44.md) | [Next →](part46.md)
