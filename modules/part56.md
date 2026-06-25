# 🐧 Linux System Administrator — Complete Course
## Part 56 of ∞: Observability Deep Dive — Prometheus, Grafana, Loki, OpenTelemetry

---

> **Reverse Engineering Approach:** You will deploy a complete observability stack, then dismantle every component — the pull model, the TSDB, the log pipeline, the trace context, the telemetry pipeline. By the time you finish, you will not just *configure* observability — you will *understand* it well enough to build your own monitoring system from scratch.

---

## 1. Three Pillars of Observability

**Metrics (numbers):** CPU utilization, request latency p99, memory usage. Optimized for storage (~2 bytes/sample compressed) and fast querying. Tell you *what* is happening.

```
node_cpu_seconds_total{cpu="0",mode="idle"} 283741.92
```

**Logs (events):** Timestamped text records. Tell you *why* something is happening. High-cardinality, expensive to store at scale.

```json
{"level":"error","time":"2025-06-24T10:31:22Z","msg":"connection refused","host":"db-01"}
```

**Traces (request lifecycle):** End-to-end request path through distributed services. Composed of spans with timing. Tell you *where* latency lives.

```
TraceID: abc123
  ├── frontend: GET /api/users (150ms)
  │   ├── auth: verify_token (12ms)
  │   └── users: query_db (85ms)
```

**How they complement each other:** Metrics show *what* is wrong (p99 spike). Logs show *why* (5xx errors). Traces show *where* (which service call is slow).

**Cardinality:** Number of unique label combinations. `http_requests_total{method,path,status}` with 4 methods × 50 paths × 5 statuses = 1000 series. Add `user_id` (100K) = 100M series — destroys Prometheus. Never use user IDs, IPs, or request IDs as labels.

**vs Traditional Monitoring:** Nagios/Zabbix check-based (OK/WARN/CRIT, no history, no trends). Observability collects everything, stores it, queries ad-hoc. Question changes from "is it up?" to "how is it behaving?"

---

## 2. Prometheus Architecture

**Pull Model:** Prometheus scrapes HTTP `/metrics` endpoints. Benefits: dead target detection, central control over scrape frequency, federation, simple HA.

```
Prometheus ── scrape :9100/metrics ──→ node_exporter
           ── scrape :8080/metrics ──→ application
           ── scrape :9115/probe   ──→ blackbox_exporter
```

**TSDB (Time Series Database):** Stores data in 2-hour blocks. Each block: `chunks/` (XOR-compressed samples), `index` (inverted label→series mapping), `meta.json`, `tombstones`. WAL for crash recovery.

```
tsdb/
├── 01G7XYZ.../ {chunks/, index, meta.json, tombstone}
├── wal/ {000001, checkpoint.000002/}
└── chunks_head/
```

**Service Discovery:**

```yaml
# kubernetes_sd_configs
scrape_configs:
  - job_name: kubernetes-pods
    kubernetes_sd_configs:
      - role: pod
    relabel_configs:
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
        action: keep
        regex: true

# ec2_sd_configs
  - job_name: aws-instances
    ec2_sd_configs:
      - region: us-east-1
        port: 9100
    relabel_configs:
      - source_labels: [__meta_ec2_tag_Name]
        target_label: instance

# file_sd_configs
  - job_name: custom
    file_sd_configs:
      - files: ['/etc/prometheus/targets/*.json']
        refresh_interval: 30s
```

**Target file (`targets/web.json`):**
```json
[{"targets": ["10.0.1.1:9100"], "labels": {"env": "prod", "team": "web"}}]
```

**Relabeling:** `relabel_configs` (pre-scrape, target labels) vs `metric_relabel_configs` (post-scrape, metric labels). Actions: `replace`, `keep`, `drop`, `hashmod`, `labelmap`, `labeldrop`, `keepequal`, `dropequal`.

**Target Status:** `up == 0` → targets that failed scrape.

---

## 3. Advanced PromQL

**Selectors:**
```promql
node_cpu_seconds_total{cpu="0",mode="idle"}            # instant vector
node_cpu_seconds_total{cpu="0",mode="idle"}[5m]         # range vector
```

**rate() vs irate() vs increase():**
```promql
rate(node_cpu_seconds_total[5m])      # smooth, for alerting
irate(node_cpu_seconds_total[5m])     # responsive, for graphing
increase(node_cpu_seconds_total[1h])  # raw increase, for billing
```

**histogram_quantile():**
```promql
histogram_quantile(0.99, rate(http_request_duration_seconds_bucket[5m]))
```

**Aggregations:**
```promql
sum(rate(node_cpu_seconds_total{mode!="idle"}[5m])) by (instance)
sum(rate(node_cpu_seconds_total{mode!="idle"}[5m])) without (cpu)
topk(5, sum(rate(node_network_receive_bytes_total[5m])) by (device))
count_values("mode_count", node_cpu_seconds_total)
```

**Binary operators:**
```promql
(1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) * 100
node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes < 0.1
up == 0 and (time() - process_start_time_seconds{job="prometheus"}) > 300
```

