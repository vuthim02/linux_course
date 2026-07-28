## 13. Real Admin Script Examples

### Example 1: Backup Script

```bash
#!/bin/bash
set -euo pipefail

# backup.sh — Full backup with rotation

SOURCE_DIR="${1:?Error: Source directory required}"
BACKUP_DIR="${2:-/var/backups}"
RETENTION_DAYS=30
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
BACKUP_NAME="backup_$(basename "$SOURCE_DIR")_${TIMESTAMP}.tar.gz"
BACKUP_PATH="${BACKUP_DIR}/${BACKUP_NAME}"
LOG_FILE="${BACKUP_DIR}/backup.log"

log() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] $1"
    echo "$msg" | tee -a "$LOG_FILE"
}

cleanup() {
    log "Cleaning up..."
}

error_handler() {
    log "ERROR on line $1: $2"
    cleanup
    exit 1
}

trap cleanup EXIT
trap 'error_handler $LINENO "$BASH_COMMAND"' ERR

[ -d "$SOURCE_DIR" ] || { log "Source $SOURCE_DIR not a directory"; exit 1; }
[ -d "$BACKUP_DIR" ] || mkdir -p "$BACKUP_DIR"

log "Starting backup of $SOURCE_DIR"

tar -czf "$BACKUP_PATH" -C "$(dirname "$SOURCE_DIR")" "$(basename "$SOURCE_DIR")"
log "Created: $BACKUP_PATH ($(du -h "$BACKUP_PATH" | cut -f1))"

log "Removing backups older than ${RETENTION_DAYS} days"
find "$BACKUP_DIR" -name "backup_$(basename "$SOURCE_DIR")_*.tar.gz" \
    -type f -mtime "+${RETENTION_DAYS}" -delete

# Keep only last 10 backups
count=$(ls -1 "${BACKUP_DIR}/backup_$(basename "$SOURCE_DIR")_"*.tar.gz 2>/dev/null | wc -l)
if [ "$count" -gt 10 ]; then
    ls -1t "${BACKUP_DIR}/backup_$(basename "$SOURCE_DIR")_"*.tar.gz | \
        tail -n $((count - 10)) | xargs rm -f
    log "Removed $((count - 10)) old backups (retaining 10)"
fi

log "Backup completed successfully"
```

### Example 2: Log Rotator

```bash
#!/bin/bash
set -euo pipefail

CONFIG_FILE="${1:-/etc/myapp/logrotate.conf}"
ROTATE_DIR="/var/log/myapp/archive"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

rotate_log() {
    local logfile="$1"
    local max_size="$2"
    local keep_count="$3"

    [ -f "$logfile" ] || { log "SKIP: $logfile not found"; return 0; }

    local size
    size=$(stat -f%z "$logfile" 2>/dev/null || stat -c%s "$logfile" 2>/dev/null)

    if [ "$size" -lt "$max_size" ]; then
        log "OK: $logfile ($(numfmt --to=iec $size)) under limit"
        return 0
    fi

    log "ROTATING: $logfile ($(numfmt --to=iec $size)) exceeds limit"

    local timestamp
    timestamp=$(date '+%Y%m%d_%H%M%S')
    local archived="${ROTATE_DIR}/$(basename "$logfile").${timestamp}.gz"

    mkdir -p "$ROTATE_DIR"

    gzip -c "$logfile" > "$archived"
    : > "$logfile"    # Truncate original

    log "ARCHIVED: $archived ($(du -h "$archived" | cut -f1))"

    local count
    count=$(ls -1t "${ROTATE_DIR}/$(basename "$logfile")."*.gz 2>/dev/null | wc -l)
    if [ "$count" -gt "$keep_count" ]; then
        ls -1t "${ROTATE_DIR}/$(basename "$logfile")."*.gz 2>/dev/null | \
            tail -n $((count - keep_count)) | xargs rm -f
        log "CLEANUP: Removed $((count - keep_count)) old archives"
    fi
}

while IFS=' ' read -r logfile max_size keep_count; do
    [[ -z "$logfile" || "$logfile" == \#* ]] && continue
    rotate_log "$logfile" "$max_size" "$keep_count"
done < "$CONFIG_FILE"

log "Log rotation complete"
```

### Example 3: Health Check Script

