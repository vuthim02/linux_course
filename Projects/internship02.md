# Internship Project 02: Monitoring & Observability Stack

## Company: CloudBase Systems (Fictional)

You are hired as a **Junior Linux System Administrator Intern** at CloudBase Systems. The company has 5 production servers but **zero monitoring**. When something breaks, customers complain first. Your job: build a complete monitoring and observability stack so the team knows about problems BEFORE customers do.

---

## Project Overview

| Aspect | Details |
|--------|---------|
| **Company** | CloudBase Systems — SaaS platform, 5 servers |
| **Your Role** | Junior SysAdmin Intern |
| **Problem** | No monitoring. Reactive firefighting. |
| **Goal** | Proactive monitoring with alerts before customers notice |
| **Stack** | Prometheus + Grafana + Alertmanager + Loki + Node Exporter |
| **Duration** | 5 working days |
| **Servers** | 1 monitoring server + 3 app servers (simulated) |

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                        YOUR MONITORING STACK                       │
│                                                                     │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐             │
│  │ App Server 1│    │ App Server 2│    │ App Server 3│             │
│  │ (Node Exp.) │    │ (Node Exp.) │    │ (Node Exp.) │             │
│  └──────┬──────┘    └──────┬──────┘    └──────┬──────┘             │
│         │                  │                  │                     │
│         └──────────────────┼──────────────────┘                     │
│                            │ scrape (pull metrics)                  │
│                            ▼                                        │
│                   ┌────────────────┐                                │
│                   │   PROMETHEUS   │ ◄── Scrapes every 15s         │
│                   │  (Time Series) │     Stores 30 days             │
│                   └───────┬────────┘                                │
│                           │                                         │
│              ┌────────────┼────────────┐                            │
│              ▼            ▼            ▼                            │
│     ┌──────────────┐ ┌─────────┐ ┌──────────────┐                  │
│     │   GRAFANA    │ │  LOKI   │ │ ALERTMANAGER │                  │
│     │ (Dashboards) │ │ (Logs)  │ │  (Alerts)    │                  │
│     └──────────────┘ └─────────┘ └──────┬───────┘                  │
│                                         │                           │
│                                         ▼                           │
│                              ┌──────────────────┐                   │
│                              │  Email / Slack   │                   │
│                              │  (Notifications) │                   │
│                              └──────────────────┘                   │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Day 1: Prometheus Server Setup

### Step 1.1 — Prepare the Monitoring Server

```bash
# Create dedicated user for monitoring
sudo useradd -m -s /bin/bash monitoring
sudo usermod -aG sudo monitoring

# Update system
sudo apt update && sudo apt upgrade -y

# Install dependencies
sudo apt install -y wget curl tar adduser libfontconfig1 musl
```

### Step 1.2 — Install Prometheus

```bash
# Download Prometheus
cd /tmp
wget https://github.com/prometheus/prometheus/releases/download/v2.51.0/prometheus-2.51.0.linux-amd64.tar.gz

# Extract
tar xzf prometheus-2.51.0.linux-amd64.tar.gz
cd prometheus-2.51.0.linux-amd64

# Create directories
sudo mkdir -p /etc/prometheus /var/lib/prometheus

# Move binaries
sudo cp prometheus promtool /usr/local/bin/

# Move config and console files
sudo cp -r consoles console_libraries /etc/prometheus/

# Set ownership
sudo chown -R monitoring:monitoring /etc/prometheus /var/lib/prometheus
```

### Step 1.3 — Configure Prometheus

```bash
sudo nano /etc/prometheus/prometheus.yml
```

