## 7. Combining Tools

### 7.1 Piping sed + awk + grep

```bash
# Pipeline: extract, transform, summarize
grep -E '^[0-9]{2}/[A-Za-z]{3}/[0-9]{4}' access.log | \
    sed 's/\[//g; s/\]//g' | \
    awk '{ print $1, $4 }' | \
    sort | uniq -c | sort -rn | head -20

# Find all config files, extract port settings
find /etc -name '*.conf' -exec grep -l '^port\b' {} \; | \
    xargs awk '/^port\s/ { print FILENAME, $0 }' | \
    sed 's/:\s*/ = /'

# Parse syslog, filter severity, format output
grep CRITICAL /var/log/syslog | \
    sed 's/^[A-Za-z0-9 ]* [0-9:]* //' | \
    awk '{ printf "[%-5s] %s\n", $1, $0 }' | \
    column -t
```

### 7.2 Extracting Structured Data From Unstructured Logs

```bash
#!/bin/bash
# parse_multiline_log.sh — extract multi-line stack traces

# Input: Java stack traces spanning multiple lines
# Output: One line per exception: timestamp, type, message

grep -E '^[0-9]{4}-[0-9]{2}-[0-9]{2}|Exception|Caused by' app.log | \
    awk '
    /^[0-9]{4}-/ {
        if (exc) print ts, exc, msg
        ts = $1" "$2
        exc = ""
        msg = ""
        next
    }
    /Exception/ {
        exc = $0
        next
    }
    /Caused by/ {
        if (!msg) msg = $0
    }
    END {
        if (exc) print ts, exc, msg
    }' | \
    column -t
```

### 7.3 Processing Output of Other Commands

```bash
# Disk usage by user (requires quota)
find /home -maxdepth 1 -type d | while read dir; do
    du -sk "$dir" 2>/dev/null
done | awk '{total += $1; print $0} END {print "Total (MB):", total/1024}'

# Package sizes (Debian)
dpkg-query -Wf '${Installed-Size} ${Package}\n' | \
    sort -rn | \
    awk 'BEGIN {print "Package Size (MB)"} {printf "%-30s %5.2f\n", $2, $1/1024}' | \
    head -20

# Process tree
ps -eo pid,ppid,cmd --no-headers | \
    awk '{ children[$2] = children[$2] " " $1; procs[$1] = $3 }
    END {
        for (p in procs) {
            printf "%s (%s)\n", procs[p], p
            if (children[p]) {
                split(children[p], kids)
                for (i in kids) printf "  \\_ %s (%s)\n", procs[kids[i]], kids[i]
            }
        }
    }'
```

---



---

[← Previous](10-6-awk-admin-patterns.md) | [↑ Index](index.md) | [Next →](12-8-cut-sort-uniq-wc.md)
