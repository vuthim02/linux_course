# Internship — Level 4, Week 23-24
## SLO Implementation + Chaos Engineering

### Real-World Scenario

The production application is deployed. Now your team needs to define reliability targets, measure them, and prove the system is resilient. You'll implement SRE practices from Google's SRE book: define SLIs/SLOs, implement burn-rate alerts, and run chaos experiments to validate the system.

### Requirements

#### Part A: Define SLIs and SLOs

For the microservice deployed in weeks 21-22, define:

**SLIs (measured from Prometheus):**

| SLI | Prometheus Query | Measurement Source |
|-----|-----------------|-------------------|
| Request latency (p99) | `histogram_quantile(0.99, rate(http_request_duration_seconds_bucket[5m]))` | App metrics |
| Request latency (p95) | `histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))` | App metrics |
| Availability (200 rate) | `sum(rate(http_requests_total{status=~"2.."}[5m])) / sum(rate(http_requests_total[5m]))` | App metrics |
| Error rate | `sum(rate(http_requests_total{status=~"5.."}[5m])) / sum(rate(http_requests_total[5m]))` | App metrics |
| CPU saturation | `avg(rate(node_cpu_seconds_total{mode="system"}[5m]))` | Node exporter |
| Memory saturation | `avg(node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)` | Node exporter |

**SLOs:**
- Latency (p99): < 500ms, 99.9% of the time over 30 days
- Availability: 99.9% over 30 days
- Error rate: < 1% over 30 days

#### Part B: Prometheus Recording Rules

```yaml
# rules/slo-rules.yml
groups:
  - name: slo-rules
    interval: 1m
    rules:
      - record: slo:request_latency_p99:30d
        expr: |
          histogram_quantile(0.99,
            sum(rate(http_request_duration_seconds_bucket[30d]))
          )
      - record: slo:availability:30d
        expr: |
          sum(rate(http_requests_total{status=~"2.."}[30d]))
          /
          sum(rate(http_requests_total[30d]))
      - record: slo:error_budget_remaining
        expr: |
          1 - (
            (1 - slo:availability:30d)
            /
            (1 - 0.999)  # SLO target
          )
```

#### Part C: Multi-Window Multi-Burn-Rate Alerts

```yaml
# rules/alert-rules.yml
groups:
  - name: slo-alerts
    rules:
      - alert: HighErrorRateFastBurn
        expr: |
          (
            sum(rate(http_requests_total{status=~"5.."}[1m]))
            /
            sum(rate(http_requests_total[1m]))
          ) > 0.01  # 1% error rate
          and on()
          (
            sum(rate(http_requests_total{status=~"5.."}[5m]))
            /
            sum(rate(http_requests_total[5m]))
          ) > 0.005
        for: 2m
        labels:
          severity: critical
          burn_rate: fast
        annotations:
          summary: "High error rate - fast burn"
          description: "Error rate > 1% over 1m and > 0.5% over 5m"

      - alert: ErrorBudgetAlmostExhausted
        expr: |
          slo:error_budget_remaining < 0.2
        labels:
          severity: warning
        annotations:
          summary: "Error budget almost exhausted"
          description: "Only {{ $value | humanizePercentage }} error budget remaining"
```

#### Part D: Grafana SLO Dashboard

Create a dashboard (as JSON or describe panels):

1. **SLO Compliance panel**: gauge showing current compliance vs target (99.9%)
2. **Error Budget panel**: remaining budget as percentage (green > 50%, yellow > 20%, red < 20%)
3. **Burn Rate panel**: 1h, 6h, 24h burn rates as heatmap or table
4. **Request Latency panel**: p50/p95/p99 over time
5. **Availability panel**: 30-day rolling availability as sparkline
6. **SLO Alerts panel**: firing alerts related to SLOs

Provide the dashboard JSON in `~/internship/sre/grafana-slo-dashboard.json`

#### Part E: Chaos Experiments

Use LitmusChaos (or `kubectl delete pod` for simplicity) to run experiments:

**Experiment 1: Pod Kill**
```bash
# Kill 2 out of 5 pods
kubectl delete pod -n production -l app=myapp --count=2 --wait=false

# Measure:
# - How long until new pods are ready?
# - Did error rate spike?
# - Was the SLO violated?
# - How much error budget was consumed?
```

**Experiment 2: CPU Stress**
```bash
# Stress one pod's CPU
kubectl exec -n production deploy/myapp -- \
  bash -c "apt-get update && apt-get install -y stress && stress --cpu 4 --timeout 60"
```

**Experiment 3: Network Latency**
```bash
# Add 100ms latency to database traffic (requires service mesh or tc)
# With Istio: DestinationRule with delay
# Or using tc directly on a pod
```

#### Part F: Blameless Postmortem

After the chaos experiment, write a postmortem:

```markdown
# Postmortem: Chaos Experiment — Pod Kill (2026-06-24)

## Summary
Killed 2 of 5 pods in production namespace. System self-healed in 45s.
SLO not violated. Error budget consumed: 0.02%.

## Timeline
- 14:00 UTC — Experiment started
- 14:00:05 — 2 pods terminated
- 14:00:10 — HPA detected missing pods
- 14:00:15 — ReplicaSet created replacement pods
- 14:00:30 — New pods in Pending state (scheduling)
- 14:00:35 — Pods assigned to nodes
- 14:00:40 — Container images pulled
- 14:00:45 — Pods ready, traffic flowing
- 14:00:45 — Experiment complete

## Impact
- Error rate: 0.3% during 5s window (3 requests failed)
- Latency p99: no significant increase
- Availability: 99.97% during experiment (within SLO)

## Root Cause
N/A — deliberate chaos experiment

## Action Items
- [ ] Automate chaos experiments with LitmusChaos for weekly runs
- [ ] Add Grafana annotation for experiment start/end
- [ ] Document error budget impact threshold for experiment approval

## Lessons Learned
- System recovered within target (goal: < 60s, actual: 45s)
- 2/5 pod kill is within tolerance
- Need to test 3/5 and 4/5 next
```

### Validation

```bash
# Test SLO recording rules
curl -X POST http://localhost:9090/api/v1/query \
  --data-urlencode "query=slo:error_budget_remaining"

# Check alert rules
curl http://localhost:9090/api/v1/rules

# Test chaos experiment
kubectl get pods -n production -l app=myapp -w
# In another terminal:
kubectl delete pod -n production -l app=myapp --count=2
# Observe recovery

# Verify HPA response
kubectl describe hpa myapp -n production
```

### Deliverables

- `~/internship/sre/sli-definitions.md` — documented SLIs with PromQL
- `~/internship/sre/prometheus-slo-rules.yaml` — recording rules
- `~/internship/sre/prometheus-alert-rules.yaml` — alerting rules
- `~/internship/sre/grafana-slo-dashboard.json` — dashboard JSON
- `~/internship/sre/chaos-experiment-results.md` — experiment logs and analysis
- `~/internship/sre/postmortem-pod-kill-2026-06-24.md` — blameless postmortem

### Hints

- `rate()` for counters, `histogram_quantile()` for latency percentiles
- For error budget: `1 - ((1 - availability) / (1 - SLO_target))`
- Burn rate = how fast error budget is consumed: `(1 - availability) / (1 - SLO)`
- `kubectl delete pod --grace-period=0 --force` for immediate kill
- `kubectl wait --for=condition=Ready pod -l app=myapp -n production --timeout=60s`
- For chaos automation: `litmuschaos` or `chaos-mesh` can be installed with Helm
