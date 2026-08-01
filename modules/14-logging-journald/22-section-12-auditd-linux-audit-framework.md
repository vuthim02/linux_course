## 🔍 Section 12: auditd — The Linux Audit Framework

`auditd` is the kernel-level audit system that logs security-relevant events. Unlike `journalctl` which captures what processes log, `auditd` captures what the kernel sees.

### Quick Start

```bash
# Check status
sudo systemctl status auditd
sudo auditctl -s                # Status: enabled, pid, rate limit

# Enable/disable auditing
sudo auditctl -e 1              # Enable
sudo auditctl -e 0              # Disable
```

### File Watch Rules

```bash
# -w = watch path, -p = permissions, -k = key name

# Watch /etc/passwd for changes
sudo auditctl -w /etc/passwd -p wa -k passwd_changes

# Watch /etc/shadow for all access
sudo auditctl -w /etc/shadow -p rwxa -k shadow_access

# Watch /usr/bin for any binary modification
sudo auditctl -w /usr/bin -p wa -k bin_changes

# Watch SSH config
sudo auditctl -w /etc/ssh/sshd_config -p wa -k ssh_config

# List all rules
sudo auditctl -l
```

### Syscall Rules

```bash
# -a = add, always = always log, exit = on syscall exit
# -S = syscall name, -F = field filter

# Log all openat calls by user 1000
sudo auditctl -a always,exit -S openat -F uid=1000 -k user_open

# Log all setuid/setgid calls
sudo auditctl -a always,exit -S setuid -S setgid -S setreuid -S setregid -k priv_esc
```

### Permanent Rules

```bash
# Rules in /etc/audit/rules.d/ — survive reboot
sudo tee /etc/audit/rules.d/custom.rules << 'EOF'
-w /etc/passwd -p wa -k passwd_changes
-w /etc/shadow -p wa -k shadow_access
-w /etc/sudoers -p wa -k sudoers_changes
-a always,exit -S openat -F uid=0 -k root_open
EOF

# Reload rules without restart
sudo augenrules --load
# Or restart
sudo systemctl restart auditd
```

### Searching with ausearch

```bash
# Search by key
sudo ausearch -k passwd_changes

# Search by user
sudo ausearch -ua 1000             # UID 1000
sudo ausearch -ui bob              # Username "bob"

# Search by time
sudo ausearch -ts today
sudo ausearch -ts 09:00 -te 17:00
sudo ausearch --start 07/29/2025 --end 07/30/2025

# Search by syscall
sudo ausearch -sc openat

# Interpret numeric values
sudo ausearch -i
```

### Reports with aureport

```bash
# Login summary
sudo aureport --login --summary

# Failed events
sudo aureport --failed

# User summary
sudo aureport -u --summary

# Executable summary
sudo aureport -x --summary

# Time range
sudo aureport -ts today -te now --login
```

### Practical Security Monitoring

```bash
# Monitor for sudo use
sudo auditctl -w /etc/sudoers -p wa -k sudoers_changes
sudo ausearch -k sudoers_changes -ts today

# Detect brute force SSH
sudo ausearch -m USER_LOGIN --failed -ts today

# Track file access on sensitive paths
sudo auditctl -w /home/secret-project -p rwxa -k project_access

# Audit all command execution by a specific user
sudo auditctl -a always,exit -S execve -F uid=1000 -k user_cmds
```

### auditd Log Files

```bash
# Main log
/var/log/audit/audit.log

# View raw events
sudo tail -f /var/log/audit/audit.log

# Disk usage
du -sh /var/log/audit/

# Configure auditd: /etc/audit/auditd.conf
# max_log_file = 8        # Size in MB before rotation
# max_log_file_action = ROTATE
# num_logs = 5
# space_left_action = EMAIL
```



[← Previous](21-section-11-logger-and-systemd-cat.md) | [↑ Index](index.md) | [Next →](23-section-13-coredumpctl-crash-analysis.md)