**Recording Rules:**
```yaml
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

---

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

## 5. Prometheus Service Discovery and Relabeling

**relabel_configs vs metric_relabel_configs:** `relabel_configs` applied before scrape (target discovery, `__address__`). `metric_relabel_configs` applied after scrape (series labels, drop/keep).

**Full action reference:**

| Action | Description |
|--------|-------------|
| `replace` | Set `target_label` from `source_labels` regex capture groups |
| `keep` | Drop target if source_labels don't match regex |
| `drop` | Drop target if source_labels match regex |
| `hashmod` | Hash source_labels mod `modulus`, store in `target_label` |
| `labelmap` | Rename labels matching regex |
| `labeldrop` | Delete labels matching regex |
| `keepequal` | Keep if source_labels == target_label value |
| `dropequal` | Drop if source_labels == target_label value |

**Complex Kubernetes relabeling:**
```yaml
relabel_configs:
  - source_labels: [__meta_kubernetes_pod_label_app_kubernetes_io_name]
    target_label: app
  - source_labels: [__meta_kubernetes_namespace]
    target_label: namespace
  - source_labels: [__meta_kubernetes_pod_node_name]
    target_label: node
  - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
    action: keep
    regex: true
  - source_labels: [__address__, __meta_kubernetes_pod_annotation_prometheus_io_port]
    action: replace
    regex: ([^:]+)(?::\d+)?;(\d+)
    replacement: $1:$2
    target_label: __address__
```

**Drop high-cardinality labels via metric_relabel_configs:**
```yaml
metric_relabel_configs:
  - source_labels: [user_id]
    regex: ".+"
    action: drop
```

---

## 6. Prometheus Storage

**Local TSDB:** Data organized into 2-hour **blocks**. Each block: `chunks/` (Gorilla XOR compressed, ~1.3 bytes/sample), `index` (inverted label→series posting lists), `meta.json`, `tombstones` (soft deletes). **WAL** (write-ahead log) ensures crash recovery — samples written to WAL first, then in-memory head block, flushed every 2h. **Compaction** merges small blocks into larger ones, removes tombstones.

**Remote Write:** Forward samples to Thanos, Cortex, Mimir, VictoriaMetrics, or cloud-managed Prometheus.

```yaml
remote_write:
  - url: https://thanos-receiver.example.com/api/v1/receive
    basic_auth: {username: prometheus, password: secret}
    queue_config:
      max_shards: 200
      max_samples_per_send: 500
      batch_send_deadline: 5s