```yaml
# Prometheus Configuration
global:
  scrape_interval: 15s          # How often to scrape targets
  evaluation_interval: 15s      # How often to evaluate alert rules
  scrape_timeout: 10s           # Timeout for each scrape

# Alert Rules
rule_files:
  - "alerts/*.yml"

# Alertmanager configuration
alerting:
  alertmanagers:
    - static_configs:
        - targets:
            - localhost:9093

# Scrape targets
scrape_configs:
  # ============================================
  # Prometheus self-monitoring
  # ============================================
  - job_name: "prometheus"
    static_configs:
      - targets: ["localhost:9090"]
        labels:
          instance: "prometheus-server"

  # ============================================
  # Node Exporters — System metrics from all servers
  # ============================================
  - job_name: "node-exporters"
    static_configs:
      - targets:
          - "192.168.1.10:9100"    # App Server 1
          - "192.168.1.11:9100"    # App Server 2
          - "192.168.1.12:9100"    # App Server 3
        labels:
          environment: "production"

  # ============================================
  # Application metrics (if your app exposes /metrics)
  # ============================================
  - job_name: "techstore-app"
    static_configs:
      - targets: ["192.168.1.10:3000"]
        labels:
          app: "techstore"
          tier: "backend"

  # ============================================
  # PostgreSQL metrics
  # ============================================
  - job_name: "postgresql"
    static_configs:
      - targets: ["192.168.1.10:9187"]

  # ============================================
  # Redis metrics
  # ============================================
  - job_name: "redis"
    static_configs:
      - targets: ["192.168.1.10:9121"]

  # ============================================
  # Nginx metrics
  # ============================================
  - job_name: "nginx"
    static_configs:
      - targets: ["192.168.1.10:9113"]
```

### Step 1.4 — Create Alert Rules

```bash
sudo mkdir -p /etc/prometheus/alerts

sudo nano /etc/prometheus/alerts/system.yml
```

```yaml
groups:
  # ============================================
  # System Alerts
  # ============================================
  - name: system_alerts
    rules:
      # High CPU usage (>80% for 5 minutes)
      - alert: HighCpuUsage
        expr: 100 - (avg by(instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High CPU usage on {{ $labels.instance }}"
          description: "CPU usage is above 80% for more than 5 minutes. Current: {{ $value }}%"

      # Critical CPU (>95% for 2 minutes)
      - alert: CriticalCpuUsage
        expr: 100 - (avg by(instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 95
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "CRITICAL: CPU usage on {{ $labels.instance }}"
          description: "CPU usage is above 95% for more than 2 minutes!"

      # High memory usage (>85%)
      - alert: HighMemoryUsage
        expr: (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 > 85
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High memory usage on {{ $labels.instance }}"
          description: "Memory usage is above 85%. Current: {{ $value }}%"

      # Disk space low (<15% free)
      - alert: DiskSpaceLow
        expr: (node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"}) * 100 < 15
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Low disk space on {{ $labels.instance }}"
          description: "Less than 15% disk space remaining. Current: {{ $value }}%"

      # Disk space critical (<5% free)
      - alert: DiskSpaceCritical
        expr: (node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"}) * 100 < 5
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "CRITICAL: Disk space on {{ $labels.instance }}"
          description: "Less than 5% disk space remaining!"

      # Server down
      - alert: ServerDown
        expr: up{job="node-exporters"} == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Server {{ $labels.instance }} is DOWN"
          description: "Node exporter has been unreachable for more than 1 minute."

      # High network errors
      - alert: NetworkErrors
        expr: rate(node_network_receive_errs_total[5m]) > 10
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Network errors on {{ $labels.instance }}"
          description: "More than 10 network receive errors per second."

  # ============================================
  # Application Alerts
  # ============================================
  - name: application_alerts
    rules:
      # Application down
      - alert: AppDown
        expr: up{job="techstore-app"} == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Application is DOWN"
          description: "TechStore application has been unreachable for more than 1 minute."

      # High HTTP error rate (>5%)
      - alert: HighHttpErrors
        expr: rate(http_requests_total{status=~"5.."}[5m]) / rate(http_requests_total[5m]) * 100 > 5
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High HTTP error rate"
          description: "More than 5% of requests are returning 5xx errors."

      # High response time (>2 seconds)
      - alert: HighResponseTime
        expr: histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m])) > 2
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Slow response times"
          description: "95th percentile response time is above 2 seconds."
```

### Step 1.5 — Create Prometheus Systemd Service

```bash
sudo nano /etc/systemd/system/prometheus.service
```

```ini
[Unit]
Description=Prometheus Monitoring System
Documentation=https://prometheus.io/docs/
Wants=network-online.target
After=network-online.target

[Service]
User=monitoring
Group=monitoring
Type=simple
ExecStart=/usr/local/bin/prometheus \
    --config.file=/etc/prometheus/prometheus.yml \
    --storage.tsdb.path=/var/lib/prometheus/ \
    --storage.tsdb.retention.time=30d \
    --web.enable-lifecycle \
    --web.enable-admin-api
ExecReload=/bin/kill -HUP $MAINPID
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable prometheus
sudo systemctl start prometheus
sudo systemctl status prometheus
```

