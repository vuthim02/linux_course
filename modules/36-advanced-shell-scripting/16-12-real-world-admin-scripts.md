## 12. Real-World Admin Scripts

### 12.1 Log Parser — Extract, Summarize, Report

```bash
#!/bin/bash
# log_analyzer.sh — analyze web server access log
# Usage: ./log_analyzer.sh /var/log/nginx/access.log

LOG="${1:-/var/log/nginx/access.log}"

if [ ! -r "$LOG" ]; then
    echo "Error: cannot read $LOG"
    exit 1
fi

echo "=========================================="
echo "  LOG ANALYZER REPORT"
echo "  File: $LOG"
echo "  Date: $(date)"
echo "=========================================="
echo ""

# Total requests
total=$(wc -l < "$LOG")
echo "Total requests: $total"

# Unique IPs
echo -n "Unique IPs:      "
awk '{print $1}' "$LOG" | sort -u | wc -l

# Status code distribution
echo ""
echo "--- Status Code Distribution ---"
awk '{
    code = $9
    codes[code]++
} END {
    for (c in codes) printf "  %s: %d\n", c, codes[c]
}' "$LOG" | sort -t: -k2 -rn

# Top 10 IPs
echo ""
echo "--- Top 10 IPs ---"
awk '{print $1}' "$LOG" | sort | uniq -c | sort -rn | head -10 | \
    awk '{ printf "  %-15s %d requests\n", $2, $1 }'

# Top 10 URLs
echo ""
echo "--- Top 10 URLs ---"
awk '{print $7}' "$LOG" | sort | uniq -c | sort -rn | head -10 | \
    awk '{ printf "  %-50s %d requests\n", $2, $1 }'

# 404 analysis
echo ""
echo "--- 404 Errors by URL ---"
awk '$9 == 404 {print $7}' "$LOG" | sort | uniq -c | sort -rn | head -10 | \
    awk '{ printf "  %-50s %d times\n", $2, $1 }'

# Hourly distribution
echo ""
echo "--- Requests by Hour ---"
awk '{
    match($4, /[0-9]{2}\/[A-Za-z]{3}\/[0-9]{4}:([0-9]{2})/, h)
    if (h[1] != "") hours[h[1]]++
} END {
    for (h=0; h<24; h++) {
        kh = sprintf("%02d", h)
        bar = ""
        for (i=0; i<hours[kh]/50; i++) bar = bar "#"
        printf "  %s: %5d %s\n", kh, hours[kh], bar
    }
}' "$LOG"

echo ""
echo "--- End of Report ---"
```

### 12.2 Config Generator — Templating with sed + awk

```bash
#!/bin/bash
# config_gen.sh — generate nginx configs from template
# Usage: ./config_gen.sh site_name domain port

set -euo pipefail

SITE="${1:?Usage: $0 site_name domain port}"
DOMAIN="${2:?}"
PORT="${3:?}"

TEMPLATE="/etc/nginx/templates/site.template"
OUTPUT="/etc/nginx/sites-available/${SITE}"

if [ ! -f "$TEMPLATE" ]; then
    echo "Template not found: $TEMPLATE"
    exit 1
fi

# Generate config using sed
sed -e "s/{{SITE}}/$SITE/g" \
    -e "s/{{DOMAIN}}/$DOMAIN/g" \
    -e "s/{{PORT}}/$PORT/g" \
    -e "s/{{DATE}}/$(date)/g" \
    -e "s/{{ADMIN}}/${ADMIN_EMAIL:-admin@$DOMAIN}/g" \
    "$TEMPLATE" > "$OUTPUT"

echo "Generated: $OUTPUT"

# Validate and enable
if nginx -t 2>&1 | grep -q successful; then
    ln -sf "$OUTPUT" /etc/nginx/sites-enabled/
    systemctl reload nginx
    echo "Site enabled: $SITE"
else
    echo "NGINX config test FAILED. Check $OUTPUT"
    nginx -t
    exit 1
fi
```

### 12.3 Inventory Report — System Audit