```

**Downsampling:** Thanos/Mimir downsample: raw (2h, 30d) → 5m (min/max/avg, 6mo) → 1h (min/max/avg, 5yr). Prometheus local TSDB does not downsample.

**Storage sizing:** ~2 bytes/sample compressed. 500K series × 1 sample/15s × 15d × 2 bytes ≈ 86 GB. 1M series @ 10s interval, 15d ≈ 260 GB.

---

## 7. Alertmanager

**Architecture:** Prometheus evaluates alerting rules → sends to Alertmanager → groups, inhibits, silences, routes → receivers.

**Alerting rules:**
```yaml
groups:
  - name: node_alerts
    interval: 30s
    rules:
      - alert: NodeDown
        expr: up{job="node"} == 0
        for: 5m
        labels: {severity: critical}
        annotations:
          summary: "Instance {{ $labels.instance }} down"
      - alert: HighCPU
        expr: 100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) by (instance) * 100) > 90
        for: 10m
        labels: {severity: warning}
      - alert: DiskSpace
        expr: (node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"}) < 0.1
        for: 5m
        labels: {severity: critical}
```

**Grouping:** Merges related alerts into one notification to reduce noise.

```yaml
route:
  group_by: ['severity', 'namespace']
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 4h
```

| Parameter | Purpose |
|-----------|---------|
| `group_by` | Labels to group notifications by |
| `group_wait` | Buffer time before first notification |
| `group_interval` | Wait before sending new alerts to existing group |
| `repeat_interval` | Re-send interval for still-firing alerts |

**Inhibition:** Suppress low-severity alerts when high-severity exists for same scope.

```yaml
inhibit_rules:
  - source_match: {severity: critical}
    target_match: {severity: warning}
    equal: ['instance']
```

**Silences:** Suppress alerts matching matchers for a duration.

```bash
amtool silence add --alertmanager.url=http://localhost:9093 \
  --author="tim-ham" --comment="Maintenance" --duration=2h \
  severity=critical instance=db-01
```

**Routing tree:**
```yaml
route:
  receiver: default
  routes:
    - match: {severity: critical}
      receiver: pagerduty-critical
      routes:
        - match: {namespace: production}
          receiver: pagerduty-production
    - match_re: {severity: ^(warning|info)$}
      receiver: slack-noncritical
    - match: {team: security}
      receiver: pagerduty-security
      continue: true
```

**Receivers:**

**Slack:**
```yaml
receivers:
  - name: slack-alerts
    slack_configs:
      - api_url: https://hooks.slack.com/services/T00/B00/XXXXX
        channel: '#alerts'
        send_resolved: true
        title: '{{ .GroupLabels.alertname }}'
        text: '{{ range .Alerts }}*{{ .Annotations.summary }}* {{ .Labels.instance }}{{ end }}'
```

**Email:**
```yaml
    email_configs:
      - to: ops@example.com
        smarthost: smtp.gmail.com:587
        auth_username: alertmanager@example.com
        auth_password: app-password
```

**PagerDuty:**
```yaml
    pagerduty_configs:
      - routing_key: YOUR_PD_KEY
        severity: critical
        description: '{{ .GroupLabels.alertname }}'
```

**Webhook:**
```yaml
    webhook_configs:
      - url: http://webhook:8080/alerts
        send_resolved: true
```

---

## 8. Grafana

**Datasources:**

```yaml
datasources:
  - name: Prometheus
    type: prometheus
    url: http://prometheus:9090
    isDefault: true
    jsonData:
      timeInterval: 30s
      httpMethod: POST
      exemplarTraceIdDestinations:
        - name: traceID
          url: http://tempo:3200/explore?traceId=$${__value.raw}

  - name: Loki
    type: loki
    url: http://loki:3100
    jsonData:
      derivedFields:
        - name: traceID
          matcherRegex: "trace_id=(\\w+)"
          url: "http://tempo:3200/explore?traceId=$${__value.raw}"

  - name: Tempo
    type: tempo
    url: http://tempo:3200
    jsonData:
      nodeGraph: {enabled: true}
      tracesToLogs:
        datasourceUid: Loki
        tags: ['instance', 'pod', 'namespace']
```

**Dashboard panels:**

| Panel Type | Use Case | Query Example |
|------------|----------|---------------|
| Time series | CPU, network, latency over time | `rate(http_requests_total[5m])` |
| Stat | Current value, single number | `sum(rate(http_requests_total{status=~"5.."}[5m])) / sum(rate(http_requests_total[5m])) * 100` |
| Gauge | Utilization 0-100% | `100 - (avg(node_memory_MemAvailable_bytes) / avg(node_memory_MemTotal_bytes) * 100)` |
| Bar gauge | Top-N comparisons | `topk(10, sum(rate(node_network_receive_bytes_total[5m])) by (device))` |
| Table | Multi-dimensional data | `node_cpu_seconds_total` with Format → Table |
| Heatmap | Latency distribution | `rate(http_request_duration_seconds_bucket[5m])` |
| Logs | Live log display | `{namespace="production"} \|= "error"` |

**Variables:**

```yaml
# Query variable
name: instance
type: query
query: label_values(node_boot_time_seconds, instance)
multi: true
includeAll: true

# Interval variable
name: interval
type: interval
query: 1m,5m,15m,30m,1h
auto: true

# Textbox (user input)
name: namespace
type: textbox

# Custom
name: env
type: custom
query: prod,staging,dev
```

Usage: `rate(http_requests_total{instance="$instance"}[$interval])`

**Transformations:** Reduce (min/max/avg/last), Filter by value, Group by, Merge, Calculate field, Rename by regex, Organize fields, Concatenate.

---

## 9. Grafana Provisioning

**Datasources:**
```yaml
# /etc/grafana/provisioning/datasources/datasource.yml
apiVersion: 1
datasources:
  - name: Prometheus
    type: prometheus
    url: http://prometheus:9090
    isDefault: true
    editable: false
  - name: Loki
    type: loki
    url: http://loki:3100
```

**Dashboards:**
```yaml
# /etc/grafana/provisioning/dashboards/dashboard.yml
apiVersion: 1
providers:
  - name: default
    folder: ''
    type: file
    options:
      path: /var/lib/grafana/dashboards
```

**Dashboard JSON (`/var/lib/grafana/dashboards/node-overview.json`):**
```json
{
  "title": "Node Exporter Overview",
  "uid": "node-overview",
  "panels": [{
    "title": "CPU Utilization",
    "type": "timeseries",
    "datasource": "Prometheus",
    "targets": [{"expr": "100 - (avg(rate(node_cpu_seconds_total{mode=\"idle\",instance=\"$instance\"}[$__rate_interval])) by (cpu) * 100)"}],
    "fieldConfig": {"defaults": {"unit": "percent", "min": 0, "max": 100, "thresholds": {"mode": "absolute", "steps": [{"color": "green", "value": null}, {"color": "yellow", "value": 80}, {"color": "red", "value": 90}]}}}
  }, {
    "title": "Memory Usage",
    "type": "gauge",
    "datasource": "Prometheus",
    "targets": [{"expr": "(1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) * 100"}]
  }],
  "templating": {"list": [{"name": "instance", "type": "query", "query": "label_values(node_boot_time_seconds, instance)"}]}
}
```

**Folders:**
```yaml
apiVersion: 1
folders:
  - title: Infrastructure
    uid: infrastructure
```

**Permissions:**
```yaml
apiVersion: 1
permissions:
  - orgId: 1
    datasources:
      - name: Prometheus
        permissions:
          - userLogin: viewer1
            permission: Query
```

**Unified Alerting provisioning:**
```yaml
apiVersion: 1
groups:
  - orgId: 1
    name: node_alerts
    folder: Infrastructure
    rules:
      - uid: node_down
        title: Node is down
        condition: A
        data:
          - refId: A
            relativeTimeRange: {from: 300, to: 0}
            datasourceUid: Prometheus
            model: {expr: 'up{job="node"} == 0', intervalMs: 10000, maxDataPoints: 100}
        noDataState: Alerting
        for: 5m
        annotations: {summary: "Instance {{ $labels.instance }} is down"}
```

**Contact points & policies:**
```yaml
contactPoints:
  - orgId: 1
    name: Slack
    receivers:
      - uid: slack-alerts
        type: slack
        settings: {url: https://hooks.slack.com/services/...}
policies:
  - orgId: 1
    receiver: Slack
    group_by: ['severity']
    group_wait: 30s
```

---

## 10. Loki

**Design:** Index only metadata (labels), not log content. Content stored as compressed chunks in object storage. Index ≈ 1% of data vs Elasticsearch's 50-100%.

```
Application → Promtail → Loki → Object Storage (S3/GCS/MinIO)
                               └→ Index (BoltDB/Cassandra/TSDB)
```

**Labels:** Choose carefully — each unique label value = new stream. Best: `job`, `namespace`, `pod`, `service`, `level`, `host`. Avoid: request IDs, user IDs.

**LogCLI:**
```bash
export LOKI_ADDR=http://loki:3100
logcli query '{namespace="production"} |= "error"' --limit=50 --since=1h
logcli query '{job="nginx"}' --output=jsonl --since=30m
logcli labels --since=24h
logcli series '{namespace=~".+"}' --since=1h
logcli query '{namespace="production"}' --tail
```

**Promtail config (`/etc/promtail/config.yml`):**
```yaml
server:
  http_listen_port: 9080
positions:
  filename: /var/log/positions.yaml
clients:
  - url: http://loki:3100/loki/api/v1/push

scrape_configs:
  - job_name: system
    static_configs:
      - targets: [localhost]
        labels:
          job: system
          __path__: /var/log/syslog
    pipeline_stages:
      - regex:
          expression: "^(?s)(?P<time>\\S+)\\s+(?P<hostname>\\S+)\\s+(?P<process>[^\\[]+)\\[(?P<pid>\\d+)\\]:\\s+(?P<message>.*)"
      - timestamp: {source: time, format: RFC3339}
      - labels: {hostname:, process:}

  - job_name: nginx
    static_configs:
      - targets: [localhost]
        labels:
          job: nginx
          __path__: /var/log/nginx/access.log
    pipeline_stages:
      - regex:
          expression: '^(?P<remote_addr>\S+)\s+-\s+(?P<remote_user>\S+)\s+\[(?P<time>[^\]]+)\]\s+"(?P<method>\S+)\s+(?P<path>\S+)\s+\S+"\s+(?P<status>\d+)\s+(?P<body_bytes>\d+).*'
      - timestamp: {source: time, format: "02/Jan/2006:15:04:05 -0700"}
      - labels: {status:}

  - job_name: json-logs
    static_configs:
      - targets: [localhost]
        labels:
          job: json-app
          __path__: /var/log/app/*.log
    pipeline_stages:
      - json:
          expressions:
            level: level
            message: message
            service: service
            trace_id: trace_id
            duration_ms: duration_ms
      - timestamp: {source: timestamp, format: RFC3339Nano}
      - labels: {level:, service:}
      - drop: {source: level, value: debug}
```

**Pipeline stages:**

| Stage | Purpose |
|-------|---------|
| `regex` | Extract fields with Go regex |
| `json` | Parse JSON log lines |
| `logfmt` | Parse logfmt-formatted logs |
| `multiline` | Merge multi-line entries (stack traces) |
| `timestamp` | Set log timestamp from field |
| `labels` | Extract fields as Loki labels |
| `static_labels` | Add constant labels |
| `drop` | Drop matching lines |
| `template` | Transform fields with Go templates |
| `output` | Set final log content |

**Loki config (`/etc/loki/config.yml`):**
```yaml
auth_enabled: false
server:
  http_listen_port: 3100
  grpc_listen_port: 9096

common:
  ring: {instance_addr: 127.0.0.1, kvstore: {store: inmemory}}
  replication_factor: 1
  path_prefix: /var/lib/loki

schema_config:
  configs:
    - from: 2024-01-01
      store: tsdb
      object_store: filesystem
      schema: v13
      index: {prefix: index_, period: 24h}

storage_config:
  tsdb_shipper:
    active_index_directory: /var/lib/loki/index
    cache_location: /var/lib/loki/cache
    shared_store: filesystem
  filesystem:
    directory: /var/lib/loki/chunks

compactor:
  working_directory: /var/lib/loki/compactor
  retention_enabled: true

limits_config:
  ingestion_rate_mb: 10
  max_streams_per_user: 10000
  max_line_size: 256KB
  reject_old_samples_max_age: 168h

ingester:
  chunk_idle_period: 30m
  chunk_block_size: 262144
  wal: {dir: /var/lib/loki/wal}

querier:
  max_concurrent: 10
  query_ingester_within: 3h

ruler:
  storage: {type: local, local: {directory: /var/lib/loki/rules}}
  alertmanager_url: http://alertmanager:9093
```

| Component | Role |
|-----------|------|
| **Ingester** | Receives streams, compresses into chunks, flushes to storage |
| **Querier** | Reads chunks + ingesters, evaluates LogQL |
| **Compactor** | Merges overlapping chunks, applies retention |
| **Distributor** | Validates, hashes, fans-out to ingesters |
| **Ruler** | Evaluates alerting/recording rules |
| **Query Frontend** | Splits queries, caches, retries |

---

## 11. LogQL

**Stream selector + pipeline:** `{label="value"} |= "search" != "exclude" | json | line_format "{{.msg}}"`

**Line filters:** `|=` (contains), `!=` (not contains), `|~` (regex match), `!~` (regex not match).

**Parsers:** `| json`, `| logfmt`, `| regexp "^(?P<name>\\S+)"`, `| unpack`.

**Label filter (after parsing):**
```
{job="nginx"} | json | path = "/api/login" | status >= 500
{job="app"} | logfmt | duration > 1000 | level = "error"
```

**Line format:**
```
{job="nginx"} | json | line_format "{{.status}} {{.path}} {{.duration}}ms"
{job="app"} | logfmt | line_format "[{{.level}}] {{.message}}"
```

**Metric queries:**

```logql
# Error count per 5m
sum(count_over_time({namespace="production"} |= "error" [5m])) by (level)

# Error rate
rate({job="nginx"} |= "error" [5m])

# Average duration
avg_over_time({job="nginx"} | json | unwrap duration_ms [5m]) by (path)

# p99 duration
quantile_over_time(0.99, {job="nginx"} | json | unwrap duration_ms [5m]) by (path)

# Error percentage
sum(rate({job="nginx"} | json | status >= 500 [5m])) by (method)
  / sum(rate({job="nginx"} | json [5m])) by (method) * 100

# Top 5 error paths
topk(5, sum(count_over_time({job="nginx"} |= "error" | json [1h])) by (path))

# Slow requests
{job="nginx"} | json | duration_ms > 5000

# Traces from logs
{namespace="production"} | logfmt | trace_id != "" | line_format "trace={{.trace_id}} {{.message}}"
```

---

## 12. Tempo

**Trace storage backend:** Stores traces in object storage (S3/GCS/MinIO), indexed by trace ID via bloom filters.

```yaml
# /etc/tempo/tempo.yml
server:
  http_listen_port: 3200
distributor:
  receivers:
    otlp:
      protocols:
        grpc: {endpoint: 0.0.0.0:4317}
        http: {endpoint: 0.0.0.0:4318}
    jaeger:
      protocols:
        grpc: {endpoint: 0.0.0.0:14250}
        thrift_compact: {endpoint: 0.0.0.0:6831}
    zipkin: {endpoint: 0.0.0.0:9411}
ingester:
  trace_idle_period: 30s
  max_block_duration: 30m
storage:
  trace:
    backend: s3
    s3:
      bucket: tempo-traces
      endpoint: s3.amazonaws.com
    wal: {path: /var/lib/tempo/wal}
overrides:
  max_bytes_per_trace: 5000000
```

**Jaeger/Zipkin compatibility:** Tempo accepts Jaeger (gRPC :14250, Thrift :6831) and Zipkin (:9411) formats. Drop-in replacement.

**Trace discovery:**
- **Service Graph:** Metrics from trace connections (request rate, error rate, latency) stored in Prometheus
- **TraceQL:** `{.service.name = "frontend" && .status = error}`, `{.duration > 1s}`, nested span conditions
- **Grafana Explore:** Search by trace ID, labels, or TraceQL

**Sampling:**
- **Head-based:** Decision at SDK. `OTEL_TRACES_SAMPLER=parentbased_traceidratio OTEL_TRACES_SAMPLER_ARG=0.1`
- **Tail-based:** Decision in Tempo after seeing all spans. Policies: `status_code` (keep errors), `latency` (keep slow), `probabilistic`.

---

## 13. OpenTelemetry (OTEL)

**OTLP protocol:** Vendor-agnostic gRPC/HTTP-protobuf telemetry protocol.

```
Application (SDK) ──OTLP──→ OTEL Collector ──OTLP──→ Tempo (traces)
                                           ──OTLP──→ Prometheus (metrics)
                                           ──OTLP──→ Loki (logs)
```

**OTEL Collector pipeline:** Receivers → Processors → Exporters + Connectors (between pipelines).

**Full collector config (`/etc/otel/config.yml`):**
```yaml
receivers:
  otlp:
    protocols:
      grpc: {endpoint: 0.0.0.0:4317}
      http: {endpoint: 0.0.0.0:4318}
  hostmetrics:
    collection_interval: 60s
    scrapers: {cpu: {}, memory: {}, disk: {}, network: {}}
  filelog:
    include: [/var/log/**/*.log]

processors:
  batch:
    timeout: 1s
    send_batch_size: 1024
  memory_limiter:
    limit_mib: 512
    spike_limit_mib: 128
  attributes:
    actions:
      - key: environment
        value: production
        action: upsert
  filter:
    logs:
      include:
        match_type: strict
        record_attributes: [{Key: level, Value: error}]
  probabilistic_sampler:
    sampling_percentage: 15
  tail_sampling:
    decision_wait: 30s
    num_traces: 10000
    policies:
      - name: errors
        type: status_code
        config: {status_code: {status_codes: [ERROR]}}
      - name: slow
        type: latency
        config: {latency: {threshold_ms: 1000}}
      - name: probabilistic
        type: probabilistic
        config: {sampling_percentage: 10}

exporters:
  otlp/tempo:
    endpoint: tempo:4317
    tls: {insecure: true}
  prometheus:
    endpoint: 0.0.0.0:8889
    namespace: otel
  otlphttp/loki:
    endpoint: https://loki:3100/otlp
    tls: {insecure: true}
  debug:
    verbosity: detailed

connectors:
  spanmetrics:
    histogram:
      explicit:
        buckets: [5ms, 10ms, 25ms, 50ms, 100ms, 250ms, 500ms, 1s, 2.5s, 5s, 10s]
    dimensions:
      - name: http.method
      - name: http.status_code
    metrics_flush_interval: 30s

service:
  pipelines:
    traces:
      receivers: [otlp]
      processors: [memory_limiter, batch, attributes, tail_sampling]
      exporters: [otlp/tempo, debug, spanmetrics]
    metrics:
      receivers: [otlp, hostmetrics]
      processors: [memory_limiter, batch, filter]
      exporters: [prometheus, debug]
    logs:
      receivers: [otlp, filelog]
      processors: [memory_limiter, batch]
      exporters: [otlphttp/loki, debug]
    metrics/spanmetrics:
      receivers: [spanmetrics]
      processors: [batch]
      exporters: [prometheus]
```

**Auto-instrumentation:**

**Java:** `-javaagent:opentelemetry-javaagent.jar -Dotel.service.name=my-service -Dotel.exporter.otlp.endpoint=http://otel-collector:4317`

**Python:**
```bash
pip install opentelemetry-distro opentelemetry-exporter-otlp
opentelemetry-bootstrap -a install
OTEL_SERVICE_NAME=my-service OTEL_EXPORTER_OTLP_ENDPOINT=http://otel-collector:4317 \
  opentelemetry-instrument python myapp.py
```

**Go:**
```go
import "go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracegrpc"

exporter, _ := otlptracegrpc.New(ctx, otlptracegrpc.WithEndpoint("otel-collector:4317"),
    otlptracegrpc.WithInsecure())
tp := trace.NewTracerProvider(trace.WithBatcher(exporter))
otel.SetTracerProvider(tp)
```

**.NET:**
```csharp
builder.Services.AddOpenTelemetry().WithTracing(tracing => tracing
    .AddAspNetCoreInstrumentation()
    .AddOtlpExporter(o => o.Endpoint = new Uri("http://otel-collector:4317")));
```

**Node.js:**
```bash
npm install @opentelemetry/sdk-node @opentelemetry/auto-instrumentations-node
OTEL_SERVICE_NAME=my-service OTEL_EXPORTER_OTLP_ENDPOINT=http://otel-collector:4317 \
  node --require @opentelemetry/auto-instrumentations-node/register app.js
```

**Manual instrumentation (Python):**
```python
from opentelemetry import trace
tracer = trace.get_tracer(__name__)

with tracer.start_as_current_span("process_payment") as span:
    span.set_attribute("payment.id", payment_id)
    span.set_attribute("payment.amount", 99.99)
    span.add_event("payment.authorized", {"provider": "stripe"})
    try:
        result = charge(payment_id)
        span.set_status(trace.StatusCode.OK)
    except Exception as e:
        span.record_exception(e)
        span.set_status(trace.StatusCode.ERROR, str(e))
```

**Sampling:** Head-based (decision at SDK per trace, propagates via W3C trace-context) vs tail-based (decision in collector after seeing all spans — keeps ALL errors, ALL slow, 10% of rest).

---

## 14. Unified Observability

**Grafana workflow:**
1. Metric spike in Prometheus → click "Logs" → jump to Loki with same time range
2. Error logs → click trace ID (via derived field) → jump to Tempo trace
3. Full distributed trace with each span's timing

**Exemplars:** Metric samples carrying trace ID. Configured in Prometheus datasource:
```yaml
jsonData:
  exemplarTraceIdDestinations:
    - name: traceID
      url: http://tempo:3200/explore?traceId=$${__value.raw}
```

**Derived fields (Loki):**
```yaml
datasources:
  - name: Loki
    jsonData:
      derivedFields:
        - name: traceID
          matcherRegex: "trace_id=(\\w+)"
          url: "http://tempo:3200/explore?traceId=$${__value.raw}"
```

**Correlations (provisioning):**
```yaml
apiVersion: 1
correlations:
  - sourceUID: prometheus-uid
    targetUID: tempo-uid
    label: "View Trace"
    config:
      type: query
      field: "traceID"
      target: {expr: '{.traceID = "${traceID}"}'}
```

**Kubernetes observability (kube-prometheus-stack):**
```bash
helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring --create-namespace \
  --set grafana.adminPassword=admin \
  --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage=100Gi
```

Key K8s metrics: `kube_pod_status_phase`, `kube_node_status_condition`, `kube_deployment_status_replicas_available`.

**Cost of observability:**

| Factor | Impact | Mitigation |
|--------|--------|------------|
| High cardinality | More RAM, disk, network | Drop high-cardinality labels |
| Retention | Linear storage growth | Downsample, tiered storage |
| Scrape interval | 1s vs 30s = 30x more data | 15s critical, 60s non-critical |
| Log volume | 50 GB/day = $150/mo cloud | Filter debug at source |
| Trace volume | ~20 bytes/span, millions/s | Sample 1% → 100x reduction |

**Recommended for 10 hosts / 50 pods:** Prometheus 8GB RAM/30d, Loki 4GB/30d, Tempo 4GB/7d/10% sampling, OTEL Collector 512MB.

---

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

---

## Deep Understanding

**Monitoring anti-patterns to avoid:**
- **Dashboard overload:** 50 panels per dashboard — no one reads it. Create focused dashboards (RED per service, USE per node, SLO compliance).
- **Alert fatigue:** 200 alerts per night — people ignore them. Tune thresholds, use `for:` to debounce, group by severity, inhibit noise.
- **Metric dumping:** Exposing every possible metric from an application. Choose cardinality-aware metrics. Use histograms, not summary + quantile label combinations.
- **Label abuse:** `method`, `path`, `status` as labels on a counter is fine. `url`, `user_agent`, `request_id` as labels will crash Prometheus.

**How Prometheus TSDB stores data:** Incoming samples go to WAL first (crash recovery), then in-memory head block. Every 2 hours, head is frozen into an immutable block: `chunks/` (Gorilla XOR compressed floats, ~1.3 bytes/sample), `index` (inverted label→series posting lists, delta-encoded and varint-compressed). Compaction merges smaller blocks into larger ones (removes tombstones, deduplicates). Query execution: parse PromQL → AST → look up posting lists → intersect/union → read chunk references → mmap decompress → decode samples → apply functions.

**Pull vs Push:** Pull (Prometheus) — server discovers and scrapes targets. Advantages: dead target detection, central control, federation, simple HA, targets don't need to know the monitoring system. Push (Graphite/InfluxDB/Datadog) — targets send to receiver. Better for short-lived jobs (batch/serverless), firewalled environments, high-frequency metrics.

**Prometheus vs VictoriaMetrics:** VictoriaMetrics is a drop-in Prometheus-compatible alternative that uses less RAM (no head block in RAM, uses mmap), has better disk compression (e.g., `ZSTD` instead of `gzip` for chunks), supports downsampling natively, and handles high cardinality better. It speaks both PromQL and MetricsQL (superset). Can be used as a remote write backend or a Prometheus replacement.

**Loki cost-effective storage:** Only labels (metadata) are indexed, not log content. Content is compressed (gzip/snappy) into chunks stored in object storage. Index is ~1% of data vs Elasticsearch's 50-100%. Queries scan compressed chunks in parallel — slower than full-text search but dramatically cheaper.

**OTEL Collector pipeline:** Receivers (OTLP, hostmetrics, filelog) → Processors (batch for efficiency, memory_limiter to prevent OOM, filter to drop data, attributes to add metadata, tail_sampling to keep important traces) → Exporters (OTLP to backends, Prometheus HTTP, debug). Connectors link pipelines (spanmetrics creates metrics from traces). Fan-out sends data to multiple exporters. Queued retry provides at-least-once delivery. Tail-based sampling decisions: wait 30s for all spans, then keep ALL errors + ALL slow traces + 10% of rest.

---

## Observability Maturity Model

| Level | Metrics | Logs | Traces | Alerting | Culture |
|-------|---------|------|--------|----------|---------|
| 0: None | No metrics | No collection | No tracing | No alerts | "It broke, fix it" |
| 1: Basic | CPU/memory from cloud console | grep in SSH sessions | Manual correlation | Email alerts, 50% false positive | "The monitoring is down again" |
| 2: Standard | Prometheus + node_exporter, core metrics | Loki, structured JSON logs | Tempo for critical services | Alertmanager with grouping, Slack | "Pager went off at 3am, was a deployment" |
| 3: Advanced | Application metrics, RED/USE method, SLOs | LogQL alerting, log patterns | All services traced, sampling configured | Multi-window, multi-burn-rate alerts | On-call responds to real issues only |
| 4: Automated | Auto-instrumented via OTEL, full coverage | Automated log parsing, anomaly detection | Tail-based sampling, service graphs | Auto-remediation (webhook → K8s rollback) | "The system fixed itself before anyone noticed" |

---

## Command Reference

| Tool | Command / File | Purpose |
|------|---------------|---------|
| **Prometheus** | `/etc/prometheus/prometheus.yml` | Main config |
| | `/etc/prometheus/rules/*.yml` | Alerting/recording rules |
| | `promtool check config /etc/prometheus/prometheus.yml` | Validate config |
| | `curl localhost:9090/api/v1/targets` | List scrape targets |
| | `curl localhost:9090/api/v1/query?query=up` | Instant query |
| **Alertmanager** | `/etc/alertmanager/alertmanager.yml` | Config |
| | `amtool alert` / `amtool silence add ...` | Manage alerts/silences |
| **node_exporter** | `node_exporter --collector.textfile.directory=/path` | Custom metrics |
| | `curl localhost:9100/metrics` | Exposed metrics |
| **blackbox** | `curl 'localhost:9115/probe?target=https://x.com&module=http_2xx'` | Manual probe |
| **Grafana** | `/etc/grafana/provisioning/datasources/` | Datasource provisioning |
| | `/etc/grafana/provisioning/dashboards/` | Dashboard provisioning |
| | `/etc/grafana/provisioning/alerting/` | Alerting provisioning |
| **Loki** | `/etc/loki/config.yml` | Config |
| | `curl localhost:3100/loki/api/v1/labels` | List label names |
| | `curl 'localhost:3100/loki/api/v1/query_range?query={job="nginx"}'` | Query logs |
| **Promtail** | `/etc/promtail/config.yml` | Config |
| | `promtail --config.file=/etc/promtail/config.yml` | Run agent |
| **LogCLI** | `logcli query '{job="nginx"}' --since=1h` | Query logs from CLI |
| | `logcli query '{job="nginx"}' --tail` | Tail live logs |
| **Tempo** | `/etc/tempo/tempo.yml` | Config |
| | `curl localhost:3200/api/traces/{traceID}` | Get trace by ID |
| | `curl 'localhost:3200/api/search?q={.service.name="frontend"}'` | TraceQL search |
| **OTEL Collector** | `/etc/otel/config.yml` | Config |
| | `otelcol-contrib --config /etc/otel/config.yml` | Run collector |
| | `curl localhost:8889/metrics` | Collector's own metrics |
| **Auto-instr** | `java -javaagent:opentelemetry-javaagent.jar -jar app.jar` | Java |
| | `opentelemetry-instrument python app.py` | Python |
| | `node --require @opentelemetry/auto-instrumentations-node/register app.js` | Node.js |

---

## What's Coming in Part 57

**Part 57: Modern Linux Networking — eBPF, Cilium, WireGuard, VXLAN**

We will cover:
- eBPF architecture: verifier, JIT compiler, maps, helpers, kprobes, tracepoints, XDP, TC
- Cilium: eBPF-based CNI, service mesh, network policies, Hubble, cluster mesh
- WireGuard: kernel-level VPN, configuration, wg-quick, roaming
- VXLAN: overlay networking, VTEPs, L2 over L3, VNI
- BGP: MetalLB, Cilium BGP, Calico BGP for Kubernetes
- Advanced troubleshooting: bpftrace, tcpdump, tc, ss, iproute2
- Performance tuning: RPS/RFS/XPS, TSO/GRO, ring buffers, IRQ affinity

---

## Self-Test

1. What are the three pillars of observability and what does each tell you?
2. How does Prometheus's pull model differ from push-based monitoring? Give one advantage.
3. Write a PromQL query for per-instance CPU utilization (non-idle, 5m average).
4. What is the difference between `rate()` and `irate()`?
5. Write a recording rule for 5m average memory utilization ratio.
6. Explain `relabel_configs` vs `metric_relabel_configs`.
7. How does Alertmanager `group_by` work and why is it useful?
8. Write an `alertmanager.yml` routing critical alerts to Slack, warning to email.
9. How does Loki differ from Elasticsearch for log storage? Why is it cheaper?
10. Write a LogQL query for p99 latency from nginx logs with a `duration_ms` field.
11. What are the 4 main OTEL Collector component types?
12. What is the difference between head-based and tail-based sampling?
13. Write a YAML snippet provisioning a Prometheus datasource in Grafana.
14. Write a PromQL alert: disk on `/` below 10% for 5 minutes.
15. How do derived fields in Loki link logs to Tempo traces?

**Score:** 12/15 correct = ready for Part 57.

---

*Linux SysAdmin Course | Part 56 of ∞ | Reverse Engineering Approach*
*Previous → Part 55: Immutable Infrastructure*
*Next → Part 57: Modern Linux Networking*

[← Previous](part55.md) | [Next →](part57.md)
