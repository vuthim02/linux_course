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



---

[← Previous](02-prerequisites.md) | [↑ Index](index.md) | [Next →](04-section-2-squid-forward-proxy.md)
