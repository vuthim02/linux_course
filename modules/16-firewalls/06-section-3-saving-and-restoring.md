## 🔍 Section 3: Saving and Restoring iptables Rules

iptables rules are **volatile** — they disappear on reboot unless saved.

```bash
# Save rules (Debian/Ubuntu)
sudo apt install iptables-persistent
sudo netfilter-persistent save
# Rules saved to /etc/iptables/rules.v4
# and /etc/iptables/rules.v6

# Save rules (Fedora/RHEL)
sudo dnf install iptables-services
sudo service iptables save
# Rules saved to /etc/sysconfig/iptables

# Manual save and restore
sudo iptables-save > /etc/iptables-backup.rules
sudo iptables-restore < /etc/iptables-backup.rules
```

---



---

[← Previous](05-level-2-intermediary-managing-firewall.md) | [↑ Index](index.md) | [Next →](07-section-4-firewalld.md)
