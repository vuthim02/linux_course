## 📝 Self-Test — Can You Answer These?

1. What is the difference between `apt update` and `apt upgrade`?
2. What is the purpose of `unattended-upgrades`?
3. What does `apt-mark hold nginx` do?
4. Why should you always check what will be upgraded before confirming?
5. What three update channels does Ubuntu provide?
6. Why are kernel updates especially impactful?
7. How do you check if a reboot is required after updates?
8. How does DNF's rollback (`dnf history undo`) work?
9. What is the difference between LTS and rolling release?
10. How do you see what changed in a package before upgrading?
11. What is the purpose of `full-upgrade` vs `upgrade`?
12. Why should you always keep at least one old kernel?
13. How do you check disk space before an update?
14. What is package pinning and when would you use it?
15. How do security updates reach your system from upstream developers?

**Score:** 12/15 correct = ready for Part 21.


## Answer Key

### Q1: What is the difference between `apt update` and `apt upgrade`?
**Answer:** `update` refreshes the package index (list of available packages). `upgrade` installs newer versions of already-installed packages.

### Q2: What is the purpose of `unattended-upgrades`?
**Answer:** Automatically installs security updates without manual intervention. Essential for server security.

### Q3: What does `apt-mark hold nginx` do?
**Answer:** Prevents nginx from being upgraded during `apt upgrade`. The package stays at its current version.

### Q4: Why should you always check what will be upgraded before confirming?
**Answer:** Unexpected upgrades may break dependencies, restart services, or introduce incompatible changes. Review prevents production issues.

### Q5: What three update channels does Ubuntu provide?
**Answer:** `-security` (critical security fixes), `-updates` (bug fixes and non-security improvements), and `-backports` (newer software from later releases).

### Q6: Why are kernel updates especially impactful?
**Answer:** They affect all running processes, may change drivers/APIs, require reboot, and can introduce or fix security vulnerabilities at the deepest level.

### Q7: How do you check if a reboot is required after updates?
**Answer:** `needs-restarting -r` (RHEL) or check for `/var/run/reboot-required` (Ubuntu/Debian).

### Q8: How does DNF's rollback (`dnf history undo`) work?
**Answer:** DNF records transaction history. `dnf history undo <ID>` reverses a specific transaction by removing/upgrading packages back.

### Q9: What is the difference between LTS and rolling release?
**Answer:** LTS provides stable, supported releases for years. Rolling release (Arch, openSUSE Tumbleweed) continuously updates with latest versions.

### Q10: How do you see what changed in a package before upgrading?
**Answer:** `apt-cache changelog package` or `rpm -q --changelog package` — shows the changelog entries.

### Q11: What is the purpose of `full-upgrade` vs `upgrade`?
**Answer:** `full-upgrade` can remove conflicting packages if needed. `upgrade` will never remove packages (may skip some upgrades).

### Q12: Why should you always keep at least one old kernel?
**Answer:** If the new kernel fails to boot, you can select the old kernel from GRUB as a recovery option.

### Q13: How do you check disk space before an update?
**Answer:** `df -h /` — checks available space on the root partition before running upgrades.

### Q14: What is package pinning and when would you use it?
**Answer:** Pinning locks a package to a specific version. Use when a newer version is known to be incompatible with your setup.

### Q15: How do security updates reach your system from upstream developers?
**Answer:** Upstream → Distro security team reviews and packages → Security repo → `apt update && apt upgrade` (or `unattended-upgrades`).


*Linux SysAdmin Course | Part 20 of ∞ | Reverse Engineering Approach*



[← Previous](16-whats-coming-in-part-21.md) | [↑ Index](index.md)
