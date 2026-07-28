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





[← Previous](12-section-11-tlsssl-lets-encrypt.md) | [↑ Index](index.md) | [Next →](14-section-13-static-file-serving.md)
