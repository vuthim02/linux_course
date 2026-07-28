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





[← Previous](01-what-you-will-achieve-in.md) | [↑ Index](index.md) | [Next →](03-section-2-apache-installation-and.md)