### Step 1.6 — Verify Prometheus

```bash
curl http://localhost:9090/-/healthy
# Should return: Prometheus Server is Healthy.

# Check targets
curl http://localhost:9090/api/v1/targets | python3 -m json.tool | head -30
```

Open in browser: `http://your_server_ip:9090`

---

## Day 2: Node Exporter (Metrics from Servers)

### Step 2.1 — Install Node Exporter on ALL Servers

Run this on **every server** you want to monitor:

```bash
# Download Node Exporter
cd /tmp
wget https://github.com/prometheus/node_exporter/releases/download/v1.7.0/node_exporter-1.7.0.linux-amd64.tar.gz

# Extract
tar xzf node_exporter-1.7.0.linux-amd64.tar.gz
cd node_exporter-1.7.0.linux-amd64

# Install binary
sudo cp node_exporter /usr/local/bin/

# Create system user
sudo useradd -rs /sbin/nologin node_exporter
```

### Step 2.2 — Create Systemd Service

```bash
sudo nano /etc/systemd/system/node_exporter.service
```

```ini
[Unit]
Description=Node Exporter
Documentation=https://prometheus.io/docs/guides/node-exporter/
Wants=network-online.target
After=network-online.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter \
    --collector.systemd \
    --collector.processes
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable node_exporter
sudo systemctl start node_exporter

# Verify
curl http://localhost:9100/metrics | head -20
```

### Step 2.3 — Open Firewall for Node Exporter

```bash
# On each monitored server
sudo ufw allow from 192.168.1.0/24 to any port 9100 proto tcp
sudo ufw reload
```

### Step 2.4 — Verify Prometheus Can Scrape

Go to Prometheus → Status → Targets. You should see all Node Exporters as "UP".

Or use the API:
```bash
curl -s http://localhost:9090/api/v1/targets | python3 -c "
import json, sys
data = json.load(sys.stdin)
for t in data['data']['activeTargets']:
    print(f\"{t['labels']['instance']:30} {t['health']:10} last_scrape: {t['lastScrape'][:19]}\")
"
```

---

## Day 3: Grafana (Dashboards)

### Step 3.1 — Install Grafana

```bash
# Add Grafana repository
sudo apt install -y apt-transport-https software-properties-common wget
sudo mkdir -p /etc/apt/keyrings/
wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor | sudo tee /etc/apt/keyrings/grafana.gpg > /dev/null

echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" | sudo tee /etc/apt/sources.list.d/grafana.list

# Install
sudo apt update
sudo apt install grafana -y

# Start
sudo systemctl enable grafana-server
sudo systemctl start grafana-server
```

### Step 3.2 — Access Grafana

Open: `http://your_server_ip:3000`

Default login:
- Username: `admin`
- Password: `admin` (change immediately!)

### Step 3.3 — Add Prometheus as Data Source

1. Grafana menu → **Connections** → **Data sources**
2. Click **Add data source**
3. Select **Prometheus**
4. URL: `http://localhost:9090`
5. Click **Save & Test** → "Data source is working"

### Step 3.4 — Import Dashboard (Node Exporter Full)

1. Grafana menu → **Dashboards** → **Import**
2. Enter ID: `1860` (Node Exporter Full — the most popular dashboard)
3. Click **Load**
4. Select Prometheus data source
5. Click **Import**

You now have a complete system monitoring dashboard with:
- CPU usage per core
- Memory usage
- Disk I/O
- Network traffic
- System load
- Uptime

### Step 3.5 — Create Custom Dashboard

1. Click **+** → **Create dashboard**
2. Click **Add visualization**

#### Panel 1: CPU Usage Gauge
```promql
100 - (avg(irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)
```
- Visualization: **Gauge**
- Min: 0, Max: 100
- Thresholds: Green < 60, Yellow < 80, Red ≥ 80

#### Panel 2: Memory Usage
```promql
(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100
```
- Visualization: **Time series**
- Unit: Percent (0-100)

#### Panel 3: Disk Space
```promql
(node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"}) * 100
```
- Visualization: **Stat**
- Unit: Percent
- Thresholds: Green > 20, Yellow > 10, Red ≤ 10

#### Panel 4: Network Traffic
```promql
rate(node_network_receive_bytes_total{device!="lo"}[5m]) * 8
```
- Visualization: **Time series**
- Unit: bits/sec (bps)

