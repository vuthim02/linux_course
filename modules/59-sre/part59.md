# 🐧 Linux System Administrator — Complete Course
## Part 59 of ∞: Site Reliability Engineering — SLIs, SLOs, Error Budgets, Incident Management

---

## Reverse Engineering Approach

We learn SRE backwards: start with a **broken production service** and work upward. You are the on-call engineer at 03:00. Alerts are firing. Users cannot check out. Every concept in this part exists because something _actually broke_ in a real system at scale.

---

## 1. What is SRE?

Site Reliability Engineering is what happens when you ask a software engineer to design an operations team. Coined at Google in 2003 by Ben Treynor Sloss.

### SRE vs DevOps

| Dimension | DevOps | SRE |
|---|---|---|
| Origin | Community movement | Google internal role |
| Focus | Culture, collaboration, pipelines | Reliability, latency, capacity |
| Key metric | Cycle time, deployment frequency | Error budget, SLO compliance |
| Operations | Everyone does ops | SREs cap ops work at 50% |

### The SRE Creed

1. **Hire SREs from software engineering** — they must be able to write code
2. **Error budget** — product owner and SRE agree on how unreliable the service can be
3. **Reduce toil** — no more than 50% of time on manual operations
4. **Monitoring and distributed systems** — deep understanding of the systems being operated

> "The primary payoff of SRE is keeping the service running while maximizing the velocity of feature development." — Google SRE Book

---

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

---

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

---

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

---

## 6. Toil Reduction

Toil is **manual, repetitive, automatable, tactical work with no enduring value**. SREs must spend < 50% on toil.

### What Is Toil?

| Work | Toil? | Reason |
|---|---|---|
| Rebooting a server | Yes | Manual, repetitive |
| Responding to same alert daily | Yes | Should be auto-remediated |
| Writing deployment pipeline | No | Enduring value |
| Incident response | No | Necessary |

### Measuring Toil

```yaml
toil_tags:
  - manual_restart
  - manual_deploy
  - alert_noise
  - config_drift
  - permission_fix
  - data_patch
  - disk_fill_cleanup
```

```promql
sum(toil_hours_total[7d]) / sum(work_hours_total[7d])
```

### Toil Budget

- **50% cap** on toil
- Track weekly in 1:1s
- When toil exceeds 50%, the team **pauses project work** to automate

### Automation Strategies

| Level | Method | Example |
|---|---|---|
| 1. Script | One-off bash/Python | `./reboot-all.sh` |
| 2. Tool | Reusable CLI | `sre-tool cert renew --all` |
| 3. Platform | Self-service UI/API | Jenkins with one click |
| 4. Product | Fully automated | Auto-scaling, auto-healing |

### Example: Automating Cert Renewal

**Before (toil):**
```bash
ssh bastion.example.com
sudo certbot renew
scp fullchain.pem lb-01: && scp privkey.pem lb-01:
ssh lb-01 sudo service haproxy reload
```

**After (automated):**
```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: cert-renewal
  namespace: cert-manager
spec:
  schedule: "0 3 1 * *"
  jobTemplate:
    spec:
      template:
        spec:
          serviceAccountName: cert-manager
          containers:
            - name: cert-renew
              image: cert-manager-controller:v1.15.0
              args: ["renew", "--all-namespaces"]
          restartPolicy: OnFailure
```

---

## 7. Incident Management

### Incident Severity Levels

| Level | Definition | Response Time | Examples |
|---|---|---|---|
| SEV1 | Critical — users cannot use service | 15 min | Full outage, data loss, security breach |
| SEV2 | Major — degraded functionality | 30 min | Partial outage, high error rates |
| SEV3 | Minor — non-critical issue | 4 hours | Single-user issue |
| SEV4 | Trivial — internal only | 1 week | Minor alert tuning |

### Incident Command System (ICS)

| Role | Responsibilities |
|---|---|
| **Incident Commander (IC)** | Coordinates, declares severity, go/no-go, timeline |
| **Operations Lead** | Investigates, mitigates, runs commands |
| **Communications Lead** | Stakeholder updates, Slack channel |
| **Scribe** | Records every action with timestamps |
| **SME** | Subject matter expert for subsystem |

### Incident Response Process

```
DETECT → RESPOND → MITIGATE → RESOLVE → POSTMORTEM
```

### Escalation Paths

