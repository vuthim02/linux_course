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



---

[← Previous](08-7-incident-management.md) | [↑ Index](index.md) | [Next →](10-9-capacity-planning.md)
