## 🔍 Section 7: nice and renice — Process Priority

Linux schedules processes based on **niceness** (NI). Higher nice value = lower priority.

### Nice Values

```
-20 (highest priority)  ←── Only root can set negative values
  0 (default)
 19 (lowest priority)   ←── Anyone can set this
```

### Starting a Process With Different Priority

```bash
# Start with low priority (nice = 10)
nice -n 10 ./backup.sh

# Start with high priority (requires root)
sudo nice -n -10 ./urgent_task.sh

# Default nice is 10 if no value given
nice ./script.sh
```

### Changing Priority of Running Process

```bash
# Make PID 1234 lower priority (nicer to other processes)
renice 10 -p 1234

# Make PID 1234 higher priority (needs root)
sudo renice -5 -p 1234

# Renice by user (all processes)
renice 10 -u alice

# Renice by group
renice 10 -g developers
```

### Viewing Nice Values

```bash
# Show nice values in ps
ps -eo pid,ni,comm

# In top, press 'r' to renice, or sort by NI with '<' and '>'
```





[← Previous](07-section-6-nohup-disown-and.md) | [↑ Index](index.md) | [Next →](09-section-8-proc-the-process.md)
