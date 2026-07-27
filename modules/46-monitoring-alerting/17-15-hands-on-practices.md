## 🛠️ 15 Hands-On Practices

### Practice 1: Install Nagios and Monitor a Host

```bash
# 1. Install Nagios Core on server (10.0.0.5)
sudo apt update && sudo apt install nagios4 nagios-plugins nagios-nrpe-plugin -y
sudo htpasswd -c /etc/nagios4/htpasswd.users nagiosadmin
sudo systemctl restart nagios4

# 2. Configure NRPE on remote host (10.0.0.10)
sudo apt install nagios-nrpe-server nagios-plugins -y
sudo sed -i 's/allowed_hosts=.*/allowed_hosts=127.0.0.1,10.0.0.5/' /etc/nagios/nrpe.cfg
sudo systemctl restart nagios-nrpe-server

# 3. Add host to Nagios config
sudo tee /etc/nagios4/conf.d/remote-hosts.cfg << 'EOF'
define host {
    use         generic-host
    host_name   web-server-01
    alias       Web Server 01
    address     10.0.0.10
    max_check_attempts 3
    check_period       24x7
    check_command      check-host-alive
    contact_groups     admins
}
define service {
    use                    generic-service
    host_name              web-server-01
    service_description    CPU Load
    check_command          check_nrpe!check_load
}
EOF

sudo systemctl restart nagios4
```

### Practice 2: Write a Custom Nagios Plugin

```bash
sudo tee /usr/lib/nagios/plugins/check_port_timeout << 'SCRIPT'
#!/bin/bash
HOST="${1:-127.0.0.1}"
PORT="${2:-80}"
WARN="${3:-2}"
CRIT="${4:-5}"

START=$(date +%s%N)
timeout "$CRIT" bash -c "echo >/dev/tcp/$HOST/$PORT" 2>/dev/null
RESULT=$?
END=$(date +%s%N)
TIME_MS=$(( (END - START) / 1000000 ))

if [ $RESULT -ne 0 ]; then
    echo "CRITICAL - Cannot connect to $HOST:$PORT"
    exit 2
fi

if [ $TIME_MS -ge $CRIT ]; then
    echo "CRITICAL - Port $PORT open but timeout ${TIME_MS}ms > ${CRIT}s | time=${TIME_MS}ms;${WARN};${CRIT};0;${CRIT}"
    exit 2
elif [ $TIME_MS -ge $WARN ]; then
    echo "WARNING - Port $PORT open but timeout ${TIME_MS}ms > ${WARN}s | time=${TIME_MS}ms;${WARN};${CRIT};0;${CRIT}"
    exit 1
fi

echo "OK - Port $PORT open in ${TIME_MS}ms | time=${TIME_MS}ms;${WARN};${CRIT};0;${CRIT}"
exit 0
SCRIPT

sudo chmod +x /usr/lib/nagios/plugins/check_port_timeout
/usr/lib/nagios/plugins/check_port_timeout 127.0.0.1 80 2 5
```

### Practice 3: Install Zabbix Server + Agent

```bash
# On Zabbix server:
sudo apt install -y zabbix-server-mysql zabbix-frontend-php zabbix-agent zabbix-sql-scripts mysql-server
sudo mysql -e "CREATE DATABASE zabbix CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;"
sudo mysql -e "CREATE USER 'zabbix'@'localhost' IDENTIFIED BY 'zabbix_pass';"
sudo mysql -e "GRANT ALL PRIVILEGES ON zabbix.* TO 'zabbix'@'localhost';"
zcat /usr/share/zabbix-sql-scripts/mysql/server.sql.gz | sudo mysql -uzabbix -pzabbix_pass zabbix
sudo tee -a /etc/zabbix/zabbix_server.conf << 'EOF'
DBPassword=zabbix_pass
EOF
sudo systemctl restart zabbix-server zabbix-agent apache2

# On monitored host:
sudo apt install zabbix-agent -y
sudo tee /etc/zabbix/zabbix_agentd.conf << 'EOF'
Server=10.0.0.5
ServerActive=10.0.0.5
Hostname=web-server-01
EOF
sudo systemctl restart zabbix-agent
```

### Practice 4: Create a Zabbix Trigger and Action

```bash
# From Zabbix Web UI:
# 1. Configuration → Hosts → web-server-01 → Triggers → Create trigger
#    Name: High CPU load on {HOST.NAME}
#    Expression: {web-server-01:system.cpu.load[all,avg1].last()}>5
#
# 2. Configuration → Actions → Trigger actions → Create action
#    Name: Email on high CPU
#    Conditions: Trigger severity = Warning
#    Operations: Send message to "Zabbix administrators" via Email
#
# 3. Administration → Users → Admin → Media → Add
#    Type: Email | Send to: admin@example.com
```

