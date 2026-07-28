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





[← Previous](08-8-grafana.md) | [↑ Index](index.md) | [Next →](10-10-loki.md)