```yaml
escalation_policy:
  sev1:
    - primary_oncall (5 min)
    - secondary_oncall (5 min)
    - vp_engineering (5 min)
    - cto (10 min)
  sev2:
    - primary_oncall (10 min)
    - secondary_oncall (10 min)
    - engineering_manager (15 min)
```

---

## 8. Blameless Postmortems

A postmortem is an **engineering investigation** to understand what happened and prevent recurrence — not a punishment.

### Culture of Safety vs Blame

| Blame Culture | Safety Culture |
|---|---|
| "Who caused this?" | "What conditions allowed this?" |
| Fire the person | Fix the system |
| Hide mistakes | Share learnings |

### Postmortem Structure

```yaml
title: "Postmortem: Elevated 5xx errors on checkout API"
date: 2026-06-24
incident_id: INC-2026-06-24-001
severity: SEV2
duration: 47 minutes
sli_impact: Availability dropped to 98.2% (SLO 99.9%)
error_budget_consumed: 0.17%

summary: >
  A database connection pool exhaustion caused 47 minutes of elevated
  errors. A deploy increased connection_ttl without adjusting pool max.

timeline:
  - "03:12 UTC — Deploy v2.31.1 (5% canary)"
  - "03:14 UTC — p99 latency spikes from 120ms to 2.3s"
  - "03:15 UTC — Fast-burn alert pages on-call"
  - "03:16 UTC — SEV2 declared"
  - "03:18 UTC — DB connection spike identified"
  - "03:22 UTC — Rollback initiated"
  - "03:47 UTC — Rollback complete, latency normal"
  - "03:59 UTC — Incident resolved"

root_cause: >
  connection_ttl changed from 300s to 3600s without adjusting max_connections.
  Long-lived connections accumulated until pool exhausted.

contributing_factors:
  - No connection pool saturation alert
  - No canary analysis on connection metrics
  - Runbook did not cover pool exhaustion

action_items:
  - description: "Add connection pool saturation alert"
    owner: "platform-sre"
    ticket: "OPS-4921"
    severity: P0
    deadline: "2026-06-26"
    type: detect
  - description: "Add connection metrics to canary analysis"
    owner: "checkout-team"
    ticket: "CHECK-1138"
    deadline: "2026-07-01"
    type: prevent
  - description: "Update runbook with pool exhaustion steps"
    owner: "platform-sre"
    ticket: "OPS-4922"
    deadline: "2026-06-28"
    type: mitigate
```

### Blameless Language Cheat Sheet

| Avoid | Use Instead |
|---|---|
| "Bob deployed bad code" | "The deploy pipeline did not catch..." |
| "The team forgot to check X" | "The checklist did not include X" |
| "Nobody monitored Y" | "We did not have an alert for Y" |

---

## 9. Capacity Planning

### Demand Forecasting

```python
#!/usr/bin/env python3
"""capacity_forecast.py — 6-month capacity planning"""
import requests
from datetime import datetime, timedelta

PROMETHEUS = "http://prometheus:9090"
end = datetime.now()
start = end - timedelta(days=180)

def get_metric(query, start, end, step="1d"):
    params = {"query": query, "start": start.isoformat(), "end": end.isoformat(), "step": step}
    r = requests.get(f"{PROMETHEUS}/api/v1/query_range", params=params)
    return r.json()["data"]["result"]

def forecast(values, days_ahead):
    n = len(values)
    xs = list(range(n))
    ys = values
    sum_x = sum(xs); sum_y = sum(ys)
    sum_xy = sum(x*y for x,y in zip(xs,ys)); sum_xx = sum(x*x for x in xs)
    slope = (n*sum_xy - sum_x*sum_y) / (n*sum_xx - sum_x*sum_x)
    intercept = (sum_y - slope*sum_x) / n
    return intercept + slope * (n + days_ahead - 1), slope

data = get_metric("avg_over_time(sum(rate(http_requests_total{job='checkout'}[1d]))[30d:])", start, end)
if data and data[0].get("values"):
    vals = [float(v[1]) for v in data[0]["values"]]
    fcast, slope = forecast(vals, 90)
    print(f"Current: {vals[-1]:.0f} req/s")
    print(f"Growth: {slope:.1f} req/s per day")
    print(f"90-day forecast: {fcast:.0f} req/s")
```

### Seasonal Patterns
```promql
sum(rate(http_requests_total[1w])) offset 1w
sum(rate(http_requests_total[1h])) by (hour_of_day)
```

### Load Testing