### Practice 5: Install Prometheus + node_exporter

```bash
# On Prometheus server:
wget https://github.com/prometheus/prometheus/releases/download/v2.53.0/prometheus-2.53.0.linux-amd64.tar.gz
tar xzf prometheus-2.53.0.linux-amd64.tar.gz
sudo mv prometheus-2.53.0.linux-amd64 /opt/prometheus
sudo useradd --no-create-home --shell /bin/false prometheus
sudo mkdir -p /var/lib/prometheus

cat > /opt/prometheus/prometheus.yml << 'EOF'
global:
  scrape_interval: 15s
scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
  - job_name: 'node'
    static_configs:
      - targets: ['10.0.0.10:9100', '10.0.0.11:9100']
EOF

sudo tee /etc/systemd/system/prometheus.service << 'EOF'
[Unit]
Description=Prometheus
After=network.target
[Service]
User=prometheus
Type=simple
ExecStart=/opt/prometheus/prometheus --config.file=/opt/prometheus/prometheus.yml --storage.tsdb.path=/var/lib/prometheus/
Restart=on-failure
[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload && sudo systemctl start prometheus

# On target hosts:
wget https://github.com/prometheus/node_exporter/releases/download/v1.8.0/node_exporter-1.8.0.linux-amd64.tar.gz
tar xzf node_exporter-1.8.0.linux-amd64.tar.gz
sudo mv node_exporter-1.8.0.linux-amd64/node_exporter /usr/local/bin/
sudo useradd --no-create-home --shell /bin/false node_exporter
sudo tee /etc/systemd/system/node_exporter.service << 'EOF'
[Unit]
Description=Node Exporter
After=network.target
[Service]
User=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter --web.listen-address=:9100
Restart=on-failure
[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload && sudo systemctl start node_exporter
```

### Practice 6: Write PromQL Queries

```promql
-- 1. Current CPU utilization per instance
100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

-- 2. Memory usage percentage
((node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes)
 / node_memory_MemTotal_bytes) * 100

-- 3. Disk usage percentage for root mount
((node_filesystem_size_bytes{mountpoint="/"}
  - node_filesystem_free_bytes{mountpoint="/"})
 / node_filesystem_size_bytes{mountpoint="/"} * 100)

-- 4. Network traffic rate
rate(node_network_receive_bytes_total[5m])

-- 5. Top 3 instances by CPU usage
topk(3, 100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100))

-- 6. Predict disk full in 24 hours
predict_linear(node_filesystem_free_bytes{mountpoint="/"}[6h], 86400)

-- 7. System uptime in days
(time() - node_boot_time_seconds) / 86400

-- 8. CPU by mode as percentage
avg by (instance, mode) (rate(node_cpu_seconds_total[5m])) * 100
```

### Practice 7: Build a Grafana Dashboard

```bash
# 1. Install Grafana
sudo apt install -y software-properties-common
sudo add-apt-repository "deb https://packages.grafana.com/oss/deb stable main"
wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -
sudo apt update && sudo apt install grafana -y
sudo systemctl start grafana-server

# 2. Login: http://localhost:3000 (admin/admin)

# 3. Add Prometheus data source:
#    Configuration → Data Sources → Add → Prometheus → URL: http://localhost:9090

# 4. Import dashboard ID 11074 (Linux Server Overview)
#    Create → Import → 11074 → Select Prometheus data source
```

### Practice 8: Configure Alertmanager for Email Alerts

```bash
wget https://github.com/prometheus/alertmanager/releases/download/v0.27.0/alertmanager-0.27.0.linux-amd64.tar.gz
tar xzf alertmanager-0.27.0.linux-amd64.tar.gz
sudo mv alertmanager-0.27.0.linux-amd64 /opt/alertmanager
sudo useradd --no-create-home --shell /bin/false alertmanager
sudo mkdir -p /var/lib/alertmanager

sudo tee /opt/alertmanager/alertmanager.yml << 'EOF'
global:
  smtp_smarthost: 'localhost:25'
  smtp_from: 'alertmanager@example.com'
  smtp_require_tls: false
route:
  group_by: ['alertname']
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 4h
  receiver: 'email-admin'
receivers:
  - name: 'email-admin'
    email_configs:
      - to: 'admin@example.com'
        headers:
          subject: '[ALERT] {{ .GroupLabels.alertname }}'
EOF

sudo /opt/alertmanager/alertmanager --config.file=/opt/alertmanager/alertmanager.yml &

# Add to prometheus.yml:
# alerting:
#   alertmanagers:
#     - static_configs:
#         - targets: ['localhost:9093']
# rule_files:
#   - 'alerts/*.yml'

# Create alert rules in /opt/prometheus/alerts/instance.yml
sudo mkdir -p /opt/prometheus/alerts
sudo systemctl restart prometheus
```

