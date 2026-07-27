## 9. Observability Stack

### kube-prometheus-stack

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --set prometheus.prometheusSpec.scrapeInterval=15s \
  --set prometheus.prometheusSpec.evaluationInterval=15s \
  --set prometheus.prometheusSpec.retention=30d \
  --set prometheus.prometheusSpec.retentionSize=50GB \
  --set prometheus.prometheusSpec.resources.requests.cpu=500m \
  --set prometheus.prometheusSpec.resources.requests.memory=2Gi \
  --set prometheus.prometheusSpec.resources.limits.cpu=1000m \
  --set prometheus.prometheusSpec.resources.limits.memory=4Gi \
  --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.storageClassName=ebs-gp3-retained \
  --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage=100Gi \
  --set alertmanager.enabled=true \
  --set alertmanager.alertmanagerSpec.replicas=2 \
  --set grafana.adminPassword=admin \
  --set grafana.defaultDashboardsEnabled=true \
  --set grafana.plugins="{grafana-piechart-panel}" \
  --set grafana.sidecar.dashboards.enabled=true \
  --set grafana.sidecar.dashboards.label=grafana_dashboard \
  --set grafana.sidecar.datasources.enabled=true
```

### Grafana Dashboards — Application SLO

```json
{
  "dashboard": {
    "title": "Capstone API - SLO Dashboard",
    "tags": ["slo", "capstone"],
    "timezone": "browser",
    "panels": [
      {
        "title": "Request Rate",
        "type": "graph",
        "gridPos": {"h": 8, "w": 12, "x": 0, "y": 0},
        "targets": [
          {
            "expr": "sum(rate(app_requests_total[5m]))",
            "legendFormat": "Total Requests/s"
          }
        ]
      },
      {
        "title": "Error Rate (5xx)",
        "type": "graph",
        "gridPos": {"h": 8, "w": 12, "x": 12, "y": 0},
        "targets": [
          {
            "expr": "sum(rate(app_errors_total[5m]))",
            "legendFormat": "Errors/s"
          }
        ]
      },
      {
        "title": "Latency P50 / P95 / P99",
        "type": "graph",
        "gridPos": {"h": 8, "w": 12, "x": 0, "y": 8},
        "targets": [
          {
            "expr": "histogram_quantile(0.50, sum(rate(app_request_duration_seconds_bucket[5m])) by (le))",
            "legendFormat": "P50"
          },
          {
            "expr": "histogram_quantile(0.95, sum(rate(app_request_duration_seconds_bucket[5m])) by (le))",
            "legendFormat": "P95"
          },
          {
            "expr": "histogram_quantile(0.99, sum(rate(app_request_duration_seconds_bucket[5m])) by (le))",
            "legendFormat": "P99"
          }
        ]
      },
      {
        "title": "SLO: Error Budget Remaining (30d rolling)",
        "type": "stat",
        "gridPos": {"h": 8, "w": 12, "x": 12, "y": 8},
        "targets": [
          {
            "expr": "1 - (sum(rate(app_errors_total[30d])) / sum(rate(app_requests_total[30d])))",
            "legendFormat": "Availability"
          }
        ],
        "thresholds": [
          {"value": 0.999, "color": "green"},
          {"value": 0.995, "color": "yellow"},
          {"value": 0.99, "color": "red"}
        ]
      },
      {
        "title": "Active Pods (per version)",
        "type": "graph",
        "gridPos": {"h": 8, "w": 24, "x": 0, "y": 16},
        "targets": [
          {
            "expr": "count(kube_pod_info{namespace=\"production\"}) by (created_by_kind)",
            "legendFormat": "{{created_by_kind}}"
          }
        ]
      }
    ],
    "schemaVersion": 27,
    "version": 1
  }
}
```

### Loki + Promtail for Logs

```bash
helm upgrade --install loki grafana/loki \
  --namespace monitoring \
  --set loki.commonConfig.replication_factor=1 \
  --set loki.storage.type=filesystem \
  --set loki.auth_enabled=false \
  --set singleBinary.replicas=1 \
  --set test.enabled=false

helm upgrade --install promtail grafana/promtail \
  --namespace monitoring \
  --set config.lokiAddress=http://loki.monitoring:3100/loki/api/v1/push \
  --set config.clients[0].url=http://loki.monitoring:3100/loki/api/v1/push \
  --set config.snippets.scrapeConfigs[0].pipelineStages[0].regex.source="(?P<level>(ERROR|WARN|INFO|DEBUG))"
```

### Tempo for Distributed Tracing

```bash
helm upgrade --install tempo grafana/tempo \
  --namespace monitoring \
  --set traces.otlp.grpc.enabled=true \
  --set traces.otlp.http.enabled=true \
  --set storage.trace.backend=local \
  --set storage.trace.local.path=/var/tempo/traces \
  --set server.http_listen_port=3200
```

---



---

[← Previous](08-8-secrets-and-configuration.md) | [↑ Index](index.md) | [Next →](10-10-scaling-and-resilience.md)
