## 🔍 Section 9: Prometheus Exporters

### 9.1 node_exporter

```bash
# On each target host
wget https://github.com/prometheus/node_exporter/releases/download/v1.8.0/node_exporter-1.8.0.linux-amd64.tar.gz
tar xzf node_exporter-1.8.0.linux-amd64.tar.gz
sudo mv node_exporter-1.8.0.linux-amd64/node_exporter /usr/local/bin/

sudo useradd --no-create-home --shell /bin/false node_exporter

sudo tee /etc/systemd/system/node_exporter.service << 'EOF'
[Unit]
Description=Node Exporter
Documentation=https://prometheus.io/docs/guides/node-exporter/
After=network.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter \
    --web.listen-address=:9100 \
    --path.rootfs=/ \
    --collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)($|/)
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl start node_exporter
sudo systemctl enable node_exporter

# Verify
curl http://localhost:9100/metrics | head -30
```

### 9.2 blackbox_exporter

```bash
wget https://github.com/prometheus/blackbox_exporter/releases/download/v0.25.0/blackbox_exporter-0.25.0.linux-amd64.tar.gz
tar xzf blackbox_exporter-0.25.0.linux-amd64.tar.gz
sudo mv blackbox_exporter-0.25.0.linux-amd64 /opt/blackbox_exporter

sudo tee /etc/systemd/system/blackbox_exporter.service << 'EOF'
[Unit]
Description=Blackbox Exporter
After=network.target

[Service]
User=nobody
Type=simple
ExecStart=/opt/blackbox_exporter/blackbox_exporter \
    --config.file=/opt/blackbox_exporter/blackbox.yml \
    --web.listen-address=:9115
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
```

```yaml
# /opt/blackbox_exporter/blackbox.yml

modules:
  http_2xx:
    prober: http
    timeout: 5s
    http:
      valid_http_versions: ["HTTP/1.1", "HTTP/2"]
      valid_status_codes: [200, 201, 202, 301, 302]
      method: GET
      preferred_ip_protocol: ip4

  tcp_connect:
    prober: tcp
    timeout: 5s

  icmp:
    prober: icmp
    timeout: 5s
    icmp:
      preferred_ip_protocol: ip4

  ssl_expiry:
    prober: http
    timeout: 10s
    http:
      valid_status_codes: []
      fail_if_not_ssl: true
```

```bash
# Test blackbox_exporter
curl 'http://localhost:9115/probe?module=http_2xx&target=https://example.com'

# Check SSL certificate expiry
curl 'http://localhost:9115/probe?module=ssl_expiry&target=https://example.com'
# Look for: probe_ssl_earliest_cert_expiry
```

### 9.3 mysqld_exporter

```bash
wget https://github.com/prometheus/mysqld_exporter/releases/download/v0.15.1/mysqld_exporter-0.15.1.linux-amd64.tar.gz
tar xzf mysqld_exporter-0.15.1.linux-amd64.tar.gz
sudo mv mysqld_exporter-0.15.1.linux-amd64/mysqld_exporter /usr/local/bin/

sudo mysql -e "CREATE USER 'prometheus'@'localhost' IDENTIFIED BY 'monitor_pass';"
sudo mysql -e "GRANT PROCESS, REPLICATION CLIENT, SELECT ON *.* TO 'prometheus'@'localhost';"

sudo tee /etc/systemd/system/mysqld_exporter.service << 'EOF'
[Unit]
Description=MySQL Exporter
After=network.target mysql.service

[Service]
User=mysql
Type=simple
Environment=DATA_SOURCE_NAME=prometheus:monitor_pass@unix(/var/run/mysqld/mysqld.sock)/
ExecStart=/usr/local/bin/mysqld_exporter \
    --web.listen-address=:9104 \
    --collect.info_schema.processlist \
    --collect.info_schema.innodb_metrics
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload && sudo systemctl start mysqld_exporter
curl http://localhost:9104/metrics | grep mysql
```

### 9.4 Textfile Collector

```bash
# Enable textfile collector in node_exporter
# Add --collector.textfile.directory=/var/lib/node_exporter/textfile

sudo mkdir -p /var/lib/node_exporter/textfile

sudo tee /usr/local/bin/custom_metrics.sh << 'SCRIPT'
#!/bin/bash
OUTPUT_FILE="/var/lib/node_exporter/textfile/custom.prom"

# SSL certificate expiry
DOMAIN="example.com"
EXPIRY=$(echo | openssl s_client -servername "$DOMAIN" -connect "$DOMAIN":443 2>/dev/null | openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2)
if [ -n "$EXPIRY" ]; then
    EXPIRY_EPOCH=$(date -d "$EXPIRY" +%s)
    NOW_EPOCH=$(date +%s)
    DAYS_LEFT=$(( (EXPIRY_EPOCH - NOW_EPOCH) / 86400 ))
    echo "ssl_cert_days_left{domain=\"$DOMAIN\"} $DAYS_LEFT" > "$OUTPUT_FILE"
fi

# Available apt updates
UPDATES=$(apt list --upgradable 2>/dev/null | grep -c upgradable || echo 0)
echo "apt_updates_available $UPDATES" >> "$OUTPUT_FILE"

# Logged-in users
USERS=$(who | wc -l)
echo "logged_in_users $USERS" >> "$OUTPUT_FILE"
SCRIPT

sudo chmod +x /usr/local/bin/custom_metrics.sh
echo "*/5 * * * * root /usr/local/bin/custom_metrics.sh" | sudo tee /etc/cron.d/custom-metrics
```

---



---

[← Previous](10-section-8-promql-prometheus-query.md) | [↑ Index](index.md) | [Next →](12-section-10-grafana.md)
