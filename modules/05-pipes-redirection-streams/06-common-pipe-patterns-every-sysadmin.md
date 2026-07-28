## 🔍 Common Pipe Patterns Every SysAdmin Should Know

### Pattern 1: Find and Count

```bash
# Count total files
find /etc -type f | wc -l

# Count lines containing "error" in logs
grep -r "ERROR" /var/log/ | wc -l
```

### Pattern 5: Unique IPs From Access Log

```bash
grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" /var/log/nginx/access.log | sort -u | wc -l
```

### Pattern 7: Create a Report

```bash
{
  echo "=== System Report $(date) ==="
  echo "--- Disk Usage ---"
  df -h
  echo "--- Memory ---"
  free -h
  echo "--- Uptime ---"
  uptime
  echo "--- Running Services ---"
  systemctl list-units --type=service --state=running
} > system_report.txt
```

### Pattern 8: Pipe Output to a Pager

```bash
# When output is very long
dmesg | less
journalctl -xe | less
ps aux | less

# Search within output interactively
dmesg | grep "error" | less
```





[← Previous](05-section-4-pipes-the-heart.md) | [↑ Index](index.md) | [Next →](07-level-1-practices.md)
