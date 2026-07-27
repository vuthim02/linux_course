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



---

[← Previous](03-section-1-monitoring-philosophy.md) | [↑ Index](index.md) | [Next →](05-section-3-nagios-plugins.md)
