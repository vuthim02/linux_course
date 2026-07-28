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


## Answer Key

### Q1: What are the three pillars of observability?
**Answer:** Metrics (numeric time-series: CPU, memory, request rate), Logs (timestamped events: error messages), Traces (request flow across services: latency, dependencies).

### Q2: How does Prometheus's pull model differ from push?
**Answer:** Pull: Prometheus scrapes targets at intervals (simpler, no delivery failures). Push: apps send metrics to a collector (Pushgateway). Advantage of pull: Prometheus detects down targets.

### Q3: PromQL for per-instance CPU utilization (5m average).
**Answer:** `100 - (avg by(instance)(irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)`

### Q4: What is the difference between `rate()` and `irate()`?
**Answer:** `rate()` = average per-second rate over the range (smooth). `irate()` = instant rate between last two points (spiky, shows bursts).

### Q5: Recording rule for 5m memory utilization ratio.
**Answer:**
```yaml
- record: instance:memory_utilization:ratio
  expr: 1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)
```

### Q6: `relabel_configs` vs `metric_relabel_configs`.
**Answer:** `relabel_configs` runs at scrape time (modifies labels on targets/metrics). `metric_relabel_configs` runs after scrape (modifies metric labels before storage).

### Q7: How does Alertmanager `group_by` work?
**Answer:** Groups alerts with matching label values into a single notification. Reduces alert fatigue — e.g., group all alerts from the same instance.

### Q8: Alertmanager config for critical→Slack, warning→email.
**Answer:**
```yaml
route:
  group_by: [alertname]
  routes:
    - match: { severity: critical }
      receiver: slack
    - match: { severity: warning }
      receiver: email
receivers:
  - name: slack
    slack_configs: [{ channel: '#alerts', ... }]
  - name: email
    email_configs: [{ to: 'admin@example.com' }]
```

### Q9: Loki vs Elasticsearch?
**Answer:** Loki indexes only labels (not full text), uses object storage (S3/GCS), much cheaper. Elasticsearch indexes all text (expensive, requires more resources).

### Q10: LogQL for p99 latency from nginx logs.
**Answer:** `quantile_over_time(0.99, {job="nginx"} | json | unwrap duration_ms [5m])`

### Q11: The 4 main OTEL Collector component types.
**Answer:** Receivers (import data), Processors (transform/filter), Exporters (send data), Extensions (healthcheck, pprof).

### Q12: Head-based vs tail-based sampling?
**Answer:** Head-based: makes sampling decision at collection time (simpler, less context). Tail-based: makes decision after collecting full trace (better accuracy, needs central storage).

### Q13: YAML for Prometheus datasource in Grafana.
**Answer:**
```yaml
apiVersion: 1
datasources:
  - name: Prometheus
    type: prometheus
    url: http://prometheus:9090
    access: proxy
    isDefault: true
```

### Q14: PromQL alert for disk below 10% for 5 minutes.
**Answer:** `predict_time(node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"} < 0.1, 5m)`

### Q15: How do Loki derived fields link logs to traces?
**Answer:** Derived fields extract a trace ID from log lines and create a clickable link to Tempo, allowing you to jump from a log entry directly to its distributed trace.


*Linux SysAdmin Course | Part 56 of ∞ | Reverse Engineering Approach*
*Previous → Part 55: Immutable Infrastructure*
*Next → Part 57: Modern Linux Networking*

[← Previous](part55.md) | [Next →](part57.md)



[← Previous](19-whats-coming-in-part-57.md) | [↑ Index](index.md)
