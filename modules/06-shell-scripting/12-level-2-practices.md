## 💻 Level 2 Practices

### ✅ Practice 1: Loops — Rename Files in Bulk

```bash
cd ~/linux-course/part6

cat > bulk_rename.sh << 'EOF'
#!/bin/bash
# Rename all .txt files to .bak in current directory
for file in *.txt; do
  [ -f "$file" ] || continue
  mv "$file" "${file%.txt}.bak"
  echo "Renamed $file -> ${file%.txt}.bak"
done
EOF

chmod +x bulk_rename.sh
touch test1.txt test2.txt test3.txt
./bulk_rename.sh
```

### ✅ Practice 2: Exit Codes — Validate Command Success

```bash
cd ~/linux-course/part6

cat > validate.sh << 'EOF'
#!/bin/bash
set -euo pipefail

validate_file() {
  local file="$1"
  if [ ! -f "$file" ]; then
    echo "Error: $file not found" >&2
    return 1
  fi
  return 0
}

validate_file "/etc/hosts" && echo "hosts exists"
validate_file "/nonexistent" && echo "OK" || echo "SKIPPED (expected failure)"
EOF

chmod +x validate.sh
./validate.sh
```

### ✅ Practice 3: Functions — Logging Utility

```bash
cd ~/linux-course/part6

cat > logger.sh << 'EOF'
#!/bin/bash

log_info()  { echo "[$(date '+%H:%M:%S')] INFO:  $*"; }
log_warn()  { echo "[$(date '+%H:%M:%S')] WARN:  $*" >&2; }
log_error() { echo "[$(date '+%H:%M:%S')] ERROR: $*" >&2; }

log_info "Starting process"
sleep 0.5
log_warn "Disk usage above 80%"
sleep 0.5
log_error "Failed to connect to database"
EOF

chmod +x logger.sh
./logger.sh
```

### ✅ Practice 4: Arrays — Process Manager

```bash
cd ~/linux-course/part6

cat > proc_list.sh << 'EOF'
#!/bin/bash

declare -A processes
processes[sshd]="Secure Shell Daemon"
processes[cron]="Task Scheduler"
processes[systemd-journald]="Logging Service"

echo "=== Known Processes ==="
for proc in "${!processes[@]}"; do
  if pgrep -x "$proc" > /dev/null 2>&1; then
    echo "  [RUNNING] $proc — ${processes[$proc]}"
  else
    echo "  [STOPPED] $proc — ${processes[$proc]}"
  fi
done
EOF

chmod +x proc_list.sh
./proc_list.sh
```

### ✅ Practice 5: I/O — Log File Analyzer

```bash
cd ~/linux-course/part6

# Create a sample log
cat > sample.log << 'LOGEOF'
2024-01-15 10:00:00 INFO  Server started
2024-01-15 10:01:23 ERROR Disk full on /dev/sda1
2024-01-15 10:02:45 INFO  Connection from 10.0.0.1
2024-01-15 10:03:12 WARN  CPU load at 95%
2024-01-15 10:04:56 ERROR Connection timeout
LOGEOF

cat > log_analyzer.sh << 'EOF'
#!/bin/bash
LOG="${1:-sample.log}"
[ ! -f "$LOG" ] && echo "Usage: $0 <logfile>" && exit 1

echo "=== Log Analysis: $LOG ==="
echo "Total lines:  $(wc -l < "$LOG")"
echo "ERROR lines:  $(grep -c ERROR "$LOG")"
echo "WARN lines:   $(grep -c WARN  "$LOG")"
echo "INFO lines:   $(grep -c INFO  "$LOG")"
echo ""

while IFS= read -r line; do
  level=$(echo "$line" | awk '{print $3}')
  msg=$(echo "$line" | awk '{$1=$2=$3=""; print $0}' | sed 's/^ *//')
  case "$level" in
    ERROR) echo "❌ $msg" ;;
    WARN)  echo "⚠️  $msg" ;;
    INFO)  echo "ℹ️  $msg" ;;
  esac
done < "$LOG"
EOF

chmod +x log_analyzer.sh
./log_analyzer.sh sample.log
```



[← Previous](11-section-5-input-and-output.md) | [↑ Index](index.md) | [Next →](13-section-1-error-handling-writing.md)
