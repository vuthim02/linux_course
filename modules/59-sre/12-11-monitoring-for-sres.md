## 11. Monitoring for SREs

### Alert Fatigue Mitigation

| Problem | Solution |
|---|---|
| Too many alerts | Page on symptoms, not causes |
| Duplicate alerts | Alertmanager grouping + inhibition |
| Noisy alerts | Tune thresholds, add `for` duration |

**Page on symptoms (users affected), not causes (pod restarting):**
```
✅ "Error rate > 5% for 5 minutes"
❌ "Node disk > 80%" (ticket, not page)
❌ "Pod restart > 3" (ticket, not page)
```

### Runbooks

Every alert needs a runbook:

```yaml
alert: HighErrorRateCheckoutAPI
runbook:
  severity: SEV2
  dashboard: https://grafana.internal/d/checkout-sre
  investigate:
    - "1. Open SLO dashboard — is SLO violated?"
    - "2. Check deploy activity: kubectl rollout history deployment/checkout-api"
    - "3. Check upstream: curl -s http://payment-api:8080/health"
    - "4. Check DB: kubectl exec checkout-api-0 -- pg_isready"
    - "5. Check logs: kubectl logs -l app=checkout-api --tail=100 | grep ERROR"
  mitigate:
    - "1. Rollback: kubectl rollout undo deployment/checkout-api"
    - "2. Scale: kubectl scale deployment/checkout-api --replicas=10"
    - "3. Circuit break: kubectl apply -f k8s/circuit-breaker.yaml"
  escalate:
    - "Not resolved in 15 min → secondary on-call"
    - "SLO violation → engineering manager"
```

### Dashboard SLOs

```json
{
  "panels": [
    {
      "title": "SLO Compliance (30d)",
      "expr": "sum(increase(http_requests_total{status=~\"2..\"}[30d])) / sum(increase(http_requests_total[30d])) * 100",
      "type": "stat",
      "thresholds": [{"value": 99.9, "color": "green"}, {"value": 99.0, "color": "yellow"}, {"value": 0, "color": "red"}]
    },
    {
      "title": "Error Budget Remaining",
      "expr": "clamp_max((1 - ((1 - (sum(increase(http_requests_total{status=~\"2..\"}[30d])) / sum(increase(http_requests_total[30d])))) / (1 - 0.999))) * 100, 100)",
      "type": "gauge",
      "thresholds": [{"value": 60, "color": "green"}, {"value": 30, "color": "yellow"}, {"value": 0, "color": "red"}]
    },
    {
      "title": "Burn Rate (1h, 6h, 3d)",
      "expr": "(1 - (sum(rate(http_requests_total{status=~\"2..\"}[1h])) / sum(rate(http_requests_total[1h])))) / (1 - 0.999)",
      "type": "timeseries"
    }
  ]
}
```

### Multi-Window Multi-Burn-Rate (MWMBR) Alerts

The gold standard. Fires only when **both** a short-term AND long-term window detect budget consumption.

#### How MWMBR Works

```
short_window (5m, 14.4× burn):  detects urgent consumption
long_window  (30m, 6× burn):    confirms steady degradation

Alert fires when:  short_window ratio > threshold
                    AND
                    long_window ratio > threshold
```

#### Prometheus MWMBR Rules

```yaml
groups:
  - name: mwmbr_slo_alerts
    interval: 1m
    rules:
      - alert: MWMBR_SLOConsumed
        expr: |
          (1 - (sum(rate(http_requests_total{job="checkout",status=~"2.."}[5m]))
                / sum(rate(http_requests_total{job="checkout"}[5m]))))
          > 14.4 * (1 - 0.999)
          AND
          (1 - (sum(rate(http_requests_total{job="checkout",status=~"2.."}[30m]))
                / sum(rate(http_requests_total{job="checkout"}[30m]))))
          > 6 * (1 - 0.999)
        for: 2m
        labels: { severity: critical }
        annotations:
          summary: "MWMBR: Fast+moderate burn rate breach"
          description: "Budget consumption critical — both 5m and 30m windows"

      - alert: MWMBR_SLOConsumed_Slow
        expr: |
          (1 - (sum(rate(http_requests_total{job="checkout",status=~"2.."}[30m]))
                / sum(rate(http_requests_total{job="checkout"}[30m]))))
          > 6 * (1 - 0.999)
          AND
          (1 - (sum(rate(http_requests_total{job="checkout",status=~"2.."}[3d]))
                / sum(rate(http_requests_total{job="checkout"}[3d]))))
          > 1.5 * (1 - 0.999)
        for: 5m
        labels: { severity: warning }
        annotations:
          summary: "MWMBR: Moderate+slow burn rate breach"
```

#### Why MWMBR Works

| Scenario | Short Window | Long Window | Alert? |
|---|---|---|---|
| Transient spike (1 min) | High burn | Normal | No |
| Steady degradation (leak) | Moderate burn | High burn | Yes |
| Full outage | Very high burn | Very high burn | Yes |
| Expected traffic surge | Normal | Normal | No |





[← Previous](11-10-release-engineering.md) | [↑ Index](index.md) | [Next →](13-12-chaos-engineering.md)
