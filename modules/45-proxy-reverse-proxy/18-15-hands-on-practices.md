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



---

[← Previous](17-section-15-security.md) | [↑ Index](index.md) | [Next →](19-deep-understanding.md)
