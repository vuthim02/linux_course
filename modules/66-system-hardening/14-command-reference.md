## 📋 Command Reference

| Task | Command |
|------|---------|
| View sysctl value | `sysctl kernel.randomize_va_space` |
| Set sysctl | `sysctl -w kernel.randomize_va_space=2` |
| Load sysctl file | `sysctl -p /etc/sysctl.d/99-hardening.conf` |
| Check mount options | `mount \| grep /tmp` |
| Mount tmpfs | `mount -t tmpfs -o noexec,nosuid,nodev tmpfs /tmp` |
| List SUID binaries | `find / -xdev -perm -4000 -type f 2>/dev/null` |
| Set immutable | `chattr +i /etc/passwd` |
| Remove immutable | `chattr -i /etc/passwd` |
| View immutable | `lsattr /etc/passwd` |
| Install auditd | `apt install auditd audispd-plugins -y` |
| Add audit watch | `auditctl -w /etc/passwd -p wa -k identity` |
| List audit rules | `auditctl -l` |
| Load audit rules | `augenrules --load` |
| Search audit logs | `ausearch -k identity --start today` |
| Audit report | `aureport --summary` |
| Test audit filter | `fail2ban-regex log filter.conf` |
| fail2ban status | `fail2ban-client status sshd` |
| Unban IP | `fail2ban-client set sshd unbanip 1.2.3.4` |
| Lynis audit | `lynis audit system` |
| Lynis score | `grep hardening_index /var/log/lynis-report.dat` |
| AIDE init | `aide --init` |
| AIDE check | `aide --check` |
| AIDE update | `aide --update` |
| OpenSCAP scan | `oscap xccdf eval --profile cis --results r.xml content.xml` |
| OpenSCAP fix | `oscap xccdf generate fix --fix-type bash --output fix.sh r.xml` |
| Check kernel lockdown | `cat /sys/kernel/security/lockdown` |
| View GRUB config | `cat /etc/default/grub` |
| Update GRUB | `update-grub` (Debian) or `grub2-mkconfig -o /boot/grub2/grub.cfg` (RHEL) |
| Check kernel ASLR | `cat /proc/sys/kernel/randomize_va_space` |
| List running services | `systemctl list-units --type=service --state=running` |

---



---

[← Previous](13-deep-understanding.md) | [↑ Index](index.md) | [Next →](15-whats-coming-in-part-67.md)
