## 🔍 Section 5: Auditd — Linux Audit Framework

### How Auditd Works

The Linux Audit Framework is a kernel-level mechanism that captures security-relevant events. It works through:

1. **kauditd** — Kernel audit subsystem, intercepts syscalls
2. **auditd** — Userspace daemon that receives events from kauditd via **netlink socket**
3. **auditctl** — Tool to configure audit rules
4. **ausearch** — Tool to search audit logs
5. **aureport** — Tool to generate summary reports

```
  Application (e.g., sshd)
        │
        ▼  System call (execve, open, write)
   ┌─────────────┐
   │   Kernel    │
   │  (kauditd)  │ → Generates audit record
   └──────┬──────┘
          │ netlink socket (AF_NETLINK, NETLINK_AUDIT)
          ▼
   ┌─────────────┐
   │   auditd    │ → Writes to /var/log/audit/audit.log
   └─────────────┘
```

### Installation and Basic Configuration

```bash
sudo apt install -y auditd audispd-plugins
sudo systemctl enable --now auditd

# Check status
sudo auditctl -s
# Output: enabled 1 (1=running, 0=stopped)
```

### Configuration Files

**`/etc/audit/auditd.conf`** — Daemon settings:

```bash
sudo tee /etc/audit/auditd.conf > /dev/null << 'EOF'
#
# auditd.conf — Linux Audit Daemon Configuration
#
log_file = /var/log/audit/audit.log
log_format = RAW
log_group = adm
priority_boost = 4
flush = INCREMENTAL_ASYNC
freq = 50
num_logs = 5
max_log_file = 50
max_log_file_action = ROTATE
space_left = 75
space_left_action = SYSLOG
admin_space_left = 50
admin_space_left_action = SUSPEND
disk_full_action = SUSPEND
disk_error_action = SUSPEND
EOF

# Restart to apply
sudo systemctl restart auditd
```

### Audit Rules — /etc/audit/rules.d/audit.rules

```bash
sudo tee /etc/audit/rules.d/audit.rules > /dev/null << 'EOF'
# /etc/audit/rules.d/audit.rules

# Remove any existing rules
-D

# Buffer size (must be large enough for all rules)
-b 8192

# Failure mode
# 0 = silent, 1 = printk (print to kernel log), 2 = panic
-f 1

# --- File and directory watches ---

# Watch /etc/passwd for writes (w), attribute changes (a)
-w /etc/passwd -p wa -k passwd_changes

# Watch /etc/shadow
-w /etc/shadow -p wa -k shadow_changes

# Watch /etc/group
-w /etc/group -p wa -k group_changes

# Watch /etc/sudoers
-w /etc/sudoers -p wa -k sudoers_changes

# Watch /etc/ssh/sshd_config
-w /etc/ssh/sshd_config -p wa -k sshd_config

# Watch entire /etc for suspicious changes
-w /etc/ -p wa -k etc_changes

# Watch /root
-w /root -p wa -k rootdir_changes

# --- System call auditing ---

# Audit all privilege escalation (setuid, setgid) attempts
-a always,exit -F arch=b64 -S execve -C uid!=euid -F euid=0 -k priv_esc
-a always,exit -F arch=b32 -S execve -C uid!=euid -F euid=0 -k priv_esc

# Audit user/group ID changes
-a always,exit -F arch=b64 -S setuid -S setgid -S setreuid -S setregid -S setresuid -S setresgid -k identity
-a always,exit -F arch=b32 -S setuid -S setgid -S setreuid -S setregid -S setresuid -S setresgid -k identity

# Audit time changes
-a always,exit -F arch=b64 -S adjtimex -S settimeofday -S clock_settime -k time_change
-a always,exit -F arch=b32 -S adjtimex -S settimeofday -S clock_settime -k time_change

# Audit module loading/unloading
-w /sbin/insmod -p x -k modules
-w /sbin/modprobe -p x -k modules
-w /sbin/rmmod -p x -k modules

# Audit mount operations
-a always,exit -F arch=b64 -S mount -S umount2 -k mount
-a always,exit -F arch=b32 -S mount -S umount2 -k mount

# Audit deletion and renaming of files
-a always,exit -F arch=b64 -S unlink -S unlinkat -S rename -S renameat -k deletion
-a always,exit -F arch=b32 -S unlink -S unlinkat -S rename -S renameat -k deletion

# Audit failed login attempts (via pam, sshd)
-w /var/log/faillog -p wa -k logins
-w /var/log/lastlog -p wa -k logins

# Audit network environment changes
-a always,exit -F arch=b64 -S sethostname -S setdomainname -k network_env
-a always,exit -F arch=b32 -S sethostname -S setdomainname -k network_env

# Make the configuration immutable (-e 2) — requires reboot to change
# Leave commented until rules are finalized
# -e 2
EOF

# Apply rules
sudo auditctl -R /etc/audit/rules.d/audit.rules

# Or restart auditd
sudo systemctl restart auditd
```

