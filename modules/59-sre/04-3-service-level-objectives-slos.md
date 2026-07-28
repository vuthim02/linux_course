## 3. Service Level Objectives (SLOs)

An SLO is a **target value or range** for an SLI.

### Target Definition
```
SLO: 99.9% of requests succeed with latency < 200ms (p99) over a 30-day rolling window.
```

### SLO Window

| Window | Use Case |
|---|---|
| 30 days | Standard for web services |
| 7 days | Critical path services |
| Quarterly | Reporting and reviews |

### SLO Compliance Calculation
```
compliance = good_events / total_events over the window
```

With Prometheus recording rules:
```yaml
groups:
  - name: slo_rules
    interval: 1m
    rules:
      - record: slo:checkout_total_requests:rate_5m
        expr: sum(rate(http_requests_total{endpoint="/api/checkout"}[5m]))
      - record: slo:checkout_good_requests:rate_5m
        expr: sum(rate(http_requests_total{endpoint="/api/checkout",status=~"2.."}[5m]))
      - record: slo:checkout_compliance:rate_30d
        expr: |
          sum(increase(http_requests_total{endpoint="/api/checkout",status=~"2.."}[30d]))
          /
          sum(increase(http_requests_total{endpoint="/api/checkout"}[30d]))
```

### Multi-SLO Services

| Operation | SLO | Downtime/yr |
|---|---|---|
| GET /api/products | 99.99% | 52.56 min |
| POST /api/checkout | 99.9% | 8.76 h |
| POST /api/reports | 99.0% | 3.65 days |

### Why 100% Is the Wrong Target

- **Cost grows exponentially** approaching 100% (redundancy, testing, engineering time)
- **Users cannot tell** the difference between 99.999% and 100%
- **Innovation stops** — no error budget remains for risky changes
- **False precision** — no measurement system is perfectly accurate

> "The difference between 99.9% and 99.99% is 10x the engineering cost for 0.09% improvement." — Ben Treynor Sloss





[← Previous](03-2-service-level-indicators-slis.md) | [↑ Index](index.md) | [Next →](05-4-error-budgets.md)
