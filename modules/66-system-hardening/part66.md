# 🐧 Linux System Administrator — Complete Course
## Part 66 of ∞: System Hardening — CIS Benchmarks, auditd, and Defense in Depth

---

> **Reverse Engineering Approach:** Every compromised server had a hardened version of itself running somewhere before the breach. System hardening isn't about making things perfect — it's about shrinking the attack surface until an attacker's job becomes impractical. This part dissects every layer of Linux hardening: CIS Benchmarks tell you *what* to fix, auditd tells you *what's happening*, fail2ban tells attackers *you're watching*, and AIDE tells you *what changed*. Together, they form a defense-in-depth strategy that turns a soft target into a hardened fortress.

---

## 🎯 What You Will Achieve

- Understand defense-in-depth philosophy and attack surface reduction
- Apply CIS Benchmark recommendations to a running Linux system
- Harden the kernel with sysctl tuning, ASLR, stack protectors, and kernel lockdown modes
- Secure filesystems with noexec, nosuid, nodev, and dedicated tmpfs partitions
- Master auditd: build rules, interpret logs, and trace syscalls
- Configure fail2ban with custom jails, filters, and action scripts
- Run Lynis security audits, interpret scores, and automate remediation
- Deploy AIDE for file integrity monitoring with daily baseline checks
- Combine OpenSCAP and Ansible for automated compliance enforcement

---

## 1. Defense in Depth — The Layered Security Model

### The Core Principle

No single security measure is enough. Defense in depth stacks multiple independent controls so that breaching one layer still leaves the attacker facing others.

```
┌──────────────────────────────────────────────────────────────┐
│                    ATTACK SURFACE                             │
│                                                               │
│  Layer 1: PHYSICAL                                            │
│  ├─ BIOS/UEFI passwords                                      │
│  ├─ Full-disk encryption (LUKS)                               │
│  └─ Secure Boot                                               │
│                                                               │
│  Layer 2: NETWORK                                             │
│  ├─ Firewall rules (iptables/nftables/firewalld)              │
│  ├─ fail2ban                                                  │
│  ├─ Network segmentation                                      │
│  └─ TLS everywhere                                            │
│                                                               │
│  Layer 3: OS KERNEL                                           │
│  ├─ Kernel hardening (sysctl)                                 │
│  ├─ Module signing                                            │
│  ├─ Kernel lockdown                                           │
│  └─ Seccomp / AppArmor / SELinux                              │
│                                                               │
│  Layer 4: FILESYSTEM                                          │
│  ├─ Mount options (noexec, nosuid, nodev)                     │
│  ├─ File integrity monitoring (AIDE)                          │
│  ├─ Proper permissions (least privilege)                      │
│  └─ Encryption at rest                                        │
│                                                               │
│  Layer 5: USER / AUTHENTICATION                               │
│  ├─ Strong passwords / PAM policies                           │
│  ├─ SSH hardening                                             │
│  ├─ Multi-factor authentication                               │
│  └─ Least-privilege sudo                                      │
│                                                               │
│  Layer 6: APPLICATION                                         │
│  ├─ Minimal packages installed                                │
│  ├─ Non-root service accounts                                 │
│  ├─ Sandboxing (containers, namespaces)                       │
│  └─ Input validation                                          │
│                                                               │
│  Layer 7: MONITORING & RESPONSE                               │
│  ├─ auditd (syscall tracing)                                  │
│  ├─ logwatch / journald                                       │
│  ├─ AIDE (integrity)                                          │
│  ├─ Lynis (continuous assessment)                             │
│  └─ Incident response plan                                   │
└──────────────────────────────────────────────────────────────┘
```

### Attack Surface Reduction Checklist

```bash
# Audit installed packages — remove what you don't need
dpkg --audit -l | grep "^ii"       # Debian/Ubuntu
rpm -qa --qf '%{NAME}\n' | wc -l    # RHEL/CentOS

# List listening services
ss -tlnp
systemctl list-units --type=service --state=running

# List running SUID/SGID binaries
find / -xdev -perm -4000 -type f 2>/dev/null   # SUID
find / -xdev -perm -2000 -type f 2>/dev/null   # SGID

# List open kernel modules
lsmod | wc -l
```

> 🔍 **Reverse Engineering Insight:** The average Linux server runs 150+ services, but a hardened web server might need only 5. Every unnecessary service is an unpatched door. Attack surface reduction is the single most effective hardening step.

### Common Attack Vectors on Linux

| Vector | Countermeasure |
|--------|---------------|
| SSH brute force | fail2ban, key-only auth, non-standard port |
| Exploited web app | AppArmor/SELinux, non-root, chroot |
| Kernel vulnerability | Kernel lockdown, ASLR, patching |
| Privilege escalation | SUID audit, sudo hardening, least privilege |
| Persistence via cron | auditd rules, AIDE monitoring |
| Lateral movement | Network segmentation, firewall |
| Supply chain | Image scanning, signed packages |

---

## 2. CIS Benchmarks — The Security Playbook

### What Are CIS Benchmarks?

The Center for Internet Security publishes vendor-specific hardening guides. Each benchmark contains hundreds of numbered rules, each with:

- **Description** — what the setting does
- **Rationale** — why it matters
- **Audit** — how to check compliance
- **Remediation** — how to fix non-compliance

### CIS Benchmark Levels

```
┌──────────────────────────────────────────────────┐
│              CIS BENCHMARK LEVELS                  │
├──────────────────────────────────────────────────┤
│                                                    │
│  Level I (Minimum Hygiene)                         │
│  ├─ Basic security controls                        │
│  ├─ Low risk of functionality impact               │
│  └─ Suitable for all systems                       │
│                                                    │
│  Level II (Defense in Depth)                       │
│  ├─ Additional controls for sensitive systems      │
│  ├─ May require additional testing                │
│  └─ Recommended for servers                        │
│                                                    │
│  Level III (High Security / Defense Only)          │
│  ├─ Maximum hardening                              │
│  ├─ May break applications                         │
│  └─ For high-security / classified systems         │
│                                                    │
└──────────────────────────────────────────────────┘
```

### Applying CIS Benchmarks Manually (Key Items)

