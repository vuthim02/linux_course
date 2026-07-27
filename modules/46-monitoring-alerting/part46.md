# 🐧 Linux System Administrator — Complete Course
## Part 46 of ∞: Monitoring and Alerting — Nagios, Zabbix, Prometheus, Grafana

---

> **Reverse Engineering Approach:** Instead of memorizing monitoring tool syntax, we start from the problem — *"How do you know your server is down before your users do?"*. We trace the path of a metric from its source (CPU counter, disk usage, HTTP response code) through collection, storage, visualization, and alerting, and then configure each component properly.

---

## 🎯 What You Will Achieve in Part 46

By the end of this part, you will:

- Understand the **four pillars of monitoring** — metrics, logging, tracing, alerting
- **Install and configure Nagios Core** with NRPE to monitor remote hosts
- **Write custom Nagios plugins** with proper return codes
- **Deploy Zabbix** with server, agent, frontend, and auto-discovery
- **Install Prometheus** with node_exporter, blackbox_exporter, and Alertmanager
- **Write PromQL queries** for real-time and historical analysis
- **Build Grafana dashboards** with Prometheus and Zabbix data sources
- **Configure unified alerting** with Alertmanager grouping, inhibition, and routing
- **Deploy Loki + Promtail** for log aggregation
- **Build a complete monitoring stack** — Prometheus + node_exporter + Grafana + Alertmanager

---

## 📋 Prerequisites

| Requirement | Details |
|-------------|---------|
| OS | Ubuntu 22.04 / Debian 12 (or RHEL-equivalent with `dnf`) |
| Access | Root or `sudo` on at least 3 servers (or VMs/containers) |
| Services | A test web server (e.g., `python3 -m http.server 8000`) |
| Tools | `curl`, `systemctl`, `mysql`, `git` |
| Time | 4–6 hours of hands-on lab work |
| Ports | 80, 9090 (Prometheus), 3000 (Grafana), 9100 (node_exporter), 5666 (NRPE), 10051 (Zabbix) |

---

## 🔍 Section 1: Monitoring Philosophy

### 1.1 The Four Golden Signals (Google SRE)

| Signal | What it measures | Example |
|--------|------------------|---------|
| **Latency** | Time to serve a request | HTTP response time > 500ms |
| **Traffic** | Demand on the system | Requests per second, active users |
| **Errors** | Rate of failed requests | HTTP 5xx, exceptions, crash rate |
| **Saturation** | How "full" the system is | CPU %, disk I/O wait, memory pressure |

### 1.2 What to Monitor

```
Layer          What to Monitor              Tools
─────          ───────────────              ─────
Application    HTTP response codes,         Prometheus, custom exporters
               latency, error rates,
               business metrics (orders/min)

System         CPU, memory, disk,           node_exporter, NRPE, Zabbix agent
               network I/O, processes,
               swap usage, load average

Network        Packet loss, latency,        blackbox_exporter, Nagios plugins
               bandwidth, connection state,
               DNS resolution time

Security       Failed logins, file          auditd, Wazuh, custom scripts
               integrity, open ports,
               certificate expiry

Logs           Application logs,            Loki, ELK, Graylog
               syslog, auth.log,
               structured JSON output
```

### 1.3 Push vs Pull Models

| Aspect | Pull Model | Push Model |
|--------|-----------|------------|
| **How it works** | Server scrapes metrics from targets | Targets send metrics to server |
| **Example** | Prometheus | Zabbix agent (active), Graphite |
| **Discovery** | Service discovery / static config | Targets must know server address |
| **Firewall** | Easier (server reaches out) | Easier (targets initiate outbound) |
| **Scalability** | Federation for horizontal scale | Proxies/aggregators for scale |
| **Load distribution** | Server controls scrape schedule | Targets control send timing |

### 1.4 Agents vs Agentless

| Approach | How it works | Pros | Cons |
|----------|-------------|------|------|
| **Agent-based** | Install software on target (NRPE, Zabbix agent, node_exporter) | Detailed metrics, low overhead, offline buffering | Must install and update on every host |
| **Agentless** | Check via SSH, SNMP, WMI, or API | No installation needed, easier to start | Higher overhead, less detail, credential management |
| **SNMP** | Standard protocol for network devices | Works on switches/routers, universal | Limited metric depth, MIB complexity |

### 1.5 The Monitoring Pipeline

```
┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐
│  Source   │───►│ Collect  │───►│  Store   │───►│Visualize │───►│  Alert   │
│ (metric)  │    │  (agent) │    │  (TSDB)  │    │ (Grafana)│    │(manager) │
└──────────┘    └──────────┘    └──────────┘    └──────────┘    └──────────┘

Source:   CPU counter, disk usage, HTTP response, log line
Collect:  node_exporter, NRPE, Zabbix agent, Promtail
Store:    Prometheus TSDB, Zabbix DB (MySQL/PostgreSQL), Loki
Visualize:Grafana, Zabbix frontend, Nagios UI
Alert:    Alertmanager, Zabbix actions, Nagios notifications
```

---

## 🔍 Section 2: Nagios Core

### 2.1 Installation

```bash
# Debian / Ubuntu
sudo apt update
sudo apt install nagios4 nagios-nrpe-plugin nagios-plugins -y

# Set admin password
sudo htpasswd -c /etc/nagios4/htpasswd.users nagiosadmin
# Enter password when prompted

# Start and enable
sudo systemctl restart nagios4
sudo systemctl enable nagios4

# Verify
sudo systemctl status nagios4
# Access: http://your-server/nagios4
# Login: nagiosadmin / (your password)
```

### 2.2 Nagios Architecture

```
┌────────────────────────────────────────────────────────┐
│                    Nagios Server                        │
│  ┌────────────────────────────────────────────────┐   │
│  │              Nagios Core (Daemon)               │   │
│  │  ┌─────────┐ ┌──────────┐ ┌────────────────┐   │   │
│  │  │Commands │ │  Hosts   │ │  Services      │   │   │
│  │  │(plugins)│ │definitions│ │  definitions    │   │   │
│  │  └─────────┘ └──────────┘ └────────────────┘   │   │
│  └────────────────────────────────────────────────┘   │
│                        │                               │
│         ┌──────────────┼──────────────┐               │
│         ▼              ▼              ▼               │
│   check_ping     check_nrpe      check_http           │
│         │              │              │               │
└─────────┼──────────────┼──────────────┼───────────────┘
          │              │              │
          ▼              ▼              ▼
       Remote Host   NRPE Daemon    Web Server
                     (port 5666)
```

### 2.3 Core Configuration Files

