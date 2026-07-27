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



---

[← Previous](14-section-12-haproxy-advanced-features.md) | [↑ Index](index.md) | [Next →](16-section-14-proxy-protocol.md)
