## Command Reference

| Tool | Command / File | Purpose |
|------|---------------|---------|
| **Prometheus** | `/etc/prometheus/prometheus.yml` | Main config |
| | `/etc/prometheus/rules/*.yml` | Alerting/recording rules |
| | `promtool check config /etc/prometheus/prometheus.yml` | Validate config |
| | `curl localhost:9090/api/v1/targets` | List scrape targets |
| | `curl localhost:9090/api/v1/query?query=up` | Instant query |
| **Alertmanager** | `/etc/alertmanager/alertmanager.yml` | Config |
| | `amtool alert` / `amtool silence add ...` | Manage alerts/silences |
| **node_exporter** | `node_exporter --collector.textfile.directory=/path` | Custom metrics |
| | `curl localhost:9100/metrics` | Exposed metrics |
| **blackbox** | `curl 'localhost:9115/probe?target=https://x.com&module=http_2xx'` | Manual probe |
| **Grafana** | `/etc/grafana/provisioning/datasources/` | Datasource provisioning |
| | `/etc/grafana/provisioning/dashboards/` | Dashboard provisioning |
| | `/etc/grafana/provisioning/alerting/` | Alerting provisioning |
| **Loki** | `/etc/loki/config.yml` | Config |
| | `curl localhost:3100/loki/api/v1/labels` | List label names |
| | `curl 'localhost:3100/loki/api/v1/query_range?query={job="nginx"}'` | Query logs |
| **Promtail** | `/etc/promtail/config.yml` | Config |
| | `promtail --config.file=/etc/promtail/config.yml` | Run agent |
| **LogCLI** | `logcli query '{job="nginx"}' --since=1h` | Query logs from CLI |
| | `logcli query '{job="nginx"}' --tail` | Tail live logs |
| **Tempo** | `/etc/tempo/tempo.yml` | Config |
| | `curl localhost:3200/api/traces/{traceID}` | Get trace by ID |
| | `curl 'localhost:3200/api/search?q={.service.name="frontend"}'` | TraceQL search |
| **OTEL Collector** | `/etc/otel/config.yml` | Config |
| | `otelcol-contrib --config /etc/otel/config.yml` | Run collector |
| | `curl localhost:8889/metrics` | Collector's own metrics |
| **Auto-instr** | `java -javaagent:opentelemetry-javaagent.jar -jar app.jar` | Java |
| | `opentelemetry-instrument python app.py` | Python |
| | `node --require @opentelemetry/auto-instrumentations-node/register app.js` | Node.js |

---



---

[← Previous](17-observability-maturity-model.md) | [↑ Index](index.md) | [Next →](19-whats-coming-in-part-57.md)
