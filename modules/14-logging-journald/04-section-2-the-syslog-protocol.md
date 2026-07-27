## 🔍 Section 2: The syslog Protocol

Syslog is the standard for log messages. Every log line has a standard format.

### Syslog Facility and Severity

Each message has a **facility** (what generated it) and a **severity** (how serious).

**Facilities:**

| Code | Keyword | Description |
|------|---------|-------------|
| 0 | kern | Kernel messages |
| 1 | user | User-level messages |
| 2 | mail | Mail system |
| 3 | daemon | System daemons |
| 4 | auth | Authentication (login, su) |
| 5 | syslog | Syslogd itself |
| 6 | lpr | Line printer subsystem |
| 7 | news | Network news subsystem |
| 8 | uucp | UUCP subsystem |
| 9 | cron | Clock daemon (cron/at) |
| 10 | authpriv | Security/authorization |
| 11 | ftp | FTP daemon |
| 16-23 | local0-local7 | Locally defined |

**Severities:**

| Code | Severity | Description |
|------|----------|-------------|
| 0 | emerg | System is unusable |
| 1 | alert | Action must be taken immediately |
| 2 | crit | Critical conditions |
| 3 | err | Error conditions |
| 4 | warning | Warning conditions |
| 5 | notice | Normal but significant |
| 6 | info | Informational |
| 7 | debug | Debug-level messages |

### Standard Log Format

```
Jan 15 10:30:45 server sshd[12345]: Failed password for root from 192.168.1.100 port 22 ssh2
└─────┬────┘ └──┬┘ └──┬┘ └───┬──┘ └─────────────────────────┬────────────────────────┘
 timestamp    host   prog[PID]           message
```

---



---

[← Previous](03-section-1-the-linux-logging.md) | [↑ Index](index.md) | [Next →](05-section-4-key-log-files.md)
