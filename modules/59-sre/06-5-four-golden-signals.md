## 5. Four Golden Signals

### 1. Latency
```promql
histogram_quantile(0.99, sum(rate(http_request_duration_seconds_bucket{status=~"2.."}[5m])) by (le))
```

### 2. Traffic
```promql
sum(rate(http_requests_total[5m])) by (endpoint)
```

### 3. Errors
```promql
sum(rate(http_requests_total{status=~"5.."}[5m])) / sum(rate(http_requests_total[5m]))
```

### 4. Saturation
```promql
1 - avg(rate(node_cpu_seconds_total{mode="idle"}[5m]))

node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes
```

### The RED Method (for services)

| Metric | What |
|---|---|
| Rate | Requests per second |
| Errors | Failed requests per second |
| Duration | Latency distributions |

### The USE Method (for resources)

| Metric | What |
|---|---|
| Utilization | Average time resource was busy |
| Saturation | Degree of extra work queued |
| Errors | Count of error events |

```promql
# CPU utilization
1 - avg(rate(node_cpu_seconds_total{mode="idle"}[5m]))
# CPU saturation
node_load1 / node_cpu_cores_total
# Disk errors
rate(node_disk_io_time_seconds_total{device=~"sd.*"}[5m])
```





[← Previous](05-4-error-budgets.md) | [↑ Index](index.md) | [Next →](07-6-toil-reduction.md)
