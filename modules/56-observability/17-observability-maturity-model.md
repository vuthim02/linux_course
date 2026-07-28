## Observability Maturity Model

| Level | Metrics | Logs | Traces | Alerting | Culture |
|-------|---------|------|--------|----------|---------|
| 0: None | No metrics | No collection | No tracing | No alerts | "It broke, fix it" |
| 1: Basic | CPU/memory from cloud console | grep in SSH sessions | Manual correlation | Email alerts, 50% false positive | "The monitoring is down again" |
| 2: Standard | Prometheus + node_exporter, core metrics | Loki, structured JSON logs | Tempo for critical services | Alertmanager with grouping, Slack | "Pager went off at 3am, was a deployment" |
| 3: Advanced | Application metrics, RED/USE method, SLOs | LogQL alerting, log patterns | All services traced, sampling configured | Multi-window, multi-burn-rate alerts | On-call responds to real issues only |
| 4: Automated | Auto-instrumented via OTEL, full coverage | Automated log parsing, anomaly detection | Tail-based sampling, service graphs | Auto-remediation (webhook → K8s rollback) | "The system fixed itself before anyone noticed" |

### How to Advance Between Levels

**Level 0 → 1:** Deploy Prometheus + node_exporter. Add Loki with a basic docker-compose stack. This alone catches 80% of issues before users report them.

**Level 1 → 2:** Add application-level RED metrics (Rate, Errors, Duration). Define SLOs for critical services. Set up Alertmanager with severity grouping. Replace email alerts with Slack/PagerDuty.

**Level 2 → 3:** Instrument all services with OpenTelemetry. Implement multi-burn-rate alerts (e.g., 2% errors for 5 minutes = page). Add log pattern analysis with LogQL. Build SLO dashboards.

**Level 3 → 4:** Enable auto-instrumentation (OTEL SDK injection). Deploy tail-based sampling to keep 100% of error traces. Build auto-remediation playbooks (e.g., rollback on error budget burn).

### Key Takeaways

- **Most teams are at Level 1-2.** Don't aim for Level 4 on day one — incremental progress compounds.
- **The biggest jump is 0 → 1.** Even basic metrics + logs transform your ability to debug.
- **Alerts should be actionable.** If nobody acts on an alert, delete it or fix the threshold.
- **Culture matters as much as tooling.** The best dashboards are useless if no one checks them.





[← Previous](16-deep-understanding.md) | [↑ Index](index.md) | [Next →](18-command-reference.md)
