## 🔍 Section 13: Uptime and Certificate Monitoring

### 13.1 SSL Certificate Expiry Monitoring

```bash
# Method 1: Nagios check_ssl_cert
sudo apt install monitoring-plugins-standard -y
/usr/lib/nagios/plugins/check_ssl_cert -H example.com -w 30 -c 10

# Method 2: Prometheus + blackbox_exporter
# In prometheus.yml:
#   params:
#     module: [ssl_expiry]
# Alert rule:
#   probe_ssl_earliest_cert_expiry - time() < 86400 * 14

# Method 3: Shell script + textfile collector
# See Section 9.6
```

### 13.2 Uptime Monitoring Tools

| Tool | Type | Features |
|------|------|----------|
| **UptimeRobot** | SaaS | Free tier: 50 monitors, 5-min checks, email/SMS |
| **Checkmk** | On-premise | Agent-based, auto-discovery, Nagios-compatible |
| **Icinga2** | On-premise | Nagios fork, modern config DSL, distributed |
| **StatusCake** | SaaS | Uptime, SSL, domain expiry monitoring |





[← Previous](14-section-12-log-monitoring.md) | [↑ Index](index.md) | [Next →](16-section-14-distributed-monitoring.md)
