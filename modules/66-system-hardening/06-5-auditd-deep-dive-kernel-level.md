## 5. auditd Deep Dive — Kernel-Level Monitoring

### Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     AUDIT SUBSYSTEM                           │
│                                                               │
│  User Space                                                  │
│  ┌──────────┐  ┌───────────┐  ┌───────────┐  ┌───────────┐ │
│  │ auditctl │  │ ausearch  │  │ aureport  │  │ audispd   │ │
│  │ (rules)  │  │ (query)   │  │ (summary) │  │ (dispatch)│ │
│  └────┬─────┘  └─────┬─────┘  └─────┬─────┘  └─────┬─────┘ │
│       │              │              │              │         │
│  ─────┴──────────────┴──────────────┴──────────────┴─────── │
│                                                               │
│  Kernel Space                                                │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │              auditd Kernel Module                        │ │
│  │  ┌──────────┐  ┌──────────────┐  ┌──────────────────┐  │ │
│  │  │ syscall  │  │ file watch   │  │ MAC audit        │  │ │
│  │  │ auditing │  │ (inotify)    │  │ (LSM events)     │  │ │
│  │  └──────────┘  └──────────────┘  └──────────────────┘  │ │
│  │           audit buffer (ring buffer in kernel)           │ │
│  └─────────────────────────────────────────────────────────┘ │
│                         │                                     │
│                   /var/log/audit/audit.log                     │
└─────────────────────────────────────────────────────────────┘
```

### Installation and Basic Configuration

```bash
# Install auditd
apt install auditd audispd-plugins -y   # Debian/Ubuntu
yum install audit audit-libs -y          # RHEL/CentOS

# Start and enable
systemctl enable auditd
systemctl start auditd

# Main config: /etc/audit/auditd.conf
# Key settings:
#   max_log_file = 50          # MB per log file
#   num_logs = 5               # number of log files to keep
#   max_log_file_action = ROTATE
#   space_left = 100           # MB free space warning
#   action_mail_acct = root
#   flush = INCREMENTAL_ASYNC   # flush to disk periodically
```

### Building Audit Rules

```bash
# View current rules
auditctl -l

# === DELETE ALL EXISTING RULES (use with caution) ===
# auditctl -D

# === RULE 1: Monitor /etc/passwd changes ===
auditctl -w /etc/passwd -p wa -k passwd_changes
# -w = watch path, -p wa = write+attribute, -k = key for searching

# === RULE 2: Monitor /etc/shadow ===
auditctl -w /etc/shadow -p wa -k shadow_changes

# === RULE 3: Monitor sudoers ===
auditctl -w /etc/sudoers -p wa -k sudoers_changes
auditctl -w /etc/sudoers.d/ -p wa -k sudoers_changes

# === RULE 4: Monitor user/group commands ===
auditctl -a always,exit -F arch=b64 -S execve -F path=/usr/sbin/useradd -k user_add
auditctl -a always,exit -F arch=b64 -S execve -F path=/usr/sbin/userdel -k user_del
auditctl -a always,exit -F arch=b64 -S execve -F path=/usr/sbin/usermod -k user_mod
auditctl -a always,exit -F arch=b64 -S execve -F path=/usr/sbin/groupadd -k group_add

# === RULE 5: Monitor network connections (for server) ===
auditctl -a always,exit -F arch=b64 -S connect -k network_connect

# === RULE 6: Monitor kernel module loading ===
auditctl -a always,exit -F arch=b64 -S init_module -S finit_module -k module_load

# === RULE 7: Monitor all commands run by root ===
auditctl -a always,exit -F arch=b64 -S execve -F euid=0 -F auid>=1000 -F auid!=4294967295 -k root_commands

# === RULE 8: Monitor cron changes ===
auditctl -w /etc/crontab -p wa -k cron_changes
auditctl -w /etc/cron.d/ -p wa -k cron_changes
auditctl -w /var/spool/cron/ -p wa -k cron_changes
```

### Persistent Rules File

```bash
# /etc/audit/rules.d/hardening.rules
cat > /etc/audit/rules.d/hardening.rules << 'RULES'



[← Previous](05-4-filesystem-hardening.md) | [↑ Index](index.md) | [Next →](07-6-cis-hardening-audit-rules.md)
