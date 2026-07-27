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



---

[← Previous](16-deep-understanding.md) | [↑ Index](index.md) | [Next →](18-whats-coming-in-part-60.md)
