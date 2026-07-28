## 📝 Section 10: Logging

### 10.1 Query Logging

**Config method:**

```c
options { querylog yes; };
```

**Runtime toggle:**

```bash
sudo rndc querylog on
sudo rndc querylog off
```

Query log format:
```
24-Jun-2026 14:32:15.123 queries: client 192.168.1.100#54321 (www.google.com): query: www.google.com IN A + (192.168.1.10)
```

### 10.2 Log Rotation

Built-in: `file "path.log" versions 3 size 50m;`

External logrotate (`/etc/logrotate.d/named`):

```bash
/var/log/named/*.log {
    daily
    rotate 30
    compress
    delaycompress
    postrotate
        /usr/sbin/rndc reload 2>&1 > /dev/null || true
    endscript
}
```

### 10.3 Debugging with rndc

```bash
sudo rndc trace 3           # Set debug level
sudo rndc notrace           # Disable debugging
sudo rndc dumpdb -cache     # Dump cache to file
sudo rndc stats             # Dump statistics
sudo journalctl -u named -f # Follow live logs
```





[← Previous](13-section-9-access-control.md) | [↑ Index](index.md) | [Next →](15-section-11-tuning-and-performance.md)
