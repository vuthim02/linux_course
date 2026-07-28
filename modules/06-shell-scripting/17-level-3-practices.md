## 💻 Level 3 Practices

### ✅ Practice 1: Error Handling With trap

```bash
cd ~/linux-course/part6

cat > safe_script.sh << 'EOF'
#!/bin/bash
set -euo pipefail

cleanup() {
    echo "Cleaning up..."
    if [ -d /tmp/mytempdir ]; then
        rm -rf /tmp/mytempdir
        echo "Removed temp directory"
    fi
    echo "Exiting."
}

trap cleanup EXIT

echo "Creating temp directory..."
mkdir -p /tmp/mytempdir
echo "Working..."
# Simulate some work
sleep 2
echo "Done."
EOF

chmod +x safe_script.sh
./safe_script.sh
```


### ✅ Practice 2: Real Script — System Info Report

```bash
cd ~/linux-course/part6

cat > sysinfo.sh << 'EOF'
#!/bin/bash
set -euo pipefail

echo "=================================="
echo "  SYSTEM INFORMATION REPORT"
echo "=================================="
echo "Hostname:  $(hostname)"
echo "Kernel:    $(uname -r)"
echo "Uptime:    $(uptime -p)"
echo "CPU:       $(nproc) cores"
echo "Memory:    $(free -h | awk '/^Mem:/ {print $3 "/" $2}')"
echo "Disk:      $(df -h / | awk 'NR==2 {print $3 "/" $2 " (" $5 ")"}')"
echo "Users:     $(who | wc -l) logged in"
echo "Processes: $(ps aux | wc -l)"
echo "=================================="
EOF

chmod +x sysinfo.sh
./sysinfo.sh
```


### ✅ Practice 3: Real Script — Disk Usage Alert

```bash
cd ~/linux-course/part6

cat > disk_alert.sh << 'EOF'
#!/bin/bash

THRESHOLD=80

echo "Checking disk usage (threshold: ${THRESHOLD}%)..."
echo ""

df -h | awk -v threshold="$THRESHOLD" '
NR==1 {print; next}
{
    usage = $5
    gsub(/%/, "", usage)
    if (usage >= threshold) {
        printf "\033[1;31mWARNING\033[0m %s is at %s\n", $6, $5
    }
}
'
EOF

chmod +x disk_alert.sh
./disk_alert.sh
```


### ✅ Practice 4: Real Script — Backup Directory

```bash
cd ~/linux-course/part6

cat > backup_dir.sh << 'EOF'
#!/bin/bash
set -euo pipefail

SOURCE="${1:-}"
DEST="${2:-/tmp/backup}"
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')

if [ -z "$SOURCE" ]; then
    echo "Usage: $0 <source_directory> [destination_directory]"
    exit 1
fi

if [ ! -d "$SOURCE" ]; then
    echo "Error: $SOURCE is not a directory."
    exit 1
fi

mkdir -p "$DEST"

BASENAME=$(basename "$SOURCE")
ARCHIVE="${DEST}/${BASENAME}_${TIMESTAMP}.tar.gz"

echo "Backing up $SOURCE to $ARCHIVE..."
tar -czf "$ARCHIVE" -C "$(dirname "$SOURCE")" "$BASENAME"

echo "Done. Archive size: $(du -h "$ARCHIVE" | cut -f1)"
EOF

chmod +x backup_dir.sh
mkdir -p /tmp/test_backup_source
touch /tmp/test_backup_source/{file1,file2,file3}.txt
./backup_dir.sh /tmp/test_backup_source /tmp/backup_test
ls -la /tmp/backup_test/
```


### ✅ Practice 5: Real Script — User Audit

```bash
cd ~/linux-course/part6

cat > user_audit.sh << 'EOF'
#!/bin/bash

echo "=== USER ACCOUNT AUDIT ==="
echo ""

echo "--- Regular Users (UID >= 1000) ---"
awk -F: '$3 >= 1000 {printf "  %-15s UID=%-5s Home=%-20s Shell=%s\n", $1, $3, $6, $7}' /etc/passwd

echo ""
echo "--- Users with Login Access ---"
grep -v '/sbin/nologin\|/bin/false' /etc/passwd | awk -F: '{print "  " $1}'

echo ""
echo "--- Users in sudo/wheel group ---"
for group in sudo wheel; do
    if grep -q "^$group:" /etc/group 2>/dev/null; then
        members=$(grep "^$group:" /etc/group | cut -d: -f4)
        [ -n "$members" ] && echo "  $group: $members" || echo "  $group: (no members)"
    fi
done

echo ""
echo "--- Last Login ---"
last -10 2>/dev/null || echo "  (no login history)"
EOF

chmod +x user_audit.sh
./user_audit.sh
```


