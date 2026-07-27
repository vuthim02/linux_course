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



---

[← Previous](10-section-9-nginx-as-reverse.md) | [↑ Index](index.md) | [Next →](12-section-11-tlsssl-lets-encrypt.md)
