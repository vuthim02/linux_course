## 13. Hands-On Practices (15)

### Level 1 — Basic

#### Practice 1: grep Patterns
Find all lines in `/var/log/syslog` that contain either "ERROR" or "FATAL" (case-insensitive), print only the matching text, and prefix with line numbers.
```bash
grep -inoE 'ERROR|FATAL' /var/log/syslog
```

#### Practice 4: Pipe Pipeline for System Analysis
Build a one-liner that shows top 5 CPU-eating processes with PID, command, and CPU%, formatted as a table.
```bash
ps aux --no-headers | sort -k3 -rn | head -5 | \
    awk '{ printf "%-8s %-30s %5.1f%%\n", $2, $11, $3 }'
```

#### Practice 6: Create a CSV Report with awk
Generate a report of all users with UID ≥ 1000, showing username, UID, home directory, and shell, as a CSV.
```bash
awk -F: '$3 >= 1000 { printf "%s,%s,%s,%s\n", $1, $3, $6, $7 }' /etc/passwd > users.csv
```

#### Practice 7: Apply Patches with diff/patch
Create a patch from two versions of a config file, then apply and revert it.
```bash
diff -u /etc/nginx/nginx.conf.bak /etc/nginx/nginx.conf > nginx.patch
sudo patch < nginx.patch
sudo patch -R < nginx.patch
```

#### Practice 11: Text Processing with tr, cut, sort
Extract the domain portion from email addresses in a file, sort, and count unique domains.
```bash
tr -s '[:space:]' '\n' < emails.txt | grep -oE '@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}' | \
    tr -d '@' | sort | uniq -c | sort -rn
```

#### Practice 13: join/paste Data Merging
Create a CSV by joining `/etc/passwd` (UID) with `/etc/group` (GID) to map each user to their primary group name.
```bash
sort -t: -k4 /etc/passwd > pwd_sorted
sort -t: -k3 /etc/group > grp_sorted
join -t: -1 4 -2 3 -o 1.1,2.1,1.3 pwd_sorted grp_sorted | head
```

### Level 2 — Intermediary

#### Practice 2: sed Search/Replace in Config
Edit `/etc/ssh/sshd_config` to change `#Port 22` to `Port 2222` (uncomment and change value), creating a backup first.
```bash
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
sudo sed -i 's/^#\s*Port\s\+22/Port 2222/' /etc/ssh/sshd_config
```

#### Practice 3: awk Log Parser
Using `/var/log/auth.log`, extract all IP addresses from "Failed password" lines, count occurrences, and display top 10.
```bash
awk '/Failed password/ {
    for (i=1; i<=NF; i++) if ($i ~ /^[0-9]{1,3}\./) ips[$i]++
} END {
    for (ip in ips) print ips[ip], ip
}' /var/log/auth.log | sort -rn | head -10
```

#### Practice 5: xargs Parallel Task Execution
Find all `.conf` files under `/etc`, validate them with `nginx -t`, and restart nginx if all pass, using parallel xargs.
```bash
find /etc/nginx -name '*.conf' -print0 | xargs -0 -P4 -I{} nginx -t -c {} 2>&1
```

#### Practice 8: Multi-tool Log Analysis Pipeline
Count 404 errors per URL from an Apache/Nginx log, sorted by frequency, with human-readable output.
```bash
awk '$9 == 404 {print $7}' /var/log/nginx/access.log | sort | uniq -c | sort -rn | \
    awk '{ printf "%-6d %s\n", $1, $2 }' | head -20
```

#### Practice 9: sed Multi-File Config Update
Update `max_connections` in all `.conf` files under `/etc/mysql/` from 100 to 500, with backups.
```bash
find /etc/mysql -name '*.conf' -exec sh -c 'cp "$1" "$1.bak"; sed -i "s/max_connections=100/max_connections=500/" "$1"' _ {} \;
```

#### Practice 10: awk Report with Grouping and Totals
Parse `df -h` output and produce a report sorted by usage percentage, with a total line at the end.
```bash
df -h | awk 'NR>1 {
    pct = $5
    gsub(/%/, "", pct)
    if (pct+0 > 0) {
        printf "%-20s %6s %5s\n", $1, $5, $3
        total += pct
        count++
    }
} END {
    printf "%-20s %6s\n", "Average Usage:", int(total/count)"%"
}'
```

#### Practice 14: awk Inline Script
Write an awk one-liner that takes `ps aux` output and prints processes where RSS > 100MB (RSS field is $6, in KB).
```bash
ps aux --no-headers | awk '$6 > 102400 { printf "%-10s %-30s %6.1f MB\n", $1, $11, $6/1024 }'
```

