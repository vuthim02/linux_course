## 🔍 Section 9: Nginx as Reverse Proxy

### Basic Reverse Proxy

```nginx
server {
    listen 80;
    server_name app.example.com;

    location / {
        proxy_pass http://127.0.0.1:3000;          # Backend address
        proxy_set_header Host $host;                # Preserve original Host
        proxy_set_header X-Real-IP $remote_addr;    # Client real IP
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme; # Original protocol (http/https)

        # Timeouts
        proxy_connect_timeout 5s;
        proxy_read_timeout 60s;
        proxy_send_timeout 60s;

        # Buffering
        proxy_buffering on;
        proxy_buffer_size 4k;
        proxy_buffers 8 4k;
    }
}
```

### WebSocket Proxy

```nginx
location /ws/ {
    proxy_pass http://backend:8080;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_set_header Host $host;
    proxy_read_timeout 86400s;   # Long timeout for persistent connections
}
```

### `upstream` Blocks — Load Balancing

```nginx
upstream backend_servers {
    # Load balancing method
    # least_conn;           # Send to server with fewest connections
    # ip_hash;              # Sticky sessions based on client IP
    # hash $request_uri;    # Consistent hashing based on URI

    server 10.0.0.1:8080 weight=3 max_fails=3 fail_timeout=30s;
    server 10.0.0.2:8080 weight=1 max_fails=3 fail_timeout=30s;
    server 10.0.0.3:8080 backup;               # Backup, only used if others fail
    server 10.0.0.4:8080 down;                 # Manually disabled
}

server {
    listen 80;
    server_name app.example.com;

    location / {
        proxy_pass http://backend_servers;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

### Proxy Headers Explained

| Header | Purpose |
|--------|---------|
| `X-Real-IP` | Single client IP address |
| `X-Forwarded-For` | Comma-separated list of IPs in the chain |
| `X-Forwarded-Proto` | Original protocol (http or https) |
| `X-Forwarded-Host` | Original Host header value |

Backend apps need to be configured to trust these headers, otherwise they log Nginx's IP instead of the real client.





[← Previous](09-section-8-nginx-server-blocks.md) | [↑ Index](index.md) | [Next →](11-section-10-nginx-as-load.md)
