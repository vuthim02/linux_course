## CIS Hardening Audit Rules

# Delete all existing rules (clean slate)
-D

# Set buffer size (8MB)
-b 8192

# Failure mode: 1=printk, 2=panic
-f 1

# === Identity Rules ===
-w /etc/passwd -p wa -k identity
-w /etc/group -p wa -k identity
-w /etc/shadow -p wa -k identity
-w /etc/gshadow -p wa -k identity
-w /etc/security/opasswd -p wa -k identity

# === Authorization ===
-w /etc/sudoers -p wa -k sudoers
-w /etc/sudoers.d/ -p wa -k sudoers

# === Login/logout ===
-w /var/log/lastlog -p wa -k logins
-w /var/run/faillock/ -p wa -k logins
-w /var/log/wtmp -p wa -k logins
-w /var/log/btmp -p wa -k logins

# === File deletion ===
-a always,exit -F arch=b64 -S unlink -S unlinkat -S rename -S renameat -F auid>=1000 -F auid!=4294967295 -k file_deletion

# === Privileged commands ===
-a always,exit -F arch=b64 -S execve -F path=/usr/bin/su -F perm=x -k priv_escalation
-a always,exit -F arch=b64 -S execve -F path=/usr/bin/sudo -F perm=x -k priv_escalation
-a always,exit -F arch=b64 -S execve -F path=/usr/bin/passwd -F perm=x -k priv_escalation
-a always,exit -F arch=b64 -S execve -F path=/usr/bin/chsh -F perm=x -k priv_escalation
-a always,exit -F arch=b64 -S execve -F path=/usr/bin/newgrp -F perm=x -k priv_escalation

# === Kernel modules ===
-w /sbin/insmod -p x -k modules
-w /sbin/rmmod -p x -k modules
-w /sbin/modprobe -p x -k modules
-a always,exit -F arch=b64 -S init_module -S delete_module -k modules

# === Time changes ===
-w /etc/localtime -p wa -k time_change

# === System hostname ===
-a always,exit -F arch=b64 -S sethostname -S setdomainname -k system_network

# === /etc/issue (banner) ===
-w /etc/issue -p wa -k system_info
-w /etc/issue.net -p wa -k system_info

# Make rules immutable (requires reboot to change)
-e 2
RULES

# Load rules
augenrules --load
```

> ⚠️ **Warning:** `-e 2` makes rules immutable until reboot. If you add `-e 2` without loading all your rules first, you'll need to reboot to add more. Always add `-e 2` as the very last line.

### Querying Audit Logs

```bash
# Search by key
ausearch -k passwd_changes --start today

# Search for all events from a specific user
ausearch -ua 1000 --start today

# Search for failed syscalls
ausearch -m SYSCALL -sc failed

# Search for specific executable
ausearch -x /usr/bin/sudo --start this-week

# Generate summary report
aureport --summary

# Report on failed login attempts
aureport --auth --summary --failed

# Report on file access
aureport -f --summary

# Report on executable usage
aureport -x --summary

# Full daily report
aureport --date today
```

### audit2allow and audit2why

```bash
# When SELinux/AppArmor blocks a process, audit generates "denied" messages.
# These tools help you understand and fix denials.

# Capture denials from last 10 minutes
ausearch -m avc --start recent

# Convert denials to policy module (SELinux)
ausearch -m avc --start recent | audit2allow -M my_module
# Creates: my_module.te (type enforcement), my_module.pp (compiled policy)

# Install the module
semodule -i my_module.pp

# See WHY something was denied (more educational)
ausearch -m avc --start recent | audit2why
# Output explains:
#   type=AVC ... denied { read } for pid=1234 comm="httpd"
#   Suggested: setsebool -P httpd_read_user_content 1

# For AppArmor: parse audit log
grep "apparmor=\"DENIED\"" /var/log/syslog | audit2allow -M apparmor_fix
```

### Real-World Audit Scenario

```bash
# Detect potential intrusion: find who ran suspicious commands
ausearch -k root_commands --start today | \
  aureport --summary

# Find who modified sshd_config
ausearch -k passwd_changes --start 2026-07-20 --end 2026-07-26 | \
  ausearch -f /etc/ssh/sshd_config

# Detect privilege escalation attempts
ausearch -k priv_escalation --start today | \
  aureport --auth --summary

# Find processes that opened network connections as root
ausearch -k network_connect -ua 0 | \
  ausearch -x /usr/bin/curl
```

> 🔍 **Reverse Engineering Insight:** The audit subsystem runs inside the kernel itself. Even if an attacker deletes logs from syslog or journald, audit records in `/var/log/audit/audit.log` are harder to tamper with (and should be on a separate partition with immutable attributes). This is why CIS mandates auditd — it's your last line of defense for forensic evidence.

---



---

[← Previous](06-5-auditd-deep-dive-kernel-level.md) | [↑ Index](index.md) | [Next →](08-6-fail2ban-automated-intrusion-prevention.md)
