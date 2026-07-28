## 🔍 Section 2: SELinux — Modes and Policies

### Three Modes of SELinux

| Mode | Behavior |
|------|----------|
| **Enforcing** | Policy enforced, denials logged and BLOCKED |
| **Permissive** | Policy not enforced, denials only LOGGED |
| **Disabled** | SELinux turned off completely |

```bash
# Check current mode
getenforce

# Check mode with more detail
sestatus

# Set mode temporarily (until reboot)
sudo setenforce 0    # Permissive
sudo setenforce 1    # Enforcing

# Set mode permanently (in /etc/selinux/config)
sudo cat /etc/selinux/config
```

Output of `sestatus`:

```
SELinux status:                 enabled
SELinuxfs mount:                /sys/fs/selinux
SELinux root directory:         /etc/selinux
Loaded policy name:             targeted
Current mode:                   enforcing
Mode from config file:          enforcing
Policy MLS status:              enabled
Policy deny_unknown status:     allowed
Memory protection checking:     actual (secure)
Max kernel policy version:      33
```

### SELinux Policies

```bash
# Policy types:
# targeted  — Only specific daemons are confined (default)
# minimum   — Minimal policy (subset of targeted)
# mls       — Multi-Level Security (military grade)

# Installed policies
ls /etc/selinux/

# Policy files
ls /etc/selinux/targeted/
```

### Disabling SELinux (Not Recommended)

```bash
# Edit /etc/selinux/config:
# SELINUX=disabled

# Then reboot (SELinux fully disabled)
# Or change to permissive first, then disable later

# Better: Use permissive mode for troubleshooting:
setenforce 0
# Then fix the issue, then setenforce 1
```





[← Previous](03-section-1-dac-vs-mac.md) | [↑ Index](index.md) | [Next →](05-level-2-intermediary-selinux-contexts.md)
