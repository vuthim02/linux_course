## 📋 Prerequisites

| Requirement | Details |
|-------------|---------|
| OS | Ubuntu 22.04 / Debian 12 (or RHEL-equivalent with `dnf`) |
| Access | Root or `sudo` on at least 3 servers (or VMs/containers) |
| Services | A test web server (e.g., `python3 -m http.server 8000`) |
| Tools | `curl`, `systemctl`, `mysql`, `git` |
| Time | 4–6 hours of hands-on lab work |
| Ports | 80, 9090 (Prometheus), 3000 (Grafana), 9100 (node_exporter), 5666 (NRPE), 10051 (Zabbix) |

### Docker Alternative

If you have Docker, you can use containers for Prometheus, Grafana, and Alertmanager instead of installing packages directly.

### Recommended Setup

For the best learning experience, use at least two separate machines (or VMs) — one for the monitoring stack and one as the target being monitored. This simulates a realistic environment where the monitoring system is independent of the services it watches.

If a multi-machine setup is not available, a single Ubuntu 22.04 VM with 4 GB of RAM and 2 CPU cores is sufficient. You can run Prometheus, Grafana, and a sample application on the same host.

### Network Notes

Ensure that the following ports are open between your monitoring server and the hosts being monitored:

- **9100** — Prometheus node_exporter metrics
- **9090** — Prometheus web UI and API
- **3000** — Grafana dashboard
- **9093** — Alertmanager webhook receiver


[← Previous](01-what-you-will-achieve-in.md) | [↑ Index](index.md) | [Next →](03-section-1-monitoring-philosophy.md)
