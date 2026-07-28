## 4. Error Budgets

The error budget is the **acceptable amount of unreliability** in a service.

### Definition
```
Error budget = 100% - SLO target = 100% - 99.9% = 0.1%
```

For 10M requests/day: daily budget = 10,000,000 × 0.001 = 10,000 failed requests.

### Budget Consumption Rate
```
consumption_rate = (1 - current_compliance) / (1 - SLO_target) × 100
```

### Spending Policy

| Budget Remaining | Action |
|---|---|
| > 60% | Normal deploys |
| 30% — 60% | Add manual review |
| 10% — 30% | Deploy freeze |
| < 10% | War room |
| 0% (exhausted) | Rollback |

### Budget Burn Rate Alerts

Burn rate = `error_rate / (1 - SLO_target)`

| Type | Window | Burn Rate | Page? |
|---|---|---|---|
| Fast burn | 1h | 14.4× | Yes (pager) |
| Medium burn | 6h | 6× | Yes (pager) |
| Slow burn | 3d | 1.5× | Ticket/email |

### Prometheus Alerting Rules

```yaml
groups:
  - name: error_budget_burn_rate
    interval: 1m
    rules:
      - alert: ErrorBudgetFastBurn
        expr: |
          (1 - (sum(rate(http_requests_total{status=~"2.."}[1h])) / sum(rate(http_requests_total[1h]))))
          > 14.4 * (1 - 0.999)
        for: 5m
        labels: { severity: critical }
        annotations:
          summary: "Fast error budget burn ({{ $value | humanize }}x)"
          description: "Budget would exhaust in ~2 days"

      - alert: ErrorBudgetMediumBurn
        expr: |
          (1 - (sum(rate(http_requests_total{status=~"2.."}[6h])) / sum(rate(http_requests_total[6h]))))
          > 6 * (1 - 0.999)
        for: 5m
        labels: { severity: warning }
        annotations:
          summary: "Medium error budget burn ({{ $value | humanize }}x)"
          description: "Budget would exhaust in ~5 days"

      - alert: ErrorBudgetSlowBurn
        expr: |
          (1 - (sum(rate(http_requests_total{status=~"2.."}[3d])) / sum(rate(http_requests_total[3d]))))
          > 1.5 * (1 - 0.999)
        for: 10m
        labels: { severity: info }
        annotations:
          summary: "Slow error budget burn ({{ $value | humanize }}x)"
          description: "Budget would exhaust in ~20 days"
```

### Error Budget Policy

```yaml
service: checkout-api
slo: 99.9% availability over 30d
error_budget: 0.1%

policies:
  deploy_freeze:
    condition: error_budget_remaining < 10%
    action: Block all production deploys
  postmortem_trigger:
    condition: budget_exhausted == true
    action: Blameless postmortem within 5 business days
  rollback:
    condition: error_budget_consumed > 20% in 1h
    action: Auto-rollback last deploy
```

### Error Budget Culture

The error budget is a **negotiation between SRE and product development**:
- Product wants velocity → they consume error budget
- SRE wants reliability → they enforce the budget
- When budget is spent → product velocity stops





[← Previous](04-3-service-level-objectives-slos.md) | [↑ Index](index.md) | [Next →](06-5-four-golden-signals.md)
