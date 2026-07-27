## 15 Hands-On Practices

### Practice 1: Define 3 SLIs for a Web Service

```yaml
service: payment-gateway
sli_1_latency:
  name: "Charge creation latency"
  metric: "p99 for POST /api/v1/charges"
  query: "histogram_quantile(0.99, rate(http_request_duration_seconds_bucket{endpoint='/api/v1/charges'}[5m]))"
  target: "< 500ms"

sli_2_availability:
  name: "API availability"
  metric: "Fraction of requests returning 2xx"
  query: "sum(rate(http_requests_total{status=~'2..'}[5m])) / sum(rate(http_requests_total[5m]))"
  target: "> 99.9%"

sli_3_error_rate:
  name: "Charge failure rate"
  metric: "Fraction of charges that fail"
  query: "sum(rate(http_requests_total{endpoint='/api/v1/charges',status=~'5..'}[5m])) / sum(rate(http_requests_total{endpoint='/api/v1/charges'}[5m]))"
  target: "< 1%"
```

✅ **Expected**: Three SLIs with name, measurement method, and target.

### Practice 2: Measure SLIs from Prometheus Metrics

Given histogram buckets:
```
le="0.005": 11234  le="0.01": 22345  le="0.025": 44567
le="0.05": 67890   le="0.1": 89123   le="0.25": 94567
le="0.5": 97890    le="1.0": 99123   le="2.5": 99890
le="5.0": 99999    le="+Inf": 100000
count: 100000      sum: 2678.5
```

```promql
# p50: ~35ms
histogram_quantile(0.50, rate(http_request_duration_seconds_bucket[5m]))
# p90: ~120ms
histogram_quantile(0.90, rate(http_request_duration_seconds_bucket[5m]))
# p99: ~380ms
histogram_quantile(0.99, rate(http_request_duration_seconds_bucket[5m]))
# p999: ~2.3s
histogram_quantile(0.999, rate(http_request_duration_seconds_bucket[5m]))
# Avg: ~26.8ms
rate(http_request_duration_seconds_sum[5m]) / rate(http_request_duration_seconds_count[5m])
```

✅ **Expected**: p50, p90, p99, p999, and average calculated from histogram.

### Practice 3: Set SLO and Calculate Compliance

SLO: 99.9% over 30 days. Total requests: 45M, Failed: 38,500.

```python
total = 45_000_000; failed = 38_500
compliance = (total - failed) / total
print(f"{compliance:.4%}")  # 99.9144%
print(f"SLO met: {compliance >= 0.999}")  # True
```

✅ **Expected**: 99.9144% — SLO met.

### Practice 4: Error Budget Burn-Rate Alerts

```yaml
groups:
  - name: error_budget_alerts
    interval: 30s
    rules:
      - alert: FastBurnRate
        expr: |
          (1 - (sum(rate(http_requests_total{status=~"2.."}[1h])) / sum(rate(http_requests_total[1h]))))
          > 14.4 * (1 - 0.999)
        for: 2m
        labels: { severity: critical }
      - alert: MediumBurnRate
        expr: |
          (1 - (sum(rate(http_requests_total{status=~"2.."}[6h])) / sum(rate(http_requests_total[6h]))))
          > 6 * (1 - 0.999)
        for: 5m
        labels: { severity: warning }
      - alert: SlowBurnRate
        expr: |
          (1 - (sum(rate(http_requests_total{status=~"2.."}[3d])) / sum(rate(http_requests_total[3d]))))
          > 1.5 * (1 - 0.999)
        for: 10m
        labels: { severity: info }
```

```yaml
route:
  receiver: pagerduty-critical
  routes:
    - match: { severity: critical }
      receiver: pagerduty-critical
    - match: { severity: warning }
      receiver: pagerduty-warning
    - match: { severity: info }
      receiver: slack-ticket
receivers:
  - name: pagerduty-critical
    pagerduty_configs: [{ routing_key: <PD_KEY>, severity: critical }]
  - name: pagerduty-warning
    pagerduty_configs: [{ routing_key: <PD_KEY>, severity: warning }]
  - name: slack-ticket
    slack_configs: [{ api_url: <SLACK_URL>, channel: "#sre-alerts" }]
```

✅ **Expected**: Prometheus rules + Alertmanager config with severity routing.

### Practice 5: Deploy and Observe Error Budget Consumption

