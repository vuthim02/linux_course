## 📏 Rules of Thumb

### The Monitoring Rules

| Rule | Description | Why |
|------|-------------|-----|
| **Monitor CPU, memory, disk, network** | The four pillars | Complete picture |
| **Set up alerts** | Know before users | Proactive |
| **Check baseline** | Know what's normal | Context |
| **Log everything** | Debug later | Evidence |

### The "System Slow" Checklist

```bash
# 1. Check load average:
uptime

# 2. Check CPU usage:
top -o %CPU

# 3. Check memory usage:
free -h

# 4. Check I/O wait:
vmstat 1 5

# 5. Check swap usage:
free -h
```

---

**Why these rules matters:** Following these rules helps you catch problems before they become emergencies.

[← Previous](25-20-self-test.md) | [↑ Index](index.md)
