## ⭐ Level 3: Advanced — S.M.A.R.T., Prometheus, and Deep Monitoring Infrastructure

![Prometheus architecture diagram showing metric collection flow](https://upload.wikimedia.org/wikipedia/commons/3/38/Prometheus_architecture.png)

> *"When you've outgrown `top` and `iostat`, you build monitoring infrastructure. Prometheus scrapes, Grafana visualizes, and your pager goes off before users notice. The goal isn't more data — it's the right data at the right time."*

### What You'll Cover
- Prometheus architecture: pull-based metrics, time series, PromQL
- node_exporter: exposing hardware and OS metrics
- Grafana dashboards for visualization and trending
- Alertmanager: routing, silencing, and notification channels
- S.M.A.R.T.: disk health attributes, predictive failure, `smartctl`
- I/O scheduler internals and their impact on monitoring metrics
- Building automated health reports with shell scripts

At this level you build monitoring infrastructure that runs continuously and alerts before problems become outages.

At this level you will master:

- **Prometheus**: A pull-based monitoring system that scrapes HTTP endpoints for metrics. Install `prometheus` and `node_exporter`. Configure `prometheus.yml` with scrape targets. Query metrics with PromQL: `rate(node_cpu_seconds_total{mode="idle"}[5m])` shows CPU utilization over 5 minutes.
- **node_exporter**: Runs on each server and exposes `/metrics` with CPU, memory, disk, and network metrics. `systemctl enable --now node_exporter` starts it on port 9100. Prometheus scrapes this endpoint on a schedule (typically every 15 seconds).
- **Grafana**: Connect Prometheus as a data source, then build dashboards with panels for CPU, memory, disk, and network. Use pre-built dashboards from grafana.com (dashboard ID 1860 for node_exporter). Set up variables for server selection.
- **Alertmanager**: Define alert rules in Prometheus (`rules.yml`). Alertmanager routes alerts to email, Slack, PagerDuty, or webhook receivers. Use silences to suppress alerts during maintenance windows.
- **S.M.A.R.T.**: `smartctl -a /dev/sda` shows all SMART attributes. Key attributes: Reallocated_Sector_Ct (growing = dying disk), Current_Pending_Sector (waiting to be remapped), Temperature_Celsius. Set up `smartd` for automated monitoring and email alerts.


[← Previous](19-17-sosreport-system-diagnostic-reporting.md) | [↑ Index](index.md) | [Next →](21-12-prometheus-nodeexporter-modern-metrics.md)
