## 🔍 Section 13: Log Security

### Remote Log Shipping with rsyslog

Centralized logging prevents attackers from covering their tracks by deleting local logs:

```bash
# On the log server (receiver)
sudo tee /etc/rsyslog.d/remote.conf > /dev/null << 'EOF'
# Listen for remote logs on TCP/UDP 514
module(load="imtcp")
module(load="imudp")
input(type="imtcp" port="514")
input(type="imudp" port="514")

# Template for organizing logs by hostname
$template RemoteLogs,"/var/log/remote/%hostname%/%programname%.log"
*.* ?RemoteLogs

# Stop processing after writing to remote file (don't write locally)
& ~
EOF

sudo systemctl restart rsyslog
sudo ufw allow 514/tcp
sudo ufw allow 514/udp

# On client machines (senders)
sudo tee /etc/rsyslog.d/forward.conf > /dev/null << 'EOF'
# Forward all logs to central server
*.* @@logserver.example.com:514    # TCP (reliable)
# *.* @logserver.example.com:514   # UDP (faster, less reliable)
EOF

sudo systemctl restart rsyslog
```

### Log Encryption with TLS

For logs containing sensitive data, encrypt in transit:

```bash
# On the log server
sudo tee /etc/rsyslog.d/tls-server.conf > /dev/null << 'EOF'
# Load TLS module
module(load="imtcp")
module(load="gtls")

# TCP listener with TLS
input(type="imtcp"
      port="6514"
      TLS="on"
      TLS.CertFile="/etc/ssl/certs/logserver.crt"
      TLS.KeyFile="/etc/ssl/private/logserver.key"
      TLS.CAFile="/etc/ssl/certs/ca.crt"
)
EOF

# On clients
sudo tee /etc/rsyslog.d/tls-client.conf > /dev/null << 'EOF'
# Load TLS module
module(load="omtcp")
module(load="gtls")

# Forward with TLS
action(type="omfwd"
       Target="logserver.example.com"
       Port="6514"
       Protocol="tcp"
       TCP_Framing="octet-counted"
       StreamDriver="gtls"
       StreamDriverMode="1"          # Authenticate TLS
       StreamDriverAuthMode="x509/name"
       StreamDriverPermittedPeers="logserver.example.com"
       ResendLastMSGOnReconnect="on"
       Action.ResumeInterval="10"
)
EOF
```

### Log Rotation

```bash
# Default config is in /etc/logrotate.conf
# Custom configs go in /etc/logrotate.d/

sudo tee /etc/logrotate.d/security-logs > /dev/null << 'EOF'
/var/log/audit/audit.log {
    rotate 7
    daily
    maxsize 50M
    missingok
    notifempty
    compress
    delaycompress
    postrotate
        /sbin/auditctl -R /etc/audit/rules.d/audit.rules
    endscript
}

/var/log/remote/*.log {
    rotate 30
    daily
    maxsize 100M
    missingok
    notifempty
    compress
    sharedscripts
    postrotate
        /usr/bin/systemctl reload rsyslog > /dev/null 2>&1 || true
    endscript
}
EOF
```

### Immutable Logs (Append-Only)

Prevent log tampering even by root:

```bash
# Make log files append-only
sudo chattr +a /var/log/auth.log
sudo chattr +a /var/log/syslog
sudo chattr +a /var/log/kern.log
sudo chattr +a /var/log/audit/audit.log

# Verify
lsattr /var/log/auth.log /var/log/syslog /var/log/audit/audit.log
# -----a----------e-- /var/log/auth.log
# -----a----------e-- /var/log/syslog
# -----a----------e-- /var/log/audit/audit.log

# To remove (must be root with CAP_LINUX_IMMUTABLE)
sudo chattr -a /var/log/auth.log
```

### SIEM Integration Basics

**SIEM** (Security Information and Event Management) aggregates logs from multiple sources for correlation, alerting, and compliance reporting:

```bash
# Common SIEM log shipping methods:

# 1. rsyslog -> SIEM (as shown above)
# 2. Filebeat + Logstash + Elasticsearch (ELK)
# 3. Splunk Universal Forwarder
# 4. Fluentd / Fluent Bit
# 5. Wazuh (open-source fork of OSSEC)

# Filebeat configuration example (shipping audit logs to Elasticsearch):
# filebeat.inputs:
# - type: log
#   enabled: true
#   paths:
#     - /var/log/audit/audit.log
#   fields:
#     log_type: auditd
# output.elasticsearch:
#   hosts: ["https://elastic.example.com:9200"]
#   username: "filebeat"
#   password: "${ES_PWD}"
```





[← Previous](13-section-12-ssh-hardening.md) | [↑ Index](index.md) | [Next →](15-section-14-security-auditing-procedures.md)
