## 🔍 Section 11: Alerting

### 11.1 Nagios Notifications

```
Event Flow:
  1. Plugin executes → returns CRITICAL (exit code 2)
  2. Nagios updates service status
  3. Nagios checks notification settings:
     - Is notification_enabled=1?
     - Is current time within notification_period?
     - Has notification_interval passed since last notification?
  4. Nagios looks up contact_groups for this service/host
  5. For each contact, checks notification_period and notification_options
  6. Executes contact's notification_command (e.g., notify-service-by-email)
```

### 11.2 Zabbix Actions

```bash
# Email media type
# Administration → Media types → Email
# SMTP server:   smtp.example.com
# SMTP port:     587
# SMTP helo:     example.com
# SMTP email:    zabbix@example.com
# Connection security: STARTTLS

# Slack webhook
# Administration → Media types → Webhook
# Script: /usr/share/zabbix/alertscripts/slack.sh
```

### 11.3 Prometheus Alertmanager

```bash
# Install Alertmanager
wget https://github.com/prometheus/alertmanager/releases/download/v0.27.0/alertmanager-0.27.0.linux-amd64.tar.gz
tar xzf alertmanager-0.27.0.linux-amd64.tar.gz
sudo mv alertmanager-0.27.0.linux-amd64 /opt/alertmanager

sudo useradd --no-create-home --shell /bin/false alertmanager
sudo mkdir -p /var/lib/alertmanager
sudo chown alertmanager:alertmanager /var/lib/alertmanager

sudo tee /etc/systemd/system/alertmanager.service << 'EOF'
[Unit]
Description=Alertmanager
After=network.target

[Service]
User=alertmanager
Group=alertmanager
Type=simple
ExecStart=/opt/alertmanager/alertmanager \
    --config.file=/opt/alertmanager/alertmanager.yml \
    --storage.path=/var/lib/alertmanager/ \
    --web.listen-address=:9093
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload && sudo systemctl start alertmanager
curl http://localhost:9093/-/healthy
```

```yaml
# /opt/alertmanager/alertmanager.yml

global:
  resolve_timeout: 5m
  smtp_smarthost: 'smtp.example.com:587'
  smtp_from: 'alertmanager@example.com'
  smtp_auth_username: 'alertmanager@example.com'
  smtp_auth_password: 'password'
  smtp_require_tls: true

route:
  group_by: ['alertname', 'cluster']
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 4h
  receiver: 'default-receiver'

  routes:
    - match:
        severity: critical
      receiver: 'pagerduty-critical'
      repeat_interval: 10m

    - match:
        severity: warning
      receiver: 'email-warning'

    - match_re:
        service: ^(mysql|postgres|redis)$
      receiver: 'database-team'

inhibit_rules:
  - source_match:
      severity: 'critical'
    target_match:
      severity: 'warning'
    equal: ['alertname', 'cluster', 'instance']

  - source_match:
      alertname: 'InstanceDown'
    target_match_re:
      severity: 'warning|info'
    equal: ['instance']

receivers:
  - name: 'default-receiver'
    email_configs:
      - to: 'admin@example.com'

  - name: 'pagerduty-critical'
    pagerduty_configs:
      - routing_key: 'your-pagerduty-key'
        severity: critical

  - name: 'email-warning'
    email_configs:
      - to: 'team@example.com'
        headers:
          subject: '[WARNING] {{ .GroupLabels.alertname }}'

  - name: 'database-team'
    email_configs:
      - to: 'db-team@example.com'
    slack_configs:
      - api_url: 'https://hooks.slack.com/services/T00/B00/xxxx'
        channel: '#db-alerts'
        title: '{{ .GroupLabels.service }} on {{ .GroupLabels.instance }}'

  - name: 'slack-platform'
    slack_configs:
      - api_url: 'https://hooks.slack.com/services/T00/B00/xxxx'
        channel: '#platform-alerts'
```

### 11.4 Prometheus Alert Rules

```yaml
# /opt/prometheus/alerts/infrastructure.yml

groups:
  - name: infrastructure
    interval: 30s
    rules:
      - alert: InstanceDown
        expr: up == 0
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "Instance {{ $labels.instance }} is down"
          description: "{{ $labels.instance }} has been unreachable for more than 5 minutes."

      - alert: HighCPUUsage
        expr: |
          100 - (avg by(instance)
            (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 90
        for: 10m
        labels:
          severity: critical
        annotations:
          summary: "High CPU usage on {{ $labels.instance }}"
          description: "CPU usage is {{ $value | humanizePercentage }} on {{ $labels.instance }}"

      - alert: HighMemoryUsage
        expr: |
          (node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes)
          / node_memory_MemTotal_bytes * 100 > 90
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "High memory usage on {{ $labels.instance }}"

      - alert: DiskSpaceCritical
        expr: |
          (node_filesystem_size_bytes{mountpoint="/"}
          - node_filesystem_free_bytes{mountpoint="/"})
          / node_filesystem_size_bytes{mountpoint="/"} * 100 > 95
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "Disk space critical on {{ $labels.instance }}"
          description: "Disk usage is {{ $value | humanizePercentage }}"

      - alert: SSLCertificateExpiringSoon
        expr: probe_ssl_earliest_cert_expiry - time() < 86400 * 14
        for: 1h
        labels:
          severity: warning
        annotations:
          summary: "SSL certificate expiring soon for {{ $labels.instance }}"

      - alert: SSLCertificateExpired
        expr: probe_ssl_earliest_cert_expiry - time() < 0
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "SSL certificate expired for {{ $labels.instance }}"
```

---



---

[← Previous](12-section-10-grafana.md) | [↑ Index](index.md) | [Next →](14-section-12-log-monitoring.md)
