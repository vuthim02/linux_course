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



---

[← Previous](07-section-5-squid-logging.md) | [↑ Index](index.md) | [Next →](09-section-7-nginx-as-reverse.md)