```bash
#!/bin/bash
set -euo pipefail
APP="checkout-api"; NAMESPACE="checkout"
kubectl apply -f k8s/deployment.yaml -n ${NAMESPACE}
kubectl rollout status deployment/${APP} -n ${NAMESPACE} --timeout=3m
kubectl run traffic-generator --image=alpine/curl -it --rm -- \
  sh -c 'while true; do curl -s http://checkout-api:8080/checkout > /dev/null 2>&1; done' &
while true; do
  C=$(curl -s "http://prometheus:9090/api/v1/query" --data-urlencode \
    'query=sum(increase(http_requests_total{status=~"2.."}[5m])) / sum(increase(http_requests_total[5m]))' \
    | jq -r '.data.result[0].value[1]')
  B=$(echo "1 - ((1 - $C) / (1 - 0.999))" | bc -l)
  echo "[$(date)] Compliance: $(echo "$C*100" | bc -l)% | Budget: $(echo "$B*100" | bc -l)%"
  sleep 30
done
```

✅ **Expected**: Running script showing real-time budget consumption.

### Practice 6: Load Test with k6

```javascript
import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  stages: [
    { duration: '1m', target: 50 },
    { duration: '3m', target: 100 },
    { duration: '1m', target: 0 },
  ],
  thresholds: { http_req_duration: ['p(95)<200'], http_req_failed: ['rate<0.01'] },
};

export default function () {
  const payload = JSON.stringify({
    user_id: `user_${__VU}`,
    items: [{ product_id: `prod_${Math.floor(Math.random()*1000)}`, quantity: 1 }],
    payment_method: "card",
    shipping_address: { street: "123 Test St", city: "Seattle", state: "WA", zip: "98101" }
  });
  const res = http.post('http://localhost:8080/api/checkout', payload, { headers: { 'Content-Type': 'application/json' } });
  check(res, { 'status 200': (r) => r.status === 200, 'duration < 500ms': (r) => r.timings.duration < 500 });
  sleep(1);
}
```

Run: `k6 run loadtest.js`

✅ **Expected**: k6 test results with P95/P99 latency and error rate.

### Practice 7: Grafana Dashboard — SLO & Error Budget

```json
{
  "title": "SRE — Checkout API SLO Dashboard",
  "panels": [
    {
      "title": "SLO Compliance (30d)",
      "expr": "sum(increase(http_requests_total{status=~\"2..\"}[30d])) / sum(increase(http_requests_total[30d])) * 100",
      "type": "stat", "unit": "percent", "decimals": 3,
      "thresholds": [{"value": 99.9, "color": "green"}, {"value": 99.0, "color": "yellow"}, {"value": 0, "color": "red"}]
    },
    {
      "title": "Error Budget Remaining",
      "expr": "clamp_max((1 - ((1 - (sum(increase(http_requests_total{status=~\"2..\"}[30d])) / sum(increase(http_requests_total[30d])))) / (1 - 0.999))) * 100, 100)",
      "type": "gauge", "unit": "percent",
      "thresholds": [{"value": 60, "color": "green"}, {"value": 30, "color": "yellow"}, {"value": 0, "color": "red"}]
    },
    {
      "title": "Burn Rate",
      "type": "timeseries",
      "targets": [
        {"expr": "(1 - (sum(rate(http_requests_total{status=~\"2..\"}[1h])) / sum(rate(http_requests_total[1h])))) / (1 - 0.999)", "legendFormat": "1h"},
        {"expr": "(1 - (sum(rate(http_requests_total{status=~\"2..\"}[6h])) / sum(rate(http_requests_total[6h])))) / (1 - 0.999)", "legendFormat": "6h"}
      ]
    },
    {
      "title": "Latency (p50, p90, p99)",
      "type": "timeseries", "unit": "s",
      "targets": [
        {"expr": "histogram_quantile(0.50, sum(rate(http_request_duration_seconds_bucket[5m])) by (le))", "legendFormat": "p50"},
        {"expr": "histogram_quantile(0.90, sum(rate(http_request_duration_seconds_bucket[5m])) by (le))", "legendFormat": "p90"},
        {"expr": "histogram_quantile(0.99, sum(rate(http_request_duration_seconds_bucket[5m])) by (le))", "legendFormat": "p99"}
      ]
    },
    {
      "title": "Request Rate",
      "type": "timeseries",
      "targets": [
        {"expr": "sum(rate(http_requests_total[5m]))", "legendFormat": "Total"},
        {"expr": "sum(rate(http_requests_total{status=~\"5..\"}[5m]))", "legendFormat": "Errors"}
      ]
    }
  ]
}
```

