## 6. awk Admin Patterns

### 6.1 Log Parsing

```bash
# Apache/Nginx access log analysis
awk '{ print $1 }' access.log | sort | uniq -c | sort -rn | head -10
awk '{ print $9 }' access.log | sort | uniq -c | sort -rn

# HTTP status code counts from Apache combined format
# Format: IP - - [date] "METHOD URL PROTO" STATUS SIZE "REFERER" "UA"
awk '{
    status = $9
    if (status ~ /^[0-9]+$/) {
        if (status ~ /^2/) group = "2xx Success"
        else if (status ~ /^3/) group = "3xx Redirect"
        else if (status ~ /^4/) group = "4xx Client Error"
        else if (status ~ /^5/) group = "5xx Server Error"
        else group = "Other"
        counts[group]++
        total++
    }
} END {
    for (g in counts) printf "%-20s %5d (%.1f%%)\n", g, counts[g], counts[g]/total*100
}' access.log

# 404 by URL
awk '$9 == 404 { print $7 }' access.log | sort | uniq -c | sort -rn | head -20

# Response time > 5 seconds (if in log)
awk '{
    split($NF, t, "/")
    if (t[1] > 5) print $1, $7, t[1]
}' access.log
```

### 6.2 CSV Data Extraction

```bash
# CSV with possible quoted fields
awk -F',' '{
    # Strip quotes from fields
    for (i=1; i<=NF; i++) {
        gsub(/^"|"$/, "", $i)
    }
    print $1, $3
}' data.csv

# Filter rows where column 2 > 100
awk -F, '$2+0 > 100 { print $1, $2 }' data.csv

# Extract specific columns
awk -F, '{ print $1, $4, $7 }' OFS=',' employees.csv

# CSV with header
awk -F, 'NR==1 { print "HEADER:", $0 } NR>1 { print "DATA:", $1 }' file.csv
```

### 6.3 Summarization

```bash
# Total, average, min, max
awk '{
    sum += $1
    count++
    if ($1 > max) max = $1
    if (min == "" || $1 < min) min = $1
} END {
    print "Count:", count
    print "Sum:", sum
    print "Avg:", sum/count
    print "Min:", min
    print "Max:", max
}' numbers.txt

# Group by category
awk -F, '{
    cat = $2
    count[cat]++
    total[cat] += $3
} END {
    for (c in count) printf "%-20s Count: %5d Total: %8.2f\n", c, count[c], total[c]
}' sales.csv

# Top-N by group
awk -F, '{
    items[$1][$2] = $3
} END {
    for (cat in items) {
        print "Category:", cat
        n = asorti(items[cat], sorted, "@val_num_desc")
        for (i=1; i<=3 && i<=n; i++) print "  ", sorted[i], items[cat][sorted[i]]
    }
}' data.csv
```

### 6.4 Report Generation

```bash
#!/bin/bash
# report.sh — generates system summary report with awk

{
    echo "============================================"
    echo "  SYSTEM REPORT - $(date)"
    echo "============================================"
    echo ""
    echo "--- DISK USAGE ---"
    df -h | awk 'NR==1 || int($5) > 80 { print $0 }'
    echo ""
    echo "--- TOP MEMORY PROCESSES ---"
    ps aux | awk 'NR==1 { print $0 } NR>1 { print $0 | "sort -k4 -rn" }' | head -6
    echo ""
    echo "--- FAILED LOGIN ATTEMPTS ---"
    journalctl -u sshd --since "24 hours ago" | grep "Failed password" | \
        awk '{ print $11 }' | sort | uniq -c | sort -rn | head -10
    echo ""
    echo "--- NETWORK CONNECTIONS ---"
    ss -tuna | awk 'NR>1 { print $5 }' | awk -F: '{ print $1 }' | sort | uniq -c | sort -rn | head -10
    echo ""
    echo "--- END REPORT ---"
}
```

### 6.5 Columnar Output

```bash
# Format passwd as a table
awk -F: 'BEGIN {
    printf "%-20s %-6s %-6s %-30s %-20s\n", "Username", "UID", "GID", "Home", "Shell"
    printf "%-20s %-6s %-6s %-30s %-20s\n", "--------", "---", "---", "----", "-----"
}
{
    printf "%-20s %-6s %-6s %-30s %-20s\n", $1, $3, $4, $6, $7
}' /etc/passwd

# Expand tabs to aligned columns
awk -v OFS='\t' '{ $1=$1; print }' file.txt | column -t -s $'\t'
```

### 6.6 Two-File Processing

```bash
# Process two files using NR and FNR
awk 'NR==FNR { ids[$1]=1; next } $1 in ids { print $0 }' ids.txt data.txt

# Join on first field
awk 'NR==FNR { a[$1]=$2; next } $1 in a { print $0, a[$1] }' lookup.txt main.txt

# Diff two files
awk 'NR==FNR { a[$0]=1; next } !($0 in a)' file1 file2   # lines in file2 not in file1
```

---



---

[← Previous](09-5-awk-text-processing-language.md) | [↑ Index](index.md) | [Next →](11-7-combining-tools.md)