| File | Purpose |
|------|---------|
| `/etc/nagios4/nagios.cfg` | Main configuration — includes other files, defines paths |
| `/etc/nagios4/objects/commands.cfg` | Command definitions (what plugins to run) |
| `/etc/nagios4/objects/hosts.cfg` | Host definitions (servers to monitor) |
| `/etc/nagios4/objects/services.cfg` | Service definitions (what to check on each host) |
| `/etc/nagios4/objects/contacts.cfg` | Contact definitions (who gets alerts) |
| `/etc/nagios4/objects/timeperiods.cfg` | Time period definitions (24x7, work hours) |
| `/etc/nagios4/htpasswd.users` | Web UI authentication (Apache htpasswd) |
| `/etc/nagios4/cgi.cfg` | CGI (web interface) configuration |

### 2.4 Command Definitions

```bash
# /etc/nagios4/objects/commands.cfg

# Define a command — how to execute a plugin
define command {
    command_name    check_local_disk
    command_line    /usr/lib/nagios/plugins/check_disk -w $ARG1$ -c $ARG2$ -p $ARG3$
}

define command {
    command_name    check_local_load
    command_line    /usr/lib/nagios/plugins/check_load -w $ARG1$ -c $ARG2$
}

define command {
    command_name    check_local_procs
    command_line    /usr/lib/nagios/plugins/check_procs -w $ARG1$ -c $ARG2$ -s $ARG3$
}

define command {
    command_name    check_nrpe
    command_line    /usr/lib/nagios/plugins/check_nrpe -H $HOSTADDRESS$ -c $ARG1$
}

define command {
    command_name    check_http
    command_line    /usr/lib/nagios/plugins/check_http -H $HOSTADDRESS$ -u $ARG1$ -w $ARG2$ -c $ARG3$
}

define command {
    command_name    check_ping
    command_line    /usr/lib/nagios/plugins/check_ping -H $HOSTADDRESS$ -w $ARG1$ -c $ARG2$
}
```

### 2.5 Host and Service Definitions

```bash
# /etc/nagios4/objects/hosts.cfg

# Generic host template
define host {
    name                    generic-host
    notifications_enabled   1
    event_handler_enabled   1
    flap_detection_enabled  1
    process_perf_data       1
    retain_status_information 1
    retain_nonstatus_information 1
    register                0    # Template only, not a real host
}

# Local Nagios server
define host {
    use                     generic-host
    host_name               nagios-server
    alias                   Nagios Core Server
    address                 127.0.0.1
    max_check_attempts      3
    check_period            24x7
    check_command           check-host-alive
    contact_groups          admins
    notification_interval   60
    notification_period     24x7
}

# Remote web server
define host {
    use                     generic-host
    host_name               web-server-01
    alias                   Production Web Server
    address                 10.0.0.10
    max_check_attempts      3
    check_period            24x7
    check_command           check-host-alive
    contact_groups          admins
    notification_interval   60
    notification_period     24x7
}
```

```bash
# /etc/nagios4/objects/services.cfg

# Generic service template
define service {
    name                    generic-service
    active_checks_enabled   1
    passive_checks_enabled  1
    parallelize_check       1
    obsess_over_service     1
    check_freshness         0
    notifications_enabled   1
    event_handler_enabled   1
    flap_detection_enabled  1
    process_perf_data       1
    retain_status_information 1
    retain_nonstatus_information 1
    register                0
}

# Check local disk usage
define service {
    use                     generic-service
    host_name               nagios-server
    service_description     Root Disk Usage
    check_command           check_local_disk!20%!10%!/
    max_check_attempts      3
    check_interval          5
    retry_interval          1
    check_period            24x7
    notification_interval   60
    notification_period     24x7
    contact_groups          admins
}

# Check HTTP on web server
define service {
    use                     generic-service
    host_name               web-server-01
    service_description     HTTP Check
    check_command           check_http!/index.html!5!10
    max_check_attempts      3
    check_interval          5
    retry_interval          1
    check_period            24x7
    notification_interval   60
    notification_period     24x7
    contact_groups          admins
}

# Check SSH on web server via NRPE
define service {
    use                     generic-service
    host_name               web-server-01
    service_description     SSH Service
    check_command           check_nrpe!check_ssh
    max_check_attempts      3
    check_interval          5
    retry_interval          1
    check_period            24x7
    notification_interval   60
    notification_period     24x7
    contact_groups          admins
}

# Check disk via NRPE on web server
define service {
    use                     generic-service
    host_name               web-server-01
    service_description     Remote Disk Usage
    check_command           check_nrpe!check_disk
    max_check_attempts      3
    check_interval          10
    retry_interval          2
    check_period            24x7
    notification_interval   60
    notification_period     24x7
    contact_groups          admins
}
```

### 2.6 Hostgroups and Servicegroups

```bash
# /etc/nagios4/objects/hosts.cfg — hostgroups

define hostgroup {
    hostgroup_name  web-servers
    alias           Web Servers
    members         web-server-01, web-server-02
}

define hostgroup {
    hostgroup_name  db-servers
    alias           Database Servers
    members         db-server-01
}

# Apply services to entire hostgroups instead of individual hosts
define service {
    use                     generic-service
    hostgroup_name          web-servers
    service_description     HTTP Check
    check_command           check_http!/index.html!5!10
    max_check_attempts      3
    check_interval          5
    contact_groups          admins
}
```

### 2.7 Contacts and Notifications

```bash
# /etc/nagios4/objects/contacts.cfg

define contact {
    contact_name                    admin
    alias                           System Administrator
    service_notification_period     24x7
    host_notification_period        24x7
    service_notification_options    w,u,c,r,f,s
    host_notification_options       d,u,r,f,s
    service_notification_commands   notify-service-by-email
    host_notification_commands      notify-host-by-email
    email                           admin@example.com
}

define contactgroup {
    contactgroup_name   admins
    alias               System Administrators
    members             admin
}
```

### 2.8 Time Periods

```bash
# /etc/nagios4/objects/timeperiods.cfg

define timeperiod {
    timeperiod_name     24x7
    alias               24 Hours A Day, 7 Days A Week
    sunday              00:00-24:00
    monday              00:00-24:00
    tuesday             00:00-24:00
    wednesday           00:00-24:00
    thursday            00:00-24:00
    friday              00:00-24:00
    saturday            00:00-24:00
}

define timeperiod {
    timeperiod_name     workhours
    alias               Standard Work Hours
    monday              09:00-17:00
    tuesday             09:00-17:00
    wednesday           09:00-17:00
    thursday            09:00-17:00
    friday              09:00-17:00
}

define timeperiod {
    timeperiod_name     after-hours
    alias               After Hours / Weekend
    sunday              00:00-24:00
    monday              17:00-24:00
    tuesday             17:00-24:00
    wednesday           17:00-24:00
    thursday            17:00-24:00
    friday              17:00-24:00
    saturday            00:00-24:00
}
```

---

## 🔍 Section 3: Nagios Plugins

### 3.1 Standard Plugins

