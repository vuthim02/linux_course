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



---

[← Previous](05-section-3-nagios-plugins.md) | [↑ Index](index.md) | [Next →](07-section-5-zabbix.md)