### Step 3.6 — Create Alert Dashboard

Create a new dashboard called "Alert Overview":

#### Panel: Active Alerts
```promql
ALERTS{alertstate="firing"}
```
- Visualization: **Table**

#### Panel: Alert History
```promql
changes(ALERTS{alertstate="firing"}[1h])
```
- Visualization: **Bar chart**

### Step 3.7 — Set Up Grafana Alerting

1. Grafana menu → **Alerting** → **Alert rules**
2. Click **New alert rule**

#### Rule: High CPU Alert
```promql
100 - (avg(irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
```
- Evaluate every: 1m
- For: 5m
- Labels: severity=warning
- Summary: "High CPU on {{ $labels.instance }}"

---

## Day 4: Loki (Log Aggregation) + Alertmanager

### Step 4.1 — Install Loki

```bash
# Download Loki
cd /tmp
wget https://github.com/grafana/loki/releases/download/v2.9.4/loki-linux-amd64.zip
unzip loki-linux-amd64.zip
sudo mv loki-linux-amd64 /usr/local/bin/loki

# Create config
sudo mkdir -p /etc/loki
sudo nano /etc/loki/loki-config.yml
```

```yaml
auth_enabled: false

server:
  http_listen_port: 3100

common:
  path_prefix: /tmp/loki
  storage:
    filesystem:
      chunks_directory: /tmp/loki/chunks
      rules_directory: /tmp/loki/rules
  replication_factor: 1
  ring:
    kvstore:
      store: inmemory

schema_config:
  configs:
    - from: "2024-01-01"
      store: tsdb
      object_store: filesystem
      schema: v13
      index:
        prefix: index_
        period: 24h

limits_config:
  reject_old_samples: true
  reject_old_samples_max_age: 168h

storage_config:
  filesystem:
    directory: /tmp/loki/chunks

compactor:
  working_directory: /tmp/loki/compactor
  compaction_interval: 10m
  retention_enabled: true
  retention_delete_delay: 2h
  retention_delete_worker_count: 150
```

### Step 4.2 — Create Loki Systemd Service

```bash
sudo nano /etc/systemd/system/loki.service
```

```ini
[Unit]
Description=Loki Log Aggregation
Wants=network-online.target
After=network-online.target

[Service]
User=monitoring
Group=monitoring
Type=simple
ExecStart=/usr/local/bin/loki -config.file=/etc/loki/loki-config.yml
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable loki
sudo systemctl start loki

# Verify
curl http://localhost:3100/ready
```

### Step 4.3 — Install Promtail (Log Shipper)

Run on **every server** you want to collect logs from:

```bash
cd /tmp
wget https://github.com/grafana/loki/releases/download/v2.9.4/promtail-linux-amd64.zip
unzip promtail-linux-amd64.zip
sudo mv promtail-linux-amd64 /usr/local/bin/promtail

# Create config
sudo nano /etc/promtail-config.yml
```

```yaml
server:
  http_listen_port: 9080

positions:
  filename: /tmp/positions.yaml

clients:
  - url: http://LOKI_SERVER_IP:3100/loki/api/v1/push

scrape_configs:
  # ============================================
  # System logs
  # ============================================
  - job_name: system
    static_configs:
      - targets:
          - localhost
        labels:
          job: syslog
          __path__: /var/log/syslog

  # ============================================
  # Authentication logs
  # ============================================
  - job_name: auth
    static_configs:
      - targets:
          - localhost
        labels:
          job: auth
          __path__: /var/log/auth.log

  # ============================================
  # Nginx logs
  # ============================================
  - job_name: nginx-access
    static_configs:
      - targets:
          - localhost
        labels:
          job: nginx
          type: access
          __path__: /var/log/nginx/access.log

  - job_name: nginx-error
    static_configs:
      - targets:
          - localhost
        labels:
          job: nginx
          type: error
          __path__: /var/log/nginx/error.log

  # ============================================
  # Application logs
  # ============================================
  - job_name: app
    static_configs:
      - targets:
          - localhost
        labels:
          job: techstore
          __path__: /var/log/techstore/*.log
    pipeline_stages:
      - json:
          expressions:
            level: level
            msg: message
      - labels:
            level:
```

```bash
# Create systemd service
sudo nano /etc/systemd/system/promtail.service
```