### Viewing Active Rules

```bash
sudo auditctl -l
# Example output:
# -w /etc/passwd -p wa -k passwd_changes
# -w /etc/shadow -p wa -k shadow_changes
# -a always,exit -S execve -F arch=b64 -F uid!=euid -F euid=0 -k priv_esc
```

### Searching Audit Logs with ausearch

```bash
# Search for events with a specific key
sudo ausearch -k passwd_changes

# Search by user ID
sudo ausearch -au 1000

# Search by command
sudo ausearch -c sudo

# Search by time range
sudo ausearch -ts 10:00:00 -te 11:00:00

# Search for successful/failed syscalls
sudo ausearch --success yes -k priv_esc
sudo ausearch --success no -k priv_esc

# Search for login events
sudo ausearch -m USER_LOGIN -sv no

# Output as interpreted text (default)
sudo ausearch -k passwd_changes -i

# Interpret UIDs/GIDs as names
sudo ausearch -k passwd_changes -ui
```

### Generating Reports with aureport

```bash
# Summary report of all events
sudo aureport

# Authentication report
sudo aureport -au

# Login report
sudo aureport -l

# User activity summary
sudo aureport -u

# Failed events summary
sudo aureport --failed

# Time-based report (last hour)
sudo aureport -ts now-1h

# Executable/command report
sudo aureport -x

# File access summary
sudo aureport -f

# Export to CSV for analysis in spreadsheets
sudo aureport -f --csv > /tmp/audit-file-report.csv
```

### Watching Specific Files and Syscalls

```bash
# Watch a specific file for reads, writes, and attribute changes
sudo auditctl -w /etc/resolv.conf -p rwa -k resolv_changes

# Watch a directory recursively
sudo auditctl -w /srv/critical_data/ -p wa -k critical_data

# Watch a specific syscall on all processes
sudo auditctl -a always,exit -F arch=b64 -S openat -S open -F path=/etc/shadow -F perm=r -k shadow_read

# Monitor all connect() syscalls (outgoing network connections)
sudo auditctl -a always,exit -F arch=b64 -S connect -k outbound_conn
```

### Audit Log Interpretation

A raw audit log line:

```
type=SYSCALL msg=audit(1719234567.890:12345): 
  arch=c000003e syscall=2 success=no exit=-13 
  a0=7ffe5a1b3f10 a1=0 a2=1fffff a3=7ffe5a1b1b50 
  items=1 ppid=2345 pid=3456 auid=1000 uid=1000 gid=1000 
  euid=1000 suid=1000 fsuid=1000 egid=1000 sgid=1000 fsgid=1000 
  tty=pts0 ses=3 comm="cat" exe="/usr/bin/cat" 
  subj=unconfined_u:unconfined_r:unconfined_t:s0-s0:c0.c1023 
  key="shadow_read"
```

| Field | Meaning |
|-------|---------|
| `syscall=2` | Syscall number 2 = open (on x86_64) |
| `success=no` | The syscall failed |
| `exit=-13` | Returned -13 (EACCES — Permission denied) |
| `uid=1000` | Real user ID |
| `auid=1000` | Login UID (original login user) |
| `comm="cat"` | Command name |
| `exe="/usr/bin/cat"` | Full path to executable |
| `subj=...` | SELinux context |
| `key="shadow_read"` | The audit rule key |

---



---

[← Previous](05-section-4-openscap.md) | [↑ Index](index.md) | [Next →](07-section-6-file-integrity-monitoring.md)