```bash
# === CIS Item 1.1.1.1 — Disable unused filesystems ===
echo "install cramfs /bin/true" >> /etc/modprobe.d/disable-fs.conf
echo "install freevxfs /bin/true" >> /etc/modprobe.d/disable-fs.conf
echo "install udf /bin/true" >> /etc/modprobe.d/disable-fs.conf

# === CIS Item 1.1.1.4 — Disable USB storage ===
echo "install usb-storage /bin/true" >> /etc/modprobe.d/disable-fs.conf

# === CIS Item 1.3.1 — Ensure AIDE is installed ===
apt install aide -y    # or: yum install aide -y

# === CIS Item 3.1.1 — Disable IP forwarding (non-router) ===
sysctl -w net.ipv4.ip_forward=0
echo "net.ipv4.ip_forward = 0" >> /etc/sysctl.d/99-cis.conf

# === CIS Item 3.2.1 — Disable source routing ===
sysctl -w net.ipv4.conf.all.accept_source_route=0
sysctl -w net.ipv4.conf.default.accept_source_route=0

# === CIS Item 4.1.1 — Ensure auditing is enabled (audit=1) ===
grep -q "audit=1" /etc/default/grub || \
  sed -i 's/GRUB_CMDLINE_LINUX=""/GRUB_CMDLINE_LINUX="audit=1"/' /etc/default/grub
update-grub

# === CIS Item 5.2.4 — SSH: Set idle timeout ===
echo "ClientAliveInterval 300" >> /etc/ssh/sshd_config
echo "ClientAliveCountMax 2" >> /etc/ssh/sshd_config

# === CIS Item 5.2.10 — SSH: Disable X11 forwarding ===
echo "X11Forwarding no" >> /etc/ssh/sshd_config

# === CIS Item 5.4.1 — Set password expiration ===
sed -i 's/^PASS_MAX_DAYS.*/PASS_MAX_DAYS   90/' /etc/login.defs
sed -i 's/^PASS_MIN_DAYS.*/PASS_MIN_DAYS   7/'  /etc/login.defs
sed -i 's/^PASS_WARN_AGE.*/PASS_WARN_AGE   14/' /etc/login.defs
```

> ⚠️ **Warning:** Always test CIS changes on a staging system first. Some settings (like disabling filesystems or tightening SSH) can lock you out or break applications.

### Automated CIS Hardening with Scripts

```bash
# Download CIS-CAT (free scanner from CIS)
# or use OpenSCAP with CIS profiles (covered in Section 9)

# Using Ansible CIS role (popular community approach)
ansible-galaxy role install dev-sec.os-hardening

# In playbook:
# - role: dev-sec.os-hardening
#   vars:
#     os_auth_pw_max_age: 90
#     os_auth_pw_min_age: 7
#     os_auth_pw_remember_password: 5
```

### CIS Audit with OpenSCAP

```bash
# Install OpenSCAP
apt install libopenscap8 scap-security-guide -y   # Ubuntu
yum install openscap-scap-security-guide -y         # RHEL

# Scan against CIS benchmark
oscap xccdf eval \
  --profile xccdf_org.ssgproject.content_profile_cis_level1_server \
  --results /tmp/cis-results.xml \
  --report /tmp/cis-report.html \
  /usr/share/xml/scap/ssg/content/ssg-ubuntu2204-ds.xml

# View results
echo "Open /tmp/cis-report.html in a browser"
```

---

## 3. Kernel Hardening — sysctl and Beyond

### ASLR (Address Space Layout Randomization)

```bash
# Check current ASLR setting
cat /proc/sys/kernel/randomize_va_space
# 0 = Disabled, 1 = Partial (mmap), 2 = Full (stack + heap + mmap) ← recommended

# Enable full ASLR
sysctl -w kernel.randomize_va_space=2

# Make persistent
echo "kernel.randomize_va_space = 2" >> /etc/sysctl.d/99-hardening.conf
```

### Stack Protector and NX Bit

```bash
# Verify kernel compiled with stack protector
grep -i stack_protector /boot/config-$(uname -r)
# CONFIG_CC_STACKPROTECTOR=y
# CONFIG_CC_STACKPROTECTOR_STRONG=y

# Verify NX (No-Execute) support
grep -i nx /proc/cpuinfo | head -1
# flags: nx            ← present if CPU supports NX
```

### Kernel Lockdown Mode (Linux 5.4+)

```bash
# Three modes: none, integrity, confidentiality
# integrity: blocks unsigned kernel modules, /dev/mem writes
# confidentiality: also blocks reading kernel memory

# Set via boot parameter (recommended method)
sed -i 's/GRUB_CMDLINE_LINUX="/GRUB_CMDLINE_LINUX="lsm=lockdown /' /etc/default/grub
update-grub

# Or set at runtime (requires boot param for next reboot)
cat /sys/kernel/security/lockdown
# [none] integrity confidentiality
```

### Comprehensive sysctl Hardening

```bash
cat > /etc/sysctl.d/99-hardening.conf << 'EOF'
# === Network Hardening ===
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.all.log_martians = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1
net.ipv4.tcp_syncookies = 1
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0
net.ipv6.conf.all.accept_ra = 0

# === Kernel Hardening ===
kernel.randomize_va_space = 2
kernel.sysrq = 0
kernel.core_uses_pid = 1
kernel.dmesg_restrict = 1
kernel.kptr_restrict = 2
kernel.yama.ptrace_scope = 1

# === Filesystem Hardening ===
fs.suid_dumpable = 0
fs.protected_hardlinks = 1
fs.protected_symlinks = 1
EOF

# Apply all settings
sysctl -p /etc/sysctl.d/99-hardening.conf
```

> 🔍 **Reverse Engineering Insight:** `kptr_restrict = 2` prevents even root from reading `/proc/kallsyms` without CAP_SYSLOG, closing a kernel infoleak that rootkits exploit to find function addresses for hooking.

### Module Signing Enforcement

```bash
# Check if module signing is enabled
grep MODULE_SIG /boot/config-$(uname -r)
# CONFIG_MODULE_SIG=y
# CONFIG_MODULE_SIG_FORCE=y     ← rejects unsigned modules

# Verify a module's signature
modinfo -F signer /lib/modules/$(uname -r)/kernel/drivers/net/e1000/e1000.ko
```

---

## 4. Filesystem Hardening

### Mount Options: noexec, nosuid, nodev

```bash
# Mount /tmp with noexec, nosuid, nodev, tmpfs
echo "tmpfs /tmp tmpfs defaults,noexec,nosuid,nodev,size=2G 0 0" >> /etc/fstab

# Mount /var/tmp similarly
echo "tmpfs /var/tmp tmpfs defaults,noexec,nosuid,nodev,size=1G 0 0" >> /etc/fstab

# Remount /home without SUID (if no local builds needed)
# First back up data, then:
# /dev/sda3  /home  ext4  defaults,nosuid,nodev  0  2

# Remount /dev/shm restricted
mount -o remount,noexec,nosuid,nodev /dev/shm
```

> ⚠️ **Warning:** `noexec` on `/tmp` breaks programs that compile and run from `/tmp` (e.g., some installer scripts). Test in staging first.

### Dedicated Partition Layout

```
┌──────────────────────────────────────────────────┐
│              SECURE PARTITION LAYOUT               │
├──────────────────────────────────────────────────┤
│                                                    │
│  /           ext4  defaults,errors=remount-ro      │
│  /boot      ext4  defaults                        │
│  /boot/efi  vfat  umask=0077                       │
│  /home      ext4  defaults,nosuid,nodev            │
│  /tmp       tmpfs noexec,nosuid,nodev,size=2G      │
│  /var/tmp   tmpfs noexec,nosuid,nodev,size=1G      │
│  /var       ext4  defaults,nosuid                  │
│  /var/log   ext4  defaults,nosuid,nodev            │
│  /var/log/audit  ext4  defaults,nosuid,nodev       │
│  /dev/shm   tmpfs noexec,nosuid,nodev              │
│  /srv       ext4  defaults,nosuid,nodev            │
│                                                    │
└──────────────────────────────────────────────────┘
```

