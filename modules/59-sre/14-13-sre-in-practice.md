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





[← Previous](13-12-chaos-engineering.md) | [↑ Index](index.md) | [Next →](15-15-hands-on-practices.md)
