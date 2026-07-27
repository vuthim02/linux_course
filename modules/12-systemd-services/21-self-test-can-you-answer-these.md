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

---

*Linux SysAdmin Course | Part 12 of ∞ | Reverse Engineering Approach*
*Previous → Part 11: Package Management — apt, dnf, yum, snap*
*Next → Part 13: Scheduling Tasks — cron, at, systemd timers*

[← Previous](part11.md) | [Next →](part13.md)


---

[← Previous](20-whats-coming-in-part-13.md) | [↑ Index](index.md)
