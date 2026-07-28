## 🔍 Section 1: The Linux Logging Architecture

Linux has two parallel logging systems:

```
Application (nginx, sshd, mysql...)
    │
    ├──→ systemd-journald (binary, structured, default)
    │       │
    │       ├──→ /run/log/journal/  (volatile, in memory)
    │       └──→ /var/log/journal/  (persistent, on disk)
    │
    └──→ rsyslog (traditional, text-based)
            │
            ├──→ /var/log/syslog     (everything)
            ├──→ /var/log/auth.log   (authentication)
            ├──→ /var/log/kern.log   (kernel messages)
            └──→ /var/log/mail.log   (mail server)
```

### Why Two Systems?

| Aspect | journald | rsyslog |
|--------|----------|---------|
| Format | Binary (structured) | Plain text |
| Storage | Default: memory, Optional: disk | Files on disk |
| Query speed | Very fast (indexed) | grep-based (slower) |
| Field structure | Yes (100+ fields) | No (text only) |
| Reliability | Tamper-evident (signed) | Standard text files |
| Network forwarding | Limited | Primary use case |

In modern Linux, both work together:
1. journald captures everything first
2. rsyslog reads from journald and writes traditional files
3. Most tools still read from `/var/log/` files





[← Previous](02-level-1-basic-logging-architecture.md) | [↑ Index](index.md) | [Next →](04-section-2-the-syslog-protocol.md)
