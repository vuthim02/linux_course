## 14. 15 Hands-On Practices

### Level 1 Practices: Basic Scripting

#### Practice 1: System Info Script

Write a script that displays hostname, OS version, kernel, uptime, CPU load, memory usage, disk usage:

```bash
#!/bin/bash
# system_info.sh

echo "=== System Information ==="
echo "Hostname: $(hostname)"
echo "OS: $(lsb_release -ds 2>/dev/null || cat /etc/os-release 2>/dev/null | head -1)"
echo "Kernel: $(uname -r)"
echo "Uptime: $(uptime -p)"
echo "CPU Load: $(uptime | awk -F'load average:' '{print $2}')"
echo "Memory: $(free -h | awk '/^Mem:/ {print $3 "/" $2}')"
```

#### Practice 2: Log Analyzer

```bash
#!/bin/bash
# log_analyzer.sh — Analyze access logs

LOG_FILE="${1:-/var/log/nginx/access.log}"

[ -f "$LOG_FILE" ] || { echo "File not found: $LOG_FILE"; exit 1; }

echo "=== Log Analysis: $LOG_FILE ==="
echo
echo "Top 10 IPs:"
awk '{print $1}' "$LOG_FILE" | sort | uniq -c | sort -rn | head -10
echo
echo "Top 10 URLs:"
awk '{print $7}' "$LOG_FILE" | sort | uniq -c | sort -rn | head -10
echo
echo "HTTP Status Codes:"
awk '{print $9}' "$LOG_FILE" | sort | uniq -c | sort -rn
```

### Level 2 Practices: Intermediary Scripting

#### Practice 3: Backup Script with Rotation

Extend the backup example:
- Accept multiple source directories
- Compress with `pigz` (parallel gzip) if available
- Encrypt backups with GPG
- Email success/failure report
- Verify backup integrity after creation

#### Practice 4: User Creation with Error Handling

Build on the user creation example:
- Accept JSON input instead of CSV
- Send welcome email to new users
- Generate SSH keys for each user
- Create home directory skeleton structure
- Log all actions to syslog

#### Practice 5: Monitoring Dashboard

Create a real-time terminal dashboard:
- Use `watch` or a `while` loop with `clear`
- Display: uptime, CPU, memory, disk, network, top processes
- Color-code warnings (green/yellow/red)
- Refresh every 2 seconds

#### Practice 6: Service Restart Wrapper

```bash
#!/bin/bash
# safe_restart.sh — Safe service restart with rollback

SERVICE="$1"
MAX_RETRIES=3
HEALTH_CHECK_URL="http://localhost:8080/health"

restart_service() {
    echo "Restarting $SERVICE..."
    systemctl stop "$SERVICE"
    sleep 2
    systemctl start "$SERVICE"
}

check_health() {
    for i in $(seq 1 10); do
        if curl -sf "$HEALTH_CHECK_URL" &>/dev/null; then
            echo "Service is healthy"
            return 0
        fi
        sleep 2
    done
    return 1
}

for attempt in $(seq 1 "$MAX_RETRIES"); do
    restart_service
    if check_health; then
        echo "Restart successful"
        exit 0
    fi
done

echo "All attempts failed — rolling back"
systemctl start "$SERVICE" || true
exit 1
```

#### Practice 7: Disk Space Alert

```bash
#!/bin/bash
# disk_alert.sh — Disk space monitoring with alerting

THRESHOLD=80
ALERT_EMAIL="admin@example.com"

df -h --exclude-type=tmpfs --exclude-type=devtmpfs | tail -n +2 | while read line; do
    pct=$(echo "$line" | awk '{print $5}' | tr -d '%')
    mount=$(echo "$line" | awk '{print $6}')
    if [ "$pct" -ge "$THRESHOLD" ]; then
        echo "WARNING: $mount at ${pct}%"
    fi
done
```

#### Practice 8: Permission Audit