| Plugin | Purpose | Example |
|--------|---------|---------|
| `check_ping` | ICMP ping with thresholds | `check_ping -H 10.0.0.1 -w 100,20% -c 200,50%` |
| `check_http` | HTTP/S check with content match | `check_http -H example.com -u /health -s "OK"` |
| `check_ssh` | SSH service check | `check_ssh 10.0.0.10` |
| `check_disk` | Disk usage check | `check_disk -w 20% -c 10% -p /dev/sda1` |
| `check_load` | System load average | `check_load -w 5.0,4.0,3.0 -c 10.0,6.0,4.0` |
| `check_procs` | Process count | `check_procs -w 150 -c 200` |
| `check_swap` | Swap usage | `check_swap -w 50% -c 25%` |
| `check_ntp` | NTP time offset | `check_ntp -H pool.ntp.org -w 0.5 -c 1.0` |
| `check_dns` | DNS resolution | `check_dns -H example.com -s 8.8.8.8` |
| `check_tcp` | TCP port check | `check_tcp -H 10.0.0.10 -p 3306` |
| `check_udp` | UDP service check | `check_udp -H 10.0.0.10 -p 161` |
| `check_smtp` | SMTP service check | `check_smtp -H mail.example.com` |
| `check_mysql` | MySQL connection check | `check_mysql -H 10.0.0.10 -u nagios -p secret` |

### 3.2 Plugin Return Codes

```bash
# Every Nagios plugin must return ONE of these exit codes:

# 0 = OK       — Everything is working fine
# 1 = WARNING  — Something is concerning but not critical
# 2 = CRITICAL — Something is broken, take action
# 3 = UNKNOWN  — Could not determine status

# Examples:
/usr/lib/nagios/plugins/check_ping -H 8.8.8.8 -w 100,20% -c 200,50%
echo $?
# 0 (OK) — ping responded within thresholds

/usr/lib/nagios/plugins/check_disk -w 80% -c 90% -p /
echo $?
# 0 (OK) or 1 (WARNING) or 2 (CRITICAL) depending on disk usage
```

### 3.3 Plugin Output Format

```
Plugin output format:
OK - Description | 'label'=value;warn;crit;min;max

Example output:
OK - Disk / is at 45% used (24GB/53GB) | '/used'=45%;80;90;0;100

Nagios parses:
  - The status text before the pipe: "OK - Disk / is at 45% used (24GB/53GB)"
  - Performance data after the pipe: '/used'=45%;80;90;0;100
  - Performance data is stored in the Nagios status log and can be graphed
```

### 3.4 Writing a Custom Nagios Plugin

```bash
#!/bin/bash
# /usr/lib/nagios/plugins/check_custom_app — Custom Python application health check

# A valid Nagios plugin MUST:
# 1. Print one line of output
# 2. Exit with 0 (OK), 1 (WARNING), 2 (CRITICAL), or 3 (UNKNOWN)

# Check if our app is responding on TCP port 8080
HOST="${1:-127.0.0.1}"
PORT="${2:-8080}"
WARN_THRESHOLD="${3:-2}"
CRIT_THRESHOLD="${4:-5}"

# Measure response time
START=$(date +%s%N)
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}:%{time_total}" \
    --connect-timeout 5 \
    "http://${HOST}:${PORT}/health" 2>/dev/null)
END=$(date +%s%N)
RESPONSE_TIME_MS=$(( (END - START) / 1000000 ))

HTTP_CODE="${RESPONSE%%:*}"
TIME_SECONDS="${RESPONSE##*:}"

if [ "$HTTP_CODE" = "200" ]; then
    STATUS="OK"
    EXIT_CODE=0
elif [ "$HTTP_CODE" = "" ]; then
    STATUS="CRITICAL"
    EXIT_CODE=2
    echo "CRITICAL - Connection to ${HOST}:${PORT} failed"
    exit 2
else
    STATUS="WARNING"
    EXIT_CODE=1
fi

# Compare response time to thresholds
if (( $(echo "$TIME_SECONDS > $CRIT_THRESHOLD" | bc -l) )); then
    STATUS="CRITICAL"
    EXIT_CODE=2
elif (( $(echo "$TIME_SECONDS > $WARN_THRESHOLD" | bc -l) )); then
    STATUS="WARNING"
    EXIT_CODE=1
fi

# Output with performance data
echo "${STATUS} - App on ${HOST}:${PORT} returned HTTP ${HTTP_CODE} in ${TIME_SECONDS}s | 'response_time'=${TIME_SECONDS};${WARN_THRESHOLD};${CRIT_THRESHOLD};0;30 'http_code'=${HTTP_CODE};;;0;599"

exit $EXIT_CODE
```

```bash
# Make it executable
sudo chmod +x /usr/lib/nagios/plugins/check_custom_app

# Test it
/usr/lib/nagios/plugins/check_custom_app 127.0.0.1 8080 2 5
# OK - App on 127.0.0.1:8080 returned HTTP 200 in 0.045s | 'response_time'=0.045;2;5;0;30 'http_code'=200;;;0;599
echo $?
# 0

# Register in Nagios
# In commands.cfg:
# define command {
#     command_name    check_custom_app
#     command_line    /usr/lib/nagios/plugins/check_custom_app $HOSTADDRESS$ $ARG1$ $ARG2$ $ARG3$
# }

# In services.cfg:
# define service {
#     host_name               app-server-01
#     service_description     Custom App Health
#     check_command           check_custom_app!8080!2!5
#     max_check_attempts      3
#     check_interval          1
#     retry_interval          1
#     contact_groups          admins
# }
```

### 3.5 NRPE — Nagios Remote Plugin Executor

```bash
# On the remote host (the one being monitored):
sudo apt update
sudo apt install nagios-nrpe-server nagios-plugins -y

# Configure NRPE daemon
sudo tee /etc/nagios/nrpe.cfg << 'EOF'
server_port=5666
server_address=0.0.0.0
allowed_hosts=127.0.0.1,10.0.0.5
dont_blame_nrpe=0
debug=0
command_timeout=60

command[check_users]=/usr/lib/nagios/plugins/check_users -w 5 -c 10
command[check_load]=/usr/lib/nagios/plugins/check_load -w 5.0,4.0,3.0 -c 10.0,6.0,4.0
command[check_disk]=/usr/lib/nagios/plugins/check_disk -w 20% -c 10% -p /
command[check_swap]=/usr/lib/nagios/plugins/check_swap -w 50% -c 25%
command[check_procs]=/usr/lib/nagios/plugins/check_procs -w 150 -c 200
command[check_ssh]=/usr/lib/nagios/plugins/check_ssh 127.0.0.1
EOF

sudo systemctl restart nagios-nrpe-server
sudo systemctl enable nagios-nrpe-server

# Verify NRPE is listening
sudo ss -tlnp | grep 5666
# LISTEN 0  128  0.0.0.0:5666  0.0.0.0:*  users:(("nrpe",pid=1234,fd=3))
```

