## 🔍 More Pipe Patterns

### Pattern 2: Find Largest Files

```bash
find / -type f -size +100M 2>/dev/null | xargs ls -lhS 2>/dev/null | head -10
```

### Pattern 3: Top CPU-Consuming Processes

```bash
ps aux --sort=-%cpu | head -6
```

### Pattern 4: Most Frequent Commands in History

```bash
history | awk '{print $2}' | sort | uniq -c | sort -rn | head -10
```

### Pattern 6: Monitor Logs in Real Time

```bash
tail -f /var/log/syslog | grep --line-buffered "ERROR" | tee /tmp/errors.log
```

---



---

[← Previous](11-section-4-heredocs-and-herestrings.md) | [↑ Index](index.md) | [Next →](13-level-2-practices.md)