```bash
#!/bin/bash
# permission_audit.sh — Find security issues

SCAN_DIR="${1:-/home}"
REPORT_FILE="/tmp/perm_audit_$(date +%Y%m%d).txt"

echo "Permission Audit — $(date)" > "$REPORT_FILE"

# World-writable files
find "$SCAN_DIR" -type f -perm -o+w -ls 2>/dev/null >> "$REPORT_FILE"

# SUID/SGID files
find "$SCAN_DIR" -type f \( -perm -4000 -o -perm -2000 \) -ls 2>/dev/null >> "$REPORT_FILE"

# Files with no owner
find "$SCAN_DIR" -nouser -o -nogroup -ls 2>/dev/null >> "$REPORT_FILE"

echo "Report saved to $REPORT_FILE"
```

#### Practice 9: Network Connectivity Checker

```bash
#!/bin/bash
# netcheck.sh — Network connectivity diagnostics

HOSTS=("google.com" "github.com" "8.8.8.8")

for host in "${HOSTS[@]}"; do
    if ping -c2 -W2 "$host" &>/dev/null; then
        echo "OK: $host ($(dig +short "$host" | head -1))"
    else
        echo "FAIL: $host"
    fi
done
```

#### Practice 10: Package Auditor

```bash
#!/bin/bash
# pkg_audit.sh — Audit installed packages

if command -v dpkg &>/dev/null; then
    echo "Total packages: $(dpkg -l | wc -l)"
    echo "Manually installed: $(apt-mark showmanual | wc -l)"
    echo "Updatable: $(apt list --upgradable 2>/dev/null | grep -c upgradable)"
elif command -v rpm &>/dev/null; then
    echo "Total packages: $(rpm -qa | wc -l)"
fi
```

#### Practice 11: Cron Job Manager

```bash
#!/bin/bash
# cronman.sh — Manage system cron jobs

list_jobs() {
    echo "=== System crontab ==="
    [ -f /etc/crontab ] && cat /etc/crontab

    for dir in /etc/cron.hourly /etc/cron.daily /etc/cron.weekly /etc/cron.monthly; do
        echo "=== $dir ==="
        [ -d "$dir" ] && ls -la "$dir"
    done
}

case "${1:-list}" in
    list) list_jobs ;;
    *) echo "Usage: $0 {list}" ;;
esac
```

#### Practice 12: System Cleanup Script

```bash
#!/bin/bash
# cleanup.sh — System maintenance cleanup

log() { echo "[$(date '+%H:%M:%S')] $1"; }

DRY_RUN=false
[ "${1:-}" = "--dry-run" ] && DRY_RUN=true

clean_journal() {
    log "Cleaning journals older than 7 days..."
    [ "$DRY_RUN" = false ] && journalctl --vacuum-time=7d 2>/dev/null || true
}

clean_apt() {
    if command -v apt-get &>/dev/null; then
        log "Cleaning apt cache..."
        [ "$DRY_RUN" = false ] && { apt-get clean; apt-get autoclean; apt-get autoremove --purge -y; }
    fi
}

clean_logs() {
    log "Truncating old log files..."
    [ "$DRY_RUN" = false ] && find /var/log -name "*.log" -type f -size +100M -exec truncate -s 0 {} \;
}

echo "=== System Cleanup $(date) ==="
clean_journal
clean_apt
clean_logs
log "Cleanup complete"
```

### Level 3 Practices: Advanced Scripting

#### Practice 13: Configuration Backup Script

Back up all configs from `/etc/`:
- Only changed files (compare with package manager checksums)
- Version-controlled backup (git init in backup dir)
- Include installed packages list
- Include cron jobs, systemd unit files
- Restore function

#### Practice 14: Mail Queue Monitor

