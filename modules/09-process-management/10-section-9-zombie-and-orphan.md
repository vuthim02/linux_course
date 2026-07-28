## 🔍 Section 9: Zombie and Orphan Processes

### Zombie Processes

A **zombie** is a process that has finished executing but still has an entry in the process table because its parent hasn't read its exit status.

```bash
# Find zombies
ps aux | grep Z
# Or:
top -b -n 1 | grep zombie

# Zombies show STAT = Z in ps
```

**Can you kill a zombie?** No. A zombie is already dead. It's just waiting for its parent to call `wait()`. The only ways to remove zombies:
1. Kill the parent process (zombies are inherited by init which reaps them)
2. The parent calls `wait()` to collect the exit status

### Orphan Processes

When a parent dies before its child, the child becomes an **orphan**. Orphans are adopted by PID 1 (systemd/init), which periodically calls `wait()` to clean them up.

```bash
# Orphans are normal and harmless
# They just get re-parented to PID 1
```





[← Previous](09-section-8-proc-the-process.md) | [↑ Index](index.md) | [Next →](11-practice-section-15-hands-on-exercises.md)