### File Permission Hardening

```bash
# CIS: Ensure no world-writable files
find / -xdev -type f -perm -0002 -exec chmod o-w {} \;

# CIS: Ensure no unowned files
find / -xdev -nouser -o -nogroup 2>/dev/null

# CIS: Set proper permissions on key files
chmod 600 /etc/shadow
chmod 600 /etc/gshadow
chmod 644 /etc/passwd
chmod 644 /etc/group
chmod 700 /root
chmod 600 /boot/grub/grub.cfg
chmod 700 /etc/cron.{hourly,daily,weekly,monthly}
chmod 600 /etc/crontab
chmod 700 /etc/cron.d
chmod 700 /etc/cron.daily
chmod 600 /etc/ssh/sshd_config

# Lock critical files with immutable attribute
chattr +i /etc/passwd
chattr +i /etc/shadow
chattr +i /etc/group
chattr +i /etc/gshadow
```

### Secure GRUB

```bash
# Set GRUB password
grub-mkpasswd-pbkdf2
# Enter password, get hash

# Add to /etc/grub.d/40_custom
set superusers="admin"
password_pbkdf2 admin grub.pbkdf2.sha512.10000...

# Set permissions
chmod 600 /boot/grub/grub.cfg
chmod 700 /boot/grub
```

---

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

## 6. fail2ban — Automated Intrusion Prevention

### Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      fail2ban ARCHITECTURE                    │
│                                                               │
│  Log Files                                                   │
│  /var/log/auth.log ◄──┐                                     │
│  /var/log/nginx/      │    ┌──────────────┐                  │
│  access.log    ───────┼───►│  fail2ban    │                  │
│  /var/log/apache2/    │    │  Server      │                  │
│  access.log    ───────┘    │              │                  │
│                            │  ┌────────┐  │                  │
│                            │  │ Filter │  │  Match patterns  │
│                            │  │ Engine │  │  in logs         │
│                            │  └────────┘  │                  │
│                            │  ┌────────┐  │                  │
│                            │  │  Jail  │  │  Ban rules       │
│                            │  │ Manager│  │                  │
│                            │  └────────┘  │                  │
│                            │  ┌────────┐  │                  │
│                            │  │ Action │  │  iptables/nft    │
│                            │  │ Engine │  │  + email + more  │
│                            │  └────────┘  │                  │
│                            └──────┬───────┘                  │
│                                   │                           │
│                            iptables/nftables                  │
│                            BAN <IP> for N seconds             │
└─────────────────────────────────────────────────────────────┘
```

### Installation

```bash
# Debian/Ubuntu
apt install fail2ban -y

# RHEL/CentOS (EPEL)
yum install epel-release -y
yum install fail2ban fail2ban-systemd -y

# Start (do NOT enable on RHEL — firewall conflict)
systemctl enable --now fail2ban

# Verify
fail2ban-client status
```

### Core Configuration

```bash
# NEVER edit /etc/fail2ban/jail.conf — it gets overwritten
# Create local overrides in /etc/fail2ban/jail.local

cat > /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
# Ban for 1 hour
bantime = 3600

# Detection window: 10 minutes
findtime = 600

# Ban after 5 failures
maxretry = 5

# Use systemd (modern) or syslog
backend = systemd

# Action: ban + email
banaction = iptables-multiport
action = %(action_mwl)s

# Whitelist local network and trusted IPs
ignoreip = 127.0.0.1/8 ::1 192.168.1.0/24 10.0.0.0/8