| Tool | Language | Best For |
|---|---|---|
| Locust | Python | HTTP, custom scenarios |
| k6 | JavaScript | CI/CD, thresholds |
| vegeta | Go | CLI load testing |
| wrk | C | Raw throughput |

### Locust Test
```python
from locust import HttpUser, task, between
import random

class CheckoutUser(HttpUser):
    wait_time = between(1, 5)
    @task(3)
    def browse(self): self.client.get("/api/products")
    @task(1)
    def view_cart(self): self.client.get("/api/cart")
    @task(2)
    def add_to_cart(self):
        self.client.post("/api/cart", json={"product_id": random.randint(1,1000), "quantity": 1})
    @task(1)
    def checkout(self):
        self.client.post("/api/checkout", json={
            "cart_id": "cart_12345", "payment_method": "card",
            "shipping_address": {"street": "123 Main St", "city": "Portland", "state": "OR", "zip": "97201"}
        })
```

### k6 Load Test
```javascript
import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  stages: [
    { duration: '2m', target: 100 },
    { duration: '5m', target: 100 },
    { duration: '2m', target: 200 },
    { duration: '5m', target: 200 },
    { duration: '2m', target: 0 },
  ],
  thresholds: { http_req_duration: ['p(99)<200'], http_req_failed: ['rate<0.001'] },
};

export default function () {
  const res = http.get('https://api.example.com/health');
  check(res, { 'status is 200': (r) => r.status === 200 });
  sleep(1);
}
```

### Right-Sizing & Scaling Triggers

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: checkout-api-hpa
spec:
  minReplicas: 3
  maxReplicas: 50
  metrics:
    - type: Resource
      resource:
        name: cpu
        target: { type: Utilization, averageUtilization: 70 }
```

```promql
avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) < 0.3
sum(rate(http_requests_total[5m])) > expected_capacity * 0.7
avg(rabbitmq_queue_messages_ready{queue="checkout"}[5m]) > 1000
```

---

## 10. Release Engineering

### Progressive Delivery

| Technique | Risk | Rollback Time |
|---|---|---|
| Feature flags | Very low | Seconds |
| Canary release | Low | Minutes |
| Blue/green | Low | Seconds |
| Rolling update | Medium | Depends |

### Feature Flags with Flagger

```yaml
apiVersion: flagger.app/v1beta1
kind: Canary
metadata:
  name: checkout-api
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: checkout-api
  service:
    port: 8080
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

### Blue/Green Deployment Script

```bash
#!/bin/bash
# blue-green-deploy.sh
set -euo pipefail
APP="checkout-api"
BLUE_NS="${APP}-blue"; GREEN_NS="${APP}-green"
ACTIVE_NS=$(kubectl get svc -n "${BLUE_NS}" -o name >/dev/null 2>&1 && echo "${BLUE_NS}" || echo "${GREEN_NS}")
INACTIVE_NS=$([ "$ACTIVE_NS" = "${BLUE_NS}" ] && echo "${GREEN_NS}" || echo "${BLUE_NS}")
echo "Active: ${ACTIVE_NS}, deploying to: ${INACTIVE_NS}"

kubectl apply -f k8s/deployment.yaml -n "${INACTIVE_NS}"
kubectl rollout status deployment/"${APP}" -n "${INACTIVE_NS}" --timeout=5m
curl -f -s "http://${APP}-${INACTIVE_NS}/health" || exit 1
kubectl apply -f k8s/service.yaml -n "${INACTIVE_NS}"
sleep 300  # observation window
kubectl scale deployment/"${APP}" -n "${ACTIVE_NS}" --replicas=0
echo "Deploy complete. Active: ${INACTIVE_NS}"
```

### Rollback Triggers

```yaml
triggers:
  - error_rate_5m > 5%
  - p99_latency_5m > 500ms
  - error_budget_burn_rate > 10x

kubernetes_rollback:
  - "kubectl rollout undo deployment/checkout-api"
  - "kubectl rollout status deployment/checkout-api"
```

---

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

---

## 12. Chaos Engineering

Chaos engineering is **experimenting on a system** to build confidence in its resilience.

### Principles
```
1. Hypothesize — "What happens if we kill the database pod?"
2. Experiment — Run in controlled conditions
3. Measure — Observe SLIs
4. Learn — What broke? Fix it. Repeat.
```

### Tools