### Practice 9: Deploy Loki and Promtail

```bash
# See complete setup in Section 12.1
# After setup:
# 1. Add Loki data source in Grafana
# 2. Explore: {job="system"} |= "error"
# 3. Dashboard panel: rate({job="nginx"} |= "500" [5m])
```

### Practice 10: Zabbix Auto-Discovery

```bash
# 1. Enable auto-registration on Zabbix server
# 2. Create auto-registration action:
#    Conditions: Host metadata contains "linux"
#    Operations: Link template "Template OS Linux by Zabbix agent"
#
# 3. On new hosts:
sudo apt install zabbix-agent -y
sudo tee /etc/zabbix/zabbix_agentd.conf << 'EOF'
Server=10.0.0.5
ServerActive=10.0.0.5
Hostname=
HostMetadata=linux production webserver
EOF
sudo systemctl restart zabbix-agent
```

### Practice 11: Prometheus Recording Rules

```yaml
sudo mkdir -p /opt/prometheus/rules
cat > /opt/prometheus/rules/recording.yml << 'EOF'
groups:
  - name: cpu
    interval: 15s
    rules:
      - record: instance:cpu_utilization:percent
        expr: 100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)
  - name: memory
    interval: 30s
    rules:
      - record: instance:memory_used:percent
        expr: (node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes * 100
EOF
```

### Practice 12: Nagios Service Escalation

```bash
sudo tee -a /etc/nagios4/objects/contacts.cfg << 'EOF'
define contact {
    contact_name                    manager
    alias                           On-Call Manager
    service_notification_period     24x7
    host_notification_period        24x7
    service_notification_options    c,r
    host_notification_options       d,r
    email                           manager@example.com
}
define contactgroup {
    contactgroup_name   managers
    alias               Managers
    members             manager
}
define serviceescalation {
    host_name               web-server-01
    service_description     HTTP Check
    first_notification      5
    last_notification       0
    notification_interval   15
    contact_groups          managers
    escalation_period       24x7
    escalation_options      w,u,c
}
EOF
sudo systemctl restart nagios4
```

### Practice 13: Grafana Alerting

```bash
# Create via Grafana UI:
# Alerting → Alert rules → New alert rule
# Query: (node_filesystem_size_bytes{mountpoint="/"}
#         - node_filesystem_free_bytes{mountpoint="/"})
#        / node_filesystem_size_bytes{mountpoint="/"} * 100
# Condition: WHEN last() OF query(A) IS ABOVE 90
# Evaluate: every 1m for 5m
# Labels: severity=critical
```

### Practice 14: Custom Metrics with Textfile Collector

```bash
# See Section 9.6
# Create a script, make it executable, add to cron
# node_exporter --collector.textfile.directory=/var/lib/node_exporter/textfile
# Verify: curl http://localhost:9100/metrics | grep custom
```

### Practice 15: Real-World Integration — Complete Monitoring Stack

Build the full stack: Prometheus + node_exporter + Grafana + Alertmanager

```
Application Servers (3 hosts)
  ├── node_exporter (:9100) — system metrics
  ├── blackbox_exporter (:9115) — external checks
  └── promtail (:9080) — log shipping

Prometheus Server (:9090)
  ├── Scrapes all exporters
  ├── Evaluates alert rules
  └── TSDB storage

Alertmanager (:9093)
  ├── Receives alerts from Prometheus
  ├── Groups, deduplicates, inhibits
  └── Sends to email/Slack/PagerDuty

Grafana (:3000)
  ├── Prometheus data source (metrics)
  ├── Loki data source (logs)
  ├── Dashboards
  └── Unified alerting

Loki (:3100)
  └── Log storage
```

```bash
# Deploy all components using the commands from Practices 1-14
# Verify each component:
curl http://localhost:9090/-/healthy          # Prometheus
curl http://localhost:9093/-/healthy          # Alertmanager
curl http://localhost:3000/api/health         # Grafana
curl http://localhost:3100/ready              # Loki
curl http://localhost:9100/metrics | head -1  # node_exporter

# Test alerts:
# Stop node_exporter on one host → InstanceDown alert
# Fill disk: dd if=/dev/zero of=/tmp/bigfile bs=1M count=5000 → Disk alert

# Check alerts in:
# - Prometheus: http://localhost:9090/alerts
# - Alertmanager: http://localhost:9093/#/alerts
# - Grafana: Alerting → Alert groups

# View logs:
# Grafana → Explore → Loki → {job="system"}
```

---



---

[← Previous](16-section-14-distributed-monitoring.md) | [↑ Index](index.md) | [Next →](18-deep-understanding.md)