# SSH jail (enabled by default)
[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600
EOF
```

### Custom Jail: Nginx Brute Force

```bash
# Filter: /etc/fail2ban/filter.d/nginx-bruteforce.conf
cat > /etc/fail2ban/filter.d/nginx-bruteforce.conf << 'EOF'
[Definition]
failregex = ^<HOST> .* "(GET|POST|HEAD) .* HTTP/.*" (401|403) .*$
ignoreregex =
EOF

# Jail: add to /etc/fail2ban/jail.local
cat >> /etc/fail2ban/jail.local << 'EOF'
[nginx-bruteforce]
enabled  = true
port     = http,https
filter   = nginx-bruteforce
logpath  = /var/log/nginx/access.log
maxretry = 10
findtime = 300
bantime  = 3600
EOF

# Reload
fail2ban-client reload
```

### Custom Jail: WordPress Login

```bash
# /etc/fail2ban/filter.d/wordpress-login.conf
cat > /etc/fail2ban/filter.d/wordpress-login.conf << 'EOF'
[Definition]
failregex = ^<HOST> .* "POST /wp-login.php.*" 200 .*$
ignoreregex =
EOF

# Add jail
cat >> /etc/fail2ban/jail.local << 'EOF'
[wordpress-login]
enabled  = true
port     = http,https
filter   = wordpress-login
logpath  = /var/log/nginx/access.log
maxretry = 5
findtime = 600
bantime  = 7200
EOF
```

### Custom Action Script

```bash
# /etc/fail2ban/action.d/custom-alert.action
cat > /etc/fail2ban/action.d/custom-alert.action << 'ACTION'
[Definition]

actionstart =
actionstop =
actioncheck =

actionban = echo "<hostname> banned <ip> for <failures> failures at $(date)" >> /var/log/fail2ban-custom.log
            curl -s -X POST https://hooks.slack.com/services/YOUR/WEBHOOK/URL \
              -d '{"text":"Banned <ip> on <hostname> (<failures> failures)"}'

actionunban = echo "<hostname> unbanned <ip> at $(date)" >> /var/log/fail2ban-custom.log
ACTION

# Reference in jail
# [sshd]
# action = %(action_)s custom-alert
```

### Managing fail2ban

```bash
# Status of all jails
fail2ban-client status

# Status of specific jail
fail2ban-client status sshd

# Manually unban an IP
fail2ban-client set sshd unbanip 192.168.1.100

# Manually ban an IP
fail2ban-client set sshd banip 10.0.0.50

# Check banned IPs
iptables -L f2b-sshd -n --line-numbers

# Test a filter against a log
fail2ban-regex /var/log/auth.log /etc/fail2ban/filter.d/sshd.conf

# View fail2ban logs
journalctl -u fail2ban -f
```

---

## 7. Lynis — Security Auditing and Compliance

### What Is Lynis?

Lynis is an open-source security auditing tool for Unix-based systems. It performs an extensive scan of your system and provides a hardening score with actionable recommendations.

### Installation

```bash
# From package manager
apt install lynis -y      # Debian/Ubuntu
yum install lynis -y      # RHEL/CentOS (EPEL)

# From git (latest version)
cd /opt
git clone https://github.com/CISOfy/lynis.git
cd lynis
./lynis audit system
```

### Running a Full Audit

```bash
# Full system audit
sudo lynis audit system

# Example output (truncated):
# [+] Boot and services
# [+] Kernel
# [+] Memory and processes
# [+] Users, Groups and Authentication
# [+] Shells
# [+] File systems
# [+] Storage
# [+] NFS
# [+] Software: name services
# [+] Networking
# [+] Firewalls
# [+] SSH Support
# [+] SSH Software
# [+] PHP
# [+] Databases
# [+] LDAP
# [+] NTP
# [+] cryptography
# [+] Virtualization
# [+] Containers
# [+] Security frameworks
# [+] Software: file integrity
# [+] Software: logging
# [+] Insecure services
# [+] End of scan
#
#   Hardening index : 67 [##############       ]
#
#   Lynis security scan details:
#     Scan mode              : Full
#     Plugins enabled        : No
#
#   Follow-up:
#     - Show details of the scan (l): ?
#     - Show the menu for Lynis (--menu)
#
#   Best practice: Use "lynis show details <scan-id>" to review detailed information
```

### Understanding the Score

```
┌────────────────────────────────────────────────────────┐
│                LYNIS SCORE RANGES                        │
├────────────────────────────────────────────────────────┤
│                                                          │
│  0-30   : Very poor — critical issues                    │
│  31-50  : Poor — many vulnerabilities open               │
│  51-65  : Moderate — basic hardening done                 │
│  66-75  : Good — above average security                  │
│  76-85  : Very good — well-hardened system                │
│  86-100 : Excellent — maximum achievable (rare)           │
│                                                          │
│  Typical unhardened server: 35-50                         │
│  After CIS Level I:         60-70                         │
│  After full hardening:      75-85                         │
│                                                          │
└────────────────────────────────────────────────────────┘
```

### Viewing Detailed Results

```bash
# List all scans
lynis show scans

# View details of latest scan
scan_id=$(lynis show scans | tail -1 | awk '{print $NF}')
lynis show details $scan_id

# View only warnings
lynis show warnings

# View only suggestions
lynis show suggestions

# View specific category
lynis show details $scan_id | grep -A 5 "Networking"
```

### Remediation

```bash
# Each suggestion includes a hardening index and remediation info
# Example output from lynis show details:
#
#   [SSH-7404] SSH Warning: Protocol version 1 enabled [WARNING]!
#   ├─ Solution: Disable protocol version 1 in sshd_config
#   └─ Related: https://cisofy.com/lynis/controls/SSH-7404/
#
# Apply individual fixes:
# 1. Read the suggestion
# 2. Follow the remediation
# 3. Re-run lynis to verify improvement

# Common quick wins:
# - Enable password aging (PASS_MAX_DAYS in /etc/login.defs)
# - Disable unused filesystems (CIS Item 1.1.1)
# - Set proper permissions on critical files
# - Enable auditd
```

### Automating Lynis

```bash
# Cron job: daily audit at 3 AM
cat > /etc/cron.d/lynis-audit << 'EOF'
0 3 * * * root /usr/sbin/lynis audit system --cron --quiet --report-file /var/log/lynis-report.dat 2>/dev/null
EOF

# Parse daily score
grep "hardening_index" /var/log/lynis-report.dat

# Email report (with sendmail/mailx)
0 4 * * * root score=$(grep "hardening_index" /var/log/lynis-report.dat | cut -d= -f2); echo "Lynis Score: $score" | mail -s "Daily Lynis Audit" admin@example.com

# Web dashboard with lynis + custom script
# Write score + timestamp to CSV for Grafana
echo "$(date +%s),$(grep hardening_index /var/log/lynis-report.dat | cut -d= -f2)" >> /var/log/lynis-history.csv
```

> 🔍 **Reverse Engineering Insight:** Lynis doesn't actually fix anything — it only identifies issues. That's by design. Automated fixes can break production systems. Use Lynis as a diagnostic tool, then apply targeted remediation with your change management process.

---

## 8. AIDE — File Integrity Monitoring

### Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    AIDE WORKFLOW                              │
│                                                               │
│  STEP 1: INIT (Baseline)                                    │
│  ┌─────────────────────────────────────────────┐             │
│  │  aide --init                                │             │
│  │  Scans filesystem → generates baseline DB   │             │
│  │  Stored in: /var/lib/aide/aide.db.new       │             │
│  └─────────────────────────────────────────────┘             │
│                      │                                       │
│                      ▼                                       │
│  STEP 2: INSTALL (Activate baseline)                         │
│  ┌─────────────────────────────────────────────┐             │
│  │  cp /var/lib/aide/aide.db.new               │             │
│  │      /var/lib/aide/aide.db                  │             │
│  └─────────────────────────────────────────────┘             │
│                      │                                       │
│                      ▼                                       │
│  STEP 3: CHECK (Compare current vs baseline)                 │
│  ┌─────────────────────────────────────────────┐             │
│  │  aide --check                              │             │
│  │  Compares current state to aide.db          │             │
│  │  Reports: added, removed, changed files     │             │
│  └─────────────────────────────────────────────┘             │
│                      │                                       │
│                      ▼                                       │
│  STEP 4: UPDATE (Accept changes)                             │
│  ┌─────────────────────────────────────────────┐             │
│  │  aide --update                             │             │
│  │  Generates new DB with current state        │             │
│  │  cp aide.db.new aide.db                     │             │
│  └─────────────────────────────────────────────┘             │
│                      │                                       │
│                      ▼                                       │
│  Repeat STEP 3 → STEP 4 periodically                         │
└─────────────────────────────────────────────────────────────┘
```

### Installation and Configuration

```bash
# Install AIDE
apt install aide -y        # Debian/Ubuntu
yum install aide -y        # RHEL/CentOS

# Main config: /etc/aide.conf (Debian) or /etc/aide.conf (RHEL)
```

### AIDE Configuration Deep Dive

```bash
cat /etc/aide.conf | head -60

# Key settings in /etc/aide.conf:

# === Database locations ===
database_in=file:/var/lib/aide/aide.db
database_out=file:/var/lib/aide/aide.db.new

# === Gzip the database (recommended) ===
gzip_dbout=yes

# === Default rule sets ===
# p:  permissions    (file type + permissions)
# i:  inode          (inode number)
# n:  link count
# u:  user
# g:  group
# s:  size
# b:  block count
# m:  mtime
# a:  atime
# c:  ctime
# S:  check for growing size
# md5:    MD5 hash
# sha1:   SHA1 hash
# sha256: SHA256 hash (recommended)
# sha512: SHA512 hash

# === Rule definitions ===
NORMAL = p+i+n+u+g+s+m+c+sha256
PERMS  = p+u+g+acl+selinux+xattrs
LOG    = p+u+g+i+n+S
CONTENT = sha256+ftype
DATAONLY = p+n+u+g+s+acl+selinux+xattrs
DIR    = p+i+n+u+g

# === What to monitor ===
/etc            NORMAL
/bin            NORMAL
/sbin           NORMAL
/lib            NORMAL
/lib64          NORMAL
/usr/bin        NORMAL
/usr/sbin       NORMAL
/usr/lib        NORMAL
/boot           NORMAL
/usr/share      NORMAL

# === What to exclude ===
!/var/log
!/var/spool
!/var/cache
!/var/tmp
!/tmp
!/proc
!/sys
!/dev
!/run
!/var/lib/aide
!/var/lib/docker
!/var/lib/containerd
!/root/.ssh/known_hosts
!/var/lib/mlocate
!/var/lib/openssh/authorized_keys
```

### Running AIDE

```bash
# Step 1: Initialize baseline (takes 10-30 minutes on large systems)
sudo aide --init

# Output:
# AIDE, version 0.18.2
# AIDE found differences between database and filesystem!!
# ...
# Start timestamp: 2026-07-26 14:30:00
# Number of entries: 245678
# AIDE database initialization complete.

# Step 2: Activate the baseline
sudo cp /var/lib/aide/aide.db.new /var/lib/aide/aide.db

# Step 3: Check (daily)
sudo aide --check

# Output if changes detected:
# AIDE found differences between database and filesystem!!
# Summary:
#   Total number of entries:    245678
#   Added entries:              12
#   Removed entries:            3
#   Changed entries:            7
#
# Detailed changes:
#   /etc/passwd        : CHANGED  mtime, sha256
#   /etc/ssh/sshd_config: CHANGED  mtime, sha256, permissions
#   /tmp/malicious.sh   : ADDED
#   /usr/bin/suspicious  : ADDED

# If no changes:
# AIDE found no differences between database and filesystem.
# Everything looks clean.
```

### Automating AIDE with Daily Reports

```bash
# Daily check script
cat > /usr/local/bin/aide-check.sh << 'SCRIPT'
#!/bin/bash
REPORT="/var/log/aide/aide-check-$(date +%Y%m%d).log"
EMAIL="admin@example.com"

mkdir -p /var/log/aide

# Run check
aide --check > "$REPORT" 2>&1
exit_code=$?

if [ $exit_code -ne 0 ]; then
    # Changes detected
    mail -s "AIDE ALERT: File changes detected on $(hostname)" "$EMAIL" < "$REPORT"
    logger -t aide -p auth.alert "AIDE detected changes on $(hostname)"
else
    echo "$(date): AIDE check clean" >> /var/log/aide/aide-clean.log
fi
SCRIPT
chmod 700 /usr/local/bin/aide-check.sh

# Cron: run daily at 5 AM
echo "0 5 * * * root /usr/local/bin/aide-check.sh" > /etc/cron.d/aide-check
```

> ⚠️ **Warning:** After legitimate system updates (apt upgrade, yum update), you MUST run `aide --update` and copy the new database. Otherwise, every update will trigger false alerts.

### Protecting AIDE Database

```bash
# Store AIDE database on separate partition
# /etc/fstab:
# /dev/sdb1  /var/lib/aide  ext4  defaults,nosuid,nodev  0 2

# Set immutable attribute
chattr +i /var/lib/aide/aide.db
# (remove before aide --update, then re-set)

# Backup to off-system location
cp /var/lib/aide/aide.db /backup/aide/aide.db.$(date +%Y%m%d)
```

---

## 9. Automated Compliance — OpenSCAP and Ansible

### OpenSCAP

```bash
# Install
yum install openscap-scanner scap-security-guide -y
apt install libopenscap8 scap-security-guide -y

# List available profiles
oscap info /usr/share/xml/scap/ssg/content/ssg-rhel8-ds.xml | grep "Profile"

# RHEL/CentOS profiles:
#   - cis                 (CIS benchmark)
#   - cis_server_l1      (CIS Level 1)
#   - cis_server_l2      (CIS Level 2)
#   - standard            (Standard System Security)
#   - stig                (STIG for DoD)
#   - pci-dss             (PCI DSS compliance)

# Run a scan
oscap xccdf eval \
  --profile xccdf_org.ssgproject.content_profile_cis \
  --results /tmp/openscap-results.xml \
  --report /tmp/openscap-report.html \
  /usr/share/xml/scap/ssg/content/ssg-rhel8-ds.xml

# Remediate (auto-fix) — generates a script
oscap xccdf generate fix \
  --fix-type bash \
  --output /tmp/remediation.sh \
  /tmp/openscap-results.xml

# Review and apply
less /tmp/remediation.sh
# Then: bash /tmp/remediation.sh (after testing!)
```

### OpenSCAP in Cron

```bash
# Weekly scan with email
cat > /usr/local/bin/openscap-weekly.sh << 'SCRIPT'
#!/bin/bash
RESULT="/tmp/openscap-results-$(date +%Y%m%d).xml"
REPORT="/tmp/openscap-report-$(date +%Y%m%d).html"

oscap xccdf eval \
  --profile xccdf_org.ssgproject.content_profile_cis_server_l1 \
  --results "$RESULT" \
  --report "$REPORT" \
  /usr/share/xml/scap/ssg/content/ssg-$(cat /etc/os-release | grep ID | head -1 | cut -d'"' -f2)$(cat /etc/os-release | grep VERSION_ID | cut -d'"' -f2)-ds.xml 2>/dev/null

mail -s "OpenSCAP Report $(hostname)" admin@example.com < "$REPORT"
SCRIPT
chmod 700 /usr/local/bin/openscap-weekly.sh
echo "0 2 * * 0 root /usr/local/bin/openscap-weekly.sh" > /etc/cron.d/openscap-weekly
```

### Ansible Hardening Playbooks

```bash
# Install required roles
ansible-galaxy role install dev-sec.os-hardening
ansible-galaxy role install dev-sec.ssh-hardening
ansible-galaxy collection install devsec.hardening

# Playbook: full system hardening
cat > harden.yml << 'PLAYBOOK'
---
- name: System Hardening Playbook
  hosts: all
  become: true

  vars:
    # SSH hardening
    ssh_allow_groups: "wheel admin"
    ssh_max_auth_tries: 3
    ssh_permit_root_login: "no"
    ssh_x11_forwarding: "no"
    ssh_password_authentication: "no"

    # Kernel hardening
    sysctl_settings:
      net.ipv4.ip_forward: 0
      net.ipv4.conf.all.accept_redirects: 0
      net.ipv4.conf.all.send_redirects: 0
      net.ipv4.conf.all.rp_filter: 1
      kernel.randomize_va_space: 2
      kernel.dmesg_restrict: 1
      kernel.kptr_restrict: 2
      fs.suid_dumpable: 0
      fs.protected_hardlinks: 1
      fs.protected_symlinks: 1

    # Audit rules
    audit_rules: |
      -w /etc/passwd -p wa -k identity
      -w /etc/shadow -p wa -k identity
      -w /etc/sudoers -p wa -k sudoers
      -a always,exit -F arch=b64 -S execve -F euid=0 -F auid>=1000 -F auid!=4294967295 -k root_commands

  roles:
    - dev-sec.os-hardening
    - dev-sec.ssh-hardening

  tasks:
    - name: Install and configure AIDE
      apt:
        name: aide
        state: present
      when: ansible_os_family == "Debian"

    - name: Configure AIDE
      template:
        src: templates/aide.conf.j2
        dest: /etc/aide.conf
        owner: root
        group: root
        mode: '0600'

    - name: Configure fail2ban
      apt:
        name: fail2ban
        state: present

    - name: Deploy fail2ban local config
      template:
        src: templates/jail.local.j2
        dest: /etc/fail2ban/jail.local
        owner: root
        group: root
        mode: '0644'
      notify: restart fail2ban

    - name: Install Lynis
      apt:
        name: lynis
        state: present

    - name: Create AIDE daily cron
      cron:
        name: "AIDE daily check"
        hour: 5
        minute: 0
        job: "/usr/local/bin/aide-check.sh"

  handlers:
    - name: restart fail2ban
      systemd:
        name: fail2ban
        state: restarted
PLAYBOOK

# Run against all servers
ansible-playbook -i inventory.ini harden.yml --check   # Dry run first
ansible-playbook -i inventory.ini harden.yml            # Apply
```

### Compliance Verification Workflow

```
┌─────────────────────────────────────────────────────────────┐
│              COMPLIANCE VERIFICATION FLOW                     │
│                                                               │
│  1. BASELINE                                                  │
│     └─► Lynis scan → Score: 45                               │
│     └─► OpenSCAP scan → 87 failures                          │
│                                                               │
│  2. REMEDIATE                                                  │
│     └─► Ansible hardening playbook                            │
│     └─► Manual CIS fixes                                      │
│     └─► Deploy auditd rules                                   │
│                                                               │
│  3. VERIFY                                                     │
│     └─► Lynis scan → Score: 78                               │
│     └─► OpenSCAP scan → 3 failures (acceptable)              │
│     └─► AIDE initialized with clean baseline                  │
│                                                               │
│  4. MONITOR                                                    │
│     └─► Daily AIDE checks                                     │
│     └─► Weekly Lynis scans                                    │
│     └─► Monthly OpenSCAP scans                                │
│     └─► Continuous auditd monitoring                          │
│     └─► fail2ban active on all services                       │
│                                                               │
│  5. MAINTAIN                                                   │
│     └─► Update baselines after approved changes               │
│     └─► Review audit logs weekly                              │
│     └─► Re-scan after patches                                 │
│     └─► Track score trends in Grafana                         │
└─────────────────────────────────────────────────────────────┘
```

---

## 🛠️ Hands-On Practices

### Practice 1: Build a Hardened sysctl Configuration

```bash
# Create and apply a hardening sysctl file
cat > /etc/sysctl.d/99-hardening.conf << 'EOF'
kernel.randomize_va_space = 2
kernel.dmesg_restrict = 1
kernel.kptr_restrict = 2
kernel.sysrq = 0
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.all.rp_filter = 1
net.ipv4.tcp_syncookies = 1
EOF
sysctl -p /etc/sysctl.d/99-hardening.conf
```

✅ Expected: `sysctl` outputs each setting without errors; `cat /proc/sys/kernel/randomize_va_space` shows `2`

---

### Practice 2: Mount /tmp on tmpfs with Restrictions

```bash
echo "tmpfs /tmp tmpfs defaults,noexec,nosuid,nodev,size=2G 0 0" >> /etc/fstab
mount -a
mount | grep /tmp
```

✅ Expected: `/tmp` shows `tmpfs` type with `noexec,nosuid,nodev` options; `touch /tmp/test && chmod +x /tmp/test && /tmp/test` fails with "Permission denied"

---

### Practice 3: Configure and Test auditd

```bash
# Add a watch on /etc/passwd
auditctl -w /etc/passwd -p wa -k identity_test

# Make a change
echo "testuser:x:9999:9999::/nonexistent:/bin/false" >> /etc/passwd

# Search for the event
ausearch -k identity_test --start recent

# Clean up
sed -i '/testuser/d' /etc/passwd
auditctl -d -w /etc/passwd -p wa -k identity_test
```

✅ Expected: `ausearch` shows the write event to `/etc/passwd` with timestamp, user, and command

---

### Practice 4: Deploy fail2ban with SSH Jail

```bash
# Install and configure
apt install fail2ban -y
cat > /etc/fail2ban/jail.local << 'EOF'
[sshd]
enabled = true
port = ssh
maxretry = 3
bantime = 300
findtime = 60
EOF
systemctl restart fail2ban

# Test: fail login 4 times
for i in {1..4}; do
  ssh nonexistentuser@localhost -p 22 2>&1 | head -1
done

# Check ban status
fail2ban-client status sshd
iptables -L f2b-sshd -n
```

✅ Expected: After 3 failures, `fail2ban-client status sshd` shows `Currently banned: 1` and the IP appears in iptables

---

### Practice 5: Run a Lynis Audit and Interpret Results

```bash
# Install and run
apt install lynis -y
lynis audit system 2>&1 | tee /tmp/lynis-full.log

# Extract score
grep "hardening_index" /tmp/lynis-full.log

# View warnings only
lynis show warnings 2>/dev/null || grep "\[WARNING\]" /tmp/lynis-full.log

# View suggestions
grep "\[SUGGESTION\]" /tmp/lynis-full.log | head -20
```

✅ Expected: Score displayed (30-80 depending on current state); warnings show specific issues; suggestions provide actionable fixes

---

### Practice 6: Initialize AIDE Baseline

```bash
# Install
apt install aide -y

# Initialize
aide --init

# Activate baseline
cp /var/lib/aide/aide.db.new /var/lib/aide/aide.db

# Verify clean check
aide --check
```

✅ Expected: `aide --init` completes without error; `aide --check` reports "AIDE found no differences between database and filesystem"

---

### Practice 7: Detect Changes with AIDE

```bash
# After Practice 6 baseline, make changes
echo "malicious" > /etc/malicious.conf
chmod 777 /etc/malicious.conf

# Run check
aide --check

# Clean up and update baseline
rm /etc/malicious.conf
aide --update
cp /var/lib/aide/aide.db.new /var/lib/aide/aide.db
```

✅ Expected: AIDE reports `/etc/malicious.conf` as ADDED and `/etc/malicious.conf` permissions as CHANGED

---

### Practice 8: CIS Quick Wins — Disable Unused Filesystems

```bash
# Disable unused filesystems
for fs in cramfs freevxfs jffs2 hfs hfsplus squashfs udf vfat; do
  echo "install $fs /bin/true" >> /etc/modprobe.d/disable-fs.conf
done

# Verify
for fs in cramfs freevxfs jffs2 hfs hfsplus squashfs udf vfat; do
  modprobe $fs 2>&1 && echo "$fs: loaded (BAD)" || echo "$fs: blocked (GOOD)"
done
```

✅ Expected: Each `modprobe` returns "Operation not permitted" or "Required key not available", confirming modules are blocked

---

### Practice 9: Set Immutable Attributes on Critical Files

```bash
# Protect critical files
chattr +i /etc/passwd
chattr +i /etc/shadow
chattr +i /etc/group

# Verify
lsattr /etc/passwd
# ----i------------- /etc/passwd

# Test: try to modify
echo "test" >> /etc/passwd  # Should fail
```

✅ Expected: `lsattr` shows the `i` flag; echo append fails with "Operation not permitted"

---

### Practice 10: Build a Complete Audit Rules File

```bash
# Create persistent rules
cat > /etc/audit/rules.d/99-hardening.rules << 'EOF'
-D
-b 8192
-f 1
-w /etc/passwd -p wa -k identity
-w /etc/shadow -p wa -k identity
-w /etc/sudoers -p wa -k sudoers
-w /etc/ssh/sshd_config -p wa -k sshd_config
-a always,exit -F arch=b64 -S execve -F euid=0 -F auid>=1000 -k root_cmd
-a always,exit -F arch=b64 -S init_module -S finit_module -k mod_load
-e 2
EOF

# Load rules
augenrules --load

# Verify
auditctl -l
```

✅ Expected: `auditctl -l` shows all rules; `auditctl -s` shows "enabled 1" and "failure 1" (printk mode)

---

### Practice 11: fail2ban Custom Filter for Nginx

```bash
# Create filter
cat > /etc/fail2ban/filter.d/nginx-auth.conf << 'EOF'
[Definition]
failregex = ^<HOST> .* "(GET|POST) .* HTTP/.*" 401 .*$
ignoreregex =
EOF

# Create jail
cat >> /etc/fail2ban/jail.local << 'EOF'
[nginx-auth]
enabled = true
port = http,https
filter = nginx-auth
logpath = /var/log/nginx/access.log
maxretry = 5
bantime = 3600
EOF

# Test filter
fail2ban-regex /var/log/nginx/access.log /etc/fail2ban/filter.d/nginx-auth.conf
```

✅ Expected: `fail2ban-regex` shows "matched" count; `fail2ban-client status nginx-auth` shows the jail is active

---

### Practice 12: OpenSCAP Quick Scan

```bash
# Find content file
ls /usr/share/xml/scap/ssg/content/ssg-*-ds.xml

# Run CIS Level 1 scan
oscap xccdf eval \
  --profile xccdf_org.ssgproject.content_profile_cis_server_l1 \
  --results /tmp/scap-results.xml \
  --report /tmp/scap-report.html \
  /usr/share/xml/scap/ssg/content/ssg-$(lsb_release -si | tr '[:upper:]' '[:lower:]')$(lsb_release -rs | tr -d '.')-ds.xml

# Generate remediation script
oscap xccdf generate fix --fix-type bash --output /tmp/scap-fix.sh /tmp/scap-results.xml
head -30 /tmp/scap-fix.sh
```

✅ Expected: HTML report generated; remediation script contains bash commands to fix non-compliant settings

---

### Practice 13: Automated Daily Hardening Check Script

```bash
cat > /usr/local/bin/daily-security-check.sh << 'SCRIPT'
#!/bin/bash
REPORT="/var/log/security-check-$(date +%Y%m%d).txt"
echo "=== Daily Security Check: $(date) ===" > "$REPORT"

echo -e "\n--- fail2ban Status ---" >> "$REPORT"
fail2ban-client status >> "$REPORT" 2>&1

echo -e "\n--- Open SUID Files ---" >> "$REPORT"
find / -xdev -perm -4000 -type f 2>/dev/null >> "$REPORT"

echo -e "\n--- Failed Logins (last 24h) ---" >> "$REPORT"
journalctl -u sshd --since "24 hours ago" | grep -i "failed" | wc -l >> "$REPORT"

echo -e "\n--- AIDE Status ---" >> "$REPORT"
aide --check 2>&1 | tail -5 >> "$REPORT"

echo -e "\n--- Lynis Score ---" >> "$REPORT"
grep "hardening_index" /var/log/lynis-report.dat 2>/dev/null >> "$REPORT"

echo -e "\n--- Auditd Rule Count ---" >> "$REPORT"
auditctl -l 2>/dev/null | wc -l >> "$REPORT"

echo -e "\n--- Unmodified Critical Files ---" >> "$REPORT"
lsattr /etc/passwd /etc/shadow /etc/ssh/sshd_config 2>/dev/null >> "$REPORT"
SCRIPT
chmod 700 /usr/local/bin/daily-security-check.sh

# Add to cron
echo "0 6 * * * root /usr/local/bin/daily-security-check.sh" > /etc/cron.d/security-check
```

✅ Expected: Script runs and generates `/var/log/security-check-YYYYMMDD.txt` containing status from all tools

---

### Practice 14: Ansible Hardening Dry Run

```bash
# Create inventory
cat > inventory.ini << 'INI'
[webserver]
web1 ansible_host=192.168.1.10
web2 ansible_host=192.168.1.11

[all:vars]
ansible_user=deploy
ansible_become=yes
INI

# Install roles
ansible-galaxy role install dev-sec.os-hardening

# Create playbook
cat > test-hardening.yml << 'YML'
---
- hosts: webserver
  become: true
  roles:
    - role: dev-sec.os-hardening
      vars:
        os_auth_pw_max_age: 90
        sysctl_set:
          - key: kernel.randomize_va_space
            value: 2
          - key: net.ipv4.conf.all.accept_redirects
            value: 0
YML

# Dry run
ansible-playbook -i inventory.ini test-hardening.yml --check --diff
```

✅ Expected: Ansible shows "changed" or "ok" for each task; `--check` mode applies nothing but reports what would change

---

### Practice 15: Full Hardening Workflow End-to-End

```bash
# 1. Document current state
lynis audit system 2>&1 | grep "hardening_index" | tee /tmp/before-score.txt

# 2. Apply hardening
sysctl -p /etc/sysctl.d/99-hardening.conf
cat /etc/ssh/sshd_config | grep -E "^(PermitRootLogin|PasswordAuth|X11Forwarding|MaxAuthTries)"

# 3. Enable services
systemctl enable --now auditd
systemctl enable --now fail2ban

# 4. Load audit rules
augenrules --load

# 5. Initialize AIDE
aide --init && cp /var/lib/aide/aide.db.new /var/lib/aide/aide.db

# 6. Re-audit
lynis audit system 2>&1 | grep "hardening_index" | tee /tmp/after-score.txt

# 7. Compare
echo "Before: $(cat /tmp/before-score.txt)"
echo "After:  $(cat /tmp/after-score.txt)"
```

✅ Expected: Lynis score increases by 10-30 points; auditd has rules loaded; fail2ban is running; AIDE baseline is active

---

## 🧠 Deep Understanding

### The Hardening Decision Matrix

```
┌───────────────────────────────────────────────────────────────────┐
│              HARDENING vs FUNCTIONALITY TRADE-OFFS                  │
├───────────────────────────────────────────────────────────────────┤
│                                                                     │
│  HIGH HARDENING / LOW IMPACT                                      │
│  ├─ ASLR (randomize_va_space=2)                                   │
│  ├─ Audit rules for /etc/passwd                                    │
│  ├─ fail2ban on SSH                                                 │
│  ├─ Disable unused services                                        │
│  └─ Password expiration policies                                   │
│                                                                     │
│  HIGH HARDENING / MEDIUM IMPACT                                   │
│  ├─ noexec on /tmp (breaks some installers)                       │
│  ├─ Kernel module signing (rejects some drivers)                  │
│  ├─ Strict SSH config (key-only, no X11)                           │
│  └─ Immutable file attributes (breaks package manager)             │
│                                                                     │
│  HIGH HARDENING / HIGH IMPACT                                     │
│  ├─ Kernel lockdown confidentiality (breaks debugging)            │
│  ├─ Disable ALL SUID (breaks su, sudo, passwd)                    │
│  ├─ Seccomp on all services (breaks complex apps)                 │
│  └─ Network namespace isolation (breaks inter-service comms)      │
│                                                                     │
│  RECOMMENDED APPROACH: Start top, work down, test each change     │
└───────────────────────────────────────────────────────────────────┘
```

### Tool Comparison

```
┌──────────────┬───────────────┬────────────────────────────┐
│    Tool       │   Purpose     │   Frequency                │
├──────────────┼───────────────┼────────────────────────────┤
│ CIS          │ What to fix   │ Quarterly review            │
│ sysctl       │ Kernel tune   │ Set once, verify monthly   │
│ mount opts   │ FS protection │ Set once, verify monthly   │
│ auditd       │ What's happening│ Continuous (24/7)         │
│ fail2ban     │ Block attacks │ Continuous (24/7)          │
│ Lynis        │ Am I secure?  │ Weekly scan                │
│ AIDE         │ What changed? │ Daily check                │
│ OpenSCAP     │ Am I compliant│ Weekly/Monthly scan        │
│ Ansible      │ Enforce state │ On change + weekly verify  │
└──────────────┴───────────────┴────────────────────────────┘
```

### Security Event Response Chain

```
┌──────────────────────────────────────────────────────────────┐
│           SECURITY EVENT RESPONSE CHAIN                       │
│                                                               │
│  1. DETECT                                                    │
│     auditd: unauthorized syscall                              │
│     fail2ban: brute force attempt                             │
│     AIDE: unexpected file change                              │
│     Lynis: score dropped                                      │
│                                                               │
│  2. IDENTIFY                                                  │
│     ausearch -k <key> --start recent                          │
│     fail2ban-client status <jail>                              │
│     aide --check | grep "ADDED\|CHANGED"                      │
│     aureport --auth --summary                                 │
│                                                               │
│  3. CONTAIN                                                   │
│     fail2ban auto-bans IP                                     │
│     iptables -A INPUT -s <attacker_ip> -j DROP                │
│     chattr +i on affected files                               │
│                                                               │
│  4. ERADICATE                                                 │
│     Remove malicious files (identified by AIDE)               │
│     Revoke compromised credentials                            │
│     Patch the vulnerability                                   │
│                                                               │
│  5. RECOVER                                                   │
│     Restore from known-good backup                            │
│     Rebuild AIDE baseline                                     │
│     Re-run Lynis audit                                        │
│                                                               │
│  6. LESSONS LEARNED                                           │
│     Update audit rules                                        │
│     Add new fail2ban filters                                  │
│     Update AIDE configuration                                 │
│     Document incident                                         │
└──────────────────────────────────────────────────────────────┘
```

> 🔍 **Reverse Engineering Insight:** Security is not a state — it's a process. The most hardened server in the world becomes vulnerable the moment a new CVE is published. That's why defense in depth matters: when one layer fails (an unpatched vulnerability), the next layer (auditd detecting suspicious behavior) catches the anomaly, and the layer after that (fail2ban banning the attacker) stops the damage.

---

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

## What's Coming in Part 67

```
┌─────────────────────────────────────────────────────────┐
│   Part 67: Course Summary — Everything Ties Together     │
├─────────────────────────────────────────────────────────┤
│   • Complete course roadmap and skill tree               │
│   • Quick reference for all 66 parts                     │
│   • Career pathways: SysAdmin → SRE → DevSecOps         │
│   • Certification prep (RHCSA, RHCE, LFCS, CompTIA)    │
│   • Final capstone project checklist                     │
│   • Recommended labs and practice environments          │
│   • Community resources and continued learning          │
│   • Your Linux administration journey continues         │
└─────────────────────────────────────────────────────────┘
```

---

## Self-Test

1. What are the three levels of CIS Benchmarks and who uses each?
2. What does `kernel.randomize_va_space = 2` enable and why does it matter?
3. What is the difference between `noexec`, `nosuid`, and `nodev` mount options?
4. Why should `/tmp` be on a separate tmpfs partition?
5. What is the purpose of auditd's `-e 2` rule and what happens when you use it?
6. How do you search audit logs for all events related to password file changes?
7. What is the difference between `audit2allow` and `audit2why`?
8. In fail2ban, what do `bantime`, `findtime`, and `maxretry` control?
9. Why should you never edit `/etc/fail2ban/jail.conf` directly?
10. What does Lynis score 67 vs 82 tell you about a system's security?
11. How does AIDE detect unauthorized file changes?
12. What must you do after running `apt upgrade` if AIDE is active?
13. What is the correct order to initialize and activate AIDE?
14. How does OpenSCAP differ from Lynis in purpose?
15. Why is defense in depth more effective than relying on a single hardening tool?

**Answers:**
1. Level I = minimum hygiene (all systems), Level II = defense in depth (servers), Level III = maximum hardening (classified/high-security)
2. Full ASLR — randomizes stack, heap, mmap, and VDSO addresses; prevents attackers from predicting memory layout for exploitation
3. `noexec` = prevent code execution, `nosuid` = ignore SUID/SGID bits, `nodev` = don't treat as device files
4. Separate tmpfs prevents /tmp from filling the root partition, enables noexec/nosuid/nodev, and is cleared on reboot (no persistent malware)
5. `-e 2` makes rules immutable — no changes possible until reboot; prevents attackers from deleting audit rules
6. `ausearch -k passwd_changes --start today` searches by key; `ausearch -f /etc/passwd` searches by file path
7. `audit2allow` generates SELinux policy modules to permit denied actions; `audit2why` explains the reason behind the denial
8. `bantime` = duration of ban, `findtime` = window to count failures, `maxretry` = failures before ban
9. `jail.conf` is overwritten on package upgrades; `jail.local` persists your customizations
10. 67 = moderate (some hardening done), 82 = very good (well-hardened with most controls in place)
11. AIDE computes cryptographic hashes (SHA256/512) of files at baseline, then re-computes and compares on each check
12. Run `aide --update` and copy `aide.db.new` to `aide.db` to accept legitimate changes as new baseline
13. `aide --init` (generate baseline) → `cp aide.db.new aide.db` (activate) → `aide --check` (verify)
14. OpenSCAP validates compliance against formal standards (CIS, STIG, PCI-DSS) with pass/fail per rule; Lynis provides security scoring with suggestions
15. Each tool covers different attack vectors; layered defense means if one control fails or is bypassed, others still provide protection

**Score:** 12/15 correct = ready for Part 67.

---

*Linux SysAdmin Course | Part 66 of ∞ | Reverse Engineering Approach*
*Previous → Part 65: PAM & Centralized Auth*
*Next → Part 67: Course Summary*

[← Previous](part65.md) | [Next →](part67.md)
