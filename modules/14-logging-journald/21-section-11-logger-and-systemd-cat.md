## 🔍 Section 11: logger and systemd-cat — Sending Log Messages

### logger — Write to syslog from Scripts

```bash
# Basic usage
logger "Backup completed successfully"

# With tag (identifies the source)
logger -t myapp "User bob logged in"

# With facility and priority
logger -p auth.info "SSH login from 10.0.0.5"
logger -p local0.err "Disk failure detected"

# Log to stderr too
logger -s -t myapp "Message on console and syslog"

# Include PID
logger -t myapp[$$] "Processing job $JOB_ID"

# Read message from file
logger -f /tmp/message.txt

# Send to remote syslog (bypass local config)
logger -n logserver.example.com -P 514 "Remote log test"
```

### Structured Logging with logger

```bash
# Send structured journal fields (systemd systems)
logger --journald <<'EOF'
MESSAGE=User password changed
PRIORITY=4
SYSLOG_FACILITY=4
MYAPP_USER=bob
MYAPP_ACTION=password_change
EOF

# Then query with:
journalctl MESSAGE="User password changed"
journalctl --output=verbose | grep MYAPP_
```

### systemd-cat — Pipe Output to journald

```bash
# Run any command and capture its output in the journal
systemd-cat echo "Hello from systemd-cat"

# With identifier
systemd-cat -t myapp /usr/local/bin/backup.sh

# With priority
systemd-cat -p err /usr/local/bin/check.sh

# Capture stdout and stderr separately
systemd-cat -t builder -p info ./build.sh
# Stdout → priority 6 (info), stderr → priority 3 (err)

# Combine with journalctl filtering
journalctl -t myapp --since "1 hour ago"
```

### Practical Patterns

```bash
# Pattern 1: Log script progress with timestamps
#!/bin/bash
log() {
    logger -t myapp "$(date '+%Y-%m-%d %H:%M:%S') $*"
}
log "Starting backup"
log "Backup complete"

# Pattern 2: Capture command output to journal
*/5 * * * * /usr/bin/systemd-cat -t healthcheck /usr/local/bin/check.sh

# Pattern 3: Alert on failure
if ! /usr/local/bin/backup.sh; then
    logger -p daemon.err -t backup "Backup FAILED with exit code $?"
    mail -s "Backup Failed" admin@example.com
fi

# Pattern 4: Monitor systemd-cat output
journalctl -t healthcheck -f
```

### Comparison

| Tool | Best For |
|------|----------|
| `logger` | Scripts, one-off messages, structured fields |
| `systemd-cat` | Wrapping commands, capturing all output |
| `echo > /dev/kmsg` | Kernel messages (rarely needed) |
| Direct `journalctl` | System services (already logged by systemd) |



[← Previous](19-section-10-logwatch-and-syslog-ng.md) | [↑ Index](index.md) | [Next →](22-section-12-auditd-linux-audit-framework.md)
