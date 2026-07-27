## 💻 Level 3 Practices

### ✅ Practice 1: Process Substitution

```bash
cd ~/linux-course/part5

# Compare two directory listings
diff <(ls /etc) <(ls /etc/default)

# Count files matching pattern in two locations
echo "Confs in /etc: $(ls /etc/*.conf 2>/dev/null | wc -l)"
echo "Confs in /etc/nginx: $(ls /etc/nginx/*.conf 2>/dev/null | wc -l)"

# Use diff on command outputs
diff <(ps aux | sort) <(ps aux | sort)  # Should show no difference
```

---

### ✅ Practice 2: File Descriptors

```bash
cd ~/linux-course/part5

# Create custom file descriptors
exec 3> fd3_output.txt
exec 4> fd4_output.txt

# Write to them
echo "Message for FD 3" >&3
echo "Message for FD 4" >&4
echo "Normal stdout message"

# Close them
exec 3>&-
exec 4>&-

# Verify
cat fd3_output.txt
cat fd4_output.txt
```

---

### ✅ Practice 3: Real SysAdmin Scenario — Build a System Report

```bash
cd ~/linux-course/part5

# Build a comprehensive system report using redirection
{
  echo "========================================"
  echo "  SYSTEM REPORT - $(date)"
  echo "  Hostname: $(hostname)"
  echo "  User: $(whoami)"
  echo "========================================"
  echo ""
  echo "--- UPTIME ---"
  uptime
  echo ""
  echo "--- DISK USAGE ---"
  df -h
  echo ""
  echo "--- MEMORY ---"
  free -h
  echo ""
  echo "--- RUNNING PROCESSES (top 10 by CPU) ---"
  ps aux --sort=-%cpu | head -11
  echo ""
  echo "--- OPEN PORTS ---"
  ss -tlnp 2>/dev/null
  echo ""
  echo "--- LAST 5 LOGIN ATTEMPTS ---"
  last -5 2>/dev/null || echo "No login records"
  echo ""
  echo "========================================"
  echo "  END OF REPORT"
  echo "========================================"
} > system_report_$(date +%Y%m%d).txt 2>&1

# View the report
less system_report_*.txt

# Or email it (if mail command is available):
# mail -s "System Report $(hostname) $(date)" admin@example.com < system_report_*.txt
```

---



---

[← Previous](18-deep-understanding-how-streams-really.md) | [↑ Index](index.md) | [Next →](20-summary-complete-command-reference.md)