```bash
#!/bin/bash
# mailq_monitor.sh — Monitor mail queue

ALERT_THRESHOLD=100
ALERT_EMAIL="postmaster@example.com"

check_mailq() {
    if command -v mailq &>/dev/null; then
        local count
        count=$(mailq 2>/dev/null | tail -1 | awk '{print $5}')
        [ -z "$count" ] && count=0

        echo "Mail queue: $count messages"

        if [ "$count" -ge "$ALERT_THRESHOLD" ]; then
            echo "ALERT: Queue at ${count} (threshold: ${ALERT_THRESHOLD})"
            mailq | mail -s "ALERT: High mail queue (${count}) on $(hostname)" "$ALERT_EMAIL"
        fi
    fi
}

check_mailq
```

#### Practice 15: Real-World Integration — Complete Admin Toolkit

```bash
#!/bin/bash
# sysadmin.sh — Complete System Administration Toolkit
# Usage: sysadmin.sh [command] [options]

set -euo pipefail

VERSION="1.0.0"
CONFIG_DIR="${HOME}/.sysadmin"
LOG_FILE="${CONFIG_DIR}/sysadmin.log"

mkdir -p "$CONFIG_DIR"

log() {
    local level="$1"
    local msg="$2"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[${timestamp}] [${level}] ${msg}" | tee -a "$LOG_FILE"
}

info()  { log "INFO" "$1"; }
warn()  { log "WARN" "$1"; }
error() { log "ERROR" "$1" >&2; }

cmd_sysinfo() {
    echo "=========================================="
    echo " System Information — $(hostname)"
    echo "=========================================="
    echo "OS:    $(lsb_release -ds 2>/dev/null || cat /etc/os-release 2>/dev/null | grep -m1 PRETTY_NAME | cut -d= -f2- | tr -d '\"')"
    echo "Kernel: $(uname -r)"
    echo "Uptime: $(uptime -p)"
    echo "CPU:   $(nproc) cores, Load: $(uptime | awk -F'load average:' '{print $2}')"
    echo "Memory: $(free -h | awk '/^Mem:/ {print $3 "/" $2}')"
    echo "Disk:  $(df -h / | awk 'NR==2 {print $3 "/" $2 " (" $5 ")"}')"
}

cmd_backup() {
    local source="${1:?backup: source directory required}"
    local dest="${2:-/var/backups}"
    local name="backup_$(basename "$source")_$(date +%Y%m%d_%H%M%S).tar.gz"
    [ ! -d "$source" ] && { error "Source not found: $source"; return 1; }
    mkdir -p "$dest"
    tar -czf "${dest}/${name}" -C "$(dirname "$source")" "$(basename "$source")"
    info "Backup complete: ${dest}/${name}"
}

cmd_health() {
    echo "=== Health Check: $(hostname) ==="
    local load cores pct
    load=$(awk '{print $1}' /proc/loadavg)
    cores=$(nproc)
    pct=$(echo "$load $cores" | awk '{printf "%.0f", ($1/$2)*100}')
    [ "$pct" -gt 80 ] && warn "CPU: ${pct}% load" || info "CPU: ${pct}% load"
}

cmd_network() {
    echo "=== Network Diagnostics ==="
    echo "Interfaces:"
    ip -br addr show 2>/dev/null | grep -v lo
    echo "Default route:"
    ip route show default 2>/dev/null
    echo "Connectivity:"
    for host in google.com 8.8.8.8; do
        ping -c1 -W2 "$host" &>/dev/null && echo "  ✓ $host reachable" || echo "  ✗ $host unreachable"
    done
}

usage() {
    cat <<EOF
sysadmin.sh v${VERSION} — System Administration Toolkit
Usage: $0 <command> [options]
Commands:
    sysinfo              System information report
    backup <src> [dest]  Backup a directory
    health               System health check
    network              Network diagnostics
    help                 Show this help
EOF
}

cmd="${1:-help}"
shift 2>/dev/null || true

case "$cmd" in
    sysinfo|health|network) "cmd_${cmd}" "$@" ;;
    backup) cmd_backup "$@" ;;
    help|--help|-h) usage ;;
    *) error "Unknown command: $cmd"; usage; exit 1 ;;
esac
```





[← Previous](20-16-command-reference.md) | [↑ Index](index.md) | [Next →](22-17-self-test.md)