```ini
[Unit]
Description=Promtail Log Shipper
Wants=network-online.target
After=network-online.target

[Service]
User=promtail
Group=promtail
Type=simple
ExecStart=/usr/local/bin/promtail -config.file=/etc/promtail-config.yml
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

```bash
# Create user
sudo useradd -rs /sbin/nologin promtail

sudo systemctl daemon-reload
sudo systemctl enable promtail
sudo systemctl start promtail
```

### Step 4.4 — Add Loki to Grafana

1. Grafana → **Connections** → **Data sources** → **Add data source**
2. Select **Loki**
3. URL: `http://localhost:3100`
4. **Save & Test**

### Step 4.5 — Query Logs in Grafana

Go to **Explore** → Select **Loki** data source:

```logql
# All logs
{job="syslog"}

# Errors only
{job="syslog"} |= "error"

# Nginx 5xx errors
{job="nginx", type="access"} |= " 5"

# Authentication failures
{job="auth"} |= "Failed password"

# Last 5 minutes of app logs
{job="techstore"} | json | level="error"
```

### Step 4.6 — Install Alertmanager

```bash
cd /tmp
wget https://github.com/prometheus/alertmanager/releases/download/v0.27.0/alertmanager-0.27.0.linux-amd64.tar.gz
tar xzf alertmanager-0.27.0.linux-amd64.tar.gz
cd alertmanager-0.27.0.linux-amd64

sudo cp alertmanager amtool /usr/local/bin/
sudo mkdir -p /etc/alertmanager /var/lib/alertmanager
sudo chown -R monitoring:monitoring /etc/alertmanager /var/lib/alertmanager
```

### Step 4.7 — Configure Alertmanager

```bash
sudo nano /etc/alertmanager/alertmanager.yml
```

```yaml
global:
  resolve_timeout: 5m

# Email configuration
smtp_smarthost: 'smtp.gmail.com:587'
smtp_from: 'alerts@cloudbase.com'
smtp_auth_username: 'alerts@cloudbase.com'
smtp_auth_password: 'your-app-password'
smtp_require_tls: true

# Route alerts to the right place
route:
  group_by: ['alertname', 'severity']
  group_wait: 30s        # Wait 30s before sending first alert
  group_interval: 5m     # Wait 5m between alert groups
  repeat_interval: 4h    # Re-send unresolved alerts every 4h
  receiver: 'default'

  routes:
    # Critical alerts → immediate notification
    - match:
        severity: critical
      receiver: 'critical-alerts'
      group_wait: 10s
      repeat_interval: 1h

    # Warning alerts → batched notifications
    - match:
        severity: warning
      receiver: 'warning-alerts'
      repeat_interval: 4h

# Receivers
receivers:
  - name: 'default'
    email_configs:
      - to: 'admin@cloudbase.com'

  - name: 'critical-alerts'
    email_configs:
      - to: 'admin@cloudbase.com'
        send_resolved: true
    # Slack webhook (uncomment if you have Slack)
    # slack_configs:
    #   - api_url: 'https://hooks.slack.com/services/YOUR/WEBHOOK/URL'
    #     channel: '#alerts-critical'
    #     title: '{{ .GroupLabels.alertname }}'
    #     text: '{{ range .Alerts }}{{ .Annotations.description }}{{ end }}'

  - name: 'warning-alerts'
    email_configs:
      - to: 'admin@cloudbase.com'
        send_resolved: true

# Inhibition rules (suppress warning when critical is firing)
inhibit_rules:
  - source_match:
      severity: 'critical'
    target_match:
      severity: 'warning'
    equal: ['alertname', 'instance']
```

### Step 4.8 — Create Alertmanager Service

```bash
sudo nano /etc/systemd/system/alertmanager.service
```

```ini
[Unit]
Description=Alertmanager
Wants=network-online.target
After=network-online.target

[Service]
User=monitoring
Group=monitoring
Type=simple
ExecStart=/usr/local/bin/alertmanager \
    --config.file=/etc/alertmanager/alertmanager.yml \
    --storage.path=/var/lib/alertmanager
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable alertmanager
sudo systemctl start alertmanager

# Verify
curl http://localhost:9093/-/healthy
```

### Step 4.9 — Test Alerting

