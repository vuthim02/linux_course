## 🔍 Section 7: Centralized Logging

In production, you send logs from all servers to a central location.

### Rsyslog as a Central Server

**Server side (log receiver):**

```bash
# /etc/rsyslog.conf — enable UDP and/or TCP reception
# Uncomment these lines:
module(load="imudp")
input(type="imudp" port="514")

module(load="imtcp")
input(type="imtcp" port="514")

# Store logs from remote hosts
$template RemoteLogs,"/var/log/remote/%HOSTNAME%/%PROGRAMNAME%.log"
*.* ?RemoteLogs
& ~
```

**Client side (log sender):**

```bash
# /etc/rsyslog.d/50-forward.conf
*.* @logserver.example.com:514   # UDP (single @)
*.* @@logserver.example.com:514  # TCP (double @@)

# Restart
sudo systemctl restart rsyslog
```

### Security Considerations

```bash
# Use firewall to restrict access to port 514
sudo ufw allow from 10.0.0.0/8 to any port 514

# Consider using RELP (Reliable Event Logging Protocol) for TCP
# TLS encryption for logs in transit
# Restrict who can write to log directories
```





[← Previous](10-level-3-advanced-centralized-logging.md) | [↑ Index](index.md) | [Next →](12-section-8-analyzing-logs-for.md)