| Tool | Scope |
|---|---|
| Chaos Monkey | AWS, GCP instance termination |
| LitmusChaos | Kubernetes (pod kill, network, stress) |
| Chaos Mesh | Kubernetes (DNS, HTTP, network, IO) |
| Gremlin | Multi-cloud SaaS |

### Chaos Experiment: Kill a Pod (LitmusChaos)

```yaml
apiVersion: litmuschaos.io/v1alpha1
kind: ChaosEngine
metadata:
  name: checkout-api-chaos
spec:
  appInfo:
    appns: checkout
    applabel: "app=checkout-api"
    appkind: deployment
  chaosServiceAccount: litmus-admin
  experiments:
    - name: pod-delete
      spec:
        components:
          env:
            - name: TOTAL_CHAOS_DURATION
              value: "60"
            - name: CHAOS_INTERVAL
              value: "10"
            - name: FORCE
              value: "true"
        probe:
          - name: health-check
            type: httpProbe
            httpProbe:
              url: http://checkout-api:8080/health
              method: { get: { criteria: ==, responseCode: 200 } }
            mode: Continuous
```

### Chaos Experiment: Network Latency (Chaos Mesh)

```yaml
apiVersion: chaos-mesh.org/v1alpha1
kind: NetworkChaos
metadata:
  name: checkout-latency
spec:
  action: delay
  mode: one
  selector:
    namespaces: ["checkout"]
    labelSelectors: { app: checkout-api }
  delay:
    latency: "2000ms"
    jitter: "500ms"
  duration: "60s"
```

### Game Days

```yaml
game_day:
  title: "2026 Q2 Resilience Test"
  scenario: "Regional AWS us-east-1 outage"
  schedule:
    - "00:00 — Briefing: scenario, rules, safety"
    - "00:15 — Block all traffic to us-east-1"
    - "00:20 — Observe failover"
    - "01:00 — Observe recovery when region returns"
    - "02:00 — Retrospective"
  safety:
    - "Kill switch: kubectl delete chaosengine..."
    - "Timebox: 30 min auto-stop"
    - "Scope: checkout namespace only"
```

### Resilience Scenarios

| Experiment | Tests | Expected Outcome |
|---|---|---|
| Kill 3 pods | HPA, readiness probes | Pods restart, traffic re-routes |
| Saturate CPU to 90% | Autoscaling | HPA scales up |
| Block DB port 5432 | Circuit breakers | Circuit opens, cached results served |
| DNS failure 5 min | DNS caching | Cache serves requests |

---

## 13. SRE in Practice

### Implementing SRE in Non-Google Organizations

Start small:

```yaml
phase_1:
  - "Pick ONE critical service"
  - "Define 3 SLIs"
  - "Set an SLO (start 99.9%)"
  - "Create error budget policy"
  - "Implement 1 meaningful page alert"
  - "Write 1 runbook"
  - "Conduct 1 blameless postmortem"
```

### Reliability as a Product

| Business Impact | Suggested SLO | Budget/mo | Cost |
|---|---|---|---|
| Internal tool | 99.0% | 7h 18m | 1× |
| Customer web | 99.9% | 43m 48s | 2× |
| Payment processing | 99.99% | 4m 23s | 5× |
| Transaction DB | 99.999% | 26s | 20× |

### Tradeoffs: Velocity vs Reliability

The error budget makes the tradeoff explicit:
- Product: "We want 50 deploys this week"
- SRE: "That consumes 0.3% of budget"
- Product: "We accept the risk"
- SRE: "Tracked. If exhausted, deploys stop."

### SRE Team Structure

| Model | Description | Best For |
|---|---|---|
| **Embedded** | SREs sit inside product teams | Large product teams |
| **Consultative** | Central SRE advises product teams | Growing org |
| **Centralized** | One SRE team owns reliability for all | Small org, consistent standards |

**Growth path:**
```
Startup (< 20 eng)  → Devs own ops
Early (20-50)       → 1-2 embedded SREs
Growth (50-200)     → Central SRE (3-5)
Scale (> 200)       → Embedded + Platform SRE (8-15)
```

---

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

---

## Command Reference