```bash
# Send a test alert
amtool alert add \
    --alertname="TestAlert" \
    --severity=warning \
    --annotation="summary=This is a test alert" \
    --annotation="description=Testing alertmanager integration"

# Check active alerts
amtool alert

# Verify it was sent (check email or logs)
sudo journalctl -u alertmanager --since "5 minutes ago"
```

---

## Day 5: SLO/SLI, Incident Response & Documentation

### Step 5.1 — Define SLOs (Service Level Objectives)

Create an SLO document:

```bash
cat > /home/monitoring/SLO.md << 'EOF'
# Service Level Objectives (SLOs)

## What are SLOs?

- **SLI** (Service Level Indicator) — What you measure (e.g., uptime %)
- **SLO** (Service Level Objective) — What you promise (e.g., 99.9% uptime)
- **SLA** (Service Level Agreement) — What happens if you fail (contractual)

## Our SLOs

| Service | SLI | SLO | Error Budget |
|---------|-----|-----|--------------|
| Application | Uptime | 99.9% (8.76h downtime/year) | 43.8 min/month |
| Database | Uptime | 99.95% (4.38h downtime/year) | 21.9 min/month |
| API Response | Latency p99 | < 500ms | — |
| Error Rate | 5xx responses | < 0.1% of total requests | — |

## Error Budget

If our SLO is 99.9%, we have **0.1% error budget**.

Per month: 0.1% × 30 days × 24 hours = **7.2 minutes** of allowed downtime.

When error budget is exhausted:
- Stop deploying new features
- Focus on reliability improvements
- Conduct incident review

## Prometheus Queries for SLO Monitoring

### Availability SLO (99.9%)
```promql
# Actual availability
1 - (sum(rate(http_requests_total{status=~"5.."}[30d])) / sum(rate(http_requests_total[30d])))

# Error budget remaining
(1 - (sum(rate(http_requests_total{status=~"5.."}[30d])) / sum(rate(http_requests_total[30d])))) - 0.999
```

### Latency SLO (99% of requests under 500ms)
```promql
# Percentage of requests under 500ms
1 - histogram_quantile(0.99, rate(http_request_duration_seconds_bucket[30d])) > 0.5
```
EOF
```

### Step 5.2 — Create Incident Response Runbook

```bash
cat > /home/monitoring/INCIDENT_RESPONSE.md << 'EOF'
# Incident Response Playbook

## Severity Levels

| Level | Description | Response Time | Example |
|-------|-------------|---------------|---------|
| SEV-1 | Service down, all users affected | 15 minutes | Server unreachable, database down |
| SEV-2 | Major feature broken, many users affected | 30 minutes | Login failing, API returning 500s |
| SEV-3 | Minor feature issue, some users affected | 2 hours | Slow page load, occasional errors |
| SEV-4 | Cosmetic issue, minimal impact | 24 hours | UI glitch, non-critical log errors |

## When Alert Fires

### Step 1: Acknowledge (within response time)
```bash
# In Alertmanager UI or via CLI
amtool alert acknowledge <alertname> --comment="Investigating"
```

### Step 2: Triage — Is it real?
```bash
# Check the dashboard
# Open Grafana → Alert Overview dashboard

# Check server status
ssh server1 "uptime && free -h && df -h /"

# Check if it's a false positive
curl -s http://server1:9100/metrics | grep node_cpu_seconds_total
```

### Step 3: Impact Assessment
```bash
# How many users affected?
curl -s http://localhost:9090/api/v1/query?query=up | python3 -m json.tool

# What's the error rate?
curl -s "http://localhost:9090/api/v1/query?query=rate(http_requests_total{status=~'5..'}[5m])" | python3 -m json.tool
```

### Step 4: Mitigate (Stop the bleeding)
```bash
# If server is down → restart
sudo systemctl restart <service>

# If disk is full → clean up
sudo journalctl --vacuum-size=500M
sudo apt autoremove -y

# If high CPU → find the process
top -bn1 | head -20
ps aux --sort=-%cpu | head -10

# If memory leak → restart the app
pm2 restart techstore
# or
sudo systemctl restart app
```

### Step 5: Resolve & Document
```bash
# Create incident report
cat > /home/monitoring/incidents/incident-$(date +%Y%m%d).md << REPORT
# Incident Report

## Date: $(date)
## Duration: [start time] — [end time]
## Severity: [1/2/3/4]

## Summary
[What happened]

## Impact
[Who was affected, how many users]

