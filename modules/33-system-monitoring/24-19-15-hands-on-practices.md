## 19. 15 Hands-On Practices

### Level 1 Practices: Basic Monitoring

#### Practice 1: Identify Top CPU Consumers

```bash
$ top -b -n 1 | head -20
$ ps aux --sort=-%cpu | head -10
$ htop  # interactive, press P to sort by CPU
```

Write a one-liner that lists the top 5 CPU consumers with PID, %CPU, and command:
```bash
$ ps aux --sort=-%cpu | awk 'NR>1 {print $2, $3, $11}' | head -5
```

#### Practice 2: Identify Top Memory Consumers

```bash
$ top -b -n 1 -o %MEM | head -15
$ ps aux --sort=-%mem | head -10
$ ps -eo pid,pmem,rss,comm --sort=-pmem | head -5
```

#### Practice 3: Analyze I/O Bottlenecks with `iostat`

**Setup:** Simulate I/O load:
```bash
$ dd if=/dev/zero of=/tmp/testfile bs=1M count=1000 &
```

**Monitor:**
```bash
$ iostat -x 1 10
```

Watch `r_await`, `w_await`, `%util`. Note what happens to `%iowait` in `mpstat`.

#### Practice 4: Monitor Network Connections with `ss`

```bash
# Show all listening services
$ ss -tulnp

# Count connections per state
$ ss -t | awk '{print $1}' | sort | uniq -c

# Find process listening on port 8080
$ ss -tulnp | grep 8080
```

#### Practice 5: Track Swap Usage

```bash
$ free -h -s 2
$ vmstat 2
$ swapon --show
```

Create a stress test:
```bash
$ stress --vm 2 --vm-bytes 2G --timeout 30
```

Watch `si` and `so` in `vmstat`. Record peak swap rates.

### Level 2 Practices: Intermediary Monitoring

#### Practice 6: Create a Monitoring Dashboard with `glances`

```bash
# Run glances with CSV export
$ glances --export csv --export-csv-file /tmp/glances.csv

# Run in server mode on remote host
$ glances -s -B 0.0.0.0

# Connect from local machine
$ glances -c <remote-ip>

# Web interface
$ glances -w
$ curl http://localhost:61208/api/3/mem
```

#### Practice 7: Generate a Performance Baseline Report

Create a script that captures current system performance:
```bash
#!/bin/bash
# /tmp/baseline.sh - System Performance Baseline

REPORT="/tmp/baseline-$(date +%Y%m%d-%H%M).txt"

{
echo "=========================================="
echo "  SYSTEM PERFORMANCE BASELINE"
echo "  Generated: $(date)"
echo "  Hostname: $(hostname)"
echo "=========================================="
echo ""

echo "--- CPU ---"
echo "Model: $(grep 'model name' /proc/cpuinfo | head -1 | cut -d: -f2)"
echo "Cores: $(nproc)"
echo ""

echo "--- Memory ---"
free -h
echo ""

echo "--- Disks ---"
lsblk -o NAME,SIZE,TYPE,MOUNTPOINT,FSTYPE
echo ""

echo "--- Network ---"
ip -br addr | grep -v lo
echo ""

echo "--- Load Average ---"
cat /proc/loadavg
echo ""

echo "--- Top 10 CPU Consumers ---"
ps aux --sort=-%cpu | head -11
echo ""

echo "--- Top 10 Memory Consumers ---"
ps aux --sort=-%mem | head -11
echo ""

echo "--- Filesystem Usage ---"
df -h
echo ""
} > "$REPORT"

cat "$REPORT"
```

#### Practice 8: `dstat` Plugin Exploration

```bash
# List all plugins
$ dstat --list

# Monitor top CPU, I/O, and memory processes
$ dstat --top-cpu --top-io --top-mem 2

# Save output to CSV
$ dstat -tcdngy --output /tmp/dstat-export.csv 5 10
```

