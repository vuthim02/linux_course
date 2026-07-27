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



---

[← Previous](07-7-alertmanager.md) | [↑ Index](index.md) | [Next →](09-9-grafana-provisioning.md)
