## 🔍 Section 11: HAProxy Load Balancing Algorithms

### 11.1 Balance Methods

```cfg
# Round Robin (default) — distributes evenly
balance roundrobin

# Least Connections — sends to server with fewest active connections
balance leastconn

# Source IP hash — consistent hash of client IP (sticky)
balance source

# URI hash — same URI always goes to same server (good for cache)
balance uri

# URL Parameter — hash of a specific URL parameter
balance url_param user_id

# Header value — hash of an HTTP header
balance hdr(X-Session-ID)

# Random — pick a random server, weighted
balance random
```

### 11.2 Server Configuration

```cfg
backend web_back
    balance leastconn

    # Main servers
    server web1 10.0.0.10:80 weight 10 check inter 2s fall 3 rise 2
    server web2 10.0.0.11:80 weight 20 check inter 2s fall 3 rise 2
    server web3 10.0.0.12:80 weight 10 check inter 2s fall 3 rise 2

    # Backup server — only used when all main servers are down
    server backup1 10.0.0.99:80 backup

    # Disabled server (manual maintenance)
    server web4 10.0.0.13:80 disabled
```

| Server Option | Description |
|---------------|-------------|
| `weight N` | Relative weight for load distribution (default: 1) |
| `check` | Enable health checks |
| `inter N` | Health check interval in milliseconds |
| `fall N` | Number of failed checks before marking server DOWN |
| `rise N` | Number of successful checks before marking server UP |
| `backup` | Only used when all non-backup servers are down |
| `disabled` | Manually disabled |
| `slowstart N` | Gradually increase weight after coming up |

### 11.3 Stick-Table Persistence

```cfg
backend web_back
    balance roundrobin

    # Stick table stores mapping of client IP → selected server
    stick-table type ip size 200k expire 30m
    stick on src

    server web1 10.0.0.10:80 check
    server web2 10.0.0.11:80 check
    server web3 10.0.0.12:80 check
```

**Stick by cookie:**

```cfg
backend web_back
    balance roundrobin

    # Insert a cookie to track which server
    cookie SERVERID insert indirect nocache

    server web1 10.0.0.10:80 check cookie srv1
    server web2 10.0.0.11:80 check cookie srv2
    server web3 10.0.0.12:80 check cookie srv3
```

### 11.4 Health Check Tuning

```cfg
backend web_back
    # HTTP health check (expects 200 status)
    option httpchk GET /health HTTP/1.1\r\nHost:\ example.com

    # Or TCP health check (just test port is open)
    # option tcp-check

    server web1 10.0.0.10:80 check inter 1s fall 2 rise 2
    server web2 10.0.0.11:80 check inter 1s fall 2 rise 2
```

---



---

[← Previous](12-section-10-haproxy-installation-and.md) | [↑ Index](index.md) | [Next →](14-section-12-haproxy-advanced-features.md)