```bash
#!/bin/bash
# inventory.sh — generate system inventory report
# Output: CSV with hostname, os, kernel, cpu, mem, disk

OUTPUT="${1:-inventory_$(hostname)_$(date +%Y%m%d).csv}"

echo "hostname,os,kernel,cpu_cores,mem_gb,disk_gb,ip_address" > "$OUTPUT"

OS=$(awk -F= '/^NAME/{gsub(/"/,"",$2); print $2}' /etc/os-release)
KERNEL=$(uname -r)
CPU=$(nproc)
MEM=$(awk '/MemTotal/{printf "%.1f", $2/1024/1024}' /proc/meminfo)
DISK=$(df -h / | awk 'NR==2 {print $2}')
IP=$(hostname -I 2>/dev/null | awk '{print $1}')

echo "$(hostname),$OS,$KERNEL,$CPU,$MEM,$DISK,$IP" >> "$OUTPUT"

# For multiple servers
# cat servers.txt | xargs -P10 -I{} ssh {} 'bash -s' < inventory.sh

echo "Inventory written to: $OUTPUT"
```

### 12.4 CSV-to-HTML Converter

```bash
#!/bin/bash
# csv2html.sh — convert CSV to HTML table
# Usage: ./csv2html.sh data.csv > report.html

CSV="${1:?Usage: $0 file.csv}"
TITLE="${2:-CSV Report}"

if [ ! -r "$CSV" ]; then
    echo "Error: cannot read $CSV"
    exit 1
fi

cat <<EOF
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>$TITLE</title>
<style>
  table { border-collapse: collapse; width: 100%; }
  th, td { border: 1px solid #999; padding: 8px; text-align: left; }
  th { background-color: #4CAF50; color: white; }
  tr:nth-child(even) { background-color: #f2f2f2; }
</style>
</head>
<body>
<h1>$TITLE</h1>
<p>Generated: $(date)</p>
<table>
EOF

awk -F, '
BEGIN {
    row = 0
}
{
    row++
    if (row == 1) {
        printf "<thead>\n<tr>\n"
        for (i=1; i<=NF; i++) {
            gsub(/^"|"$/, "", $i)
            printf "<th>%s</th>\n", $i
        }
        printf "</tr>\n</thead>\n<tbody>\n"
    } else {
        printf "<tr>\n"
        for (i=1; i<=NF; i++) {
            gsub(/^"|"$/, "", $i)
            printf "<td>%s</td>\n", $i
        }
        printf "</tr>\n"
    }
}
END {
    printf "</tbody>\n</table>\n</body>\n</html>\n"
}' "$CSV"
```

### 12.5 Log Watchdog — Multi-tool Alerting

```bash
#!/bin/bash
# log_watchdog.sh — monitor logs and trigger alerts
# Uses grep, sed, awk, mail

LOG="${1:-/var/log/syslog}"
PATTERNS="ERROR|FATAL|PANIC|CRITICAL|OOM|killed"
STATE_FILE="/tmp/log_watchdog_last"
SLEEP=60
ALERT_EMAIL="root@localhost"

while true; do
    skip=$(cat "$STATE_FILE" 2>/dev/null || echo 0)

    # Use sed to skip already-processed lines
    matches=$(tail -n +$((skip + 1)) "$LOG" | \
        grep -E "$PATTERNS" | \
        sed 's/^/ALERT: /')

    if [ -n "$matches" ]; then
        echo "$matches" | \
            awk '{ printf "[%s] %s\n", strftime("%H:%M:%S"), $0 }' | \
            while read line; do
                logger -t log_watchdog "$line"
                echo "$line" | mail -s "ALERT from $(hostname)" "$ALERT_EMAIL"
            done
    fi

    # Update state
    wc -l < "$LOG" > "$STATE_FILE"
    sleep "$SLEEP"
done
```

### 12.6 Parallel Log Analyzer (xargs -P)

```bash
#!/bin/bash
# parallel_log_analysis.sh — analyze multiple log files in parallel
# Usage: ./parallel_log_analysis.sh /var/log/*.log

analyze_file() {
    local file="$1"
    local errors warnings total

    errors=$(grep -ci 'error\|fatal\|panic' "$file" 2>/dev/null || echo 0)
    warnings=$(grep -ci 'warn' "$file" 2>/dev/null || echo 0)
    total=$(wc -l < "$file" 2>/dev/null || echo 0)

    printf "[%s] %s errors=%d warnings=%d total=%d\n" \
        "$(date -r "$file" '+%Y-%m-%d %H:%M')" \
        "$(basename "$file")" "$errors" "$warnings" "$total"
}

export -f analyze_file

if [ $# -eq 0 ]; then
    echo "Usage: $0 <logfile> [logfile ...]"
    exit 1
fi

echo "Parallel analysis of $# files..."
printf "%s\0" "$@" | xargs -0 -P "$(nproc)" -I {} bash -c 'analyze_file "$@"' _ {}
```

---



---

[← Previous](15-11-diff-and-patch.md) | [↑ Index](index.md) | [Next →](17-level-3-advanced-practices-internals.md)