✅ **Expected**: Grafana JSON dashboard with SLO, budget, burn rate, and latency panels.

### Practice 8: Write a Runbook for High Latency

```yaml
alert: CheckoutAPILatencyHigh
runbook:
  severity: SEV2
  dashboard: https://grafana.internal/d/checkout-sre
  investigation:
    - "1. SLO dashboard → compliance, budget, burn rate"
    - "2. kubectl rollout history deployment/checkout-api -n checkout"
    - "3. Check upstream dependencies: payment-api, inventory-api, shipping-api"
    - "4. kubectl exec deploy/checkout-api -n checkout -- psql -c \"SELECT count(*) FROM pg_stat_activity WHERE state = 'active';\""
    - "5. kubectl top pod -n checkout -l app=checkout-api"
  mitigation:
    - "If CPU > 80%: kubectl scale deployment/checkout-api -n checkout --replicas=10"
    - "If correlates with deploy: kubectl rollout undo deployment/checkout-api -n checkout"
    - "If memory > 90%: kubectl rollout restart deployment/checkout-api -n checkout"
    - "If DB pool saturated: kubectl set env deployment/checkout-api -n checkout DB_POOL_SIZE=50"
  escalation:
    - "15 min: Secondary on-call"
    - "30 min: Engineering manager"
  resolution: "p99 < 200ms for 5 min, error rate < 0.1%"
```

✅ **Expected**: Complete runbook with investigation, mitigation, escalation.

### Practice 9: Simulate a SEV2 Incident

```yaml
simulation:
  severity: SEV2
  scenario: "Database connection leak causes checkout errors"

  events:
    - time: "T+0m"     event: "v2.31.1 deployed — connection_ttl 300→3600s"
    - time: "T+3m"     event: "FastBurnRate alert — 8% error rate"
    - time: "T+4m"     event: "SEV2 declared, #inc-checkout-latency opened"
    - time: "T+6m"     event: "SLO dashboard shows 98.7% availability"
    - time: "T+8m"     event: "Deploy diff reviewed — connection_ttl change found"
    - time: "T+10m"    event: "DB pool at 100% — pg_isready confirms"
    - time: "T+12m"    event: "Rollback initiated"
    - time: "T+15m"    event: "Stale DB connections cleared"
    - time: "T+20m"    event: "Error rate dropping 8%→2%"
    - time: "T+30m"    event: "Error rate 0.05%, latency baseline"
    - time: "T+35m"    event: "Resolved, stakeholder update sent"
    - time: "T+45m"    event: "Postmortem scheduled"
```

✅ **Expected**: Timed simulation following incident command structure.

### Practice 10: Write a Blameless Postmortem

```yaml
title: "Postmortem: DB Connection Exhaustion — Checkout API"
incident_id: INC-2026-06-24-003
severity: SEV2
duration: 35 min
sli_impact: "Availability 98.7% (SLO 99.9%), p99 latency 2300ms"
error_budget_consumed: 0.23%

summary: >
  Deploy v2.31.1 changed connection_ttl from 300s to 3600s without
  adjusting max_connections. Idle connections accumulated until the
  pool exhausted, causing HTTP 500 errors for 35 minutes.

timeline:
  - "14:00 UTC — Deploy v2.31.1"
  - "14:02 UTC — p99 latency 120ms→2.3s"
  - "14:03 UTC — FastBurn alert fires"
  - "14:04 UTC — SEV2 declared"
  - "14:10 UTC — DB pool at 100%"
  - "14:12 UTC — Rollback started"
  - "14:35 UTC — Incident resolved"

root_cause: "connection_ttl increase from 300s to 3600s without pool size adjustment"

contributing_factors:
  - No connection pool saturation alert
  - Deploy pipeline did not validate connection parameter changes
  - No runbook for pool exhaustion

action_items:
  - action: "Add pool saturation alert"              owner: platform-sre   deadline: "2026-06-28" type: detect
  - action: "Add connection_ttl validation to pipeline" owner: platform-eng  deadline: "2026-07-07" type: prevent
  - action: "Write pool exhaustion runbook"           owner: platform-sre   deadline: "2026-06-30" type: mitigate
  - action: "Increase canary to 25%"                  owner: checkout-team  deadline: "2026-07-15" type: mitigate
```

✅ **Expected**: Complete blameless postmortem with all sections.

### Practice 11: Feature Flags with Flagger

