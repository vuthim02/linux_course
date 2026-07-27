## 🔍 Section 5: Apache Performance — MPM (Multi-Processing Modules)

Apache has three MPMs that determine how it handles concurrent connections. Choosing the right one is the most important performance decision.

### Prefork MPM (Default for mod_php)

- **Model:** One process per connection
- **Pros:** Stable, thread-safe, each request isolated
- **Cons:** High memory usage per connection, slow under many concurrent connections
- **Use when:** You need mod_php (PHP embedded in Apache) — libphp is not thread-safe

```apache
# /etc/apache2/mods-available/mpm_prefork.conf
<IfModule mpm_prefork_module>
    StartServers             5
    MinSpareServers          5
    MaxSpareServers         10
    MaxRequestWorkers      150
    MaxConnectionsPerChild  3000
</IfModule>
```

### Worker MPM (Threaded, Mixed)

- **Model:** Multiple processes, each with multiple threads. Each thread handles one connection.
- **Pros:** Lower memory than prefork, handles more connections
- **Cons:** Thread-safety issues with non-thread-safe modules
- **Use when:** You need mod_php is not required, you use PHP-FPM instead

```apache
<IfModule mpm_worker_module>
    StartServers             2
    MinSpareThreads         25
    MaxSpareThreads         75
    ThreadLimit             64
    ThreadsPerChild         25
    MaxRequestWorkers      150
    MaxConnectionsPerChild  3000
</IfModule>
```

### Event MPM (Async, Modern)

- **Model:** Dedicated listener threads + worker threads. The listener thread handles keep-alive connections (idle connections) separately.
- **Pros:** Best performance, lowest memory, handles 10K+ concurrent connections
- **Cons:** Requires PHP-FPM (not mod_php)
- **Use when:** Production with PHP-FPM, high-traffic sites

```apache
<IfModule mpm_event_module>
    StartServers             3
    MinSpareThreads         75
    MaxSpareThreads        250
    ThreadLimit             64
    ThreadsPerChild         25
    MaxRequestWorkers      400
    MaxConnectionsPerChild  3000
</IfModule>
```

### MPM Architecture Comparison

```
Prefork:
┌─ Process 1 ──┐  ┌─ Process 2 ──┐  ┌─ Process N ──┐
│ Request A    │  │ Request B    │  │ Request N    │
│ (blocking)   │  │ (blocking)   │  │ (blocking)   │
└──────────────┘  └──────────────┘  └──────────────┘
Memory: O(n) for n concurrent requests

Worker:
┌─ Process 1 ─────────────────┐  ┌─ Process N ─────────────────┐
│ Thread 1 │ Thread 2 │ T...  │  │ Thread 1 │ Thread 2 │ T...  │
│ Req A    │ Req B    │ ...   │  │ Req N    │ ...      │       │
└──────────────────────────────┘  └──────────────────────────────┘
Memory: O(n threads / process) — more efficient

Event:
┌─ Listener Thread ─────┐  ┌─ Worker Thread Pool ────────────┐
│ Accepts connections   │  │ Thread 1 │ Thread 2 │ T...      │
│ Handles keep-alive    │  │ Req A    │ Req B    │ ...       │
│ Passes to workers     │  │ (only while actively processing)│
└────────────────────────┘  └─────────────────────────────────┘
Best for high concurrency, keep-alive doesn't tie up workers
```

### KeepAlive

```apache
KeepAlive On
MaxKeepAliveRequests 100
KeepAliveTimeout 5
```

- `KeepAlive On` — reuse the same TCP connection for multiple requests (critical for HTTP/1.1)
- `MaxKeepAliveRequests` — max requests per connection before closing
- `KeepAliveTimeout` — how long to wait for the next request on an idle keep-alive connection

### `mod_status` — Live Server Metrics

```bash
sudo a2enmod status
```

```apache
# /etc/apache2/mods-available/status.conf
<Location "/server-status">
    SetHandler server-status
    Require local
    # Require ip 192.168.1.0/24  # For remote monitoring
</Location>
```

Visit `http://your-server/server-status` to see:

```
Apache Server Status for localhost (via ::1)
Server Version: Apache/2.4.62 (Ubuntu)
Server MPM: event

Current Time: Wednesday, 24-Jun-2026 12:00:00 UTC
Restart Time: Wednesday, 24-Jun-2026 08:00:00 UTC
Parent Server Config. Generation: 2
Parent Server MPM Generation: 1
Server uptime: 4 hours 0 minutes
Server load: 0.25 0.30 0.20
Total accesses: 15234 - Total Traffic: 234.5 MB
CPU Usage: u.24 s.12 cu0 cs0
Requests/sec: 1.06 - Bytes/sec: 16.7 KB/sec

1 requests currently being processed, 19 idle workers
```

Key fields: `_W_` (waiting/idle), `_S_` (starting), `_R_` (reading request), `_W_` (sending response), `_K_` (keepalive), `_D_` (DNS lookup).

---



---

[← Previous](05-section-4-apache-modules.md) | [↑ Index](index.md) | [Next →](07-section-6-apache-logging.md)
