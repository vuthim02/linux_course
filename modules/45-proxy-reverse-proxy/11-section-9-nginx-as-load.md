## 🔍 Section 9: Nginx as Load Balancer

### 9.1 Basic TCP/UDP Load Balancing (Stream Module)

```nginx
# /etc/nginx/nginx.conf

# In the main context, load the stream module
# (usually baked in by default)

stream {
    upstream mysql_backend {
        least_conn;
        server 10.0.0.10:3306;
        server 10.0.0.11:3306;
        server 10.0.0.12:3306 backup;
    }

    server {
        listen 3306;
        proxy_pass mysql_backend;
        proxy_connect_timeout 10s;
        proxy_timeout 30s;
    }
}
```

### 9.2 HTTP Load Balancing with Health Checks

```nginx
upstream web_servers {
    # Passive health checks
    server 10.0.0.10:80 max_fails=3 fail_timeout=30s;
    server 10.0.0.11:80 max_fails=3 fail_timeout=30s;
    server 10.0.0.12:80 max_fails=3 fail_timeout=30s;

    # Slow start — gradually increase traffic to recovering server
    server 10.0.0.13:80 slow_start=30s;
}

server {
    listen 80;
    server_name lb.example.com;

    # Health check endpoint (simulate)
    location /health {
        proxy_pass http://web_servers;
        health_check interval=5s fails=3 passes=2;
    }

    location / {
        proxy_pass http://web_servers;
    }
}
```

### 9.3 Zone Sync (Nginx Plus)

```nginx
# Shared state across Nginx instances (commercial)
upstream backend {
    zone backend 64k;
    server 10.0.0.10:80;
    server 10.0.0.11:80;
}

server {
    listen 80;
    server_name lb.example.com;
    status_zone lb.example.com;

    location / {
        proxy_pass http://backend;
    }
}
```





[← Previous](10-section-8-nginx-caching.md) | [↑ Index](index.md) | [Next →](12-section-10-haproxy-installation-and.md)