| Concept | PromQL / Tool | Description |
|---|---|---|
| SLI latency p99 | `histogram_quantile(0.99, rate(http_bucket[5m]))` | 99th percentile duration |
| SLI availability | `sum(rate(2xx[5m])) / sum(rate(total[5m]))` | Fraction successful |
| SLI error rate | `sum(rate(5xx[5m])) / sum(rate(total[5m]))` | Fraction failed |
| SLO compliance | `sum(increase(2xx[30d])) / sum(increase(total[30d]))` | 30-day compliance |
| Error budget rem. | `1 - ((1 - compliance) / (1 - slo_target))` | Budget fraction |
| Burn rate | `measured_error / target_error` | Budget consumption speed |
| Fast burn alert | `burn_rate > 14.4 over 1h` | Urgent page |
| Medium burn | `burn_rate > 6 over 6h` | Warning page |
| Slow burn | `burn_rate > 1.5 over 3d` | Ticket |
| MWMBR | Short AND long window | Multi-window alert |
| CPU saturation | `1 - avg(rate(node_cpu_idle[5m]))` | CPU utilization |
| Memory saturation | `1 - mem_avail / mem_total` | Memory utilization |
| Throughput | `sum(rate(http_requests[5m]))` | Requests/s |
| RED method | Rate, Errors, Duration | Service monitoring |
| USE method | Utilization, Saturation, Errors | Resource monitoring |
| Canary deploy | `step 5, max 50` | Flagger/Argo progressive |
| Chaos experiment | `NetworkChaos delay: 2000ms` | Inject failure |
| Load test | `k6 run --vus 100 --duration 5m` | Performance testing |
| Alertmanager route | `match: severity: critical` | Route to PagerDuty |

---

## What's Coming in Part 60

```
┌─────────────────────────────────────────────────────────┐
│   Part 60: Final Capstone — Production-Grade Infrastructure
├─────────────────────────────────────────────────────────┤
│   • Build complete production infrastructure            │
│   • Multi-region K8s cluster with HA control plane      │
│   • CI/CD pipeline (GitOps with ArgoCD)                 │
│   • Monitoring stack (Prometheus + Grafana + Loki)      │
│   • Incident response automation                        │
│   • Disaster recovery plan and test                     │
│   • Cost optimization and right-sizing                  │
│   • Security hardening (RBAC, network policies, Vault)  │
│   • Full SRE integration                                │
│   • Career roadmap                                      │
└─────────────────────────────────────────────────────────┘
```

---

## Self-Test

1. What is the difference between an SLI and an SLO?
2. Why is 100% the wrong SLO target?
3. Calculate: SLO is 99.99%, 5M requests/day, how many can fail per day?
4. What does a burn rate of 14.4× mean?
5. Name the Four Golden Signals.
6. How does MWMBR prevent false positive alerts?
7. What is the RED method? When would you use it?
8. What is toil? Give three examples.
9. What are the five roles in incident command?
10. What sections must a blameless postmortem include?
11. Write a PromQL query for SLO compliance over 30 days.
12. What burn rate thresholds correspond to fast, medium, and slow?
13. Difference between embedded, consultative, and centralized SRE?
14. How does error budget create shared language between product and SRE?
15. What is the first thing an SRE should do when joining a new service?

**Answers:**
1. SLI = indicator (what you measure); SLO = objective (what you target)
2. Cost approaches infinity, users cannot tell difference, innovation stops
3. 5,000,000 × 0.0001 = **500 requests/day**
4. Budget consumed 14.4× faster than planned; will exhaust in ~2 days
5. Latency, Traffic, Errors, Saturation
6. Requires BOTH short window AND long window to fire — filters transient spikes
7. Rate, Errors, Duration — for **service** monitoring
8. Manual, repetitive, automatable, no enduring value (rebooting servers, manual cert renewal, same alert daily)
9. IC, Ops Lead, Comms Lead, Scribe, SME
10. Summary, Timeline, Root Cause, Contributing Factors, Action Items
11. `sum(increase(http_requests_total{status=~"2.."}[30d])) / sum(increase(http_requests_total[30d]))`
12. Fast: 14.4×, Medium: 6×, Slow: 1.5×
13. Embedded (in product team), Consultative (central advises), Centralized (one team for all)
14. SRE defines cost of unreliability; product decides if features worth spending that cost
15. Find existing dashboards, runbooks, SLOs, and incident history — measure before changing

**Score:** 12/15 correct = ready for Part 60.

---

*Linux SysAdmin Course | Part 59 of ∞ | Reverse Engineering Approach*
*Previous → Part 58: Secrets Management*
*Next → Part 60: Final Capstone — Production-Grade Infrastructure*

[← Previous](part58.md) | [Next →](part60.md)
