## 📝 Self-Test — Can You Answer These?

1. What is the difference between `systemctl start` and `systemctl enable`?
2. What is a systemd "unit"? Name at least 4 types.
3. Where do system distribution unit files live? Where do admin overrides go?
4. What does `systemctl daemon-reload` do and when must you run it?
5. What is the difference between `Type=simple` and `Type=forking` in a service file?
6. What does `Restart=on-failure` do?
7. How do you view logs for a specific service?
8. What is a systemd target and how does it relate to old SysV runlevels?
9. What is the difference between `journalctl -u nginx` and `tail /var/log/nginx/access.log`?
10. How do you create a systemd timer?
11. What does `systemd-analyze blame` show?
12. What is the difference between masking and disabling a service?
13. How do you prevent a service from being started accidentally?
14. What is a drop-in override and why is it safer than editing the unit file directly?
15. How does systemd track all processes of a service even if they fork?

**Score:** 12/15 correct = ready for Part 13.


## Answer Key

### Q1: What is the difference between `systemctl start` and `systemctl enable`?
**Answer:** `start` activates a service immediately. `enable` configures it to start automatically at boot.

### Q2: What is a systemd "unit"? Name at least 4 types.
**Answer:** A unit is a systemd configuration file describing a system resource. Types: `.service`, `.socket`, `.timer`, `.mount`, `.target`, `.path`, `.slice`.

### Q3: Where do distribution unit files live? Where do admin overrides go?
**Answer:** Distribution: `/lib/systemd/system/`. Admin overrides: `/etc/systemd/system/` (takes priority).

### Q4: What does `systemctl daemon-reload` do?
**Answer:** Reloads systemd's unit file configuration after you modify any unit file. Required before restarting a modified service.

### Q5: What is the difference between `Type=simple` and `Type=forking`?
**Answer:** `simple`: the main process is the service itself. `forking`: the service forks and the parent exits (traditional daemon behavior).

### Q6: What does `Restart=on-failure` do?
**Answer:** Systemd automatically restarts the service when it exits with a non-zero exit code (crash or error).

### Q7: How do you view logs for a specific service?
**Answer:** `journalctl -u service-name` — filters journald logs for that unit.

### Q8: What is a systemd target and how does it relate to SysV runlevels?
**Answer:** A target groups services for a system state. `multi-user.target` = runlevel 3, `graphical.target` = runlevel 5.

### Q9: What is the difference between `journalctl -u nginx` and `tail /var/log/nginx/access.log`?
**Answer:** `journalctl` shows systemd journal logs (structured, filtered by unit). `tail` reads the application's own log file directly.

### Q10: How do you create a systemd timer?
**Answer:** Create a `.timer` unit file specifying `OnCalendar=` and a matching `.service` unit. Example: `OnCalendar=daily` triggers the service once per day.

### Q11: What does `systemd-analyze blame` show?
**Answer:** Lists all units sorted by initialization time, showing which services slow down boot.

### Q12: What is the difference between masking and disabling?
**Answer:** `disable` prevents auto-start at boot but manual start is possible. `mask` completely prevents starting (even manually) by symlinking to `/dev/null`.

### Q13: How do you prevent a service from being started accidentally?
**Answer:** `systemctl mask service-name` — creates a symlink to `/dev/null`, blocking all start attempts.

### Q14: What is a drop-in override and why is it safer than editing the unit file?
**Answer:** A drop-in is a `.conf` file in `/etc/systemd/system/service.d/` that overrides specific directives without modifying the original unit file (survives package updates).

### Q15: How does systemd track all processes of a service even if they fork?
**Answer:** Systemd uses cgroups. All child processes inherit the service's cgroup, so systemd can track them regardless of PID changes.


*Linux SysAdmin Course | Part 12 of ∞ | Reverse Engineering Approach*
*Previous → Part 11: Package Management — apt, dnf, yum, snap*
*Next → Part 13: Scheduling Tasks — cron, at, systemd timers*

[← Previous](part11.md) | [Next →](part13.md)



[← Previous](20-whats-coming-in-part-13.md) | [↑ Index](index.md)
