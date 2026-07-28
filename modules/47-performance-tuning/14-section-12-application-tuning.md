## 🔍 Section 12: Application Tuning

### Database Connection Pooling

Opening a database connection is expensive (TCP handshake + TLS + auth). Connection pooling reuses connections:

**PostgreSQL — PgBouncer:**

```bash
# Install
sudo apt install pgbouncer

# /etc/pgbouncer/pgbouncer.ini
cat <<EOF | sudo tee /etc/pgbouncer/pgbouncer.ini
[databases]
mydb = host=127.0.0.1 port=5432 dbname=mydb

[pgbouncer]
listen_addr = 127.0.0.1
listen_port = 6432
auth_type = scram-sha-256
auth_file = /etc/pgbouncer/userlist.txt
pool_mode = transaction   # best for web workloads
default_pool_size = 25    # per database
max_client_conn = 100
EOF
```

**MySQL — ProxySQL:**

```
mysql> INSERT INTO mysql_servers (hostgroup_id, hostname, port) VALUES (1, '127.0.0.1', 3306);
mysql> INSERT INTO mysql_users (username, password, default_hostgroup) VALUES ('app', 'pass', 1);
mysql> SET mysql-max_connections = 200;
mysql> LOAD MYSQL SERVERS TO RUNTIME; LOAD MYSQL USERS TO RUNTIME; SAVE CONFIG TO DISK;
```

### Web Server Tuning

**Nginx:**

```bash
# /etc/nginx/nginx.conf
worker_processes auto;              # one per CPU core
worker_connections 4096;            # connections per worker
use epoll;                          # efficient event loop

# Enable sendfile (zero-copy)
sendfile on;
tcp_nopush on;
tcp_nodelay on;

# Buffers
client_body_buffer_size 128k;
client_max_body_size 10m;
```

**Apache — MPM Event:**

```bash
# Enable MPM event (Apache 2.4+, higher performance than prefork)
sudo a2dismod mpm_prefork
sudo a2enmod mpm_event

# /etc/apache2/mods-available/mpm_event.conf
<IfModule mpm_event_module>
    StartServers         2
    MinSpareThreads      25
    MaxSpareThreads      75
    ThreadLimit          64
    ThreadsPerChild      25
    MaxRequestWorkers    150
    MaxConnectionsPerChild 10000
</IfModule>
```

### PHP-FPM Tuning

```bash
# /etc/php/8.2/fpm/pool.d/www.conf

pm = dynamic                    # start, grow, shrink children
pm.max_children = 50            # max PHP processes (memory bound)
pm.start_servers = 10
pm.min_spare_servers = 5
pm.max_spare_servers = 20
pm.max_requests = 500           # recycle after N requests (avoid memory leaks)

# Opcache (PHP bytecode cache)
# /etc/php/8.2/cli/conf.d/10-opcache.ini
opcache.enable=1
opcache.memory_consumption=256   # MB of shared memory for opcache
opcache.interned_strings_buffer=16
opcache.max_accelerated_files=10000
opcache.revalidate_freq=2
opcache.fast_shutdown=1
```

### Redis/Memcached Caching Patterns

**Cache-aside (lazy population):**

```python
def get_user(user_id):
    user = cache.get(f"user:{user_id}")
    if not user:
        user = db.query("SELECT * FROM users WHERE id = %s", user_id)
        cache.set(f"user:{user_id}", user, ttl=300)
    return user
```

**Write-through:**

```python
def update_user(user_id, data):
    db.execute("UPDATE users SET ... WHERE id = %s", data)
    cache.set(f"user:{user_id}", data, ttl=300)
```

### JVM Tuning

```bash
# Heap sizing
java -Xms4g -Xmx4g \              # min and max heap (same = no resizing)
     -XX:+UseG1GC \               # G1 garbage collector (latency-friendly)
     -XX:MaxGCPauseMillis=100 \   # target max GC pause
     -XX:+ParallelRefProcEnabled \
     -XX:+DisableExplicitGC \
     -jar myapp.jar
```

**JVM heap sizing rules of thumb:**

| App Type | Heap | GC | Notes |
|----------|------|----|-------|
| Web app | 2-4 GB | G1GC | Low latency |
| Batch processing | Up to 80% RAM | ParallelGC | High throughput |
| Microservices | 256 MB - 1 GB | G1GC or Shenandoah | Fast startup |
| Monolith | 8-32 GB | G1GC | Watch for long GC pauses |





[← Previous](13-section-11-benchmarking.md) | [↑ Index](index.md) | [Next →](15-section-13-capacity-planning.md)
