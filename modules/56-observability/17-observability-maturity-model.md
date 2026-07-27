## Observability Maturity Model

| Level | Metrics | Logs | Traces | Alerting | Culture |
|-------|---------|------|--------|----------|---------|
| 0: None | No metrics | No collection | No tracing | No alerts | "It broke, fix it" |
| 1: Basic | CPU/memory from cloud console | grep in SSH sessions | Manual correlation | Email alerts, 50% false positive | "The monitoring is down again" |
| 2: Standard | Prometheus + node_exporter, core metrics | Loki, structured JSON logs | Tempo for critical services | Alertmanager with grouping, Slack | "Pager went off at 3am, was a deployment" |
| 3: Advanced | Application metrics, RED/USE method, SLOs | LogQL alerting, log patterns | All services traced, sampling configured | Multi-window, multi-burn-rate alerts | On-call responds to real issues only |
| 4: Automated | Auto-instrumented via OTEL, full coverage | Automated log parsing, anomaly detection | Tail-based sampling, service graphs | Auto-remediation (webhook → K8s rollback) | "The system fixed itself before anyone noticed" |

---



---

[← Previous](16-deep-understanding.md) | [↑ Index](index.md) | [Next →](18-command-reference.md)
