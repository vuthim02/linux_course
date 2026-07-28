## 14. Log-Based Monitoring

### `tail` and `multitail`

```
$ tail -f /var/log/syslog
$ tail -f /var/log/syslog | grep -i error
$ sudo multitail /var/log/syslog /var/log/auth.log
$ sudo multitail -s 2 /var/log/syslog /var/log/kern.log
```

### `logwatch` — Daily Report Generator

```
$ sudo logwatch --detail high --range today --service sshd --service auth
$ sudo logwatch --detail high --range "between -7 days and today" --service all
```

### `lnav` — The Log File Navigator

```
$ lnav /var/log/syslog /var/log/kern.log
```

Features: automatic log format detection, colorized output, timeline view, SQL-based querying.

```
; SELECT COUNT(*) FROM syslog WHERE loglevel = 'error' GROUP BY date_logged
; SELECT * FROM syslog WHERE regexp(message, 'OOM|out of memory')
```

### `journalctl` — systemd's Log Manager

```
$ journalctl -xe                     # Current boot, explanation
$ journalctl -f                      # Follow mode
$ journalctl -u nginx.service        # Specific unit
$ journalctl -p err                  # Priority=error and above
$ journalctl --since "1 hour ago"    # Time range
$ journalctl -k -f                   # Kernel messages, follow
$ journalctl -o json-pretty          # JSON output for parsing
```





[← Previous](15-11-glances-python-power-monitor.md) | [↑ Index](index.md) | [Next →](17-15-ncdu-ncurses-disk-usage.md)
