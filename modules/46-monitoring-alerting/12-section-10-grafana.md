## 🔍 Section 10: Grafana

### 10.1 Installation

```bash
sudo apt install -y software-properties-common
sudo add-apt-repository "deb https://packages.grafana.com/oss/deb stable main"
wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -
sudo apt update && sudo apt install grafana -y

sudo systemctl daemon-reload
sudo systemctl start grafana-server
sudo systemctl enable grafana-server

# Access: http://your-server:3000
# Default login: admin / admin
```

### 10.2 Configuration

```ini
# /etc/grafana/grafana.ini

[server]
protocol = http
http_addr =
http_port = 3000
domain = your-server.example.com
root_url = %(protocol)s://%(domain)s:%(http_port)s/

[security]
admin_user = admin
admin_password = admin
secret_key = changeme

[auth.anonymous]
enabled = false

[alerting]
enabled = true
execute_alerts = true
```

### 10.3 Data Sources

```bash
# From the Grafana Web UI:
# Configuration → Data Sources → Add data source

# ── Prometheus ──
# Name:    Prometheus
# Type:    Prometheus
# URL:     http://localhost:9090
# Access:  Server (default)

# ── Zabbix ── (requires alexanderzobnin-zabbix plugin)
# Name:    Zabbix
# Type:    Zabbix
# URL:     http://localhost/api_jsonrpc.php

# ── Loki ──
# Name:    Loki
# Type:    Loki
# URL:     http://localhost:3100

# Install Zabbix plugin
grafana-cli plugins install alexanderzobnin-zabbix-app
sudo systemctl restart grafana-server
```

### 10.4 Dashboard Panels

| Panel Type | Use Case | Example |
|------------|----------|---------|
| **Time Series** | Line charts over time | CPU usage, network traffic |
| **Stat** | Single value display | Current memory usage |
| **Gauge** | Value within a range | Disk usage (0-100%) |
| **Table** | Tabular data | Top processes, host list |
| **Heatmap** | Distribution over time | Request latency distribution |
| **Bar Gauge** | Horizontal/vertical bars | Compare disk usage across hosts |
| **Logs** | Log lines from Loki | Real-time log streaming |
| **State Timeline** | State changes over time | Host up/down timeline |

### 10.5 Building a Dashboard

```bash
cat > dashboard.json << 'EOF'
{
  "dashboard": {
    "title": "Linux Server Overview",
    "tags": ["linux", "production"],
    "timezone": "browser",
    "panels": [
      {
        "title": "CPU Utilization",
        "type": "timeseries",
        "datasource": "Prometheus",
        "gridPos": {"h": 8, "w": 12, "x": 0, "y": 0},
        "targets": [{
          "expr": "100 - (avg by(instance) (rate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100)",
          "legendFormat": "{{instance}}"
        }]
      },
      {
        "title": "Memory Usage",
        "type": "gauge",
        "datasource": "Prometheus",
        "gridPos": {"h": 8, "w": 6, "x": 12, "y": 0},
        "targets": [{
          "expr": "(node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes * 100"
        }],
        "options": {"min": 0, "max": 100, "thresholds": [
          {"value": 80, "color": "orange"},
          {"value": 90, "color": "red"}
        ]}
      },
      {
        "title": "Network Traffic",
        "type": "timeseries",
        "datasource": "Prometheus",
        "gridPos": {"h": 8, "w": 12, "x": 0, "y": 8},
        "targets": [
          {"expr": "rate(node_network_receive_bytes_total[5m])", "legendFormat": "{{instance}} RX"},
          {"expr": "rate(node_network_transmit_bytes_total[5m])", "legendFormat": "{{instance}} TX"}
        ]
      },
      {
        "title": "System Uptime",
        "type": "stat",
        "datasource": "Prometheus",
        "gridPos": {"h": 4, "w": 4, "x": 12, "y": 8},
        "targets": [{"expr": "time() - node_boot_time_seconds", "legendFormat": "uptime"}],
        "options": {"unit": "s"}
      }
    ],
    "refresh": "30s"
  },
  "overwrite": true
}
EOF

# Import via API
curl -X POST -H "Authorization: Bearer $(curl -s -X POST -H \"Content-Type: application/json\" -d '{\"user\":\"admin\",\"password\":\"admin\"}' http://localhost:3000/api/login | jq -r '.accessToken')" http://localhost:3000/api/dashboards/db -d @dashboard.json
```

### 10.6 Grafana Alerting (Unified Alerting)

```yaml
# Grafana unified alerting works across ALL data sources

# Alert rule (via UI):
#   Alerting → Alert rules → New alert rule
#
#   Rule name:   High CPU Usage
#   Query:
#     Data source: Prometheus
#     Query: 100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)
#     Evaluate: every 1m for 5m
#   Condition: WHEN last() OF query(A, 5m, 0) IS ABOVE 90
#   Labels: severity=critical, team=platform
#   Annotations:
#     summary: "CPU usage on {{ $labels.instance }} is {{ $values.A | humanize }}%"
#
#   Notifications:
#     Contact point: email-alert
#     Repeat interval: 4h

# Contact points:
#   Alerting → Contact points → New contact point
#
#   Email:
#     Type: Email | Addresses: admin@example.com
#
#   Slack:
#     Type: Slack | Webhook URL: https://hooks.slack.com/services/...
#     Channel: #alerts
#
#   PagerDuty:
#     Type: PagerDuty | Integration key: xxxxxx
#
#   Webhook:
#     Type: Webhook | URL: https://hooks.example.com/alert
```





[← Previous](11-section-9-prometheus-exporters.md) | [↑ Index](index.md) | [Next →](13-section-11-alerting.md)
