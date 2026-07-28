## Hands-On Practices

### 1. Install Prometheus and node_exporter, verify targets

```bash
sudo useradd --no-create-home --shell /bin/false prometheus
wget https://github.com/prometheus/prometheus/releases/download/v2.53.0/prometheus-2.53.0.linux-amd64.tar.gz
tar xzf prometheus-2.53.0.linux-amd64.tar.gz
sudo mv prometheus-2.53.0.linux-amd64/{prometheus,promtool} /usr/local/bin/
sudo mkdir -p /etc/prometheus /var/lib/prometheus

# Minimal config
cat > /etc/prometheus/prometheus.yml << 'EOF'
global:
  scrape_interval: 15s
  evaluation_interval: 15s
scrape_configs:
  - job_name: prometheus
    static_configs: [{targets: ['localhost:9090']}]
  - job_name: node
    static_configs: [{targets: ['localhost:9100']}]
EOF

sudo useradd --no-create-home --shell /bin/false node_exporter
# ... install node_exporter binary ...

sudo systemctl daemon-reload
sudo systemctl enable --now prometheus node_exporter
curl http://localhost:9090/api/v1/targets | jq '.data.activeTargets[].labels'
```

### 2. Write PromQL queries

```promql
avg(rate(node_cpu_seconds_total[5m])) by (instance, mode) * 100
node_memory_MemAvailable_bytes / 1024 / 1024 / 1024
(1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) * 100
predict_linear(node_filesystem_avail_bytes{mountpoint="/"}[1h], 86400) < 0
rate(node_network_receive_bytes_total{device="eth0"}[5m])
node_load15 / count(node_cpu_seconds_total{mode="idle"}) by (instance) * 100
```

### 3. Create recording rules

```yaml
# /etc/prometheus/rules/recording.yml
groups:
  - name: node_recording
    interval: 30s
    rules:
      - record: node_cpu_utilization:avg5m
        expr: avg(rate(node_cpu_seconds_total{mode!="idle"}[5m])) by (instance)
      - record: node_memory_utilization:ratio
        expr: 1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes
      - record: node_disk_utilization:percent
        expr: 100 * (1 - node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"})
```

### 4. Configure Alertmanager with Slack webhook

```yaml
# /etc/alertmanager/alertmanager.yml
route:
  group_by: ['alertname', 'severity']
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 4h
  receiver: slack-critical
  routes:
    - match: {severity: critical}
      receiver: slack-critical
    - match: {severity: warning}
      receiver: slack-warning
receivers:
  - name: slack-critical
    slack_configs:
      - api_url: 'https://hooks.slack.com/services/T00/B00/XXXXX'
        channel: '#alerts-critical'
        title: '🚨 {{ .GroupLabels.alertname }}'
        text: '{{ range .Alerts }}*{{ .Annotations.summary }}* Instance: {{ .Labels.instance }}{{ end }}'
  - name: slack-warning
    slack_configs:
      - api_url: 'https://hooks.slack.com/services/T00/B00/XXXXX'
        channel: '#alerts-warning'
inhibit_rules:
  - source_match: {severity: critical}
    target_match: {severity: warning}
    equal: ['instance']
```

### 5. Set up blackbox_exporter

```yaml
# Additional scrape config in prometheus.yml
  - job_name: blackbox-http
    metrics_path: /probe
    params: {module: [http_2xx]}
    static_configs:
      - targets: ['https://example.com', 'https://httpbin.org/status/200']
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - target_label: __address__
        replacement: 127.0.0.1:9115
```

### 6. Install Grafana, add datasource, build dashboard

```bash
sudo apt-get install -y software-properties-common
sudo add-apt-repository "deb https://packages.grafana.com/oss/deb stable main"
wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -
sudo apt-get update && sudo apt-get install -y grafana
sudo systemctl enable --now grafana-server
```

Create dashboard with panels: CPU (time series), Memory (gauge), Disk (bar gauge), Network (time series).

### 7. Use Grafana variables

