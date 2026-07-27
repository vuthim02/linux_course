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



---

[← Previous](15-section-13-proxy-chaining-and.md) | [↑ Index](index.md) | [Next →](17-section-15-security.md)
