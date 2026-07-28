## Deep Understanding

### How Multi-Window Multi-Burn-Rate (MWMBR) Alerts Work

MWMBR solves a fundamental problem with single-window alerts:

| Single-Window Problem | MWMBR Solution |
|---|---|
| Short window catches spikes → false positives | Require BOTH windows to breach |
| Long window is slow to detect sudden outage | Short window catches it immediately |

**Mathematically:**
```
For 99.9% SLO: target_error_rate = 1 - 0.999 = 0.001

Fast detection: error_rate > 14.4 × 0.001 = 1.44% for 1h
  → consumes 14.4h of budget per hour → exhausts in 30d/14.4 ≈ 2 days
Slow detection: error_rate > 6 × 0.001 = 0.6% for 6h
  → consumes 6h of budget per hour → exhausts in 30d/6 ≈ 5 days
Both must fire → alert
```

| Scenario | 5m | 30m | 6h | 3d | Alert? |
|---|---|---|---|---|---|
| Deploy causes 100% failure | 100× | 100× | 100× | 100× | Yes |
| Slow connection leak | Normal | 8× | 4× | 2× | Yes |
| Flash sale traffic spike | 2× | 1.5× | 1.1× | 1.0× | No |
| DNS flakes for 30s | 50× | Normal | Normal | Normal | No |

### Prometheus Recording Rules for SLO

```yaml
groups:
  - name: slo_recording_rules
    interval: 1m
    rules:
      - record: slo:events:total:rate_5m
        expr: sum(rate(http_requests_total[5m])) by (job)
      - record: slo:events:good:rate_5m
        expr: sum(rate(http_requests_total{status=~"2.."}[5m])) by (job)
      - record: slo:compliance:increase_30d
        expr: |
          sum(increase(http_requests_total{status=~"2.."}[30d])) by (job)
          /
          sum(increase(http_requests_total[30d])) by (job)
      - record: slo:error_budget:remaining_30d
        expr: |
          1 - ((1 - slo:compliance:increase_30d) / on(job) group_left() (1 - slo_target))
      - record: slo:burn_rate:rate_1h
        expr: |
          (1 - slo:compliance:rate_5m) / on(job) group_left() (1 - slo_target)
```

### Math Behind Error Budget Exhaustion

```
Let:  S = SLO target (0.999),  C = current compliance
Budget remaining = 1 - ((1 - C) / (1 - S))
Budget consumed % = ((1 - C) / (1 - S)) × 100

Example: S = 0.999, C = 0.9985
  Budget consumed = (1 - 0.9985) / (1 - 0.999) = 0.0015 / 0.001 = 150% (exhausted)

Time to exhaust at burn rate R:
  Time = window_days / R
  If R = 3× and window = 30 days: Time = 30 / 3 = 10 days
```

### How the SRE Team Model Scales

| Model | Team Size | Services | Pros | Cons |
|---|---|---|---|---|
| **Embedded** | 1 SRE per 6-8 devs | 2-3 per SRE | Deep context | SREs isolated |
| **Consultative** | 3-5 SREs | 10-20 | Scalable practices | Can be bottleneck |
| **Centralized** | 5-10 SREs | 20-50 | Shared on-call | Less context |

**Growth path:**
```
Startup (<20)  → devs own ops
Early (20-50)  → 1-2 embedded SREs
Growth (50-200) → central SRE (3-5)
Scale (>200)   → embedded + platform (8-15)
```





[← Previous](15-15-hands-on-practices.md) | [↑ Index](index.md) | [Next →](17-command-reference.md)
