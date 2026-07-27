## 📋 Summary — Complete Command Reference for Part 14

### Level 1: Basic Commands — journalctl and Log Files

**journalctl**

| Command | Action |
|---------|--------|
| `journalctl` | All logs (current boot) |
| `journalctl -b` | Current boot |
| `journalctl -b -1` | Previous boot |
| `journalctl --list-boots` | List all boots |
| `journalctl -u NAME` | Specific service |
| `journalctl -f` | Follow (tail -f) |
| `journalctl -n N` | Last N lines |
| `journalctl --since TIME` | Filter by start time |
| `journalctl --until TIME` | Filter by end time |
| `journalctl -p PRIORITY` | Filter by priority |
| `journalctl -k` | Kernel messages |
| `journalctl --disk-usage` | Show disk usage |
| `journalctl --verify` | Verify journal integrity |

**Log Files**

| File | Purpose |
|------|---------|
| `/var/log/syslog` | General system log |
| `/var/log/auth.log` | Authentication log |
| `/var/log/kern.log` | Kernel log |
| `/var/log/dmesg` | Kernel ring buffer |

### Level 2: Intermediary Commands — rsyslog and logrotate

**rsyslog**

| Command | Action |
|---------|--------|
| `cat /etc/rsyslog.conf` | View configuration |
| `sudo systemctl restart rsyslog` | Restart rsyslog |
| `sudo rsyslogd -N1` | Test config syntax |

**logrotate**

| Command | Action |
|---------|--------|
| `cat /etc/logrotate.conf` | View global config |
| `ls /etc/logrotate.d/` | List per-service configs |
| `sudo logrotate -d FILE` | Dry run |
| `sudo logrotate -f FILE` | Force rotation |

### Level 3: Advanced Commands (See troubleshooting and centralized logging sections above — no additional commands)

---



---

[← Previous](15-practice-section-15-hands-on-exercises.md) | [↑ Index](index.md) | [Next →](17-whats-coming-in-part-15.md)
