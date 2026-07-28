## 7. Alertmanager

**Architecture:** Prometheus evaluates alerting rules → sends to Alertmanager → groups, inhibits, silences, routes → receivers.

**Alerting rules:**
```yaml
groups:
  - name: node_alerts
    interval: 30s
    rules:
      - alert: NodeDown
        expr: up{job="node"} == 0
        for: 5m
        labels: {severity: critical}
        annotations:
          summary: "Instance {{ $labels.instance }} down"
      - alert: HighCPU
        expr: 100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) by (instance) * 100) > 90
        for: 10m
        labels: {severity: warning}
      - alert: DiskSpace
        expr: (node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"}) < 0.1
        for: 5m
        labels: {severity: critical}
```

**Grouping:** Merges related alerts into one notification to reduce noise.

```yaml
route:
  group_by: ['severity', 'namespace']
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 4h
```

| Parameter | Purpose |
|-----------|---------|
| `group_by` | Labels to group notifications by |
| `group_wait` | Buffer time before first notification |
| `group_interval` | Wait before sending new alerts to existing group |
| `repeat_interval` | Re-send interval for still-firing alerts |

**Inhibition:** Suppress low-severity alerts when high-severity exists for same scope.

```yaml
inhibit_rules:
  - source_match: {severity: critical}
    target_match: {severity: warning}
    equal: ['instance']
```

**Silences:** Suppress alerts matching matchers for a duration.

```bash
amtool silence add --alertmanager.url=http://localhost:9093 \
  --author="tim-ham" --comment="Maintenance" --duration=2h \
  severity=critical instance=db-01
```

**Routing tree:**
```yaml
route:
  receiver: default
  routes:
    - match: {severity: critical}
      receiver: pagerduty-critical
      routes:
        - match: {namespace: production}
          receiver: pagerduty-production
    - match_re: {severity: ^(warning|info)$}
      receiver: slack-noncritical
    - match: {team: security}
      receiver: pagerduty-security
      continue: true
```

**Receivers:**

**Slack:**
```yaml
receivers:
  - name: slack-alerts
    slack_configs:
      - api_url: https://hooks.slack.com/services/T00/B00/XXXXX
        channel: '#alerts'
        send_resolved: true
        title: '{{ .GroupLabels.alertname }}'
        text: '{{ range .Alerts }}*{{ .Annotations.summary }}* {{ .Labels.instance }}{{ end }}'
```

**Email:**
```yaml
    email_configs:
      - to: ops@example.com
        smarthost: smtp.gmail.com:587
        auth_username: alertmanager@example.com
        auth_password: app-password
```

**PagerDuty:**
```yaml
    pagerduty_configs:
      - routing_key: YOUR_PD_KEY
        severity: critical
        description: '{{ .GroupLabels.alertname }}'
```

**Webhook:**
```yaml
    webhook_configs:
      - url: http://webhook:8080/alerts
        send_resolved: true
```





[← Previous](06-6-prometheus-storage.md) | [↑ Index](index.md) | [Next →](08-8-grafana.md)
