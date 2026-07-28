## 🔍 Section 4: Key Log Files and What They Contain

### Essential Log Files

| File | Purpose |
|------|---------|
| `/var/log/syslog` | Everything (general system log) |
| `/var/log/auth.log` | Authentication (logins, sudo) |
| `/var/log/kern.log` | Kernel messages |
| `/var/log/dmesg` | Kernel ring buffer (boot messages) |
| `/var/log/boot.log` | System startup messages |
| `/var/log/cron.log` | cron job execution |
| `/var/log/mail.log` | Mail server (postfix, sendmail) |
| `/var/log/apache2/access.log` | Apache web requests |
| `/var/log/apache2/error.log` | Apache errors |
| `/var/log/nginx/access.log` | Nginx web requests |
| `/var/log/nginx/error.log` | Nginx errors |
| `/var/log/mysql/error.log` | MySQL/MariaDB errors |
| `/var/log/faillog` | Failed login attempts |
| `/var/log/lastlog` | Last login for each user |
| `/var/log/wtmp` | Login records (binary) |
| `/var/log/btmp` | Bad login attempts (binary) |

### Reading Binary Logs

```bash
# wtmp, btmp, lastlog are binary — use special commands
last              # Shows logins (reads /var/log/wtmp)
lastb             # Shows failed logins (reads /var/log/btmp)
lastlog           # Shows last login for each user
```





[← Previous](04-section-2-the-syslog-protocol.md) | [↑ Index](index.md) | [Next →](06-level-2-intermediary-configuration-and.md)