### ✅ Practice 6: Real Script — Service Manager

```bash
cd ~/linux-course/part6

cat > service_ctl.sh << 'EOF'
#!/bin/bash

SERVICE_NAME="${1:-}"
ACTION="${2:-status}"

usage() {
    echo "Usage: $0 <service_name> {start|stop|restart|status|enable|disable}"
    exit 1
}

[ -z "$SERVICE_NAME" ] && usage

case "$ACTION" in
    start|stop|restart|status|enable|disable)
        echo "Running: systemctl $ACTION $SERVICE_NAME"
        sudo systemctl "$ACTION" "$SERVICE_NAME"
        ;;
    *)
        usage
        ;;
esac
EOF

chmod +x service_ctl.sh
# Test with: ./service_ctl.sh ssh status
```


### ✅ Practice 7: Real Script — Log Rotator (Simple)

```bash
cd ~/linux-course/part6

cat > rotate_logs.sh << 'EOF'
#!/bin/bash
set -euo pipefail

LOG_DIR="${1:-/var/log}"
MAX_AGE_DAYS="${2:-7}"

echo "Rotating logs in $LOG_DIR older than $MAX_AGE_DAYS days..."
echo ""

find "$LOG_DIR" -name "*.log" -type f -mtime "+$MAX_AGE_DAYS" -print | while read -r logfile; do
    gzip "$logfile"
    echo "  Compressed: $logfile"
done

echo ""
echo "Done. Run 'ls -la $LOG_DIR/*.gz' to see compressed files."
EOF

chmod +x rotate_logs.sh
mkdir -p /tmp/test_logs
touch -t 202301010000 /tmp/test_logs/old.log
touch /tmp/test_logs/new.log
./rotate_logs.sh /tmp/test_logs 7
ls -la /tmp/test_logs/
```


### ✅ Practice 8: Script With getopts

```bash
cd ~/linux-course/part6

cat > report_generator.sh << 'EOF'
#!/bin/bash
set -euo pipefail

verbose=0
output=""
format="text"

usage() {
    cat << EOF
Usage: $(basename "$0") [-v] [-o output_file] [-f format] <directory>

Generate a report of the specified directory.

Options:
    -v          Verbose output
    -o FILE     Write report to FILE (default: stdout)
    -f FORMAT   Output format: text|json (default: text)
    -h          Show this help
EOF
    exit 0
}

while getopts "vo:f:h" opt; do
    case "$opt" in
        v) verbose=1 ;;
        o) output="$OPTARG" ;;
        f) format="$OPTARG" ;;
        h) usage ;;
        *) usage ;;
    esac
done

shift $((OPTIND-1))

target="${1:-.}"
if [ ! -d "$target" ]; then
    echo "Error: '$target' is not a directory" >&2
    exit 1
fi

generate_report() {
    local dir="$1"
    local fmt="$2"
    
    case "$fmt" in
        text)
            cat << REPORT
Directory: $dir
Files:     $(find "$dir" -type f | wc -l)
Dirs:      $(find "$dir" -type d | wc -l)
Size:      $(du -sh "$dir" | cut -f1)
REPORT
            ;;
        json)
            cat << REPORT
{
    "directory": "$dir",
    "files": $(find "$dir" -type f | wc -l),
    "directories": $(find "$dir" -type d | wc -l),
    "size": "$(du -sh "$dir" | cut -f1)"
}
REPORT
            ;;
    esac
}

if [ -n "$output" ]; then
    generate_report "$target" "$format" > "$output"
    [ "$verbose" -eq 1 ] && echo "Report written to $output"
else
    generate_report "$target" "$format"
fi
EOF

chmod +x report_generator.sh
./report_generator.sh /etc
./report_generator.sh -f json /etc
./report_generator.sh -v -o /tmp/report.txt ~/linux-course
cat /tmp/report.txt
```


