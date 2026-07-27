## 4. Prometheus Exporters

**node_exporter:** System metrics (CPU, memory, disk, network, load). ~700 series/host.

```bash
wget https://github.com/prometheus/node_exporter/releases/download/v1.8.2/node_exporter-1.8.2.linux-amd64.tar.gz
tar xzf node_exporter-1.8.2.linux-amd64.tar.gz
sudo mv node_exporter-1.8.2.linux-amd64/node_exporter /usr/local/bin/
```

```ini
[Unit]
Description=Node Exporter
After=network.target
[Service]
User=node_exporter
ExecStart=/usr/local/bin/node_exporter --collector.systemd --collector.processes
[Install]
WantedBy=multi-user.target
```

Key metrics: `node_cpu_seconds_total{cpu,mode}`, `node_memory_Mem*_bytes`, `node_filesystem_*_bytes{mountpoint}`, `node_network_*_bytes_total{device}`, `node_load{1,5,15}`.

**blackbox_exporter:** Probes HTTP/DNS/TCP/ICMP endpoints.

```yaml
# /etc/blackbox_exporter/blackbox.yml
modules:
  http_2xx:
    prober: http
    http:
      valid_status_codes: [200, 301, 302]
      follow_redirects: true
  tcp_connect:
    prober: tcp
  icmp_ping:
    prober: icmp
```

Prometheus scrape config:
```yaml
  - job_name: blackbox-http
    metrics_path: /probe
    params: {module: [http_2xx]}
    static_configs:
      - targets: ['https://example.com', 'https://api.example.com/health']
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - target_label: __address__
        replacement: 127.0.0.1:9115
```

**mysqld_exporter:**
```bash
DATA_SOURCE_NAME="exporter:password@tcp(localhost:3306)/"
./mysqld_exporter
```
Metrics: `mysql_global_status_queries`, `mysql_slave_status_seconds_behind_master`.

**postgres_exporter:**
```bash
DATA_SOURCE_NAME="postgresql://exporter:password@localhost:5432/postgres?sslmode=disable"
./postgres_exporter
```
Metrics: `pg_stat_database_tup_fetched{database}`, `pg_replication_lag`.

**nginx_exporter:**
```bash
./nginx-prometheus-exporter --nginx.scrape-uri=http://localhost:8080/stub_status
```

**redis_exporter:**
```bash
./redis_exporter --redis.addr=redis://localhost:6379
```
Metrics: `redis_memory_used_bytes`, `redis_keyspace_hits_total`.

**haproxy_exporter:**
```bash
./haproxy_exporter --haproxy.scrape-uri=http://localhost:8404/haproxy?stats;csv
```

**textfile collector (custom metrics):**
```bash
#!/bin/bash
echo "# HELP custom_users_logged_in Active users"
echo "# TYPE custom_users_logged_in gauge"
echo "custom_users_logged_in $(who | wc -l)"
```
Output to `/var/lib/node_exporter/textfile_collector/custom.prom` via cron. Enable with `--collector.textfile.directory=/var/lib/node_exporter/textfile_collector`.

---



---

[← Previous](03-3-advanced-promql.md) | [↑ Index](index.md) | [Next →](05-5-prometheus-service-discovery-and.md)
