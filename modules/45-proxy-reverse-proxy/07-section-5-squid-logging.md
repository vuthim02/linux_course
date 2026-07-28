## 🔍 Section 5: Squid Logging

### 5.1 Log Files

| Log File | Path | Contents |
|----------|------|----------|
| Access log | `/var/log/squid/access.log` | Every request: timestamp, client IP, method, URL, status, bytes, hierarchy |
| Cache log | `/var/log/squid/cache.log` | Squid daemon messages: startup, errors, cache events |
| Store log | `/var/log/squid/store.log` | Cache object add/remove events (debugging) |

### 5.2 Access Log Format

```bash
sudo tail -f /var/log/squid/access.log
```

Default format (squid native):
```
1718995200.482    123 192.168.1.10 TCP_MISS/200 592 GET http://example.com/ - DIRECT/93.184.216.34 text/html
```

| Field | Meaning |
|-------|---------|
| `1718995200.482` | Unix timestamp (seconds.microseconds) |
| `123` | Response time (milliseconds) |
| `192.168.1.10` | Client IP |
| `TCP_MISS/200` | Cache result / HTTP status |
| `592` | Bytes transferred |
| `GET` | HTTP method |
| `http://example.com/` | Full URL |
| `-` | User identity (if authenticated) |
| `DIRECT/93.184.216.34` | Hierarchy code / server IP |
| `text/html` | Content type |

### 5.3 Custom Log Format

```apache
# Define a custom log format
logformat combined %tl %6tr %>a %Ss/%03>Hs %<st %rm %ru %un %Sh/%<A %mt

# Use it
access_log /var/log/squid/access.log combined

# Apache Common Log Format (for log analyzers)
logformat common %>a %[ui %[un [%tl] "%rm %ru HTTP/%rv" %>Hs %<st
access_log /var/log/squid/access.log common
```

### 5.4 Log Rotation

Squid handles log rotation natively:

```apache
# Rotate logs daily and keep 10 rotated versions
logfile_rotate 10
```

Rotation command:

```bash
# Manual rotation
sudo squid -k rotate

# Cron-based rotation (daily)
echo "0 0 * * * root /usr/sbin/squid -k rotate" | sudo tee /etc/cron.d/squid-rotate
```

### 5.5 Log Analysis

```bash
# Install SquidAnalyzer
sudo apt install squidanalyzer -y

# Configure
sudo nano /etc/squidanalyzer/squidanalyzer.conf

# Generate report
sudo squidanalyzer -f /var/log/squid/access.log

# View report (served via web)
sudo systemctl start squidanalyzer
# http://your-server:8080/squidanalyzer

# Quick stats with command line
echo "Top 10 requested URLs:"
awk '{print $7}' /var/log/squid/access.log | sort | uniq -c | sort -rn | head -10

echo "Cache hit/miss ratio:"
awk '{print $4}' /var/log/squid/access.log | cut -d'/' -f1 | sort | uniq -c | sort -rn

echo "Top 10 users by bandwidth:"
awk '{print $3, $6, $8}' /var/log/squid/access.log | awk '{sum[$1]+=$3} END {for (u in sum) print sum[u], u}' | sort -rn | head -10
```





[← Previous](06-section-4-squid-caching.md) | [↑ Index](index.md) | [Next →](08-section-6-squid-reverse-proxy.md)
