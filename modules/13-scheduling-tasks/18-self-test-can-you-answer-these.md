## 📝 Self-Test — Can You Answer These?

1. What are the five fields of a crontab entry (in order)?
2. What is the difference between a system crontab (`/etc/crontab`) and a user crontab?
3. How do you prevent cron from mailing you output?
4. What does `@daily` mean in crontab syntax?
5. Why should you always use full paths in cron jobs?
6. What is the `at` command used for?
7. How do you list pending `at` jobs?
8. What is `batch` and how is it different from `at`?
9. Name two features systemd timers have that cron does not.
10. How do you check if a cron job actually ran?
11. What does `Persistent=true` do in a systemd timer?
12. What is the `RandomizedDelaySec` directive used for?
13. What is `run-parts` and where is it used?
14. How do you add a script to run daily via cron?
15. What happens to cron output if MAILTO is not set?

**Score:** 12/15 correct = ready for Part 14.


## Answer Key

### Q1: What are the five fields of a crontab entry (in order)?
**Answer:** Minute (0-59), Hour (0-23), Day of Month (1-31), Month (1-12), Day of Week (0-7, 0 and 7 = Sunday).

### Q2: What is the difference between a system crontab and a user crontab?
**Answer:** `/etc/crontab` is the system crontab (includes a user field). User crontabs (`crontab -e`) run as the user who owns them — no user field.

### Q3: How do you prevent cron from mailing you output?
**Answer:** Redirect output to `/dev/null`: `0 3 * * * /path/script.sh > /dev/null 2>&1`

### Q4: What does `@daily` mean in crontab syntax?
**Answer:** Shorthand for `0 0 * * *` — runs once daily at midnight.

### Q5: Why should you always use full paths in cron jobs?
**Answer:** Cron has a minimal PATH. Without full paths, commands like `tar` or `grep` may not be found. Use `/usr/bin/tar` instead of `tar`.

### Q6: What is the `at` command used for?
**Answer:** Schedules a one-time job to run at a specific time. E.g., `echo "command" | at 3pm`.

### Q7: How do you list pending `at` jobs?
**Answer:** `atq` — shows all queued at jobs with their job numbers.

### Q8: What is `batch` and how is it different from `at`?
**Answer:** `batch` queues a job to run when system load drops below 1.5 (configurable). `at` runs at a specific time regardless of load.

### Q9: Name two features systemd timers have that cron does not.
**Answer:** 1) Built-in logging via journalctl, 2) Dependency management and resource control via cgroups, 3) Missed runs with `Persistent=true`.

### Q10: How do you check if a cron job actually ran?
**Answer:** Check `/var/log/syslog` for `CRON` entries, or redirect cron output to a log file, or check application-specific logs.

### Q11: What does `Persistent=true` do in a systemd timer?
**Answer:** If the system was off when the timer should have fired, it runs the missed job on the next boot.

### Q12: What is `RandomizedDelaySec`?
**Answer:** Adds a random delay (up to the specified seconds) to each timer firing, preventing thundering herd when many systems start simultaneously.

### Q13: What is `run-parts` and where is it used?
**Answer:** A utility that runs all executables in a directory. Used by `/etc/cron.daily/`, `/etc/cron.hourly/`, etc., to execute scheduled scripts.

### Q14: How do you add a script to run daily via cron?
**Answer:** Either add `0 2 * * * /path/to/script.sh` to your crontab, or place the script in `/etc/cron.daily/` and make it executable.

### Q15: What happens to cron output if MAILTO is not set?
**Answer:** Cron emails the output (stdout and stderr) to the task owner's local mailbox.


[← Previous](17-whats-coming-in-part-14.md) | [↑ Index](index.md) | [Next →](19-section-10-anacron-offline-scheduling.md)
