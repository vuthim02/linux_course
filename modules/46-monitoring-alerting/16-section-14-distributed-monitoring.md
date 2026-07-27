## 🔍 Section 14: Distributed Monitoring

### 14.1 Zabbix Proxy

```bash
# Zabbix Proxy — for remote site monitoring
sudo apt install zabbix-proxy-mysql -y

sudo tee /etc/zabbix/zabbix_proxy.conf << 'EOF'
Server=10.0.0.5
Hostname=proxy-remote-site
DBHost=localhost
DBName=zabbix_proxy
DBUser=zabbix
DBPassword=proxy_password
ConfigFrequency=3600
DataSenderFrequency=60
EOF

sudo mysql -e "CREATE DATABASE zabbix_proxy CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;"
sudo mysql -e "CREATE USER 'zabbix'@'localhost' IDENTIFIED BY 'proxy_password';"
sudo mysql -e "GRANT ALL PRIVILEGES ON zabbix_proxy.* TO 'zabbix'@'localhost';"
zcat /usr/share/zabbix-sql-scripts/mysql/proxy.sql | sudo mysql -uzabbix -pproxy_password zabbix_proxy

sudo systemctl restart zabbix-proxy && sudo systemctl enable zabbix-proxy

# On Zabbix server frontend:
# Administration → Proxies → Create proxy → proxy-remote-site → Active
```

### 14.2 Prometheus Federation

```yaml
# On the global/central Prometheus
scrape_configs:
  - job_name: 'federate-region-1'
    scrape_interval: 30s
    honor_labels: true
    metrics_path: '/federate'
    params:
      'match[]':
        - '{job="node"}'
        - '{__name__=~"node:.*"}'
    static_configs:
      - targets:
        - 'prometheus-region-1.example.com:9090'
```

### 14.3 Thanos — Prometheus HA and Long-Term Storage

```
Prometheus → Thanos Sidecar → Object Store (S3/GCS)
                                ↓
                         Thanos Querier (global view)
                                ↓
                            Grafana

Thanos Components:
  Sidecar   — Connects to Prometheus, uploads data to object store
  Store     — Reads data from object store
  Querier   — Single query endpoint across all data sources
  Compactor — Downsamples and compacts data
```

---



---

[← Previous](15-section-13-uptime-and-certificate.md) | [↑ Index](index.md) | [Next →](17-15-hands-on-practices.md)
