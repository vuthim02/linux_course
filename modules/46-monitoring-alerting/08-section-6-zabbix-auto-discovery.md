## 🔍 Section 6: Zabbix Auto-Discovery

### 6.1 Network Discovery

```bash
# From Zabbix Web UI:
# Configuration → Discovery → Create Discovery Rule
#
# Name:            Discover Linux Servers
# Discovery by:    Zabbix agent
# IP range:        10.0.0.1-254
# Checks:          system.uname (will match Linux hosts)
# Update interval: 3600
# Enabled:         Yes
#
# Discovery actions:
#   When: Discovery status = "Device discovered"
#         Service type = "Zabbix agent"
#         Service port = 10050
#   Operation: Add host, Link template "Template OS Linux by Zabbix agent"
```

### 6.2 Auto-Registration

```bash
# On Zabbix server — /etc/zabbix/zabbix_server.conf
LogFile=/var/log/zabbix/zabbix_server.log
DBHost=localhost
DBName=zabbix
DBUser=zabbix
DBPassword=strong_password
TLSAccept=unencrypted

# From Zabbix Web UI:
# Configuration → Actions → Auto-registration actions → Create Action
#
# Name:            Auto-register Linux servers
# Type:            Auto-registration
#
# Conditions:
#   Host metadata contains "linux"
#
# Operations:
#   Add to groups: Linux Servers
#   Link templates: Template OS Linux by Zabbix agent
```

```bash
# On the monitored host — /etc/zabbix/zabbix_agentd.conf
Server=10.0.0.5
ServerActive=10.0.0.5
Hostname=web-server-01
HostMetadata=linux web-server production
```

### 6.3 Low-Level Discovery (LLD)

Zabbix LLD automatically discovers and monitors dynamic resources:

```bash
# File system discovery — built into "Template OS Linux by Zabbix agent"
# Discovers all mounted filesystems and creates items for:
#   vfs.fs.size[MOUNT,total], used, pfree, pused

# Network interface discovery — also built in
# Discovers eth0, eth1, lo, etc. and creates items for:
#   net.if.in[IF,bytes], net.if.out[IF,bytes]

# Custom LLD — discover Docker containers
UserParameter=docker.discovery,sudo docker ps --format '{"{#CONTAINER_NAME}":"{{.Names}}","{#CONTAINER_ID}":"{{.ID}}"}' | jq -s '{data: .}'
```

---



---

[← Previous](07-section-5-zabbix.md) | [↑ Index](index.md) | [Next →](09-section-7-prometheus.md)