#### Practice 9: Using `sar` for Historical Data

```bash
# Enable sar collection (if not already)
$ sudo systemctl enable sysstat
$ sudo systemctl start sysstat

# Report CPU usage from today
$ sar -u

# Report memory for a specific date
$ sar -r -f /var/log/sysstat/sa15

# Report disk I/O
$ sar -b

# Report network
$ sar -n DEV
```

#### Practice 10: Log Anomaly Detection

```bash
# Find authentication failures
$ journalctl -u sshd -p err --since "24 hours ago" | grep "Failed password"

# Count OOM occurrences
$ zgrep -c "OOM" /var/log/syslog*

# Monitor kernel errors in real-time
$ dmesg -w | grep -i error

# Use lnav for multi-log correlation
$ lnav /var/log/syslog /var/log/kern.log
```

### Level 3 Practices: Advanced Monitoring

#### Practice 11: Set Up Prometheus `node_exporter`

```bash
# Download and run
$ wget https://github.com/prometheus/node_exporter/releases/download/v1.7.0/node_exporter-1.7.0.linux-amd64.tar.gz
$ tar xzf node_exporter-1.7.0.linux-amd64.tar.gz
$ ./node_exporter-1.7.0.linux-amd64/node_exporter &

# Query metrics
$ curl http://localhost:9100/metrics | head -50

# Filter specific metrics
$ curl -s http://localhost:9100/metrics | grep "^node_cpu_seconds_total"
$ curl -s http://localhost:9100/metrics | grep "^node_memory_Mem"
```

#### Practice 12: Query S.M.A.R.T. Data

```bash
# Check overall health
$ sudo smartctl -H /dev/sda

# Run short test
$ sudo smartctl -t short /dev/sda
$ sleep 120
$ sudo smartctl -l selftest /dev/sda

# Extract key attributes
$ sudo smartctl -A /dev/sda | grep -E "Reallocated|Wear_Leveling|Temperature|Percent_Lifetime"

# JSON output for scripting
$ sudo smartctl -a /dev/sda --json | jq '.ata_smart_attributes.table[] | select(.id == 5 or .id == 177) | {id: .id, name: .name, value: .value, raw: .raw.value}'
```

#### Practice 13: Disk Health Monitoring with Alert

```bash
#!/bin/bash
# /usr/local/bin/disk-health-check.sh

THRESHOLD_REALLOC=10
THRESHOLD_TEMP=55

for disk in sda sdb sdc; do
    [ -b "/dev/$disk" ] || continue
    
    realloc=$(sudo smartctl -A "/dev/$disk" | awk '/Reallocated_Sector_Ct/ {print $10}')
    temp=$(sudo smartctl -A "/dev/$disk" | awk '/Temperature_Celsius/ {print $10}')
    
    echo "=== /dev/$disk ==="
    echo "Reallocated Sectors: $realloc"
    echo "Temperature: ${temp}°C"
    
    if [ "$realloc" -gt "$THRESHOLD_REALLOC" ]; then
        echo "ALERT: High reallocated sector count on $disk!"
    fi
    
    if [ "${temp%%.*}" -gt "$THRESHOLD_TEMP" ]; then
        echo "ALERT: High temperature on $disk!"
    fi
done
```

#### Practice 14: Monitor Specific Process with `top` in Batch

```bash
$ top -b -n 10 -d 2 -p 1 | grep "^  PID\|^    1 " > /tmp/init-cpu.log
$ cat /tmp/init-cpu.log
```

#### Practice 15: Real-World Integration — Comprehensive System Health Report

