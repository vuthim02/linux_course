## 🔍 Section 1: Monitoring Philosophy

### 1.1 The Four Golden Signals (Google SRE)

| Signal | What it measures | Example |
|--------|------------------|---------|
| **Latency** | Time to serve a request | HTTP response time > 500ms |
| **Traffic** | Demand on the system | Requests per second, active users |
| **Errors** | Rate of failed requests | HTTP 5xx, exceptions, crash rate |
| **Saturation** | How "full" the system is | CPU %, disk I/O wait, memory pressure |

### 1.2 What to Monitor

```
Layer          What to Monitor              Tools
─────          ───────────────              ─────
Application    HTTP response codes,         Prometheus, custom exporters
               latency, error rates,
               business metrics (orders/min)

System         CPU, memory, disk,           node_exporter, NRPE, Zabbix agent
               network I/O, processes,
               swap usage, load average

Network        Packet loss, latency,        blackbox_exporter, Nagios plugins
               bandwidth, connection state,
               DNS resolution time

Security       Failed logins, file          auditd, Wazuh, custom scripts
               integrity, open ports,
               certificate expiry

Logs           Application logs,            Loki, ELK, Graylog
               syslog, auth.log,
               structured JSON output
```

### 1.3 Push vs Pull Models

| Aspect | Pull Model | Push Model |
|--------|-----------|------------|
| **How it works** | Server scrapes metrics from targets | Targets send metrics to server |
| **Example** | Prometheus | Zabbix agent (active), Graphite |
| **Discovery** | Service discovery / static config | Targets must know server address |
| **Firewall** | Easier (server reaches out) | Easier (targets initiate outbound) |
| **Scalability** | Federation for horizontal scale | Proxies/aggregators for scale |
| **Load distribution** | Server controls scrape schedule | Targets control send timing |

### 1.4 Agents vs Agentless

| Approach | How it works | Pros | Cons |
|----------|-------------|------|------|
| **Agent-based** | Install software on target (NRPE, Zabbix agent, node_exporter) | Detailed metrics, low overhead, offline buffering | Must install and update on every host |
| **Agentless** | Check via SSH, SNMP, WMI, or API | No installation needed, easier to start | Higher overhead, less detail, credential management |
| **SNMP** | Standard protocol for network devices | Works on switches/routers, universal | Limited metric depth, MIB complexity |

### 1.5 The Monitoring Pipeline

```
┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐
│  Source   │───►│ Collect  │───►│  Store   │───►│Visualize │───►│  Alert   │
│ (metric)  │    │  (agent) │    │  (TSDB)  │    │ (Grafana)│    │(manager) │
└──────────┘    └──────────┘    └──────────┘    └──────────┘    └──────────┘

Source:   CPU counter, disk usage, HTTP response, log line
Collect:  node_exporter, NRPE, Zabbix agent, Promtail
Store:    Prometheus TSDB, Zabbix DB (MySQL/PostgreSQL), Loki
Visualize:Grafana, Zabbix frontend, Nagios UI
Alert:    Alertmanager, Zabbix actions, Nagios notifications
```

---



---

[← Previous](02-prerequisites.md) | [↑ Index](index.md) | [Next →](04-section-2-nagios-core.md)