```yaml
apiVersion: flagger.app/v1beta1
kind: Canary
metadata:
  name: checkout-api
  namespace: checkout
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: checkout-api
  service:
    port: 8080
    gateways: [checkout-gateway]
  analysis:
    interval: 30s
    maxWeight: 50
    stepWeight: 5
    thresholds:
      maxRestarts: 2
      latency: { threshold: 200, percentile: 99 }
      errorRate: { threshold: 1 }
    metrics:
      - name: request-success-rate
        templateRef: { name: success-rate }
        threshold: 99
        interval: 1m
```

✅ **Expected**: Flagger canary configuration with analysis metrics.

### Practice 12: Multi-Window Multi-Burn-Rate Alerts

```yaml
groups:
  - name: mwmbr_slo_alerts
    interval: 30s
    rules:
      - alert: MWMBR_FastModerate
        expr: |
          (1 - (sum(rate(http_requests_total{job="checkout",status=~"2.."}[5m]))
                / sum(rate(http_requests_total{job="checkout"}[5m]))))
          > 14.4 * (1 - 0.999)
          AND
          (1 - (sum(rate(http_requests_total{job="checkout",status=~"2.."}[30m]))
                / sum(rate(http_requests_total{job="checkout"}[30m]))))
          > 6 * (1 - 0.999)
        for: 2m
        labels: { severity: critical, burn_type: "fast+moderate" }

      - alert: MWMBR_FastSlow
        expr: |
          (1 - (sum(rate(http_requests_total{job="checkout",status=~"2.."}[5m]))
                / sum(rate(http_requests_total{job="checkout"}[5m]))))
          > 14.4 * (1 - 0.999)
          AND
          (1 - (sum(rate(http_requests_total{job="checkout",status=~"2.."}[6h]))
                / sum(rate(http_requests_total{job="checkout"}[6h]))))
          > 1.5 * (1 - 0.999)
        for: 2m
        labels: { severity: critical, burn_type: "fast+slow" }

      - alert: MWMBR_ModerateSlow
        expr: |
          (1 - (sum(rate(http_requests_total{job="checkout",status=~"2.."}[30m]))
                / sum(rate(http_requests_total{job="checkout"}[30m]))))
          > 6 * (1 - 0.999)
          AND
          (1 - (sum(rate(http_requests_total{job="checkout",status=~"2.."}[3d]))
                / sum(rate(http_requests_total{job="checkout"}[3d]))))
          > 1.5 * (1 - 0.999)
        for: 5m
        labels: { severity: warning, burn_type: "moderate+slow" }
```

✅ **Expected**: Three MWMBR rules combining short+long windows.

### Practice 13: Chaos Experiment — Kill a Pod

```bash
#!/bin/bash
set -euo pipefail
APP="checkout-api"; NS="checkout"

echo "=== Baseline ==="
BL=$(curl -s "http://prometheus:9090/api/v1/query" \
  --data-urlencode 'query=histogram_quantile(0.99, sum(rate(http_request_duration_seconds_bucket{job="checkout"}[5m])) by (le))' \
  | jq -r '.data.result[0].value[1]')
BE=$(curl -s "http://prometheus:9090/api/v1/query" \
  --data-urlencode 'query=sum(rate(http_requests_total{job="checkout",status=~"5.."}[5m])) / sum(rate(http_requests_total{job="checkout"}[5m]))' \
  | jq -r '.data.result[0].value[1]')
echo "p99: ${BL}s | Errors: $(echo "$BE*100" | bc -l)%"

echo "=== Killing pod ==="
POD=$(kubectl get pod -n $NS -l app=$APP -o jsonpath='{.items[0].metadata.name}')
kubectl delete pod -n $NS $POD --grace-period=0 --force

echo "=== Observing recovery ==="
for i in $(seq 1 12); do
  sleep 5
  L=$(curl -s "http://prometheus:9090/api/v1/query" \
    --data-urlencode 'query=histogram_quantile(0.99, sum(rate(http_request_duration_seconds_bucket{job="checkout"}[1m])) by (le))' \
    | jq -r '.data.result[0].value[1]')
  E=$(curl -s "http://prometheus:9090/api/v1/query" \
    --data-urlencode 'query=sum(rate(http_requests_total{job="checkout",status=~"5.."}[1m])) / sum(rate(http_requests_total{job="checkout"}[1m]))' \
    | jq -r '.data.result[0].value[1]')
  P=$(kubectl get pod -n $NS -l app=$APP --field-selector=status.phase=Running -o json | jq '.items | length')
  echo "[+$((i*5))s] Pods: $P | p99: ${L}s | Errors: $(echo "$E*100" | bc -l)%"
done
echo "=== Complete ==="
```