```bash
# On Nagios server — test NRPE connection
/usr/lib/nagios/plugins/check_nrpe -H 10.0.0.10 -c check_load
# OK - load average: 0.23, 0.15, 0.10 | load1=0.230;5.000;10.000;0; ...

/usr/lib/nagios/plugins/check_nrpe -H 10.0.0.10 -c check_disk
# OK - Disk / is at 45% used (24GB/53GB) | '/used'=45%;20;10;0;100

# Test what commands NRPE has available
/usr/lib/nagios/plugins/check_nrpe -H 10.0.0.10
# NRPE v4.0.3
```

---

## 🔍 Section 4: Nagios Dependencies and Escalations

### 4.1 Service Dependencies

```bash
# /etc/nagios4/objects/services.cfg

# Web service depends on MySQL being up first
define servicedependency {
    dependent_host_name             web-server-01
    dependent_service_description  Web Application
    host_name                      db-server-01
    service_description            MySQL Status
    execution_failure_criteria     w,u,c
    notification_failure_criteria  w,u,c
    dependency_period              24x7
}
```

### 4.2 Host Dependencies

```bash
# /etc/nagios4/objects/hosts.cfg

define hostdependency {
    dependent_host_name         web-server-01
    host_name                   router-01
    dependency_period           24x7
    dependency_type             physical_topology
    inherits_parent             1
    execution_failure_criteria  d,u
    notification_failure_criteria d,u
}
```

### 4.3 Escalations

```bash
# /etc/nagios4/objects/contacts.cfg

define contact {
    contact_name                    oncall-manager
    alias                           On-Call Manager
    service_notification_period     after-hours
    host_notification_period        after-hours
    service_notification_options    c,r
    host_notification_options       d,r
    service_notification_commands   notify-service-by-sms
    host_notification_commands      notify-host-by-sms
    email                           manager@example.com
    pager                           555-0123@vtext.com
}

# If problem persists after 10 notifications → escalate to manager
define serviceescalation {
    host_name               web-server-01
    service_description     HTTP Check
    first_notification      10
    last_notification       0
    notification_interval   30
    contact_groups          oncall-managers
}
```

### 4.4 Notification Methods

```bash
# /etc/nagios4/objects/commands.cfg

define command {
    command_name    notify-service-by-email
    command_line    /usr/bin/printf "%b" "***** Nagios *****\\n\\nNotification Type: $NOTIFICATIONTYPE$\\n\\nService: $SERVICEDESC$\\nHost: $HOSTALIAS$\\nAddress: $HOSTADDRESS$\\nState: $SERVICESTATE$\\n\\nDate/Time: $LONGDATETIME$\\n\\nAdditional Info:\\n\\n$SERVICEOUTPUT$\\n" | /usr/bin/mail -s "** $NOTIFICATIONTYPE$ Service Alert: $HOSTALIAS$/$SERVICEDESC$ is $SERVICESTATE$ **" $CONTACTEMAIL$
}

define command {
    command_name    notify-service-by-sms
    command_line    /usr/bin/printf "%b" "Nagios: $HOSTALIAS$/$SERVICEDESC$ is $SERVICESTATE$" | /usr/bin/mail -s "" $CONTACTPAGER$
}

define command {
    command_name    notify-service-by-slack
    command_line    /usr/local/bin/nagios-slack.sh "$NOTIFICATIONTYPE$" "$HOSTALIAS$" "$SERVICEDESC$" "$SERVICESTATE$" "$SERVICEOUTPUT$"
}
```

---

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

## 🔍 Section 7: Prometheus

### 7.1 Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      Prometheus Ecosystem                     │
│                                                              │
│  ┌──────────┐    scrape     ┌──────────────┐                │
│  │ Service  │◄──────────────│  Prometheus  │                │
│  │ Discovery│               │    Server    │                │
│  │(K8s,DNS, │               │  (TSDB)      │                │
│  │ file_sd) │               └──────┬───────┘                │
│  └──────────┘                      │                        │
│                                    │                        │
│               ┌────────────────────┼──────────────────┐     │
│               ▼                    ▼                  ▼     │
│        ┌──────────┐       ┌──────────────┐    ┌──────────┐ │
│        │  Push    │       │ Alertmanager │    │  Grafana │ │
│        │ Gateway  │       │(alerts,      │    │(dashboards│ │
│        │(short-   │       │ grouping,    │    │, queries) │ │
│        │ lived)   │       │ inhibit)     │    └──────────┘ │
│        └──────────┘       └──────────────┘                 │
│                                                              │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐       │
│  │ node_    │ │ blackbox_│ │ mysql_   │ │ nginx_   │       │
│  │ exporter │ │ exporter │ │ exporter │ │ exporter │       │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘       │
└─────────────────────────────────────────────────────────────┘

Components:
  Prometheus Server    — Scrapes metrics, stores TSDB, evaluates rules
  Exporters            — Expose metrics from various systems on /metrics
  Alertmanager         — Handles alerts: dedup, group, route, silence
  Pushgateway          — Accepts pushed metrics from short-lived jobs
  Service Discovery    — Automatically finds targets
  Grafana              — Visualization and dashboarding
```

### 7.2 Installation

```bash
# Download and install Prometheus
wget https://github.com/prometheus/prometheus/releases/download/v2.53.0/prometheus-2.53.0.linux-amd64.tar.gz
tar xzf prometheus-2.53.0.linux-amd64.tar.gz
sudo mv prometheus-2.53.0.linux-amd64 /opt/prometheus

# Create user
sudo useradd --no-create-home --shell /bin/false prometheus
sudo mkdir -p /var/lib/prometheus
sudo chown prometheus:prometheus /var/lib/prometheus

# Create systemd service
sudo tee /etc/systemd/system/prometheus.service << 'EOF'
[Unit]
Description=Prometheus
Documentation=https://prometheus.io/docs/
After=network.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/opt/prometheus/prometheus \
    --config.file=/opt/prometheus/prometheus.yml \
    --storage.tsdb.path=/var/lib/prometheus/ \
    --web.console.templates=/opt/prometheus/consoles \
    --web.console.libraries=/opt/prometheus/console_libraries \
    --web.listen-address=0.0.0.0:9090
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl start prometheus
sudo systemctl enable prometheus

# Verify
curl http://localhost:9090/metrics | head -20
```

### 7.3 prometheus.yml Configuration

```yaml
# /opt/prometheus/prometheus.yml

global:
  scrape_interval:     15s
  evaluation_interval: 15s
  scrape_timeout:      10s

alerting:
  alertmanagers:
    - static_configs:
        - targets:
          - localhost:9093

rule_files:
  - "alerts/*.yml"
  - "rules/*.yml"

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'node'
    static_configs:
      - targets:
        - '10.0.0.10:9100'
        - '10.0.0.11:9100'
        - '10.0.0.12:9100'

  - job_name: 'blackbox'
    metrics_path: /probe
    params:
      module: [http_2xx]
    static_configs:
      - targets:
        - 'https://example.com'
        - 'https://api.example.com/health'
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: 127.0.0.1:9115

  - job_name: 'mysql'
    static_configs:
      - targets: ['10.0.0.12:9104']

  - job_name: 'cadvisor'
    static_configs:
      - targets: ['10.0.0.10:8080']

  - job_name: 'custom_exporters'
    file_sd_configs:
      - files:
        - '/opt/prometheus/targets/*.json'
        refresh_interval: 5m
