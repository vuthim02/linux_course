## 🔍 Section 13: Static File Serving — Optimization

### sendfile (Zero-Copy)

The `sendfile()` system call copies data directly from disk to network socket **without going through userspace**. This means:

- No copying from kernel → userspace → kernel (2 copies → 0 copies)
- CPU is free to do other work
- Dramatically faster for large static files

```
Without sendfile:
Disk → Kernel buffer → Userspace buffer → Kernel socket buffer → Network
         copy #1          copy #2          copy #3       

With sendfile:
Disk → Kernel buffer → Network (directly DMA)
         zero copies through userspace
```

```nginx
sendfile on;      # Nginx
```

```apache
EnableSendfile on;   # Apache
```

### Direct I/O

For very large files, bypass the page cache entirely to avoid cache pollution:

```nginx
location /videos/ {
    directio 4m;          # Use direct I/O for files > 4MB
    sendfile on;
}
```

### Expires Headers — Cache Control

```nginx
location ~* \.(jpg|jpeg|png|gif|webp|ico)$ {
    expires 30d;
    add_header Cache-Control "public, immutable";
}

location ~* \.(css|js)$ {
    expires 1y;
    add_header Cache-Control "public, immutable";
}

location ~* \.(html|htm)$ {
    expires 10m;
}
```

### Gzip Compression

```nginx
gzip on;
gzip_vary on;
gzip_proxied any;
gzip_comp_level 6;                  # 1-9 (1=fast, 9=max compression)
gzip_min_length 256;                # Don't compress tiny files
gzip_disable "msie6";
gzip_types
    text/plain
    text/css
    text/javascript
    application/javascript
    application/json
    application/xml
    application/rss+xml
    image/svg+xml;
```

For Apache:

```apache
AddOutputFilterByType DEFLATE text/html text/plain text/css application/javascript
```

### Brotli Compression (Better than Gzip)

Brotli typically achieves 20-30% better compression than gzip.

```bash
# Install brotli module for nginx
sudo apt install nginx-extras
```

```nginx
brotli on;
brotli_comp_level 6;
brotli_types text/plain text/css application/javascript application/json image/svg+xml;
```

### Caching Headers Explained

| Header | Meaning | Value |
|--------|---------|-------|
| `Cache-Control: public` | Any cache (CDN, browser) may cache | Public content |
| `Cache-Control: private` | Only browser may cache (not CDN) | User-specific content |
| `Cache-Control: no-cache` | Must revalidate with server | Dynamic content |
| `Cache-Control: no-store` | Never cache | Sensitive data |
| `Cache-Control: immutable` | Never revalidate within max-age | Versioned assets |
| `Expires: ...` | HTTP/1.0 fallback for Cache-Control | Date in future |
| `ETag: "abc123"` | Content hash for conditional requests | Hash value |
| `Last-Modified: ...` | Date-based revalidation | Date |

---



---

[← Previous](13-section-12-comparison-apache-vs.md) | [↑ Index](index.md) | [Next →](15-practice-section-15-hands-on-exercises.md)
