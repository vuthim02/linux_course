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



---

[← Previous](12-11-monitoring-for-sres.md) | [↑ Index](index.md) | [Next →](14-13-sre-in-practice.md)