```bash
#!/bin/bash
set -euo pipefail

ALERT_EMAIL="admin@example.com"
ALERT_DISK=90
ALERT_CPU=80
ALERT_MEM=90
HOSTNAME=$(hostname)
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

report_file=$(mktemp /tmp/health-XXXXXX)
trap 'rm -f "$report_file"' EXIT

alert() {
    local severity="$1"
    local message="$2"
    echo "[${TIMESTAMP}] [${severity}] ${message}" >> "$report_file"

    if [ "$severity" = "CRITICAL" ]; then
        echo "CRITICAL: $message" | \
            mail -s "[ALERT] ${HOSTNAME}: ${message}" "$ALERT_EMAIL"
    fi
}

check_disk() {
    df -h --exclude-type=tmpfs --exclude-type=devtmpfs | tail -n +2 | while read -r line; do
        local usage mount
        usage=$(echo "$line" | awk '{print $5}' | tr -d '%')
        mount=$(echo "$line" | awk '{print $6}')

        if [ "$usage" -ge "$ALERT_DISK" ]; then
            alert "CRITICAL" "Disk ${usage}% full on ${mount}"
        elif [ "$usage" -ge $((ALERT_DISK - 10)) ]; then
            alert "WARNING" "Disk ${usage}% full on ${mount}"
        fi
    done
}

check_cpu() {
    local load cores pct
    load=$(awk '{print $1}' /proc/loadavg)
    cores=$(nproc)
    pct=$(echo "$load $cores" | awk '{printf "%d", ($1/$2)*100}')

    if [ "$pct" -ge "$ALERT_CPU" ]; then
        alert "WARNING" "CPU load at ${pct}% (load: ${load}, cores: ${cores})"
    fi
}

check_memory() {
    local total used pct
    total=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
    used=$(awk '/^Active:/ {print $2}' /proc/meminfo)
    pct=$((used * 100 / total))

    if [ "$pct" -ge "$ALERT_MEM" ]; then
        alert "CRITICAL" "Memory at ${pct}%"
    elif [ "$pct" -ge $((ALERT_MEM - 10)) ]; then
        alert "WARNING" "Memory at ${pct}%"
    fi
}

check_services() {
    local services=("sshd" "cron" "rsyslog" "nginx")
    for svc in "${services[@]}"; do
        if systemctl is-active --quiet "$svc" 2>/dev/null; then
            echo "OK: $svc is running" >> "$report_file"
        else
            alert "CRITICAL" "Service $svc is NOT running"
            systemctl try-restart "$svc" 2>/dev/null && \
                alert "INFO" "Attempted restart of $svc"
        fi
    done
}

# Run all checks
echo "Health Check Report — ${HOSTNAME} — ${TIMESTAMP}" > "$report_file"
check_disk
check_cpu
check_memory
check_services

cat "$report_file"
```

### Example 4: User Creation Script

```bash
#!/bin/bash
set -euo pipefail

CSV_FILE="${1:?Usage: $0 <users.csv> [dry-run]}"
DRY_RUN="${2:-false}"
LOG_FILE="/var/log/user-creation.log"
DEFAULT_SHELL="/bin/bash"
PASSWORD_LENGTH=16

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

error_handler() {
    log "ERROR on line $1: $2"
    exit 1
}

trap 'error_handler $LINENO "$BASH_COMMAND"' ERR

[ -f "$CSV_FILE" ] || { log "CSV file $CSV_FILE not found"; exit 1; }

generate_password() {
    < /dev/urandom tr -dc 'A-Za-z0-9!@#$%^&*()_+' | head -c "$PASSWORD_LENGTH"
}

process_user() {
    local username="$1"
    local group="$2"
    local full_name="$3"
    local shell="${4:-$DEFAULT_SHELL}"

    [[ "$username" =~ ^[a-z_][a-z0-9_-]*$ ]] || {
        log "ERROR: Invalid username '$username'"
        return 1
    }

    if id "$username" &>/dev/null; then
        log "SKIP: User '$username' already exists"
        return 0
    fi

    if ! grep -q "^${group}:" /etc/group; then
        log "Creating group: $group"
        [ "$DRY_RUN" = false ] && groupadd "$group"
    fi

    local password
    password=$(generate_password)

    if [ "$DRY_RUN" = true ]; then
        log "DRY-RUN: Would create user: $username"
    else
        useradd -m -g "$group" -c "$full_name" -s "$shell" "$username"
        echo "$username:$password" | chpasswd
        chage -d 0 "$username"
        log "CREATED: $username (group: $group) — password: $password"
    fi
}

while IFS=',' read -r -u3 username group full_name shell; do
    username=$(echo "$username" | xargs)
    [[ -z "$username" || "$username" == \#* ]] && continue
    group=$(echo "$group" | xargs)
    full_name=$(echo "$full_name" | xargs)
    shell=$(echo "$shell" | xargs)
    shell="${shell:-$DEFAULT_SHELL}"
    process_user "$username" "$group" "$full_name" "$shell"
done 3< "$CSV_FILE"

log "User creation complete"
```





[← Previous](15-11-parsing-command-line-args.md) | [↑ Index](index.md) | [Next →](17-level-3-advanced-security-internals.md)