### ✅ Practice 9: Comprehensive Script — System Health Check

```bash
cd ~/linux-course/part6

cat > health_check.sh << 'EOF'
#!/bin/bash
set -Eeuo pipefail

VERSION="1.0.0"
VERBOSE=0
EMAIL=""

# Colors
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

usage() {
    cat << EOF
Usage: $(basename "$0") [options]

System health check tool.

Options:
    -v          Verbose mode
    -e EMAIL    Send report to email
    -h          Show help

Version: $VERSION
EOF
    exit 0
}

log() {
    local level="$1"
    local msg="$2"
    local color=""
    
    case "$level" in
        OK)   color="$GREEN" ;;
        WARN) color="$YELLOW" ;;
        FAIL) color="$RED" ;;
    esac
    
    echo -e "${color}[$level]${NC} $msg"
}

check_cpu() {
    local load
    load=$(uptime | awk -F'load average:' '{print $2}' | cut -d, -f1 | tr -d ' ')
    local cores
    cores=$(nproc)
    
    local threshold=$(echo "$cores * 0.8" | bc)
    if (( $(echo "$load > $threshold" | bc -l) )); then
        log "WARN" "CPU load high: $load (cores: $cores)"
    else
        log "OK" "CPU load normal: $load (cores: $cores)"
    fi
}

check_memory() {
    local total used percent
    total=$(free -m | awk '/^Mem:/ {print $2}')
    used=$(free -m | awk '/^Mem:/ {print $3}')
    percent=$((used * 100 / total))
    
    if [ "$percent" -gt 90 ]; then
        log "FAIL" "Memory critical: ${used}MB/${total}MB (${percent}%)"
    elif [ "$percent" -gt 75 ]; then
        log "WARN" "Memory high: ${used}MB/${total}MB (${percent}%)"
    else
        log "OK" "Memory normal: ${used}MB/${total}MB (${percent}%)"
    fi
}

check_disk() {
    df -h | awk 'NR>1 {
        usage = $5
        gsub(/%/, "", usage)
        mount = $6
        if (usage >= 90)
            printf "'"$RED"'" "[FAIL]"'"$NC"' " %s at %s\n", mount, $5
        else if (usage >= 75)
            printf "'"$YELLOW"'" "[WARN]"'"$NC"' " %s at %s\n", mount, $5
    }'
}

check_services() {
    local services=("sshd" "cron" "rsyslog" "systemd-journald")
    
    for svc in "${services[@]}"; do
        if systemctl is-active --quiet "$svc" 2>/dev/null; then
            log "OK" "Service $svc is running"
        else
            log "WARN" "Service $svc is NOT running"
        fi
    done
}

check_updates() {
    if command -v apt &> /dev/null; then
        local updates
        updates=$(apt list --upgradable 2>/dev/null | wc -l)
        if [ "$updates" -gt 1 ]; then
            log "WARN" "$((updates - 1)) package updates available"
        else
            log "OK" "System is up to date"
        fi
    else
        log "WARN" "Cannot check updates (not apt-based)"
    fi
}

# Parse arguments
while getopts "ve:h" opt; do
    case "$opt" in
        v) VERBOSE=1 ;;
        e) EMAIL="$OPTARG" ;;
        h) usage ;;
        *) usage ;;
    esac
done

# Main
echo ""
echo "============================================"
echo "  SYSTEM HEALTH CHECK"
echo "  Hostname: $(hostname)"
echo "  Date:     $(date)"
echo "============================================"
echo ""

report=$(cat << REPORT
System Health Check Report
==========================
Hostname: $(hostname)
Date:     $(date)

CPU:
$(uptime)

Memory:
$(free -h)

Disk:
$(df -h)

Services:
$(systemctl list-units --type=service --state=running --no-legend | awk '{print "  " $1}')
REPORT
)

check_cpu
check_memory
check_disk
check_services
check_updates

echo ""
echo "============================================"

if [ -n "$EMAIL" ]; then
    echo "$report" | mail -s "Health Report: $(hostname) - $(date)" "$EMAIL"
    log "OK" "Report sent to $EMAIL"
fi
EOF

chmod +x health_check.sh
./health_check.sh
```





[← Previous](16-deep-understanding-how-scripts-execute.md) | [↑ Index](index.md) | [Next →](18-summary-complete-command-reference.md)