✅ **Expected**: Chaos experiment script killing a pod and measuring impact.

### Practice 14: Capacity Planning from 6-Month Data

```python
#!/usr/bin/env python3
import requests
from datetime import datetime, timedelta

PROM = "http://prometheus:9090"
end = datetime.now(); start = end - timedelta(days=180)

def qr(query):
    r = requests.get(f"{PROM}/api/v1/query_range",
        params={"query": query, "start": start.isoformat(), "end": end.isoformat(), "step": "1d"})
    return r.json()["data"]["result"]

def forecast(vals, ahead):
    n = len(vals); xs = list(range(n))
    sx = sum(xs); sy = sum(vals)
    sxy = sum(x*y for x,y in zip(xs,vals)); sxx = sum(x*x for x in xs)
    slope = (n*sxy - sx*sy) / (n*sxx - sx*sx)
    intercept = (sy - slope*sx) / n
    return intercept + slope*(n+ahead-1), slope

def report_metric(metric, label, desc):
    d = qr(metric)
    if d and d[0].get("values"):
        vals = [float(v[1]) for v in d[0]["values"]]
        print(f"  {desc}: current={vals[-1]:.3f}, avg={sum(vals)/len(vals):.3f}, max={max(vals):.3f}")
        return vals[-1]
    return None

print("=== 6-Month Capacity Report ===")
report_metric("avg_over_time(sum(rate(http_requests_total{job='checkout'}[1d]))[30d:])", "req/s", "Request rate")
report_metric("avg_over_time(histogram_quantile(0.99, sum(rate(http_request_duration_seconds_bucket{job='checkout'}[5m])) by (le))[1d:])", "latency", "p99 Latency (s)")
report_metric("avg_over_time((sum(rate(http_requests_total{job='checkout',status=~'5..'}[5m])) / sum(rate(http_requests_total{job='checkout'}[5m])))[1d:])", "errors", "Error rate")
report_metric("avg_over_time((1 - avg(rate(node_cpu_seconds_total{mode='idle',job='checkout'}[5m])))[1d:])", "cpu", "CPU util")
report_metric("avg_over_time((1 - node_memory_MemAvailable_bytes{job='checkout'} / node_memory_MemTotal_bytes{job='checkout'})[1d:])", "mem", "Memory util")
```

Outputs current, average, and peak metrics with growth trends.

✅ **Expected**: Capacity report with request rate, latency, error rate, CPU, memory.

### Practice 15: Real-World Integration — Full SRE Practice

```yaml
project: checkout-api
sli:
  - name: "Availability"  query: "sum(rate(http_requests_total{status=~'2..'}[5m])) / sum(rate(http_requests_total[5m]))"  target: "> 0.999"
  - name: "Latency p99"   query: "histogram_quantile(0.99, sum(rate(http_request_duration_seconds_bucket[5m])) by (le))"  target: "< 0.5"
  - name: "Error rate"    query: "sum(rate(http_requests_total{status=~'5..'}[5m])) / sum(rate(http_requests_total[5m]))"  target: "< 0.01"
slo: { target: 99.9%, window: 30d }
error_budget: { freeze: 10%, feature_freeze: 30%, postmortem_threshold: 0 }
alerts:
  - name: MWMBR_FastModerate  type: mwmbr  short: { window: 5m, rate: 14.4 }  long: { window: 30m, rate: 6 }    severity: critical
  - name: MWMBR_ModerateSlow  type: mwmbr  short: { window: 30m, rate: 6 }    long: { window: 3d, rate: 1.5 }  severity: warning
runbooks: { HighLatency: "runbooks/high-latency.md", HighErrorRate: "runbooks/high-error-rate.md", BudgetExhausted: "runbooks/budget-exhausted.md" }
dashboards: [{ name: "SRE Overview", uid: "checkout-sre" }]
deployment: { strategy: canary, percent: 10, window: 15m, rollback_on: "error_rate_5m > 5% OR p99_latency_5m > 500ms" }
postmortem: { template: blameless, deadline: "5 business days", required_for: "budget_exhausted OR sev1 OR sev2" }
chaos: [{ name: pod-kill, schedule: daily }, { name: network-delay, schedule: weekly }]
capacity: { forecasting: "python capacity_forecast.py", review: quarterly }
```

✅ **Expected**: Complete real-world SRE practice integrating all components.

---



---

[← Previous](14-13-sre-in-practice.md) | [↑ Index](index.md) | [Next →](16-deep-understanding.md)