```yaml
name: instance
type: query
query: label_values(node_boot_time_seconds, instance)
multi: true
includeAll: true

name: interval
type: interval
query: 1m,5m,15m,30m,1h
auto: true
```

Panel: `rate(node_cpu_seconds_total{instance="$instance"}[$interval])`

### 8. Provision Grafana datasources and dashboards

```yaml
# /etc/grafana/provisioning/datasources/prometheus.yml
apiVersion: 1
datasources:
  - name: Prometheus
    type: prometheus
    url: http://localhost:9090
    isDefault: true
```

```yaml
# /etc/grafana/provisioning/dashboards/dashboards.yml
apiVersion: 1
providers:
  - name: default
    folder: ''
    type: file
    options: {path: /var/lib/grafana/dashboards}
```

### 9. Install Loki and Promtail with JSON pipeline

```bash
wget https://github.com/grafana/loki/releases/download/v3.0.0/loki-linux-amd64.zip
unzip loki-linux-amd64.zip && sudo mv loki-linux-amd64 /usr/local/bin/loki
wget https://github.com/grafana/loki/releases/download/v3.0.0/promtail-linux-amd64.zip
unzip promtail-linux-amd64.zip && sudo mv promtail-linux-amd64 /usr/local/bin/promtail
```

Promtail JSON pipeline config shown in Section 10.

### 10. Write LogQL queries

```logql
sum(count_over_time({job="nginx"} |= "error" [1m])) by (status)
topk(5, sum(count_over_time({job="nginx"} [5m])) by (path))
quantile_over_time(0.99, {job="nginx"} | json | unwrap duration_ms [5m]) by (path)
sum(rate({job="nginx"} | json | status >= 500 [5m])) / sum(rate({job="nginx"} | json [5m])) * 100
{job="app"} | logfmt | level = "error" | trace_id != ""
{job="nginx"} | json | duration_ms > 5000
```

### 11. Set up Grafana alerts from Loki

```yaml
# Alert rule (provisioned)
groups:
  - orgId: 1
    name: log_alerts
    folder: Logs
    rules:
      - uid: high_error_rate
        title: High error rate from logs
        condition: C
        data:
          - refId: A
            relativeTimeRange: {from: 300, to: 0}
            datasourceUid: loki
            model: {expr: 'rate({job="nginx"} | json | status >= 500 [5m])', intervalMs: 60000}
          - refId: B
            relativeTimeRange: {from: 300, to: 0}
            datasourceUid: loki
            model: {expr: 'rate({job="nginx"} | json [5m])', intervalMs: 60000}
          - refId: C
            datasourceUid: __expr__
            model: {expression: 'A / B * 100 > 5', type: threshold}
        for: 2m
        annotations: {summary: "Error rate above 5%"}
```

### 12. Deploy Tempo and configure sample app

```bash
docker run -d --name tempo -p 3200:3200 -p 4317:4317 \
  -v /etc/tempo/tempo.yml:/etc/tempo/config.yaml \
  grafana/tempo:latest -config.file=/etc/tempo/config.yaml
```

Sample Python app with tracing (see Section 13 manual instrumentation).

### 13. Install OTEL Collector

```yaml
# /etc/otel/config.yml (traces → Tempo + metrics → Prometheus)
receivers:
  otlp:
    protocols:
      grpc: {endpoint: 0.0.0.0:4317}
processors:
  batch: {timeout: 1s, send_batch_size: 1024}
  memory_limiter: {limit_mib: 512, spike_limit_mib: 128}
exporters:
  otlp/tempo:
    endpoint: tempo:4317
    tls: {insecure: true}
  prometheus:
    endpoint: 0.0.0.0:8889
    namespace: otel_app
connectors:
  spanmetrics:
    histogram: {explicit: {buckets: [2ms, 5ms, 10ms, 25ms, 50ms, 100ms, 250ms, 500ms, 1s, 2.5s, 5s, 10s]}}
    dimensions: [{name: http.method}, {name: http.status_code}]
    metrics_flush_interval: 30s
service:
  pipelines:
    traces:
      receivers: [otlp]
      processors: [memory_limiter, batch]
      exporters: [otlp/tempo, spanmetrics]
    metrics/spanmetrics:
      receivers: [spanmetrics]
      processors: [batch]
      exporters: [prometheus]
```

