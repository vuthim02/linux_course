## 🔍 Section 3: grep in Practice — Log Investigation Workflow

When something breaks, this is how a sysadmin uses grep to investigate:

### Step 1: Check for Errors

```bash
# Quick check: any errors since last boot?
journalctl -p err -b | grep -i "fail\|error\|critical"
```

### Step 2: Find the Time Window

```bash
# Find when errors started
grep -n "ERROR" /var/log/app.log | head -5
# Shows line numbers — find the first error line
```

### Step 3: Get Context

```bash
# Show 10 lines before and after the first error
grep -n "ERROR" /var/log/app.log | head -1 | cut -d: -f1
# Then check that line in context
LINE=245
sed -n "$((LINE-10)),$((LINE+10))p" /var/log/app.log
```

### Step 4: Find Related Events

```bash
# Search for a specific session/request ID near the error
grep "SessionID: abc123" /var/log/app.log
```

### Step 5: Aggregated Report

```bash
# What types of errors occur most frequently?
grep -oE "\[ERROR\] [a-zA-Z ]+" log.txt | sort | uniq -c | sort -rn
```

---



---

[← Previous](03-section-2-regular-expressions-the.md) | [↑ Index](index.md) | [Next →](05-section-4-find-advanced-file.md)
