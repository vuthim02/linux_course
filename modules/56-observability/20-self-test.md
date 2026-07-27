## Self-Test

1. What are the three pillars of observability and what does each tell you?
2. How does Prometheus's pull model differ from push-based monitoring? Give one advantage.
3. Write a PromQL query for per-instance CPU utilization (non-idle, 5m average).
4. What is the difference between `rate()` and `irate()`?
5. Write a recording rule for 5m average memory utilization ratio.
6. Explain `relabel_configs` vs `metric_relabel_configs`.
7. How does Alertmanager `group_by` work and why is it useful?
8. Write an `alertmanager.yml` routing critical alerts to Slack, warning to email.
9. How does Loki differ from Elasticsearch for log storage? Why is it cheaper?
10. Write a LogQL query for p99 latency from nginx logs with a `duration_ms` field.
11. What are the 4 main OTEL Collector component types?
12. What is the difference between head-based and tail-based sampling?
13. Write a YAML snippet provisioning a Prometheus datasource in Grafana.
14. Write a PromQL alert: disk on `/` below 10% for 5 minutes.
15. How do derived fields in Loki link logs to Tempo traces?

**Score:** 12/15 correct = ready for Part 57.

---

*Linux SysAdmin Course | Part 56 of ∞ | Reverse Engineering Approach*
*Previous → Part 55: Immutable Infrastructure*
*Next → Part 57: Modern Linux Networking*

[← Previous](part55.md) | [Next →](part57.md)


---

[← Previous](19-whats-coming-in-part-57.md) | [↑ Index](index.md)
