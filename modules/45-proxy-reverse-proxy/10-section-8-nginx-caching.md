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



---

[← Previous](09-section-7-nginx-as-reverse.md) | [↑ Index](index.md) | [Next →](11-section-9-nginx-as-load.md)
