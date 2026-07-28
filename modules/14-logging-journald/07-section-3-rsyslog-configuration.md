## 🔍 Section 3: rsyslog Configuration

rsyslog is the workhorse that writes traditional log files.

### Main Configuration

```bash
cat /etc/rsyslog.conf
```

```
#################
# MODULES        #
#################
module(load="imuxsock")    # Local system logging
module(load="imklog")      # Kernel logging
module(load="imjournal")   # Read from journald

###############
# RULES        #
###############
# Format: facility.severity  destination

auth,authpriv.*         /var/log/auth.log
*.*;auth,authpriv.none  -/var/log/syslog
cron.*                  /var/log/cron.log
daemon.*                -/var/log/daemon.log
kern.*                  -/var/log/kern.log
mail.*                  -/var/log/mail.log
user.*                  -/var/log/user.log
```

### Rule Syntax

```
facility.severity     action

Examples:
*.info                /var/log/messages     # All info and above
mail.*                /var/log/maillog      # All mail messages
auth.*                /var/log/authlog      # All auth messages
*.err                 /var/log/errorlog     # All errors
cron.*                @logserver:514        # Forward cron logs to central server
```

### Rule Selectors

```bash
# Single facility
auth.*                    # All auth messages

# Multiple facilities
auth,mail.*               # All auth AND mail messages

# Exclude
*.*;auth.none             # Everything EXCEPT auth

# Severity and above
*.err                     # err and above (err, crit, alert, emerg)
*.=err                    # EXACTLY err (not crit, alert, emerg)

# Multiple selectors (OR)
kern.info;kern.!err       # kern info and above, but NOT err
```

### Configuration Files in rsyslog.d

```bash
# Additional config files
ls /etc/rsyslog.d/

# Example: 50-default.conf
cat /etc/rsyslog.d/50-default.conf
```

### Testing rsyslog Configuration

```bash
# Test the config for syntax errors
sudo rsyslogd -N1

# Restart after changes
sudo systemctl restart rsyslog
```





[← Previous](06-level-2-intermediary-configuration-and.md) | [↑ Index](index.md) | [Next →](08-section-5-journald-deep-dive.md)
