## 🧠 Deep Understanding — How Scheduling Really Works

### The cron Daemon Internals

```
1. crond starts at boot (from systemd or init)
2. Reads all crontab files into memory
3. Sleeps 60 seconds
4. Wakes up, checks if current time matches any entry
5. If match: forks a child process, executes command
6. Child's stdout/stderr is captured
7. If output exists: pipes to /usr/sbin/sendmail
8. Parent (crond) goes back to sleep
```

### Why cron Uses a Blank Line Requirement

The crontab parser reads line by line. When it encounters EOF without a newline on the last line, the last line may be ignored. The blank line ensures proper termination.

### The Timing Precision

cron has **minute-level** precision. If you need second-level precision:
- Use a script with a `sleep` loop
- Or use systemd timers with `OnCalendar=` specifying seconds:
  ```
  OnCalendar=*:*:00   # every minute at second 0
  OnCalendar=*:*:30   # every minute at second 30
  ```

### How `at` Stores Jobs

```bash
# at jobs are stored as files
ls /var/spool/at/  # or /var/spool/cron/atjobs/
# Each job is a file containing:
# - Environment variables
# - The command to run
# - Execution time (encoded in filename)

# The at daemon (atd) checks these files every 60 seconds
```

### Systemd Timer States

```
timer unit (loaded but inactive)
    ↓ enable
timer unit (wanted by timers.target)
    ↓ start
timer unit (active, waiting)
    ↓ OnCalendar matches
service unit (triggered, runs)
    ↓ service completes
timer unit (active, waiting for next trigger)
```

---



---

[← Previous](13-section-9-real-sysadmin-scheduling.md) | [↑ Index](index.md) | [Next →](15-practice-section-15-hands-on-exercises.md)
