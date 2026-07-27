## 🔍 Section 6: Apache Logging

### CustomLog and LogFormat

```apache
# /etc/apache2/apache2.conf

LogFormat "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\"" combined
LogFormat "%h %l %u %t \"%r\" %>s %b" common
LogFormat "%{X-Forwarded-For}i %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\"" proxy

CustomLog ${APACHE_LOG_DIR}/access.log combined
ErrorLog ${APACHE_LOG_DIR}/error.log
```

| Format String | Meaning |
|---|---|
| `%h` | Client IP address |
| `%l` | Remote logname (usually `-`) |
| `%u` | Remote user (from auth) |
| `%t` | Time of the request |
| `%r` | Request line (GET /index.html HTTP/1.1) |
| `%>s` | Final status code |
| `%b` | Bytes sent (excludes headers) |
| `%{Header}i` | Value of incoming HTTP header |

### Log Rotation with `logrotate`

```bash
# /etc/logrotate.d/apache2
/var/log/apache2/*.log {
    daily
    missingok
    rotate 14
    compress
    delaycompress
    notifempty
    create 640 root adm
    sharedscripts
    postrotate
        if /etc/init.d/apache2 status > /dev/null ; then
            /etc/init.d/apache2 reload > /dev/null
        fi
    endscript
}
```

What this does:
- Rotates logs daily
- Keeps 14 days of history
- Compresses old logs (gzip)
- Reloads Apache after rotation so it opens new log files
- Without the reload, Apache keeps writing to the old (now renamed) file handle

### Piped Logs

Apache can pipe logs to an external program for processing in real-time:

```apache
CustomLog "|/usr/bin/rotatelogs /var/log/apache2/access.%Y-%m-%d.log 86400" combined
ErrorLog "|/usr/bin/rotatelogs /var/log/apache2/error.%Y-%m-%d.log 86400"
```

### Analyzing Logs

```bash
# Top 10 IPs hitting your server
sudo awk '{print $1}' /var/log/apache2/access.log | sort | uniq -c | sort -rn | head -10

# Top 10 requested pages
sudo awk '{print $7}' /var/log/apache2/access.log | sort | uniq -c | sort -rn | head -10

# HTTP status code distribution
sudo awk '{print $9}' /var/log/apache2/access.log | sort | uniq -c | sort -rn

# Requests per minute
sudo awk '{print $4}' /var/log/apache2/access.log | cut -d: -f1-2 | sort | uniq -c

# Find 404 errors
sudo grep " 404 " /var/log/apache2/access.log | awk '{print $7}' | sort | uniq -c | sort -rn

# Find slow requests (response time > 5 seconds) — requires %D in LogFormat
sudo awk '{if ($NF > 5000000) print $0}' /var/log/apache2/access.log
```

---



---

[← Previous](06-section-5-apache-performance-mpm.md) | [↑ Index](index.md) | [Next →](08-section-7-nginx-installation-and.md)
