## 🔍 Section 7: Prometheus

### 7.1 Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      Prometheus Ecosystem                     │
│                                                              │
│  ┌──────────┐    scrape     ┌──────────────┐                │
│  │ Service  │◄──────────────│  Prometheus  │                │
│  │ Discovery│               │    Server    │                │
│  │(K8s,DNS, │               │  (TSDB)      │                │
│  │ file_sd) │               └──────┬───────┘                │
│  └──────────┘                      │                        │
│                                    │                        │
│               ┌────────────────────┼──────────────────┐     │
│               ▼                    ▼                  ▼     │
│        ┌──────────┐       ┌──────────────┐    ┌──────────┐ │
│        │  Push    │       │ Alertmanager │    │  Grafana │ │
│        │ Gateway  │       │(alerts,      │    │(dashboards│ │
│        │(short-   │       │ grouping,    │    │, queries) │ │
│        │ lived)   │       │ inhibit)     │    └──────────┘ │
│        └──────────┘       └──────────────┘                 │
│                                                              │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐       │
│  │ node_    │ │ blackbox_│ │ mysql_   │ │ nginx_   │       │
│  │ exporter │ │ exporter │ │ exporter │ │ exporter │       │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘       │
└─────────────────────────────────────────────────────────────┘

Components:
  Prometheus Server    — Scrapes metrics, stores TSDB, evaluates rules
  Exporters            — Expose metrics from various systems on /metrics
  Alertmanager         — Handles alerts: dedup, group, route, silence
  Pushgateway          — Accepts pushed metrics from short-lived jobs
  Service Discovery    — Automatically finds targets
  Grafana              — Visualization and dashboarding
```

### 7.2 Installation

```bash
# Download and install Prometheus
wget https://github.com/prometheus/prometheus/releases/download/v2.53.0/prometheus-2.53.0.linux-amd64.tar.gz
tar xzf prometheus-2.53.0.linux-amd64.tar.gz
sudo mv prometheus-2.53.0.linux-amd64 /opt/prometheus

# Create user
sudo useradd --no-create-home --shell /bin/false prometheus
sudo mkdir -p /var/lib/prometheus
sudo chown prometheus:prometheus /var/lib/prometheus

# Create systemd service
sudo tee /etc/systemd/system/prometheus.service << 'EOF'
[Unit]
Description=Prometheus
Documentation=https://prometheus.io/docs/
After=network.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/opt/prometheus/prometheus \
    --config.file=/opt/prometheus/prometheus.yml \
    --storage.tsdb.path=/var/lib/prometheus/ \
    --web.console.templates=/opt/prometheus/consoles \
    --web.console.libraries=/opt/prometheus/console_libraries \
    --web.listen-address=0.0.0.0:9090
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl start prometheus
sudo systemctl enable prometheus

# Verify
curl http://localhost:9090/metrics | head -20
```

### 7.3 prometheus.yml Configuration

```yaml
# /opt/prometheus/prometheus.yml

global:
  scrape_interval:     15s
  evaluation_interval: 15s
  scrape_timeout:      10s

alerting:
  alertmanagers:
    - static_configs:
        - targets:
          - localhost:9093

rule_files:
  - "alerts/*.yml"
  - "rules/*.yml"

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'node'
    static_configs:
      - targets:
        - '10.0.0.10:9100'
        - '10.0.0.11:9100'
        - '10.0.0.12:9100'

  - job_name: 'blackbox'
    metrics_path: /probe
    params:
      module: [http_2xx]
    static_configs:
      - targets:
        - 'https://example.com'
        - 'https://api.example.com/health'
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: 127.0.0.1:9115

  - job_name: 'mysql'
    static_configs:
      - targets: ['10.0.0.12:9104']

  - job_name: 'cadvisor'
    static_configs:
      - targets: ['10.0.0.10:8080']

  - job_name: 'custom_exporters'
    file_sd_configs:
      - files:
        - '/opt/prometheus/targets/*.json'
        refresh_interval: 5m
```

### 7.4 Service Discovery Files

```json
// /opt/prometheus/targets/webservers.json
[
  {
    "targets": ["10.0.0.10:9100", "10.0.0.11:9100"],
    "labels": {
      "env": "production",
      "role": "web"
    }
  },
  {
    "targets": ["10.0.0.12:9100"],
    "labels": {
      "env": "production",
      "role": "database"
    }
  }
]
```

### 7.5 Metrics Model

| Metric Type | Description | Example | Use Case |
|-------------|-------------|---------|----------|
| **Counter** | Only increases (or resets to 0) | `http_requests_total` | Request count, errors |
| **Gauge** | Can go up or down | `node_memory_MemAvailable_bytes` | CPU, memory, disk |
| **Histogram** | Samples in configurable buckets | `http_request_duration_seconds_bucket` | Latency percentiles |
| **Summary** | Pre-computed quantiles on client side | `rpc_duration_seconds` | Pre-computed percentiles |

```bash
# Counter: always goes up (or resets to 0 on restart)
prometheus_http_requests_total{handler="/metrics",code="200"} 1024

# Gauge: can go up and down
node_memory_MemAvailable_bytes 2.45e+10

# Histogram: observe into buckets
http_request_duration_seconds_bucket{le="0.1"}  500
http_request_duration_seconds_bucket{le="0.5"}  800
http_request_duration_seconds_bucket{le="1"}    950
http_request_duration_seconds_bucket{le="+Inf"} 1000
http_request_duration_seconds_sum               450.0
http_request_duration_seconds_count             1000

# Summary: quantiles pre-computed
rpc_duration_seconds{quantile="0.5"}  0.05
rpc_duration_seconds{quantile="0.9"}  0.1
rpc_duration_seconds{quantile="0.99"} 0.3
rpc_duration_seconds_sum              450.0
rpc_duration_seconds_count            1000
```

---



---

[← Previous](08-section-6-zabbix-auto-discovery.md) | [↑ Index](index.md) | [Next →](10-section-8-promql-prometheus-query.md)
