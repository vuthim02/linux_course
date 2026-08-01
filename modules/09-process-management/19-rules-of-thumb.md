## 📏 Rules of Thumb

### The Kill Rules

| Rule | Description | Why |
|------|-------------|-----|
| **Always try SIGTERM first** | Gives process time to clean up | Prevents data loss |
| **Wait before SIGKILL** | Give process 5-10 seconds | Graceful shutdown |
| **Never SIGKILL databases** | Can corrupt data | Data integrity |
| **Check exit codes** | `echo $?` after kill | Verify success |
| **Use pkill for patterns** | Match by name, not PID | Efficiency |

### The Process Investigation Rules

| Rule | Description | Why |
|------|-------------|-----|
| **Check /proc first** | Most info is there | Complete picture |
| **Use ps for snapshots** | Quick overview | Fast |
| **Use top for real-time** | Dynamic view | Continuous monitoring |
| **Use htop for interactive** | Better UI | Easier navigation |

### The "Process Won't Die" Checklist

```bash
# 1. Try SIGTERM:
kill PID

# 2. Wait 5 seconds:
sleep 5

# 3. Check if still running:
ps -p PID

# 4. Try SIGKILL:
kill -9 PID

# 5. Check if zombie:
ps -p PID -o state=
# If state = Z, it's a zombie

# 6. Kill the parent:
kill $(ps -o ppid= -p PID)
```

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

### The zombie Cleanup Rules

```bash
# Zombies can't be killed directly:
kill -9 PID    # Doesn't work on zombies

# Must kill the parent:
ps -o ppid= -p PID    # Find parent PID
kill PARENT_PID        # Kill parent

# Or wait for init to reap:
# (init/PID 1 automatically reaps zombies)
```

---

**Why these rules matter:** Following these rules prevents data loss and system instability. The kill sequence alone prevents most process-related emergencies.

[← Previous](15-self-test-can-you-answer-these.md) | [↑ Index](index.md)
