## 🔍 Section 12: Log Monitoring

### 12.1 Loki + Promtail

```
┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐
│  Logs on │───►│Promtail  │───►│  Loki    │◄───│  Grafana │
│  Disk    │    │(agent)   │    │(storage) │    │(query)   │
└──────────┘    └──────────┘    └──────────┘    └──────────┘

Promtail:
  - Reads log files (or journald, syslog)
  - Adds labels (job, instance, filename)
  - Sends compressed chunks to Loki

Loki:
  - Stores logs in compressed chunks
  - Indexes by labels only (no full-text index)
  - Horizontally scalable
```

```bash
# Install Loki
wget https://github.com/grafana/loki/releases/download/v2.9.0/loki-linux-amd64.zip
unzip loki-linux-amd64.zip
sudo mv loki-linux-amd64 /usr/local/bin/loki

sudo useradd --no-create-home --shell /bin/false loki
sudo mkdir -p /var/lib/loki /etc/loki
sudo chown loki:loki /var/lib/loki

sudo tee /etc/loki/loki-config.yml << 'YAML'
server:
  http_listen_port: 3100
  grpc_listen_port: 9096

common:
  instance_addr: 127.0.0.1
  path_prefix: /var/lib/loki
  storage:
    filesystem:
      chunks_directory: /var/lib/loki/chunks
      rules_directory: /var/lib/loki/rules
  replication_factor: 1
  ring:
    kvstore:
      store: inmemory

schema_config:
  configs:
    - from: 2024-01-01
      store: tsdb
      object_store: filesystem
      schema: v13
      index:
        prefix: index_
        period: 24h
YAML

sudo tee /etc/systemd/system/loki.service << 'EOF'
[Unit]
Description=Loki Log Aggregator
After=network.target

[Service]
User=loki
Group=loki
Type=simple
ExecStart=/usr/local/bin/loki -config.file=/etc/loki/loki-config.yml
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload && sudo systemctl start loki && sudo systemctl enable loki
curl http://localhost:3100/ready
```

```bash
# Install Promtail
wget https://github.com/grafana/loki/releases/download/v2.9.0/promtail-linux-amd64.zip
unzip promtail-linux-amd64.zip
sudo mv promtail-linux-amd64 /usr/local/bin/promtail

sudo tee /etc/loki/promtail-config.yml << 'YAML'
server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: /var/lib/loki/positions.yaml

clients:
  - url: http://localhost:3100/loki/api/v1/push

scrape_configs:
  - job_name: system
    static_configs:
      - targets: [localhost]
        labels:
          job: system
          __path__: /var/log/syslog

  - job_name: auth
    static_configs:
      - targets: [localhost]
        labels:
          job: auth
          __path__: /var/log/auth.log

  - job_name: nginx
    static_configs:
      - targets: [localhost]
        labels:
          job: nginx
          __path__: /var/log/nginx/access.log

  - job_name: docker
    static_configs:
      - targets: [localhost]
        labels:
          job: docker
          __path__: /var/lib/docker/containers/*/*-json.log
    pipeline_stages:
      - json:
          expressions:
            log: log
            stream: stream
            time: time
      - timestamp:
          source: time
          format: RFC3339Nano
      - labels:
          stream:
      - output:
          source: log
YAML

sudo tee /etc/systemd/system/promtail.service << 'EOF'
[Unit]
Description=Promtail Log Shipper
After=loki.service

[Service]
User=root
Type=simple
ExecStart=/usr/local/bin/promtail -config.file=/etc/loki/promtail-config.yml
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload && sudo systemctl start promtail && sudo systemctl enable promtail
```

### 12.2 LogQL

```logql
# Basic log query
{job="system"}

# With line filters
{job="system"} |= "error"
{job="nginx"} |= "500"
{job="auth"} |= "Failed password"

# Filter operators
{job="nginx"} |= "500"
{job="nginx"} != "health"
{job="nginx"} |~ "5[0-9][0-9]"
{job="nginx"} !~ "2[0-9][0-9]"

# Parsers
{job="nginx"} | json
{job="apache"} | logfmt
{job="nginx"} | regexp "^(?P<ip>\\S+) \\S+ \\S+ \\[(?P<date>[^\\]]+)\\]"

# Metric queries from logs
rate({job="nginx"} |= "500" [5m])

sum by (instance) (rate({job="nginx"} | json | status >= 500 [5m]))

# Aggregation
topk(3, sum by (path) (count_over_time({job="nginx"} | json | status = "200" [1h])))

# Alerting from logs
# groups:
#   - name: log_alerts
#     rules:
#       - alert: HighErrorRate
#         expr: sum(rate({job="nginx"} | json | status =~ "5[0-9][0-9]" [5m]))
#               / sum(rate({job="nginx"} [5m])) > 0.05
```

### 12.3 ELK Stack Overview

```
Filebeat → Logstash → Elasticsearch ← Kibana
(agent)    (pipeline)  (storage)      (UI)
```

```bash
# Docker Compose for ELK
cat > docker-compose.elk.yml << 'EOF'
version: '3'
services:
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:8.12.0
    environment:
      - discovery.type=single-node
      - xpack.security.enabled=false
    ports:
      - "9200:9200"
    volumes:
      - es_data:/usr/share/elasticsearch/data

  logstash:
    image: docker.elastic.co/logstash/logstash:8.12.0
    ports:
      - "5000:5000"
    volumes:
      - ./logstash.conf:/usr/share/logstash/pipeline/logstash.conf

  kibana:
    image: docker.elastic.co/kibana/kibana:8.12.0
    ports:
      - "5601:5601"
    depends_on:
      - elasticsearch

volumes:
  es_data:
EOF
```

---



---

[← Previous](13-section-11-alerting.md) | [↑ Index](index.md) | [Next →](15-section-13-uptime-and-certificate.md)
