## 2. Service Level Indicators (SLIs)

An SLI is a **carefully defined quantitative measure** of some aspect of the service.

### What to Measure

| SLI | Definition | Example |
|---|---|---|
| Latency | Time to respond to a request | p99 latency < 200ms |
| Availability | Fraction of requests that succeed | 99.9% of requests return HTTP 2xx |
| Throughput | Requests processed per second | 10,000 req/s sustained |
| Error Rate | Fraction of requests that fail | < 0.1% HTTP 5xx |
| Durability | Probability data survives | 99.999999999% (11 9s) |

### Measuring SLIs

**Server-Side (Prometheus):**
```
# TYPE http_requests_total counter
http_requests_total{method="GET",endpoint="/api/checkout",status="200"} 102345
http_requests_total{method="GET",endpoint="/api/checkout",status="500"} 45
```

**Client-Side (RUM):**
```javascript
const observer = new PerformanceObserver((list) => {
  for (const entry of list.getEntries()) {
    navigator.sendBeacon('/metrics', JSON.stringify({
      name: entry.name, duration: entry.duration
    }));
  }
});
observer.observe({ entryTypes: ['navigation', 'resource'] });
```

**Request Logs:**
```json
{"timestamp":"2026-06-24T03:15:22.123Z","method":"POST","path":"/api/checkout","status":500,"latency_ms":2340,"trace_id":"ab12cd34ef56"}
```

### Tail Latency

Average latency lies. Measure percentiles.

| Percentile | Meaning | Example |
|---|---|---|
| p50 (median) | Half of requests faster than this | 45ms |
| p90 | 90% of requests faster than this | 120ms |
| p99 | 99% of requests faster than this | 350ms |
| p999 | 99.9% of requests faster than this | 2100ms |

In PromQL:
```promql
histogram_quantile(0.50, rate(http_request_duration_seconds_bucket[5m]))
histogram_quantile(0.99, rate(http_request_duration_seconds_bucket[5m]))
```

---



---

[← Previous](02-1-what-is-sre.md) | [↑ Index](index.md) | [Next →](04-3-service-level-objectives-slos.md)