### Level 3 — Advanced

#### Practice 12: sed Multi-Line Replacement
Replace multi-line `<div class="old">...</div>` blocks with `<div class="new">...</div>` in HTML files.
```bash
sed -i '/<div class="old">/,/<\/div>/c\<div class="new">\n  <!-- updated -->\n</div>' file.html
```

#### Practice 15: Real-World Integration
Build a complete log analysis and reporting toolkit script that:
1. Parses a web access log
2. Extracts top IPs, URLs, status codes, hourly distribution
3. Anonymizes IPs for GDPR compliance
4. Outputs both a summary report (text) and a CSV file
5. Uses at least grep, sed, awk, sort, uniq, and optionally xargs

```bash
#!/bin/bash
# complete_log_toolkit.sh — full log analysis pipeline
# Usage: ./complete_log_toolkit.sh access.log [output_dir]

LOG="${1:?Usage: $0 access.log [output_dir]}"
OUTDIR="${2:-./analysis_$(date +%Y%m%d_%H%M%S)}"
mkdir -p "$OUTDIR"

ANON_LOG="${OUTDIR}/access_anonymized.log"
REPORT="${OUTDIR}/report.txt"
CSV="${OUTDIR}/summary.csv"

echo "Analyzing: $LOG"
echo "Output:    $OUTDIR"
echo ""

# Step 1: Anonymize IPs (last octet → .0)
echo "[1/5] Anonymizing IPs..."
sed -E 's/([0-9]{1,3}\.){3}[0-9]{1,3}/\1**0/g' "$LOG" > "$ANON_LOG"
echo "  Wrote: $ANON_LOG"

# Step 2: Generate text report
echo "[2/5] Generating text report..."
{
    echo "=========================================="
    echo "  LOG ANALYSIS REPORT"
    echo "  Source: $LOG"
    echo "  Generated: $(date)"
    echo "=========================================="
    echo ""

    total=$(wc -l < "$LOG")
    echo "Total requests: $total"

    echo ""
    echo "--- Top 10 IPs ---"
    awk '{print $1}' "$LOG" | sort | uniq -c | sort -rn | head -10

    echo ""
    echo "--- Top 10 URLs ---"
    awk '{print $7}' "$LOG" | sort | uniq -c | sort -rn | head -10

    echo ""
    echo "--- Status Codes ---"
    awk '{print $9}' "$LOG" | sort | uniq -c | sort -rn

    echo ""
    echo "--- Hourly Distribution ---"
    awk '{
        match($4, /[0-9]{2}\/[A-Za-z]{3}\/[0-9]{4}:([0-9]{2})/, h)
        if (h[1] != "") hours[h[1]]++
    } END {
        for (h=0; h<24; h++) {
            kh = sprintf("%02d", h)
            printf "  %s: %d\n", kh, hours[kh]
        }
    }' "$LOG"

    echo ""
    echo "--- 404 Errors (top 10) ---"
    awk '$9 == 404 {print $7}' "$LOG" | sort | uniq -c | sort -rn | head -10
} > "$REPORT"
echo "  Wrote: $REPORT"

# Step 3: Generate CSV
echo "[3/5] Generating CSV..."
{
    echo "metric,value"
    echo "total_requests,$total"
    echo "unique_ips,$(awk '{print $1}' "$LOG" | sort -u | wc -l)"
    awk '{
        codes[$9]++
    } END {
        for (c in codes) print "status_" c "," codes[c]
    }' "$LOG"
} > "$CSV"
echo "  Wrote: $CSV"

# Step 4: Extract top offenders
echo "[4/5] Extracting top offenders..."
awk '{print $1}' "$LOG" | sort | uniq -c | sort -rn | head -5 > "${OUTDIR}/top_ips.txt"
awk '$9 == 404 {print $7}' "$LOG" | sort | uniq -c | sort -rn | head -5 > "${OUTDIR}/top_404.txt"
echo "  Wrote: top_ips.txt, top_404.txt"

# Step 5: Compress anonymized log
echo "[5/5] Compressing..."
gzip -f "$ANON_LOG"
echo "  Compressed: ${ANON_LOG}.gz"

echo ""
echo "=========================================="
echo "  ANALYSIS COMPLETE"
echo "  Report: $REPORT"
echo "  CSV:    $CSV"
echo "=========================================="
```





[← Previous](17-level-3-advanced-practices-internals.md) | [↑ Index](index.md) | [Next →](19-14-deep-understanding.md)
