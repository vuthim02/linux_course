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





[← Previous](07-6-toil-reduction.md) | [↑ Index](index.md) | [Next →](09-8-blameless-postmortems.md)