### 14. Create unified dashboard

Build a Grafana dashboard with:
- **Metrics panel** (Prometheus): `rate(http_requests_total{service="$service"}[5m])`
- **Logs panel** (Loki): `{service="$service"} |= "error"`
- **Trace panel** (Tempo): `{.service.name = "$service" && .duration > 100ms}`
- Derived field on Loki to link logs → traces via trace ID
- Variable: `$service` from `label_values(up, service)`

### 15. Full stack integration

```bash
# docker-compose.yml — complete observability stack
version: '3.8'
services:
  prometheus:
    image: prom/prometheus:latest
    volumes: [./prometheus.yml:/etc/prometheus/prometheus.yml, prometheus-data:/prometheus]
    ports: ["9090:9090"]
  node_exporter:
    image: prom/node-exporter:latest
    ports: ["9100:9100"]
  alertmanager:
    image: prom/alertmanager:latest
    volumes: [./alertmanager.yml:/etc/alertmanager/alertmanager.yml]
    ports: ["9093:9093"]
  grafana:
    image: grafana/grafana:latest
    environment: [GF_SECURITY_ADMIN_PASSWORD=admin]
    volumes: [grafana-data:/var/lib/grafana, ./grafana/provisioning:/etc/grafana/provisioning]
    ports: ["3000:3000"]
  loki:
    image: grafana/loki:latest
    volumes: [./loki.yml:/etc/loki/config.yml, loki-data:/var/lib/loki]
    ports: ["3100:3100"]
  promtail:
    image: grafana/promtail:latest
    volumes: [./promtail.yml:/etc/promtail/config.yml, /var/log:/var/log:ro]
  tempo:
    image: grafana/tempo:latest
    volumes: [./tempo.yml:/etc/tempo/config.yaml, tempo-data:/var/lib/tempo]
    ports: ["3200:3200", "4317:4317"]
  otel-collector:
    image: otel/opentelemetry-collector-contrib:latest
    volumes: [./otel-config.yml:/etc/otel/config.yml]
    ports: ["4317:4317", "8889:8889"]
  sample-app:
    build: ./app
    environment:
      - OTEL_EXPORTER_OTLP_ENDPOINT=http://otel-collector:4317
      - OTEL_SERVICE_NAME=sample-app
    ports: ["8080:8080"]
volumes: {prometheus-data:, grafana-data:, loki-data:, tempo-data:}
```

Instrument a microservice (Python with FastAPI):
```python
from fastapi import FastAPI
from opentelemetry import trace
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor
from opentelemetry.instrumentation.requests import RequestsInstrumentor
from opentelemetry.sdk.trace import TracerProvider, export.BatchSpanProcessor
import logging, json

provider = TracerProvider()
provider.add_span_processor(BatchSpanProcessor(OTLPSpanExporter()))
trace.set_tracer_provider(provider)

app = FastAPI()
FastAPIInstrumentor.instrument_app(app)
RequestsInstrumentor().instrument()
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("sample-app")

@app.get("/")
async def root():
    span = trace.get_current_span()
    span.set_attribute("http.method", "GET")
    logger.info(json.dumps({"level": "info", "message": "root request",
        "trace_id": format(span.get_span_context().trace_id, "032x")}))
    return {"status": "ok"}

@app.get("/error")
async def trigger_error():
    span = trace.get_current_span()
    span.set_attribute("error", True)
    logger.error(json.dumps({"level": "error", "message": "simulated error",
        "trace_id": format(span.get_span_context().trace_id, "032x")}))
    return {"error": "simulated"}, 500
```

Set up alerting from the unified stack: "Error rate > 5%" based on LogQL, Slack notification via Alertmanager, trace link on each alert.





[← Previous](14-14-unified-observability.md) | [↑ Index](index.md) | [Next →](16-deep-understanding.md)
