## 🔍 Section 8: PromQL — Prometheus Query Language

### 8.1 Selectors

```promql
# Basic selector
node_cpu_seconds_total

# With label matchers
node_cpu_seconds_total{cpu="0",mode="idle"}
node_cpu_seconds_total{cpu=~"0|1",mode=~"idle|system"}
node_cpu_seconds_total{mode!="idle"}

# Range vector — last 5 minutes
node_memory_MemAvailable_bytes[5m]

# Offset — compare to 1 week ago
node_memory_MemAvailable_bytes offset 1w
```

### 8.2 Rate and Irate

```promql
# rate() — per-second average over a time window (for counters)
rate(node_cpu_seconds_total{mode="idle"}[5m])

# irate() — instantaneous rate based on last 2 samples
irate(node_cpu_seconds_total{mode="idle"}[5m])

# rate()  → smooth, good for alerting
# irate() → spike-sensitive, good for graphs

# CPU utilization percentage
rate(node_cpu_seconds_total{mode!="idle"}[5m]) * 100

# HTTP requests per second
rate(prometheus_http_requests_total[1m])

# Network bytes per second
rate(node_network_receive_bytes_total[5m])
```

### 8.3 Aggregations

```promql
# sum — sum over all dimensions
sum(rate(node_cpu_seconds_total{mode="idle"}[5m]))

# avg — average across dimensions
avg(rate(node_cpu_seconds_total{mode="idle"}[5m]))

# min / max — extremes
min(node_memory_MemAvailable_bytes)
max(node_memory_MemAvailable_bytes)

# count — count of time series
count(node_cpu_seconds_total)

# topk / bottomk
topk(3, rate(node_network_receive_bytes_total[5m]))
bottomk(3, node_filesystem_free_bytes)

# quantile — approximate quantile
quantile(0.95, rate(http_request_duration_seconds_sum[5m]))

# Group: preserve specific labels
sum by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m]))
avg by (instance, cpu) (rate(node_cpu_seconds_total[5m]))

# Without: exclude labels
sum without (cpu, mode) (rate(node_cpu_seconds_total[5m]))
```

### 8.4 Binary Operators

```promql
# Arithmetic
node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes
node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes

# Memory used percentage
(node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes * 100

# Comparison (result is 0 or 1)
node_load1 > node_load15
node_filesystem_avail_bytes < 1e10
```

### 8.5 Functions

```promql
# increase() — total increase over window (counter)
increase(node_network_receive_bytes_total[1h])

# delta() — difference between first and last value (gauge)
delta(node_memory_MemAvailable_bytes[15m])

# predict_linear() — linear regression prediction
predict_linear(node_filesystem_free_bytes[1h], 3600)

# histogram_quantile() — calculate quantiles from histogram
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))

# time() — current Unix timestamp
time() - node_boot_time_seconds  # System uptime in seconds
```

### 8.6 Recording Rules

```yaml
# /opt/prometheus/rules/recording.yml

groups:
  - name: cpu_recording_rules
    interval: 15s
    rules:
      - record: instance:cpu_utilization:rate5m
        expr: |
          100 - (avg by (instance)
            (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

      - record: instance:memory_utilization:ratio
        expr: |
          (node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes)
          / node_memory_MemTotal_bytes

  - name: disk_recording_rules
    interval: 1m
    rules:
      - record: instance:disk_used:bytes
        expr: |
          node_filesystem_size_bytes{mountpoint!=""}
          - node_filesystem_free_bytes{mountpoint!=""}

      - record: instance:disk_used:percent
        expr: |
          (node_filesystem_size_bytes{mountpoint!=""}
          - node_filesystem_free_bytes{mountpoint!=""})
          / node_filesystem_size_bytes{mountpoint!=""} * 100
```





[← Previous](09-section-7-prometheus.md) | [↑ Index](index.md) | [Next →](11-section-9-prometheus-exporters.md)