## Timeline
- [time] Alert fired
- [time] Investigated
- [time] Root cause identified
- [time] Fix applied
- [time] Service restored

## Root Cause
[Why it happened]

## Resolution
[What you did to fix it]

## Action Items
- [ ] [Preventive measure 1]
- [ ] [Preventive measure 2]

## Lessons Learned
[What we learned]
REPORT
```

### Step 5.3 — Set Up Monitoring Server Firewall

```bash
# Only allow monitoring ports from trusted IPs
sudo ufw default deny incoming
sudo ufw default allow outgoing

# SSH
sudo ufw allow 22/tcp

# Prometheus (restrict to admin IP)
sudo ufw allow from 192.168.1.0/24 to any port 9090

# Grafana (restrict to admin IP)
sudo ufw allow from 192.168.1.0/24 to any port 3000

# Alertmanager (restrict to Prometheus)
sudo ufw allow from 192.168.1.10 to any port 9093

# Loki
sudo ufw allow from 192.168.1.0/24 to any port 3100

# Node Exporter (from monitored servers only)
sudo ufw allow from 192.168.1.0/24 to any port 9100

sudo ufw enable
sudo ufw status verbose
```

### Step 5.4 — Create Daily Health Check Script

```bash
cat > /home/monitoring/scripts/daily-check.sh << 'CHECK'
#!/bin/bash
# Daily monitoring health check

echo "╔══════════════════════════════════════╗"
echo "║   Daily Monitoring Health Check      ║"
echo "║   $(date '+%Y-%m-%d %H:%M:%S')"
echo "╚══════════════════════════════════════╝"
echo ""

# Check all services
echo "┌─────────────────────────────────────┐"
echo "│  SERVICE STATUS                     │"
echo "└─────────────────────────────────────┘"

for svc in prometheus alertmanager grafana-server loki; do
    status=$(systemctl is-active $svc 2>/dev/null || echo "not-found")
    if [ "$status" = "active" ]; then
        echo "  ✓ $svc: running"
    else
        echo "  ✗ $svc: $status"
    fi
done
echo ""

# Check Prometheus targets
echo "┌─────────────────────────────────────┐"
echo "│  PROMETHEUS TARGETS                 │"
echo "└─────────────────────────────────────┘"
curl -s http://localhost:9090/api/v1/targets | python3 -c "
import json, sys
data = json.load(sys.stdin)
for t in data['data']['activeTargets']:
    status = '✓ UP' if t['health'] == 'up' else '✗ DOWN'
    print(f'  {status} {t[\"labels\"][\"instance\"]:30} last: {t[\"lastScrape\"][:19]}')
"
echo ""

# Check disk usage
echo "┌─────────────────────────────────────┐"
echo "│  DISK USAGE                         │"
echo "└─────────────────────────────────────┘"
df -h / /var/lib/prometheus 2>/dev/null | tail -2 | awk '{printf "  %s: %s used of %s (%s)\n", $6, $3, $2, $5}'
echo ""

# Check alerts
echo "┌─────────────────────────────────────┐"
echo "│  ACTIVE ALERTS                      │"
echo "└─────────────────────────────────────┘"
ALERTS=$(curl -s http://localhost:9090/api/v1/alerts | python3 -c "
import json, sys
data = json.load(sys.stdin)
alerts = data['data']['alerts']
if not alerts:
    print('  No active alerts')
for a in alerts:
    print(f'  [{a[\"labels\"][\"severity\"]}] {a[\"labels\"][\"alertname\"]}: {a[\"annotations\"][\"summary\"]}')
" 2>/dev/null)
echo "$ALERTS"
echo ""

# Check Loki
echo "┌─────────────────────────────────────┐"
echo "│  LOKI STATUS                        │"
echo "└─────────────────────────────────────┘"
LOKI_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3100/ready)
if [ "$LOKI_STATUS" = "200" ]; then
    echo "  ✓ Loki is ready"
else
    echo "  ✗ Loki returned HTTP $LOKI_STATUS"
fi
echo ""

echo "═══════════════════════════════════════"
CHECK
chmod +x /home/monitoring/scripts/daily-check.sh
```

### Step 5.5 — Schedule Automated Tasks

```bash
# Daily health check at 8 AM
(crontab -l 2>/dev/null; echo "0 8 * * * /home/monitoring/scripts/daily-check.sh >> /home/monitoring/logs/daily.log 2>&1") | crontab -

