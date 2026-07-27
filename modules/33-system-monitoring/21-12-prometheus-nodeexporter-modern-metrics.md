## 12. Prometheus + `node_exporter` — Modern Metrics Stack

Prometheus is a pull-based monitoring system. `node_exporter` exposes Linux system metrics on an HTTP endpoint.

### Architecture

```
[Linux Host] → node_exporter (:9100/metrics) → Prometheus (scrape) → Grafana (dashboard)
```

### Installing `node_exporter`

```
$ wget https://github.com/prometheus/node_exporter/releases/download/v1.7.0/node_exporter-1.7.0.linux-amd64.tar.gz
$ tar xzf node_exporter-1.7.0.linux-amd64.tar.gz
$ sudo cp node_exporter-1.7.0.linux-amd64/node_exporter /usr/local/bin/
$ node_exporter &
$ curl http://localhost:9100/metrics
```

### Installing Prometheus

```
$ wget https://github.com/prometheus/prometheus/releases/download/v2.50.0/prometheus-2.50.0.linux-amd64.tar.gz
$ tar xzf prometheus-2.50.0.linux-amd64.tar.gz
$ cd prometheus-2.50.0.linux-amd64
```

### Configuring Prometheus (`prometheus.yml`)

```yaml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'node'
    static_configs:
      - targets:
        - 'localhost:9100'
        - 'web-server-01:9100'
        - 'db-server-01:9100'
```

### Key Metrics from `node_exporter`

| Metric | Type | Meaning |
|---|---|---|
| `node_cpu_seconds_total` | counter | CPU time per mode per core |
| `node_memory_MemAvailable_bytes` | gauge | Available memory |
| `node_disk_reads_completed_total` | counter | Total completed reads |
| `node_disk_io_time_seconds_total` | counter | Total I/O time |
| `node_filesystem_avail_bytes` | gauge | Available filesystem space |
| `node_network_receive_bytes_total` | counter | Total bytes received |
| `node_load1` | gauge | 1-minute load average |

### Rate Queries (Common Patterns)

```
# CPU utilization per core
100 - avg by (instance, cpu) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100

# Memory utilization
(1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) * 100

# Disk I/O utilization
rate(node_disk_io_time_seconds_total[5m])

# Network throughput
rate(node_network_receive_bytes_total[5m])
```

### Installing Grafana

```
$ sudo apt install grafana
$ sudo systemctl start grafana-server
```

Access at http://localhost:3000. Import dashboard ID `1860` (Node Exporter Full).

---



---

[← Previous](20-level-3-advanced-smart-prometheus.md) | [↑ Index](index.md) | [Next →](22-13-disk-health-monitoring.md)