```bash
#!/bin/bash
# /usr/local/bin/system-health-report.sh

REPORT_DIR="/var/log/system-health"
mkdir -p "$REPORT_DIR"

OUTPUT="$REPORT_DIR/health-report-$(date +%Y%m%d-%H%M).txt"
EMAIL="admin@example.com"

{
echo "==========================================="
echo "  SYSTEM HEALTH REPORT"
echo "  Host: $(hostname)"
echo "  Date: $(date)"
echo "  Uptime: $(uptime -p)"
echo "==========================================="
echo ""

# ── SECTION 1: Critical Resource Status ──
echo "== [1] CRITICAL RESOURCE STATUS =="

# CPU Load
LOAD=$(cat /proc/loadavg | awk '{print $1}')
CORES=$(nproc)
echo "CPU Load (1min): $LOAD / $CORES cores"

# Memory
MEM_AVAIL=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
MEM_TOTAL=$(grep MemTotal /proc/meminfo | awk '{print $2}')
MEM_PCT=$(echo "scale=2; (1 - $MEM_AVAIL / $MEM_TOTAL) * 100" | bc)
echo "Memory Usage: ${MEM_PCT}%"

# Swap
SWAP_USED=$(free -m | awk '/Swap:/ {print $3}')
echo "Swap Used: ${SWAP_USED}M"

# Disk
df -h --type=ext4 --type=xfs | tail -n+2 | while read line; do
    pct=$(echo "$line" | awk '{print $5}' | sed 's/%//')
    mount=$(echo "$line" | awk '{print $6}')
    [ "$pct" -gt 90 ] 2>/dev/null && echo "  ⚠ WARNING: $mount is ${pct}% full"
done

echo ""

# ── SECTION 2: Performance Metrics ──
echo "== [2] PERFORMANCE METRICS =="

# CPU breakdown
mpstat -P ALL 1 1 | tail -n+4 | head -n-1
echo ""

# Disk I/O
iostat -x 1 1 | tail -n+4 | head -n-1 | grep -v "^loop"
echo ""

# Network connections summary
echo "TCP Connection States:"
ss -t | awk '{print $1}' | sort | uniq -c | sort -rn
echo ""

# Top 5 by CPU
echo "Top 5 CPU Consumers:"
ps aux --sort=-%cpu | head -6 | awk '{print $2, $3"%", $11}'
echo ""

# Top 5 by memory
echo "Top 5 Memory Consumers:"
ps aux --sort=-%mem | head -6 | awk '{print $2, $4"%", $11}'
echo ""

# ── SECTION 3: Services Status ──
echo "== [3] CRITICAL SERVICES =="
for svc in sshd nginx mysql docker prometheus node_exporter; do
    systemctl is-active --quiet "$svc" 2>/dev/null
    if [ $? -eq 0 ]; then
        echo "  ✓ $svc is running"
    else
        echo "  ✗ $svc is NOT running (or not installed)"
    fi
done
echo ""

# ── SECTION 4: Disk Health ──
echo "== [4] DISK HEALTH (S.M.A.R.T.) =="
for disk in $(lsblk -d -o NAME | grep -v "^loop\|NAME"); do
    if smartctl -H "/dev/$disk" &>/dev/null; then
        status=$(sudo smartctl -H "/dev/$disk" | grep "SMART overall-health" | awk -F: '{print $2}')
        echo "  /dev/$disk: $status"
    fi
done
echo ""

# ── SECTION 5: Recent Errors ──
echo "== [5] RECENT SYSTEM ERRORS (last 24h) =="
journalctl -p err --since "24 hours ago" | tail -20
echo ""

echo "==========================================="
echo "  END OF HEALTH REPORT"
echo "==========================================="
} > "$OUTPUT"

cat "$OUTPUT"

# Optionally email
# mail -s "Health Report $(hostname) $(date +%Y-%m-%d)" "$EMAIL" < "$OUTPUT"
```

**Usage:**
```bash
# Run manually
$ sudo bash /usr/local/bin/system-health-report.sh

# Add to cron for daily report
$ sudo crontab -e
0 6 * * * /usr/local/bin/system-health-report.sh
```





[← Previous](23-18-command-reference.md) | [↑ Index](index.md) | [Next →](25-20-self-test.md)