# Weekly log cleanup
(crontab -l 2>/dev/null; echo "0 3 * * 0 find /var/lib/prometheus -mtime +30 -delete") | crontab -

# Monthly SLO report
(crontab -l 2>/dev/null; echo "0 9 1 * * /home/monitoring/scripts/slo-report.sh >> /home/monitoring/logs/slo.log 2>&1") | crontab -
```

### Step 5.6 — Final Verification

```bash
echo "=== Final Monitoring Stack Verification ==="
echo ""

echo "1. Prometheus:"
curl -s http://localhost:9090/-/healthy
echo ""

echo "2. Alertmanager:"
curl -s http://localhost:9093/-/healthy
echo ""

echo "3. Grafana:"
curl -s -o /dev/null -w "HTTP %{http_code}" http://localhost:3000/api/health
echo ""

echo "4. Loki:"
curl -s http://localhost:3100/ready
echo ""

echo "5. Node Exporter:"
curl -s http://localhost:9100/metrics | head -1
echo ""

echo "6. Targets:"
curl -s http://localhost:9090/api/v1/targets | python3 -c "
import json, sys
data = json.load(sys.stdin)
up = sum(1 for t in data['data']['activeTargets'] if t['health'] == 'up')
total = len(data['data']['activeTargets'])
print(f'  {up}/{total} targets UP')
"

echo ""
echo "7. Grafana dashboards:"
echo "  → http://your_server_ip:3000 (admin/admin)"
echo "  → Import dashboard ID: 1860"
echo ""
echo "8. Prometheus UI:"
echo "  → http://your_server_ip:9090"
echo ""
```

---

## Project Deliverables

| # | Deliverable | Status |
|---|------------|--------|
| 1 | Prometheus server scraping all targets | ☐ |
| 2 | Node Exporter on 3 servers | ☐ |
| 3 | Grafana with Node Exporter Full dashboard | ☐ |
| 4 | Custom dashboard (CPU, Memory, Disk, Network) | ☐ |
| 5 | Alert rules (CPU, Memory, Disk, Server Down) | ☐ |
| 6 | Alertmanager with email/Slack integration | ☐ |
| 7 | Loki collecting logs from all servers | ☐ |
| 8 | Promtail shipping logs to Loki | ☐ |
| 9 | Log queries in Grafana (Explore) | ☐ |
| 10 | SLO/SLI documentation | ☐ |
| 11 | Incident response runbook | ☐ |
| 12 | Daily health check script | ☐ |
| 13 | Firewall configured for monitoring ports | ☐ |

---

## Skills You Practiced

| Module | Skills Used |
|--------|-------------|
| Part 14 | Logging, journalctl |
| Part 16 | Firewalls (UFW) |
| Part 33 | System monitoring |
| Part 46 | Monitoring & Alerting |
| Part 56 | Observability (Prometheus, Grafana, Loki) |

---

## Key Metrics to Watch

| Metric | Healthy | Warning | Critical |
|--------|---------|---------|----------|
| CPU | < 60% | 60-80% | > 80% |
| Memory | < 70% | 70-85% | > 85% |
| Disk | > 20% free | 10-20% free | < 10% free |
| Load Average | < CPU cores | = CPU cores | > CPU cores |
| Network Errors | 0 | < 10/s | > 10/s |
| HTTP 5xx | < 0.1% | 0.1-5% | > 5% |

---

## Interview Prep

1. "How do you monitor production servers?" → Prometheus + Node Exporter
2. "What is the pull model in Prometheus?" → Prometheus scrapes targets (pull), not push
3. "How do you handle alert fatigue?" → Proper severity levels, inhibition rules, group_wait
4. "What is the difference between monitoring and observability?" → Monitoring = metrics, Observability = metrics + logs + traces
5. "How do you define SLOs?" → SLI (what you measure) → SLO (what you promise) → SLA (contractual)
6. "What would you do if an alert fires at 3 AM?" → Follow the incident response runbook
7. "How do you distinguish between a real incident and a false positive?" → Check dashboards, correlate multiple signals

---

> **Key Takeaway**: Monitoring is not optional — it's the difference between knowing about problems before your customers do and hearing about them from angry support tickets. This stack (Prometheus + Grafana + Loki + Alertmanager) is the industry standard for Linux infrastructure monitoring.
