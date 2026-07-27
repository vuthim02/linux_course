## 🔍 Section 5: Zabbix

### 5.1 Installation

```bash
# Zabbix requires: server + frontend + agent + database (MySQL/PostgreSQL)

# 1. Install Zabbix repository
sudo apt update
sudo apt install -y zabbix-server-mysql zabbix-frontend-php zabbix-agent zabbix-sql-scripts mysql-server

# 2. Create database
sudo mysql -e "CREATE DATABASE zabbix CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;"
sudo mysql -e "CREATE USER 'zabbix'@'localhost' IDENTIFIED BY 'strong_password';"
sudo mysql -e "GRANT ALL PRIVILEGES ON zabbix.* TO 'zabbix'@'localhost';"
sudo mysql -e "SET GLOBAL log_bin_trust_function_creators = 1;"

# 3. Import schema
zcat /usr/share/zabbix-sql-scripts/mysql/server.sql.gz | sudo mysql -uzabbix -pstrong_password zabbix
sudo mysql -e "SET GLOBAL log_bin_trust_function_creators = 0;"

# 4. Configure Zabbix server
sudo tee -a /etc/zabbix/zabbix_server.conf << 'EOF'
DBHost=localhost
DBName=zabbix
DBUser=zabbix
DBPassword=strong_password
EOF

# 5. Configure PHP for frontend
sudo sed -i 's/^post_max_size.*/post_max_size = 16M/' /etc/php/*/apache2/php.ini
sudo sed -i 's/^max_execution_time.*/max_execution_time = 300/' /etc/php/*/apache2/php.ini
sudo sed -i 's/^max_input_time.*/max_input_time = 300/' /etc/php/*/apache2/php.ini
sudo sed -i 's/^date.timezone.*/date.timezone = UTC/' /etc/php/*/apache2/php.ini

# 6. Start services
sudo systemctl restart zabbix-server zabbix-agent apache2
sudo systemctl enable zabbix-server zabbix-agent

# 7. Complete frontend setup at: http://your-server/zabbix
#    Default login: Admin / zabbix
```

### 5.2 Architecture

```
┌──────────────────┐     ┌──────────────────┐
│   Zabbix Server   │◄────│  Zabbix Frontend │
│  (data collection,│     │  (PHP web UI)    │
│   processing,     │     └──────────────────┘
│   alerting)       │
└────────┬─────────┘
         │
    ┌────┴────┐
    │         │
    ▼         ▼
┌────────┐ ┌────────┐
│ Zabbix │ │ Zabbix │
│ Proxy  │ │ Agent  │
│(remote │ │(target)│
│ site)  │ └────────┘
└────┬───┘
     │
     ▼
┌──────────┐
│ Zabbix   │
│ Agents   │
│(remote)  │
└──────────┘

Components:
  Zabbix Server     — Central daemon that polls agents, processes data, triggers alerts
  Zabbix Proxy      — Optional intermediary for remote sites (reduces server load)
  Zabbix Agent      — Installed on monitored hosts, collects and sends metrics
  Zabbix Frontend   — Web UI for configuration, monitoring, and reports
  Database          — MySQL/PostgreSQL storing all config, history, and events
```

### 5.3 Templates, Items, Triggers, Actions

| Concept | Purpose | Example |
|---------|---------|---------|
| **Host** | A monitored device | `web-server-01` |
| **Host Group** | Logical grouping of hosts | `Linux Servers`, `Databases` |
| **Template** | Reusable set of items, triggers, graphs | `Template OS Linux by Zabbix agent` |
| **Item** | A single metric to collect | `system.cpu.load`, `vfs.fs.size[/,pused]` |
| **Trigger** | A condition that generates an event | `{server:system.cpu.load.last()}>5` |
| **Action** | What to do when trigger fires | Send email, run remote command, escalate |
| **Event** | A single occurrence of a trigger firing | `CPU load > 5 at 2026-06-24 14:30:00` |
| **Media Type** | How to deliver notifications | Email, SMS, Slack, Telegram |

### 5.4 Zabbix Agent Configuration

```bash
# /etc/zabbix/zabbix_agentd.conf — on monitored host

# Which Zabbix server can poll this agent
Server=10.0.0.5

# Which Zabbix server can send active checks
ServerActive=10.0.0.5

# Hostname as configured in Zabbix frontend
Hostname=web-server-01

# Enable remote commands (for auto-remediation)
EnableRemoteCommands=1

# User parameters — custom metrics
UserParameter=custom.app.health,curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8080/health
UserParameter=custom.app.users,curl -s http://127.0.0.1:8080/api/stats | jq '.active_users'
UserParameter=custom.cert.expiry,openssl s_client -connect example.com:443 -servername example.com 2>/dev/null </dev/null | openssl x509 -noout -enddate | cut -d= -f2

# Allow custom parameters
AllowKey=custom.app.*
```

### 5.5 Adding a Host via Zabbix Frontend

```bash
# From the Zabbix Web UI:
# Configuration → Hosts → Create Host
#
# Host name:    web-server-01
# Visible name: Web Server 01
# Groups:       Linux Servers
# Interfaces:   Agent → 10.0.0.10:10050
# Templates:    Template OS Linux by Zabbix agent
#               Template Module ICMP Ping
#
# Status: Enabled
```

### 5.6 Creating a Trigger

```bash
# From the Zabbix Web UI:
# Configuration → Hosts → web-server-01 → Triggers → Create Trigger
#
# Name:         CPU load too high on {HOST.NAME}
# Severity:     Warning
# Expression:   {web-server-01:system.cpu.load[all,avg1].last()}>5
# OK event generation: Expression
# Description: CPU load average (1 min) exceeded 5.0

# Expression syntax:
#   {host:key.function(parameters)}operatorvalue
#
# Examples:
#   {web-01:system.cpu.load[all,avg1].last()}>5
#   {db-01:vfs.fs.size[/,pused].last()}>90
#   {web-01:net.if.in[eth0,bytes].avg(5m)}>1000000
#   {web-01:system.uptime.last()}<3600
```

### 5.7 Creating an Action

```bash
# From the Zabbix Web UI:
# Configuration → Actions → Trigger Actions → Create Action
#
# Action name:  Notify admins on critical issues
#
# Conditions:
#   Trigger severity ≥ Warning
#   Host group = Linux Servers
#
# Operations:
#   Send to user groups: Zabbix administrators
#   Send via: Email
#   Default message:
#     Trigger: {TRIGGER.NAME}
#     Severity: {TRIGGER.SEVERITY}
#     Host: {HOST.NAME}
#     Value: {ITEM.VALUE}
#     Time: {EVENT.DATE} {EVENT.TIME}
#     Current status: {TRIGGER.STATUS}
#
# Recovery operations:
#   Send to user groups: Zabbix administrators
#   Message: Problem resolved on {HOST.NAME}: {TRIGGER.NAME}
```

---



---

[← Previous](06-section-4-nagios-dependencies-and.md) | [↑ Index](index.md) | [Next →](08-section-6-zabbix-auto-discovery.md)
