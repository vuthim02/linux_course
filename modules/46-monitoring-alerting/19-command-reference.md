## 📋 Command Reference

### Nagios Commands

| Command | Purpose |
|---------|---------|
| `sudo apt install nagios4 nagios-plugins nagios-nrpe-plugin` | Install Nagios |
| `sudo systemctl {start\|stop\|restart\|reload\|status} nagios4` | Service management |
| `sudo htpasswd -c /etc/nagios4/htpasswd.users nagiosadmin` | Set web UI password |
| `/usr/lib/nagios/plugins/check_ping -H HOST -w THRESH -c THRESH` | Ping check |
| `/usr/lib/nagios/plugins/check_nrpe -H HOST -c COMMAND` | Execute NRPE command |
| `sudo tail -f /var/log/nagios4/nagios.log` | Watch Nagios log |
| `sudo nagios4 -v /etc/nagios4/nagios.cfg` | Validate config |

### Zabbix Commands

| Command | Purpose |
|---------|---------|
| `sudo apt install zabbix-server-mysql zabbix-frontend-php zabbix-agent` | Install Zabbix |
| `sudo systemctl {start\|stop\|restart\|status} zabbix-server` | Server management |
| `sudo systemctl {start\|stop\|restart\|status} zabbix-agent` | Agent management |
| `sudo tee -a /etc/zabbix/zabbix_server.conf <<< 'DBPassword=pass'` | Configure DB password |
| `sudo tee /etc/zabbix/zabbix_agentd.conf <<< '...'` | Configure agent |
| `zcat /usr/share/zabbix-sql-scripts/mysql/server.sql.gz \| sudo mysql zabbix` | Import schema |
| `sudo tail -f /var/log/zabbix/zabbix_server.log` | Watch server log |

### Prometheus Commands

| Command | Purpose |
|---------|---------|
| `/opt/prometheus/prometheus --config.file=/opt/prometheus/prometheus.yml` | Start Prometheus |
| `sudo systemctl {start\|stop\|restart\|status} prometheus` | Service management |
| `curl http://localhost:9090/metrics` | View all metrics |
| `curl http://localhost:9090/api/v1/query?query=up` | Query via API |
| `curl http://localhost:9090/-/healthy` | Health check |
| `/opt/prometheus/promtool check config prometheus.yml` | Validate config |
| `sudo systemctl {start\|stop\|restart\|status} alertmanager` | Alertmanager management |
| `curl http://localhost:9093/api/v2/alerts` | List active alerts |

### Grafana Commands

| Command | Purpose |
|---------|---------|
| `sudo apt install grafana` | Install Grafana |
| `sudo systemctl {start\|stop\|restart\|status} grafana-server` | Service management |
| `grafana-cli plugins install PLUGIN_NAME` | Install a plugin |
| `sudo tail -f /var/log/grafana/grafana.log` | Watch Grafana log |
| `curl http://localhost:3000/api/health` | Health check |
| `curl -X POST http://localhost:3000/api/login -d '{"user":"admin","password":"admin"}'` | API login |

### Loki / Promtail Commands

| Command | Purpose |
|---------|---------|
| `/usr/local/bin/loki -config.file=/etc/loki/loki-config.yml` | Start Loki |
| `/usr/local/bin/promtail -config.file=/etc/loki/promtail-config.yml` | Start Promtail |
| `curl http://localhost:3100/ready` | Loki health check |
| `curl -G http://localhost:3100/loki/api/v1/query_range --data-urlencode 'query={job="system"}' ` | Query logs |

### Exporter Commands

| Command | Purpose |
|---------|---------|
| `/usr/local/bin/node_exporter --web.listen-address=:9100` | Start node_exporter |
| `curl http://localhost:9100/metrics` | View node metrics |
| `curl 'http://localhost:9115/probe?module=http_2xx&target=https://example.com'` | Blackbox probe |
| `/usr/local/bin/mysqld_exporter --web.listen-address=:9104` | Start MySQL exporter |

---



---

[← Previous](18-deep-understanding.md) | [↑ Index](index.md) | [Next →](20-whats-coming-in-part-47.md)
