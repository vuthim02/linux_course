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





[← Previous](02-2-prometheus-architecture.md) | [↑ Index](index.md) | [Next →](04-4-prometheus-exporters.md)