```

### 7.4 Service Discovery Files

```json
// /opt/prometheus/targets/webservers.json
[
  {
    "targets": ["10.0.0.10:9100", "10.0.0.11:9100"],
    "labels": {
      "env": "production",
      "role": "web"
    }
  },
  {
    "targets": ["10.0.0.12:9100"],
    "labels": {
      "env": "production",
      "role": "database"
    }
  }
]
```

### 7.5 Metrics Model

| Metric Type | Description | Example | Use Case |
|-------------|-------------|---------|----------|
| **Counter** | Only increases (or resets to 0) | `http_requests_total` | Request count, errors |
| **Gauge** | Can go up or down | `node_memory_MemAvailable_bytes` | CPU, memory, disk |
| **Histogram** | Samples in configurable buckets | `http_request_duration_seconds_bucket` | Latency percentiles |
| **Summary** | Pre-computed quantiles on client side | `rpc_duration_seconds` | Pre-computed percentiles |

```bash
# Counter: always goes up (or resets to 0 on restart)
prometheus_http_requests_total{handler="/metrics",code="200"} 1024

# Gauge: can go up and down
node_memory_MemAvailable_bytes 2.45e+10

# Histogram: observe into buckets
http_request_duration_seconds_bucket{le="0.1"}  500
http_request_duration_seconds_bucket{le="0.5"}  800
http_request_duration_seconds_bucket{le="1"}    950
http_request_duration_seconds_bucket{le="+Inf"} 1000
http_request_duration_seconds_sum               450.0
http_request_duration_seconds_count             1000

# Summary: quantiles pre-computed
rpc_duration_seconds{quantile="0.5"}  0.05
rpc_duration_seconds{quantile="0.9"}  0.1
rpc_duration_seconds{quantile="0.99"} 0.3
rpc_duration_seconds_sum              450.0
rpc_duration_seconds_count            1000
```

---

## 🔍 Section 8: PromQL — Prometheus Query Language

### 8.1 Selectors

```promql
# Basic selector
node_cpu_seconds_total

# With label matchers
node_cpu_seconds_total{cpu="0",mode="idle"}
node_cpu_seconds_total{cpu=~"0|1",mode=~"idle|system"}
node_cpu_seconds_total{mode!="idle"}

# Range vector — last 5 minutes
node_memory_MemAvailable_bytes[5m]

# Offset — compare to 1 week ago
node_memory_MemAvailable_bytes offset 1w
```

### 8.2 Rate and Irate

```promql
# rate() — per-second average over a time window (for counters)
rate(node_cpu_seconds_total{mode="idle"}[5m])

# irate() — instantaneous rate based on last 2 samples
irate(node_cpu_seconds_total{mode="idle"}[5m])

# rate()  → smooth, good for alerting
# irate() → spike-sensitive, good for graphs

# CPU utilization percentage
rate(node_cpu_seconds_total{mode!="idle"}[5m]) * 100

# HTTP requests per second
rate(prometheus_http_requests_total[1m])

# Network bytes per second
rate(node_network_receive_bytes_total[5m])
```

### 8.3 Aggregations

```promql
# sum — sum over all dimensions
sum(rate(node_cpu_seconds_total{mode="idle"}[5m]))

# avg — average across dimensions
avg(rate(node_cpu_seconds_total{mode="idle"}[5m]))

# min / max — extremes
min(node_memory_MemAvailable_bytes)
max(node_memory_MemAvailable_bytes)

# count — count of time series
count(node_cpu_seconds_total)

# topk / bottomk
topk(3, rate(node_network_receive_bytes_total[5m]))
bottomk(3, node_filesystem_free_bytes)

# quantile — approximate quantile
quantile(0.95, rate(http_request_duration_seconds_sum[5m]))

# Group: preserve specific labels
sum by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m]))
avg by (instance, cpu) (rate(node_cpu_seconds_total[5m]))

# Without: exclude labels
sum without (cpu, mode) (rate(node_cpu_seconds_total[5m]))
```

### 8.4 Binary Operators

```promql
# Arithmetic
node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes
node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes

# Memory used percentage
(node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes * 100

# Comparison (result is 0 or 1)
node_load1 > node_load15
node_filesystem_avail_bytes < 1e10
```

### 8.5 Functions

```promql
# increase() — total increase over window (counter)
increase(node_network_receive_bytes_total[1h])

# delta() — difference between first and last value (gauge)
delta(node_memory_MemAvailable_bytes[15m])

# predict_linear() — linear regression prediction
predict_linear(node_filesystem_free_bytes[1h], 3600)

# histogram_quantile() — calculate quantiles from histogram
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))

# time() — current Unix timestamp
time() - node_boot_time_seconds  # System uptime in seconds
```

### 8.6 Recording Rules

```yaml
# /opt/prometheus/rules/recording.yml

