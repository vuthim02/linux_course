## 📋 Summary — Complete Command Reference for Part 13

### Level 1: Basic Commands — cron

| Command | Action |
|---------|--------|
| `crontab -e` | Edit crontab |
| `crontab -l` | List crontab entries |
| `crontab -r` | Remove crontab |
| `crontab -u USER -l` | List another user's crontab (root) |
| `systemctl status cron` | Check if cron is running |
| `journalctl -u cron` | View cron logs |
| `grep CRON /var/log/syslog` | View cron syslog entries |

**Crontab Fields**

```
Field        Value Range
minute       0-59
hour         0-23
day          1-31
month        1-12
weekday      0-7 (0=Sunday, 7=Sunday)
```

**Special @-Times**

| Keyword | Equivalent |
|---------|-----------|
| `@reboot` | Run once at boot |
| `@daily` | `0 0 * * *` |
| `@weekly` | `0 0 * * 0` |
| `@monthly` | `0 0 1 * *` |
| `@hourly` | `0 * * * *` |
| `@yearly` | `0 0 1 1 *` |

### Level 2: Intermediary Commands — at and systemd timers

**at**

| Command | Action |
|---------|--------|
| `at TIME` | Schedule a command |
| `atq` | List pending jobs |
| `atrm ID` | Remove a job |
| `at -c ID` | Show job contents |
| `batch` | Run when load is low |

**Systemd Timers**

| Command | Action |
|---------|--------|
| `systemctl list-timers` | List active timers |
| `systemctl start NAME.timer` | Start a timer |
| `systemctl enable NAME.timer` | Enable timer at boot |
| `systemctl status NAME.timer` | Show timer status |

### Level 3: Advanced Commands (No additional commands — see scheduling patterns and deep understanding sections above)





[← Previous](15-practice-section-15-hands-on-exercises.md) | [↑ Index](index.md) | [Next →](17-whats-coming-in-part-14.md)
