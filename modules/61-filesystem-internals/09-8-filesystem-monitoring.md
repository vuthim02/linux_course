## 8. Filesystem Monitoring

### Proactive Monitoring Script

```bash
#!/bin/bash
# fs_monitor.sh — Monitor filesystem health
set -euo pipefail

THRESHOLD=80
INODE_THRESHOLD=90

echo "=== Filesystem Health Report ==="
echo "Timestamp: $(date)"
echo ""

# Disk space
echo "Disk Space:"
df -h | grep -E "^/dev/" | while read line; do
    usage=$(echo "$line" | awk '{print $5}' | tr -d '%')
    mount=$(echo "$line" | awk '{print $6}')
    if [ "$usage" -gt "$THRESHOLD" ]; then
        echo "  ⚠️  WARNING: $mount at ${usage}%"
    else
        echo "  ✅ OK: $mount at ${usage}%"
    fi
done

echo ""
echo "Inode Usage:"
df -i | grep -E "^/dev/" | while read line; do
    usage=$(echo "$line" | awk '{print $5}' | tr -d '%')
    mount=$(echo "$line" | awk '{print $6}')
    if [ "$usage" -gt "$INODE_THRESHOLD" ]; then
        echo "  ⚠️  WARNING: $mount inodes at ${usage}%"
    else
        echo "  ✅ OK: $mount inodes at ${usage}%"
    fi
done

echo ""
echo "Filesystem Errors:"
sudo dmesg | grep -i "error\|corrupt\|readonly" | tail -5
```

### SMART Monitoring for Disk Health

```bash
# Check disk health
sudo smartctl -a /dev/sda

# Key attributes to watch:
# Reallocated_Sector_Ct: Growing = disk failing
# Current_Pending_Sector: Sectors waiting to be reallocated
# Offline_Uncorrectable: Uncorrectable sectors

# Run short test
sudo smartctl -t short /dev/sda

# View test results
sudo smartctl -l selftest /dev/sda
```





[← Previous](08-7-filesystem-performance-tuning.md) | [↑ Index](index.md) | [Next →](10-9-practical-recovery-scenarios.md)