groups:
  - name: cpu_recording_rules
    interval: 15s
    rules:
      - record: instance:cpu_utilization:rate5m
        expr: |
          100 - (avg by (instance)
            (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

      - record: instance:memory_utilization:ratio
        expr: |
          (node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes)
          / node_memory_MemTotal_bytes

  - name: disk_recording_rules
    interval: 1m
    rules:
      - record: instance:disk_used:bytes
        expr: |
          node_filesystem_size_bytes{mountpoint!=""}
          - node_filesystem_free_bytes{mountpoint!=""}

      - record: instance:disk_used:percent
        expr: |
          (node_filesystem_size_bytes{mountpoint!=""}
          - node_filesystem_free_bytes{mountpoint!=""})
          / node_filesystem_size_bytes{mountpoint!=""} * 100
```

---

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

## 🔍 Section 10: Grafana

### 10.1 Installation

```bash
sudo apt install -y software-properties-common
sudo add-apt-repository "deb https://packages.grafana.com/oss/deb stable main"
wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -
sudo apt update && sudo apt install grafana -y

sudo systemctl daemon-reload
sudo systemctl start grafana-server
sudo systemctl enable grafana-server

# Access: http://your-server:3000
# Default login: admin / admin
```

### 10.2 Configuration

```ini
# /etc/grafana/grafana.ini

[server]
protocol = http
http_addr =
http_port = 3000
domain = your-server.example.com
root_url = %(protocol)s://%(domain)s:%(http_port)s/

[security]
admin_user = admin
admin_password = admin
secret_key = changeme

[auth.anonymous]
enabled = false

[alerting]
enabled = true
execute_alerts = true
```

### 10.3 Data Sources

```bash
# From the Grafana Web UI:
# Configuration → Data Sources → Add data source

# ── Prometheus ──
# Name:    Prometheus
# Type:    Prometheus
# URL:     http://localhost:9090
# Access:  Server (default)

# ── Zabbix ── (requires alexanderzobnin-zabbix plugin)
# Name:    Zabbix
# Type:    Zabbix
# URL:     http://localhost/api_jsonrpc.php

# ── Loki ──
# Name:    Loki
# Type:    Loki
# URL:     http://localhost:3100

# Install Zabbix plugin
grafana-cli plugins install alexanderzobnin-zabbix-app
sudo systemctl restart grafana-server
```

### 10.4 Dashboard Panels

| Panel Type | Use Case | Example |
|------------|----------|---------|
| **Time Series** | Line charts over time | CPU usage, network traffic |
| **Stat** | Single value display | Current memory usage |
| **Gauge** | Value within a range | Disk usage (0-100%) |
| **Table** | Tabular data | Top processes, host list |
| **Heatmap** | Distribution over time | Request latency distribution |
| **Bar Gauge** | Horizontal/vertical bars | Compare disk usage across hosts |
| **Logs** | Log lines from Loki | Real-time log streaming |
| **State Timeline** | State changes over time | Host up/down timeline |

### 10.5 Building a Dashboard

```bash
cat > dashboard.json << 'EOF'
{
  "dashboard": {
    "title": "Linux Server Overview",
    "tags": ["linux", "production"],
    "timezone": "browser",
    "panels": [
      {
        "title": "CPU Utilization",
        "type": "timeseries",
        "datasource": "Prometheus",
        "gridPos": {"h": 8, "w": 12, "x": 0, "y": 0},
        "targets": [{
          "expr": "100 - (avg by(instance) (rate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100)",
          "legendFormat": "{{instance}}"
        }]
      },
      {
        "title": "Memory Usage",
        "type": "gauge",
        "datasource": "Prometheus",
        "gridPos": {"h": 8, "w": 6, "x": 12, "y": 0},
        "targets": [{
          "expr": "(node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes * 100"
        }],
        "options": {"min": 0, "max": 100, "thresholds": [
          {"value": 80, "color": "orange"},
          {"value": 90, "color": "red"}
        ]}
      },
      {
        "title": "Network Traffic",
        "type": "timeseries",
        "datasource": "Prometheus",
        "gridPos": {"h": 8, "w": 12, "x": 0, "y": 8},
        "targets": [
          {"expr": "rate(node_network_receive_bytes_total[5m])", "legendFormat": "{{instance}} RX"},
          {"expr": "rate(node_network_transmit_bytes_total[5m])", "legendFormat": "{{instance}} TX"}
        ]
      },
      {
        "title": "System Uptime",
        "type": "stat",
        "datasource": "Prometheus",
        "gridPos": {"h": 4, "w": 4, "x": 12, "y": 8},
        "targets": [{"expr": "time() - node_boot_time_seconds", "legendFormat": "uptime"}],
        "options": {"unit": "s"}
      }
    ],
    "refresh": "30s"
  },
  "overwrite": true
}
EOF

# Import via API
curl -X POST -H "Authorization: Bearer $(curl -s -X POST -H \"Content-Type: application/json\" -d '{\"user\":\"admin\",\"password\":\"admin\"}' http://localhost:3000/api/login | jq -r '.accessToken')" http://localhost:3000/api/dashboards/db -d @dashboard.json
```

### 10.6 Grafana Alerting (Unified Alerting)

```yaml
# Grafana unified alerting works across ALL data sources

# Alert rule (via UI):
#   Alerting → Alert rules → New alert rule
#
#   Rule name:   High CPU Usage
#   Query:
#     Data source: Prometheus
#     Query: 100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)
#     Evaluate: every 1m for 5m
#   Condition: WHEN last() OF query(A, 5m, 0) IS ABOVE 90
#   Labels: severity=critical, team=platform
#   Annotations:
#     summary: "CPU usage on {{ $labels.instance }} is {{ $values.A | humanize }}%"
#
#   Notifications:
#     Contact point: email-alert
#     Repeat interval: 4h

# Contact points:
#   Alerting → Contact points → New contact point
#
#   Email:
#     Type: Email | Addresses: admin@example.com
#
#   Slack:
#     Type: Slack | Webhook URL: https://hooks.slack.com/services/...
#     Channel: #alerts
#
#   PagerDuty:
#     Type: PagerDuty | Integration key: xxxxxx
#
#   Webhook:
#     Type: Webhook | URL: https://hooks.example.com/alert
```

---

## 🔍 Section 11: Alerting

### 11.1 Nagios Notifications

```
Event Flow:
  1. Plugin executes → returns CRITICAL (exit code 2)
  2. Nagios updates service status
  3. Nagios checks notification settings:
     - Is notification_enabled=1?
     - Is current time within notification_period?
     - Has notification_interval passed since last notification?
  4. Nagios looks up contact_groups for this service/host
  5. For each contact, checks notification_period and notification_options
  6. Executes contact's notification_command (e.g., notify-service-by-email)
```

### 11.2 Zabbix Actions

```bash
# Email media type
# Administration → Media types → Email
# SMTP server:   smtp.example.com
# SMTP port:     587
# SMTP helo:     example.com
# SMTP email:    zabbix@example.com
# Connection security: STARTTLS

# Slack webhook
# Administration → Media types → Webhook
# Script: /usr/share/zabbix/alertscripts/slack.sh
```

### 11.3 Prometheus Alertmanager

```bash
# Install Alertmanager
wget https://github.com/prometheus/alertmanager/releases/download/v0.27.0/alertmanager-0.27.0.linux-amd64.tar.gz
tar xzf alertmanager-0.27.0.linux-amd64.tar.gz
sudo mv alertmanager-0.27.0.linux-amd64 /opt/alertmanager

sudo useradd --no-create-home --shell /bin/false alertmanager
sudo mkdir -p /var/lib/alertmanager
sudo chown alertmanager:alertmanager /var/lib/alertmanager

sudo tee /etc/systemd/system/alertmanager.service << 'EOF'
[Unit]
Description=Alertmanager
After=network.target

[Service]
User=alertmanager
Group=alertmanager
Type=simple
ExecStart=/opt/alertmanager/alertmanager \
    --config.file=/opt/alertmanager/alertmanager.yml \
    --storage.path=/var/lib/alertmanager/ \
    --web.listen-address=:9093
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload && sudo systemctl start alertmanager
curl http://localhost:9093/-/healthy
```

```yaml
# /opt/alertmanager/alertmanager.yml

global:
  resolve_timeout: 5m
  smtp_smarthost: 'smtp.example.com:587'
  smtp_from: 'alertmanager@example.com'
  smtp_auth_username: 'alertmanager@example.com'
  smtp_auth_password: 'password'
  smtp_require_tls: true

route:
  group_by: ['alertname', 'cluster']
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 4h
  receiver: 'default-receiver'

  routes:
    - match:
        severity: critical
      receiver: 'pagerduty-critical'
      repeat_interval: 10m

    - match:
        severity: warning
      receiver: 'email-warning'

    - match_re:
        service: ^(mysql|postgres|redis)$
      receiver: 'database-team'

inhibit_rules:
  - source_match:
      severity: 'critical'
    target_match:
      severity: 'warning'
    equal: ['alertname', 'cluster', 'instance']

  - source_match:
      alertname: 'InstanceDown'
    target_match_re:
      severity: 'warning|info'
    equal: ['instance']

receivers:
  - name: 'default-receiver'
    email_configs:
      - to: 'admin@example.com'

  - name: 'pagerduty-critical'
    pagerduty_configs:
      - routing_key: 'your-pagerduty-key'
        severity: critical

  - name: 'email-warning'
    email_configs:
      - to: 'team@example.com'
        headers:
          subject: '[WARNING] {{ .GroupLabels.alertname }}'

  - name: 'database-team'
    email_configs:
      - to: 'db-team@example.com'
    slack_configs:
      - api_url: 'https://hooks.slack.com/services/T00/B00/xxxx'
        channel: '#db-alerts'
        title: '{{ .GroupLabels.service }} on {{ .GroupLabels.instance }}'

  - name: 'slack-platform'
    slack_configs:
      - api_url: 'https://hooks.slack.com/services/T00/B00/xxxx'
        channel: '#platform-alerts'
```

### 11.4 Prometheus Alert Rules

```yaml
# /opt/prometheus/alerts/infrastructure.yml

groups:
  - name: infrastructure
    interval: 30s
    rules:
      - alert: InstanceDown
        expr: up == 0
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "Instance {{ $labels.instance }} is down"
          description: "{{ $labels.instance }} has been unreachable for more than 5 minutes."

      - alert: HighCPUUsage
        expr: |
          100 - (avg by(instance)
            (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 90
        for: 10m
        labels:
          severity: critical
        annotations:
          summary: "High CPU usage on {{ $labels.instance }}"
          description: "CPU usage is {{ $value | humanizePercentage }} on {{ $labels.instance }}"

      - alert: HighMemoryUsage
        expr: |
          (node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes)
          / node_memory_MemTotal_bytes * 100 > 90
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "High memory usage on {{ $labels.instance }}"

      - alert: DiskSpaceCritical
        expr: |
          (node_filesystem_size_bytes{mountpoint="/"}
          - node_filesystem_free_bytes{mountpoint="/"})
          / node_filesystem_size_bytes{mountpoint="/"} * 100 > 95
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "Disk space critical on {{ $labels.instance }}"
          description: "Disk usage is {{ $value | humanizePercentage }}"

      - alert: SSLCertificateExpiringSoon
        expr: probe_ssl_earliest_cert_expiry - time() < 86400 * 14
        for: 1h
        labels:
          severity: warning
        annotations:
          summary: "SSL certificate expiring soon for {{ $labels.instance }}"

      - alert: SSLCertificateExpired
        expr: probe_ssl_earliest_cert_expiry - time() < 0
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "SSL certificate expired for {{ $labels.instance }}"
```

---

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

---

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

## 🧠 Deep Understanding

### How Nagios Checks Services (Active Check)

```
1. Nagios scheduler determines it's time to check a service
2. Scheduler spawns a child process (fork)
3. Child process:
   a. Drops privileges to the nagios user
   b. Executes the check_command (e.g., check_ping -H 10.0.0.10 -w 100,20% -c 200,50%)
   c. Capture stdout (plugin output)
   d. Capture exit code (0, 1, 2, or 3)
4. Child process exits, parent (Nagios daemon) reads the result
5. Nagios updates the service status:
   a. Compares new state with previous state
   b. If state changed: log event, trigger notifications, run event handler
   c. Update status file for web UI
6. If check was a "hard" state (after max_check_attempts):
   a. Execute notification commands for contacts
   b. Execute event handler command (if configured)
7. Schedule next check based on check_interval

Key distinction — Hard vs Soft states:
  Soft state:  First 1..(max_check_attempts-1) failures
               Nagios rechecks more frequently (retry_interval)
               No notifications sent yet

  Hard state:  After max_check_attempts consecutive failures
               Nagios switches to normal check_interval
               Notifications ARE sent
               Event handlers run
```

### How Prometheus Pull Model Works

```
1. Prometheus server maintains a list of scrape targets
   (from static_configs, service discovery, file_sd, etc.)

2. For each target, at the configured scrape_interval:
   a. HTTP GET request to http://target:port/metrics
   b. Parse the text-based metrics format:

      # HELP node_cpu_seconds_total Seconds the cpus spent in each mode.
      # TYPE node_cpu_seconds_total counter
      node_cpu_seconds_total{cpu="0",mode="idle"} 12345.67

   c. For each metric line:
      - Parse metric name and labels
      - Parse value (float64)
      - Create a sample: {__name__="node_cpu_seconds_total", ...} @timestamp 12345.67

3. Samples are stored in the TSDB

4. Scrape health is recorded:
   - up{job="node", instance="10.0.0.10:9100"} = 1 (success)
   - scrape_duration_seconds = 0.045

Pull model advantages over push:
  - Easier to detect down targets (up == 0)
  - Single source of truth for scrape schedule
  - Targets don't need to know where Prometheus is
  - Simpler security (server needs access to targets, not vice versa)
  - Better for pull-based service discovery (Kubernetes)
```

### Time-Series Database (Prometheus TSDB) Concepts

```
Prometheus TSDB stores every metric as a time series, identified by:
  Metric name + Labels = unique time series

Example:
  node_cpu_seconds_total{cpu="0", mode="idle", instance="web-01", job="node"}
  ─────────────────────  ────────────────────────────────────────────────
      metric name                     labels (key=value pairs)

Each time series contains:
  ┌─────────────────────────────────────────────────────┐
  │  Time Series (series identifier)                     │
  │  ┌────────────┬────────────────────────────────┐    │
  │  │   Labels    │         Samples                │    │
  │  │            │  (timestamp, value) pairs       │    │
  │  │ cpu="0"    │  (t1, v1), (t2, v2), ...       │    │
  │  │ mode="idle"│                                 │    │
  │  │ instance=..│                                 │    │
  │  └────────────┴────────────────────────────────┘    │
  └─────────────────────────────────────────────────────┘

On-disk storage layout (Prometheus TSDB):

  /var/lib/prometheus/
  ├── wal/                    # Write-Ahead Log (recent data)
  │   ├── 000001              # WAL segment files
  │   ├── 000002
  │   └── ...
  ├── chunks_head/            # In-memory chunks being written
  └── 01ABCDEFGHIJ/           # Block directory (2-hour blocks)
      ├── meta.json           # Block metadata (min/max time, stats)
      ├── index               # Inverted index (label → series mapping)
      ├── chunks/             # Compressed sample data
      │   ├── 000001
      │   └── ...
      ├── tombstones          # Deleted series markers
      └── chunks_head/

Block lifecycle:
  1. Data accumulates in memory (2 hours worth)
  2. After 2 hours, the in-memory block is "compacted" to disk
  3. Smaller blocks are periodically merged into larger blocks
     (2h → 10h → 1d → ... up to retention time)
  4. Each compaction reduces size by:
     - Removing deleted series
     - Combining overlapping chunks
     - Applying compression (XOR for floats, delta-of-delta for timestamps)

Compression algorithm:
  Timestamps: delta-of-delta encoding (average 0.64 bytes per sample)
  Values:     XOR with previous value
  Result:     ~1.3 bytes per sample average

Retention:
  Default: 15 days
  Data is deleted by dropping entire blocks when they exceed retention time
```

### How Alertmanager Handles Grouping and Deduplication

```
1. Prometheus sends alerts to Alertmanager via HTTP API:
   POST http://alertmanager:9093/api/v2/alerts

   Alert payload:
   {
     "labels": {
       "alertname": "InstanceDown",
       "instance": "web-01",
       "severity": "critical"
     },
     "annotations": {
       "summary": "Instance web-01 is down"
     },
     "startsAt": "2026-06-24T14:30:00Z"
   }

2. Alertmanager pipeline:

   ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐
   │  Ingest  │───►│  Inhibit │───►│  Silence │───►│  Group   │───► Send
   │ (receive)│    │ (suppress)│   │ (mute)   │    │ (dedup)  │
   └──────────┘    └──────────┘    └──────────┘    └──────────┘

3. Inhibition:
   - Check all active inhibition rules
   - If SOURCE alert matches (e.g., severity=critical InstanceDown)
   - Suppress TARGET alerts (e.g., severity=warning on same instance)
   - Prevents cascading noise

4. Silencing:
   - Check if alert matches any active silence
   - Silences created manually (maintenance) or via API

5. Grouping:
   - Key defined by route.group_by (e.g., ["alertname"])
   - Alerts with same key collected into a group
   - One notification per group instead of per alert
   - Example: 10 down servers = 1 notification with 10 entries

6. Timer logic:
   group_wait:     30s    # Wait for more alerts before 1st notification
   group_interval: 5m     # Wait before sending updates to same group
   repeat_interval: 4h    # Re-send if nothing changed (reminder)

7. Deduplication:
   - If same alert arrives multiple times, only latest state matters
   - Alert identity = (labels + generatorURL)
   - Resolved alerts removed from active groups

8. Output:
   - For each group, execute the route's receiver
   - Template the message using alert data
```

---

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

## 🔮 What's Coming in Part 47

**Part 47: Performance Tuning and Optimization** — We optimize Linux systems for maximum performance. Topics include:

- **Kernel tuning** — sysctl parameters, scheduler tuning, I/O schedulers
- **CPU performance** — governor scaling, process affinity (taskset), cgroups CPU shares
- **Memory optimization** — HugePages, swappiness, OOM killer tuning, NUMA awareness
- **Disk I/O tuning** — elevator algorithms, block device queue depth, filesystem mount options (noatime, nobarrier)
- **Network optimization** — TCP buffer tuning, ring buffer sizes, RPS/RFS, XDP
- **Profiling tools** — perf, flamegraphs, strace, ltrace, bpftrace
- **Benchmarking** — sysbench, fio, iperf3, stress-ng, unixbench
- **Capacity planning** — resource trend analysis, headroom calculation, scaling strategies

---

## ✅ Self-Test

Answer these 15 questions. **Score:** 12/15 correct = ready for Part 47.

### Question 1
Which Nagios plugin return code indicates a critical failure?
```
A) 0
B) 1
C) 2
D) 3
```

### Question 2
What is the primary difference between Nagios NRPE and Prometheus node_exporter?
```
A) NRPE uses push; node_exporter uses pull
B) NRPE uses pull; node_exporter uses push
C) NRPE is for databases; node_exporter is for web servers
D) They are identical in architecture
```

### Question 3
In Prometheus, which metric type is used for request latency percentiles?
```
A) Counter
B) Gauge
C) Histogram
D) Timer
```

### Question 4
What does the `rate()` function do in PromQL?
```
A) Calculates the instantaneous value of a gauge
B) Calculates the per-second average rate of increase of a counter
C) Calculates the total number of samples in a time range
D) Calculates the maximum value over a time range
```

### Question 5
Which Zabbix component reduces load on the central server for remote site monitoring?
```
A) Zabbix agent
B) Zabbix proxy
C) Zabbix frontend
D) Zabbix template
```

### Question 6
In Alertmanager, what is the purpose of `group_wait`?
```
A) How long to wait before sending the first notification for a new group
B) How long to wait before sending repeated notifications
C) How long to wait for a target to come back online
D) How long to wait before marking an alert as resolved
```

### Question 7
Which Grafana panel type is best for displaying a single metric value like "current disk usage"?
```
A) Time series
B) Table
C) Stat
D) Heatmap
```

### Question 8
What is the purpose of the Prometheus textfile collector?
```
A) To collect text files from remote servers
B) To expose custom metrics from scripts/cron jobs via node_exporter
C) To read configuration from text files
D) To store Prometheus configuration in a text file
```

### Question 9
In Zabbix, what is a "trigger"?
```
A) A command that runs on the agent
B) A condition that generates an event when met
C) A notification method
D) A type of media
```

### Question 10
What does the `up` metric represent in Prometheus?
```
A) System uptime in seconds
B) Whether the last scrape of a target was successful (1) or not (0)
C) The version of the Prometheus server
D) The number of CPU cores available
```

### Question 11
How does Loki differ from Elasticsearch in log storage?
```
A) Loki indexes only labels/metadata, not full-text content
B) Loki requires more disk space
C) Loki does not support queries
D) Loki cannot receive logs from agents
```

### Question 12
What is the purpose of `inhibit_rules` in Alertmanager?
```
A) To prevent certain receivers from triggering
B) To suppress less important alerts when critical ones fire
C) To block all alerts during maintenance
D) To prevent duplicate alerts from entering the pipeline
```

### Question 13
In Nagios, what distinguishes a "hard" state from a "soft" state?
```
A) Soft states send notifications; hard states do not
B) Hard states occur after max_check_attempts failures; notifications are sent
C) Hard states only occur for hosts, not services
D) Soft states are permanent; hard states are temporary
```

### Question 14
Which Prometheus exporter would you use to monitor whether an external website returns HTTP 200?
```
A) node_exporter
B) blackbox_exporter
C) mysqld_exporter
D) nginx_exporter
```

### Question 15
What is the default Prometheus data retention period?
```
A) 7 days
B) 15 days
C) 30 days
D) 90 days
```

---

**Score:** 12/15 correct = ready for Part 47.

**Answers:** 1-C, 2-A, 3-C, 4-B, 5-B, 6-A, 7-C, 8-B, 9-B, 10-B, 11-A, 12-B, 13-B, 14-B, 15-B

---

*Previous → Part 45: Proxy and Reverse Proxy — Squid, Nginx, HAProxy*
*Next → Part 47: Performance Tuning and Optimization*

[← Previous](part45.md) | [Next →](part47.md)
