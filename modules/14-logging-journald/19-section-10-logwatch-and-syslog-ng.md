## Section 10: logwatch and syslog-ng

### logwatch — Automatic Log Summarization

```bash
# Install
sudo apt install logwatch       # Debian/Ubuntu
sudo dnf install logwatch        # Fedora/RHEL

# Run (daily summary)
sudo logwatch --output stdout --format text --range yesterday

# Config: /etc/logwatch/conf/logwatch.conf
# Services monitored: /usr/share/logwatch/scripts/services/
```

### syslog-ng — Modern syslog Daemon (Alternative to rsyslog)

```bash
# Install
sudo apt install syslog-ng      # Debian/Ubuntu
sudo dnf install syslog-ng       # Fedora/RHEL

# Config: /etc/syslog-ng/syslog-ng.conf
# Example — log to file:
# destination d_auth { file("/var/log/auth.log"); };
# filter f_auth { facility(authpriv); };
# log { source(s_sys); filter(f_auth); destination(d_auth); };

# Reload config
sudo syslog-ng-ctl reload
```


[← Previous](18-self-test-can-you-answer-these.md) | [↑ Index](index.md) | [Next →](21-section-11-logger-and-systemd-cat.md)
