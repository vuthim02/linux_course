# 🐧 Linux System Administrator — Complete Course
## Part 49 of ∞: Security Hardening and Auditing — Lynis, OpenSCAP, CIS Benchmarks, Auditd

---

> **Course Philosophy:** We use **Reverse Engineering Tactics** — we start from *what you already see*, then dig down into *why it works that way*. Instead of memorizing theory first, you understand by taking things apart.

---

## 🎯 What You Will Achieve in Part 49

By the end of this part, you will:

- Understand the **security philosophy** behind defense in depth, least privilege, and attack surface reduction
- Apply **CIS Benchmarks** to harden a Linux system against real-world threats
- Run **Lynis** security audits and interpret the hardening index
- Perform **OpenSCAP** compliance scans with CIS, PCI-DSS, and STIG profiles
- Configure **auditd** to monitor critical files, syscalls, and user activity
- Set up **file integrity monitoring** with AIDE
- Harden **user accounts, SSH, filesystems, network, and kernel** parameters
- Understand and configure **AppArmor and SELinux**
- Implement a **security auditing procedure** and incident response plan
- Write a **complete hardening and audit script** tying everything together

---

## 🔍 Section 1: Security Philosophy

### The CIA Triad

Every security decision you make as a sysadmin traces back to three core principles:

| Principle | Meaning | Example |
|-----------|---------|---------|
| **Confidentiality** | Data is accessible only to authorized parties | File permissions, encryption, access controls |
| **Integrity** | Data is not tampered with by unauthorized parties | File integrity monitoring, checksums, audit logs |
| **Availability** | Systems and data are accessible when needed | Redundancy, backups, DDoS protection, failover |

### Defense in Depth

Never rely on a single security control. Layer them so that if one fails, another catches the threat:

```
┌─────────────────────────────────────────────────────────┐
│                    DEFENSE IN DEPTH                       │
├─────────────────────────────────────────────────────────┤
│  🌐 Network Layer   — Firewall, TCP wrappers, VPN        │
│  🖥️ Host Layer      — SELinux/AppArmor, auditd, AIDE    │
│  👤 User Layer      — PAM, password policies, SSH keys   │
│  📁 Application Layer — Web app firewall, input validation│
│  💾 Data Layer      — Encryption at rest, backups        │
└─────────────────────────────────────────────────────────┘
```

### Least Privilege

Every user, process, and service should have **only the permissions it needs** to function — nothing more.

```bash
# Bad: root for everything
sudo chmod 777 /etc/shadow      # NEVER DO THIS

# Good: specific permissions
sudo usermod -aG www-data deploy
sudo chown root:www-data /var/www
sudo chmod 750 /var/www
```

### Attack Surface Reduction

Every running service, open port, installed package, and enabled kernel feature is a potential attack vector. Remove what you don't need:

```bash
# List all listening ports
ss -tlnp

# Remove unused packages
sudo apt list --installed | grep -E 'telnet|rsh|talk'
sudo apt purge telnetd rsh-server talkd

# Disable unused services
sudo systemctl disable --now cupsd avahi-daemon rpcbind
```

### Security by Design

Build security into the architecture from the start, not as an afterthought:

- Encrypt data in transit (TLS/SSL, SSH)
- Encrypt data at rest (LUKS, eCryptfs)
- Isolate services with containers, VMs, or jails
- Use separate VLANs for different trust levels
- Automate security checks into CI/CD pipelines

---

## 🔍 Section 2: CIS Benchmarks

### What Are CIS Benchmarks?

The **Center for Internet Security (CIS)** publishes hardening guidelines for OS, cloud, network devices, and applications. Each benchmark provides:

- **Configuration recommendations** organized by section
- **Level 1** — Essential hardening that does not reduce functionality
- **Level 2** — More restrictive hardening suitable for high-security environments
- **Automated assessment tools** to check compliance

### CIS-CAT Tool

CIS provides the **CIS-CAT Pro** assessment tool (paid license for full version, free Lite version available):

```bash
# CIS-CAT Lite (normally runs via Java)
java -jar CIS-CAT-Lite.jar \
  --profile "Level 1" \
  --benchmark "CIS_Ubuntu_Linux_20.04_LTS_Benchmark_v1.0.0.xml" \
  --output-dir /root/cis-report
```

### Manual CIS Checking Examples

```bash
# CIS 1.1.1 — Ensure mounting of unused filesystems is disabled
sudo modprobe -r crampfs freevxfs jffs2 hfs hfsplus squashfs udf

# CIS 1.1.8 — Ensure nodev option on /dev/shm
mount -o remount,nodev,nosuid,noexec /dev/shm

# CIS 4.1.1 — Ensure auditd is installed and enabled
sudo apt install -y auditd audispd-plugins
sudo systemctl enable --now auditd
```

### Automated Compliance Checking with OpenSCAP

While CIS-CAT is proprietary, **OpenSCAP** (Section 3) can check many CIS rules for free:

```bash
# RHEL/CentOS — scan against CIS profile
sudo oscap xccdf eval \
  --profile xccdf_org.ssgproject.content_profile_cis \
  --results scan-results.xml \
  --report scan-report.html \
  /usr/share/xml/scap/ssg/content/ssg-rhel9-ds.xml
```

---

## 🔍 Section 3: Lynis

### What Is Lynis?

**Lynis** is an open-source security auditing tool for Unix/Linux systems. It performs hundreds of individual tests, assigns a **hardening index** score, and provides actionable hardening suggestions.

### Installation

```bash
# Debian/Ubuntu
sudo apt update
sudo apt install -y lynis

# RHEL/CentOS/Fedora
sudo dnf install -y epel-release
sudo dnf install -y lynis

# From source (always latest)
git clone https://github.com/CISOfy/lynis.git /opt/lynis
sudo /opt/lynis/lynis audit system
```

### Running a Lynis Audit

```bash
# Full system audit
sudo lynis audit system

# Audit with specific category
sudo lynis audit system --tests-from-group malware,networking

# Show available test categories
sudo lynis show categories
```

### Sample Lynis Output

```
===========================================================
  Lynis 3.1.1
===========================================================
  Profile:        /etc/lynis/default.prf
  System:         Ubuntu 24.04 LTS
  Test Groups:    all
  Hardening Index: 67 [████████░░░░░░░░░░░░░░░░░░]

===========================================================
  Warnings (4):
===========================================================
  ! File system permissions on /etc/shadow are not strict [FILE-7524]
  ! No running auditing daemon detected [ACCT-9628]
  ! Passwordless sudo entries found [AUTH-9328]
  ! Kernel hardening: no dedicated kernel hardening system [KRNL-5820]

===========================================================
  Suggestions (18):
===========================================================
  * Consider hardening SSH configuration [SSH-7408]
    - Set PermitRootLogin to no
    - Set PasswordAuthentication to no
    - Set MaxAuthTries to 3
  * Install a PAM module for password strength testing [AUTH-9262]
    - Install libpam-pwquality (apt install libpam-pwquality)
  * Install a file integrity tool [FINT-4350]
    - Install AIDE (apt install aide)
  * Configure auditd to collect system events [ACCT-9622]
    - Install and enable auditd
```

### Hardening Index

The hardening index is a score from 0-100. A score below 60 indicates significant work needed; 60-80 is reasonable; 80+ is well-hardened.

```bash
# To see only the hardening index from a previous scan:
sudo lynis show details --details | grep hardening_index

# Or grep from the full output:
sudo lynis audit system | grep -i "hardening index"
```

### Custom Lynis Profiles

```bash
# Create a custom profile for your organization
sudo mkdir -p /etc/lynis
sudo tee /etc/lynis/custom.prf > /dev/null << 'EOF'
# Custom Lynis profile for Production Web Servers
profile=production-web-server

# Skip some tests that don't apply
skip-test=PRNT-2307
skip-test=PRNT-2308

# Custom mail server for reports
mailto=security@example.com

# Custom plugins
plugin=/etc/lynis/plugins/custom_plugin
EOF

# Run with custom profile
sudo lynis audit system --profile /etc/lynis/custom.prf
```

### Compliance Framework Mapping

Lynis can map findings to compliance frameworks:

```bash
# Map results to PCI-DSS
sudo lynis audit system --compliance PCI

# Map to ISO 27001
sudo lynis audit system --compliance ISO27001

# Map to HIPAA
sudo lynis audit system --compliance HIPAA
```

---

## 🔍 Section 4: OpenSCAP

### What Is SCAP?

**SCAP** (Security Content Automation Protocol) is a U.S. government standard for expressing security checklists, vulnerabilities, and compliance data. **OpenSCAP** is the open-source implementation.

### SCAP Components

| Component | Purpose | File Extension |
|-----------|---------|----------------|
| **XCCDF** | Checklist/benchmark format (what to check) | `.xml` |
| **OVAL** | Language for defining system state checks | `.xml` |
| **CPE** | Platform identification (what OS/software) | `.dict` |
| **CVE** | Common Vulnerabilities and Exposures | NVD database |

### Installation

```bash
# Debian/Ubuntu
sudo apt install -y openscap-scanner scap-workbench

# RHEL/CentOS/Fedora
sudo dnf install -y openscap-scanner scap-workbench
```

### Available Security Profiles

```bash
# List available profiles on RHEL/CentOS
oscap info /usr/share/xml/scap/ssg/content/ssg-rhel9-ds.xml

# Example profiles:
#   - cis_level1_server    (CIS Level 1)
#   - cis_level2_server    (CIS Level 2)
#   - pci-dss              (PCI Data Security Standard)
#   - stig                 (US DoD STIG)
#   - hipaa                (HIPAA)
#   - ospp                 (Common Criteria)
```

### Running an OpenSCAP Scan

```bash
# Create output directory
mkdir -p ~/scap-results

# Run scan with CIS Level 1 profile (RHEL)
sudo oscap xccdf eval \
  --profile xccdf_org.ssgproject.content_profile_cis_level1_server \
  --results ~/scap-results/scan-results.xml \
  --report ~/scap-results/scan-report.html \
  --oval-results \
  /usr/share/xml/scap/ssg/content/ssg-rhel9-ds.xml

# For Ubuntu, use the DISA STIG or Ubuntu-specific content
sudo apt install -y ssg-base ssg-debian ssg-debderived
oscap info /usr/share/xml/scap/ssg/content/ssg-ubuntu2404-ds.xml
```

### OpenSCAP Remediation

OpenSCAP can automatically remediate some findings:

```bash
# Generate a fix script
sudo oscap xccdf generate fix \
  --profile xccdf_org.ssgproject.content_profile_cis_level1_server \
  --fix-type bash \
  --output ~/scap-results/remediation.sh \
  /usr/share/xml/scap/ssg/content/ssg-rhel9-ds.xml

# Review the script carefully, then run
sudo bash ~/scap-results/remediation.sh
```

### Using scap-workbench (GUI)

```bash
# Launch the graphical workbench
scap-workbench &

# 1. Open a SCAP content file (.xml)
# 2. Select a profile
# 3. Click "Scan" → runs locally
# 4. Click "Remediate" → applies fixes
```

### Understanding oscap Command Structure

```bash
# Generic structure:
oscap [module] [operation] [options] [input_file]

# Examples:
oscap xccdf eval --profile cis --results results.xml --report report.html scap-content.xml
oscap oval eval --results oval-results.xml oval-definitions.xml
oscap cpe scan cpe-dict.xml
```

---

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

## 🔍 Section 6: File Integrity Monitoring

### AIDE — Advanced Intrusion Detection Environment

AIDE builds a **database** of file hashes, permissions, ownership, and other metadata, then compares the current system against that database to detect unauthorized changes.

```
┌───────────────────────┐
│    Initialization     │
│  ┌─────────────────┐  │
│  │ aideinit         │  │  Creates /var/lib/aide/aide.db.new
│  │ (build database) │  │
│  └────────┬────────┘  │
│           ▼           │
│  ┌─────────────────┐  │
│  │ mv aide.db.new  │  │  Rename to active database
│  │    aide.db      │  │
│  └────────┬────────┘  │
└───────────┼───────────┘
            ▼
┌───────────────────────┐
│    Daily Check        │
│  ┌─────────────────┐  │
│  │ aide --check     │  │  Compares current state vs database
│  └────────┬────────┘  │
│           ▼           │
│  ┌─────────────────┐  │
│  │ Report changes  │  │  Output to stdout or report file
│  │ or no changes   │  │
│  └─────────────────┘  │
└───────────────────────┘
```

### Installation and Setup

```bash
sudo apt install -y aide aide-common

# Generate default config
sudo cp /etc/aide/aide.conf /etc/aide/aide.conf.default

# View default configuration
sudo less /etc/aide/aide.conf
```

### AIDE Configuration — /etc/aide/aide.conf

```bash
sudo tee /etc/aide/aide.conf > /dev/null << 'EOF'
# /etc/aide/aide.conf

# Database location
database=file:/var/lib/aide/aide.db
database_out=file:/var/lib/aide/aide.db.new
report_url=file:/var/lib/aide/aide.report

# Define custom rule groups
# p=permissions, i=inode, n=number of links, u=user, g=group
# s=size, b=block count, m=mtime, a=atime, c=ctime
# S=sha256, R=rmd160, T=tiger
ALL=p+i+n+u+g+s+b+m+c+S+R+T+md5+sha1

# For files that change frequently, omit content checks
FREQ=p+i+n+u+g

# For log files, check only metadata
LOG=p+i+n+u+g

# --- Directories and files to monitor ---

# Essential binaries
/bin ALL
/sbin ALL
/usr/bin ALL
/usr/sbin ALL
/lib ALL
/lib64 ALL
/usr/lib ALL
/usr/lib64 ALL

# Configuration files
/etc/passwd ALL
/etc/shadow ALL
/etc/group ALL
/etc/gshadow ALL
/etc/sudoers ALL
/etc/ssh/sshd_config ALL
/etc/hosts.allow ALL
/etc/hosts.deny ALL
/etc/audit/ ALL
/etc/lynis ALL
/etc/aide/ ALL

# System binaries
/boot ALL
/vmlinuz ALL
/initrd.img ALL

# --- Directories to NOT monitor ---
# Logs change too frequently
/var/log LOG
!/var/log/syslog
!/var/log/auth.log
!/var/log/kern.log
!/var/log/debug
!/var/log/messages

# Temporary files
!/tmp
!/var/tmp
!/proc
!/sys
!/dev
!/run
!/mnt
!/media

# User home directories (too much personal content)
!/root
!/home
EOF
```

### Initialize the AIDE Database

```bash
# Initialize the database (run immediately after clean system install)
sudo aideinit

# This creates /var/lib/aide/aide.db.new
# Rename it to the active database:
sudo mv /var/lib/aide/aide.db.new /var/lib/aide/aide.db
```

### Running AIDE Checks

```bash
# Check integrity (compare current state to database)
sudo aide --check

# Sample output when no changes detected:
# /etc/passwd: ... ok
# /etc/shadow: ... ok
# AIDE found NO differences between database and filesystem.

# Sample output when changes found:
# /etc/passwd: ... changed
#   Changed entries:
#   attr:  | md5    | expected: 'abc123...' | actual: 'def456...'
#   attr:  | sha256 | expected: '111222...' | actual: '333444...'
```

### Automating AIDE Checks

```bash
# Run daily via cron
sudo tee /etc/cron.daily/aide-check > /dev/null << 'EOF'
#!/bin/bash
/usr/bin/aide --check | mail -s "AIDE Daily Report" root
EOF
sudo chmod +x /etc/cron.daily/aide-check

# Or via systemd timer
sudo tee /etc/systemd/system/aide-check.service > /dev/null << 'EOF'
[Unit]
Description=Daily AIDE integrity check
[Service]
Type=oneshot
ExecStart=/usr/bin/aide --check
EOF

sudo tee /etc/systemd/system/aide-check.timer > /dev/null << 'EOF'
[Unit]
Description=Run AIDE check daily
[Timer]
OnCalendar=daily
Persistent=true
[Install]
WantedBy=timers.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now aide-check.timer
```

### Other File Integrity Tools

| Tool | Type | Key Feature |
|------|------|-------------|
| **AIDE** | Open-source | Simple, widely packaged, rule-based |
| **Tripwire** | Commercial/Open | Industry standard, policy-driven |
| **OSSEC** | Open-source | HIDS — File integrity + log analysis + rootkit detection |
| **Samhain** | Open-source | Centralized client-server integrity monitoring |
| **Osquery** | Open-source | SQL-based system introspection |
| **Integrit** | Open-source | Minimalist, fast |

```bash
# OSSEC installation (agent)
curl -s https://raw.githubusercontent.com/ossec/ossec-hids/master/install.sh | sudo bash

# Samhain setup
sudo apt install -y samhain
sudo samhain -t init   # Initialize database
sudo samhain -t check   # Run check
```

---

## 🔍 Section 7: User Account Hardening

### Password Policies — /etc/login.defs

```bash
sudo tee -a /etc/login.defs > /dev/null << 'EOF'

# --- Password aging controls ---
# These apply to local user passwords (not LDAP/AD)

PASS_MAX_DAYS   90          # Password expires after 90 days
PASS_MIN_DAYS   7           # Minimum 7 days before password can change
PASS_WARN_AGE   14          # Warn user 14 days before expiration
EOF
```

### Password Quality — PAM pwquality

```bash
sudo apt install -y libpam-pwquality

# Configure password quality
sudo tee /etc/security/pwquality.conf > /dev/null << 'EOF'
# Minimum password length
minlen = 14

# Require at least one digit
dcredit = -1

# Require at least one uppercase letter
ucredit = -1

# Require at least one lowercase letter
lcredit = -1

# Require at least one special character
ocredit = -1

# Maximum consecutive same characters
maxrepeat = 3

# Not more than N characters in sequence
maxsequence = 4

# Check based on dictionary words
dictcheck = 1

# Number of character classes required (at least 3 of 4)
minclass = 3

# Maximum credit for having digits (set to 0 to disable)
enforce_for_root
EOF

# Enable in PAM
sudo tee /etc/pam.d/common-password > /dev/null << 'EOF'
password  requisite  pam_pwquality.so retry=3
password  [success=1 default=ignore]  pam_unix.so obscure use_authtok try_first_pass sha512 shadow
password  requisite  pam_deny.so
password  required   pam_permit.so
EOF
```

### Account Lockout — pam_faillock

```bash
# Debian/Ubuntu — install and configure faillock
sudo apt install -y libpam-modules

# Configure faillock in /etc/pam.d/common-auth
sudo tee /etc/pam.d/common-auth > /dev/null << 'EOF'
auth    required    pam_faillock.so preauth audit silent deny=5 unlock_time=900
auth    [success=1 default=ignore]  pam_unix.so nullok
auth    [default=die]               pam_faillock.so authfail audit deny=5 unlock_time=900
auth    sufficient                  pam_faillock.so authsucc audit deny=5 unlock_time=900
auth    required    pam_deny.so
EOF
```

### SSH Key-Only Authentication

```bash
# Generate an ED25519 key pair (on client machine)
ssh-keygen -t ed25519 -a 100 -f ~/.ssh/id_ed25519 -C "admin-key-$(hostname)"

# Copy to server
ssh-copy-id -i ~/.ssh/id_ed25519.pub user@server

# Verify key works
ssh -i ~/.ssh/id_ed25519 user@server
```

### Disabling Root SSH

```bash
# In /etc/ssh/sshd_config
sudo sed -i 's/^#PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
# Or change from 'yes' to 'no'
sudo sed -i 's/^PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
sudo systemctl restart sshd
```

### Sudoers Hardening

```bash
# Principle: give users access to specific commands, not "ALL"

# /etc/sudoers.d/webadmin
sudo tee /etc/sudoers.d/webadmin > /dev/null << 'EOF'
# Web admin team — can manage web services only
%webadmin ALL=(root) /usr/bin/systemctl restart nginx
%webadmin ALL=(root) /usr/bin/systemctl reload nginx
%webadmin ALL=(root) /usr/bin/systemctl status nginx
%webadmin ALL=(root) /usr/bin/journalctl -u nginx

# Require password every time (no NOPASSWD for sensitive commands)
Defaults:%webadmin timestamp_timeout=0
EOF

sudo chmod 440 /etc/sudoers.d/webadmin
```

### PAM Configuration Overview

```bash
# PAM (Pluggable Authentication Modules) controls:
# - Authentication  (auth)
# - Account control (account) — lockout, expiry, time-based
# - Password       (password) — quality, hashing
# - Session        (session) — logging, limits

# Common PAM files on Debian/Ubuntu:
# /etc/pam.d/common-auth
# /etc/pam.d/common-account
# /etc/pam.d/common-password
# /etc/pam.d/common-session

# PAM module locations:
ls /lib/x86_64-linux-gnu/security/ | sort
```

---

## 🔍 Section 8: Filesystem Security

### Mount Options — nosuid, noexec, nodev

Every filesystem mount should use security options where applicable:

```bash
# Check current mount options
mount | grep -E '^/dev|tmpfs'

# Apply security options to /etc/fstab
sudo tee -a /etc/fstab > /dev/null << 'EOF'

# /tmp as tmpfs with security options
tmpfs   /tmp    tmpfs    defaults,nosuid,nodev,noexec,size=2G    0 0

# /var/tmp with security options
tmpfs   /var/tmp    tmpfs    defaults,nosuid,nodev,noexec,size=1G    0 0

# /home — no setuid binaries allowed
/dev/sdb1   /home   ext4    defaults,nosuid,nodev    0 2

# /var — separate partition (prevents log overflow on root)
/dev/sdc1   /var    ext4    defaults,nosuid,nodev    0 2

# /dev/shm — no execution
tmpfs   /dev/shm    tmpfs    defaults,nosuid,nodev,noexec    0 0
EOF
```

### /tmp Hardening

```bash
# Option 1: tmpfs in memory (fast, no disk writes)
sudo mount -o remount,noexec,nosuid,nodev /tmp

# Option 2: Persistent but hardened
# In /etc/fstab:
# UUID=xxxx /tmp ext4 defaults,nosuid,nodev,noexec 0 2

# Option 3: systemd tmpfiles.d
sudo tee /etc/tmpfiles.d/tmp-hardening.conf > /dev/null << 'EOF'
# Set secure permissions on /tmp
D /tmp 1777 root root 10d

# Clean up old files automatically
# /usr/lib/tmpfiles.d/tmp.conf already does this
EOF
```

### SUID / SGID Audit

SUID/SGID binaries are a common privilege escalation vector:

```bash
# Find all SUID binaries
sudo find / -perm -4000 -type f 2>/dev/null

# Find all SGID binaries
sudo find / -perm -2000 -type f 2>/dev/null

# Remove SUID from binaries that don't need it
sudo chmod -s /usr/bin/wall
sudo chmod -s /usr/bin/write
sudo chmod -s /usr/bin/newgrp
sudo chmod -s /usr/bin/chsh
sudo chmod -s /usr/bin/chfn

# Document which SUID binaries should exist
sudo find / -perm -4000 -type f 2>/dev/null | sort > /etc/security/suid-baseline.txt
```

### Sticky Bit

The sticky bit prevents users from deleting each other's files in shared directories:

```bash
# /tmp should already have the sticky bit
ls -ld /tmp
# drwxrwxrwt  ...  (the 't' at the end is the sticky bit)

# Set sticky bit on a shared directory
sudo chmod +t /shared

# Find directories without sticky bit that need it
sudo find / -type d -perm -1002 -not -perm -1000 2>/dev/null
```

### Immutable Files (chattr)

```bash
# Make critical files immutable (requires chattr from e2fsprogs)
sudo chattr +i /etc/passwd      # Prevent changes to user database
sudo chattr +i /etc/shadow
sudo chattr +i /etc/group
sudo chattr +i /etc/gshadow
sudo chattr +i /etc/sudoers

# Make a directory immutable (prevents file creation/deletion)
sudo chattr +i /etc/ssh

# View immutable attributes
lsattr /etc/passwd /etc/shadow /etc/group
# ----i--------e-- /etc/passwd
# ----i--------e-- /etc/shadow

# Remove immutable attribute
sudo chattr -i /etc/passwd

# Append-only mode (logs can only be appended, not deleted)
sudo chattr +a /var/log/syslog
sudo chattr +a /var/log/auth.log

# Note: chattr requires CAP_LINUX_IMMUTABLE capability
# Even root cannot modify immutable files without first removing the flag
```

---

## 🔍 Section 9: Network Security

### Unused Ports and Services

```bash
# List all listening TCP and UDP ports with process info
sudo ss -tlnp
sudo ss -ulnp

# Alternative with netstat
sudo netstat -tulnp

# Check what services are running
sudo systemctl list-units --type=service --state=running

# Close unnecessary ports by stopping/disabling services
sudo systemctl disable --now cups        # Printing
sudo systemctl disable --now avahi-daemon # mDNS
sudo systemctl disable --now rpcbind     # NFS portmapper
sudo systemctl disable --now bluetooth   # Bluetooth (servers)
sudo systemctl disable --now whoopsie    # Ubuntu crash reporting
```

### Firewall Lockdown

```bash
# UFW (Uncomplicated Firewall)
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw --force enable
sudo ufw status verbose

# nftables (modern replacement for iptables)
sudo tee /etc/nftables.conf > /dev/null << 'EOF'
#!/usr/sbin/nft -f
flush ruleset

table inet filter {
    chain input {
        type filter hook input priority 0; policy drop;
        ct state established,related accept
        ct state invalid drop
        iif lo accept
        tcp dport 22 accept
        tcp dport 80 accept
        tcp dport 443 accept
        ip protocol icmp accept
        log prefix "nftables-drop " drop
    }
    chain forward {
        type filter hook forward priority 0; policy drop;
    }
    chain output {
        type filter hook output priority 0; policy accept;
    }
}
EOF

sudo systemctl enable --now nftables
sudo nft -f /etc/nftables.conf
```

### TCP Wrappers (/etc/hosts.allow, /etc/hosts.deny)

**Note:** TCP wrappers are deprecated in most modern distros (sshd dropped libwrap support). Use firewall rules instead. For legacy systems:

```bash
# /etc/hosts.deny — default deny
echo "ALL: ALL" | sudo tee /etc/hosts.deny

# /etc/hosts.allow — specific allow
sudo tee /etc/hosts.allow > /dev/null << 'EOF'
# Allow SSH from management network only
sshd: 10.0.0.0/24, 192.168.1.0/24

# Allow NFS from specific hosts
portmap: 10.0.0.10, 10.0.0.11

# Allow rsync from backup server
rsync: 10.0.0.50
EOF
```

### ICMP and Network Hardening

```bash
# /etc/sysctl.d/10-network-security.conf
sudo tee /etc/sysctl.d/10-network-security.conf > /dev/null << 'EOF'
# Disable ICMP redirect acceptance
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0

# Disable sending ICMP redirects
net.ipv4.conf.all.send_redirects = 0

# Ignore ICMP echo requests (disable ping)
# net.ipv4.icmp_echo_ignore_all = 1

# Ignore broadcast pings (smurf attack prevention)
net.ipv4.icmp_echo_ignore_broadcasts = 1

# Ignore bogus ICMP errors
net.ipv4.icmp_ignore_bogus_error_responses = 1

# Reverse path filtering (martian packet prevention)
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1

# SYN cookies (protection against SYN flood attacks)
net.ipv4.tcp_syncookies = 1

# Disable IP forwarding unless acting as router
net.ipv4.ip_forward = 0

# Log martian packets
net.ipv4.conf.all.log_martians = 1

# Disable source routing
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
EOF

# Apply immediately
sudo sysctl --system
```

### Reverse Path Filtering Explained

**rp_filter** checks whether the source address of an incoming packet is reachable through the interface it arrived on. If not, the packet is dropped. This prevents **IP spoofing** and **martian packets** (packets with impossible source addresses):

```
┌──────────┐         ┌──────────┐
│ Attacker │────────►│ eth0     │
│ 1.2.3.4  │  spoof  │ Server   │
│          │  src=   │          │
│          │  1.1.1.1│          │
└──────────┘         └────┬─────┘
                          │
               rp_filter checks:
               "Is 1.1.1.1 reachable via eth0?"
               ┌────┐
               │ NO │ ──► DROP
               └────┘
```

---

## 🔍 Section 10: Kernel Hardening

### sysctl Security Settings

The kernel exposes many runtime parameters via `/proc/sys/`. Hardening them reduces the attack surface:

```bash
sudo tee /etc/sysctl.d/99-security-hardening.conf > /dev/null << 'EOF'
# /etc/sysctl.d/99-security-hardening.conf
# Kernel hardening parameters

# --- ASLR (Address Space Layout Randomization) ---
# 0 = disabled, 1 = randomize stack/library, 2 = full randomize (including brk)
kernel.randomize_va_space = 2

# --- Restrict kernel pointer exposure ---
# 0 = all kernel pointers visible to all
# 1 = only visible to privileged processes (CAP_SYSLOG)
# 2 = always hide (kptr_restrict introduced in kernel 4.x)
kernel.kptr_restrict = 2

# --- Restrict dmesg access ---
# 0 = any user can see kernel log
# 1 = only users with CAP_SYSLOG
kernel.dmesg_restrict = 1

# --- Disable unprivileged BPF (Berkeley Packet Filter) ---
# 0 = unprivileged users can create BPF (potential Spectre-variant attacks)
# 1 = only CAP_BPF or CAP_NET_ADMIN processes
kernel.unprivileged_bpf_disabled = 1

# --- Restrict ptrace scope ---
# 0 = any process can ptrace any other process (default for older kernels)
# 1 = only parent can ptrace child (restricted)
# 2 = only processes with CAP_SYS_PTRACE (admin only)
kernel.yama.ptrace_scope = 2

# --- Restrict perf events ---
# 0 = unprivileged, 1 = privileged only
kernel.perf_event_paranoid = 3

# --- Restrict kexec (used to boot into malicious kernel) ---
kernel.kexec_load_disabled = 1

# --- Disable SysRq (if not needed for debugging) ---
# kernel.sysrq = 0

# --- Core dump settings ---
# Do not follow symlinks when dumping core
fs.suid_dumpable = 0

# --- Restrict user namespace creation ---
# user.max_user_namespaces = 0   # Uncomment if namespaces are not needed
EOF

# Apply immediately
sudo sysctl --system

# Verify settings
sudo sysctl kernel.randomize_va_space kernel.kptr_restrict kernel.dmesg_restrict
```

### ASLR Deep Dive

**ASLR** randomizes the memory addresses where process components (stack, heap, libraries, mmap) are loaded. Without it, an attacker knows exactly where functions like `system()` live in libc (return-to-libc attacks).

```
Without ASLR:                     With ASLR:
┌─────────────────┐               ┌─────────────────┐
│ Stack: 0x7fff...│               │ Stack: 0x7f3a...│  ← different each run
│ Heap:  0x0060...│               │ Heap:  0x01c0...│
│ libc:  0x7f00...│               │ libc:  0x7f9b...│
│ ld.so: 0x7f10...│               │ ld.so: 0x7f8c...│
└─────────────────┘               └─────────────────┘
  (predictable)                      (randomized)
```

### grsecurity / PaX

**grsecurity** is a comprehensive kernel hardening patch set (commercial, requires subscription). **PaX** provides runtime code integrity (W^X — write XOR execute).

```bash
# Most distros do NOT include grsecurity in mainline kernels.
# To use it, you must:
# 1. Subscribe to grsecurity (https://grsecurity.net)
# 2. Obtain the patch for your kernel version
# 3. Apply patch and rebuild kernel

# Alternative: Use the linux-hardened kernel
# Arch Linux: pacman -S linux-hardened
# Gentoo: Enable hardened USE flag

# Check if your kernel has PaX:
grep -i pax /proc/config.gz 2>/dev/null || zcat /proc/config.gz 2>/dev/null | grep -i PAX
```

---

## 🔍 Section 11: AppArmor / SELinux

### AppArmor Overview

**AppArmor** (Application Armor) is a Mandatory Access Control (MAC) system implemented as a Linux Security Module (LSM). It confines programs to a set of listed files, capabilities, and network access defined in **profiles**.

```
Process (e.g., nginx) → AppArmor check → Allowed/Denied
                              │
                    (profile in /etc/apparmor.d/)
```

### AppArmor Status and Management

```bash
# Check if AppArmor is enabled and running
sudo aa-status
# Output:
# apparmor module is loaded.
# 34 profiles are loaded.
# 30 profiles are in enforce mode.
#    /usr/sbin/nginx
#    /usr/sbin/mysqld
# 4 profiles are in complain mode.

# List profiles by mode
sudo aa-status | grep -E 'enforce|complain'

# Get detailed status of a specific profile
sudo aa-status --profile /usr/sbin/nginx
```

### AppArmor Modes

| Mode | Behavior | Use Case |
|------|----------|----------|
| **Enforce** | Denies actions not in profile, logs to audit.log | Production |
| **Complain** | Logs violations but allows them | Testing/development |
| **Disabled** | Profile not loaded | Recovery |

```bash
# Set profile to enforce
sudo aa-enforce /usr/sbin/nginx

# Set profile to complain
sudo aa-complain /usr/sbin/mysqld

# Disable a profile
sudo aa-disable /usr/sbin/test-app

# Reload all profiles after changes
sudo systemctl reload apparmor

# Or reload a specific profile
sudo apparmor_parser -r /etc/apparmor.d/usr.sbin.nginx
```

### Creating an AppArmor Profile

```bash
# Generate a profile in complain mode first
sudo aa-genprof /usr/bin/custom-app

# This will:
# 1. Ask you to run the application in another terminal
# 2. Log all denied actions
# 3. Prompt you to allow/deny each action

# Alternative: Use aa-easyprof for simple profiles
sudo aa-easyprof /usr/bin/custom-app
```

### Sample AppArmor Profile

```bash
# /etc/apparmor.d/usr.sbin.nginx
sudo tee /etc/apparmor.d/usr.sbin.nginx > /dev/null << 'EOF'
#include <tunables/global>

/usr/sbin/nginx {
  #include <abstractions/base>
  #include <abstractions/nameservice>

  # Capabilities
  capability net_bind_service,
  capability setgid,
  capability setuid,
  capability dac_override,
  capability chown,
  capability kill,

  # Network access
  network inet tcp,
  network inet6 tcp,

  # Files and directories
  /usr/sbin/nginx mr,
  /etc/nginx/** r,
  /var/log/nginx/* w,
  /var/www/** r,
  /run/nginx.pid w,
  /run/nginx.pid rw,
  /var/lib/nginx/** rwk,
  /tmp/nginx/* rw,

  # Deny write to system configs
  deny /etc/passwd w,
  deny /etc/shadow w,
  deny /etc/nginx/nginx.conf w,
}
EOF
```

### SELinux Overview

**SELinux** (Security-Enhanced Linux) is a more granular MAC system developed by the NSA. Every process and file has a **security context** (label), and rules define which contexts can access which resources.

### SELinux Modes

```bash
# Check current mode
getenforce
# Enforcing | Permissive | Disabled

# Set mode (temporary, until reboot)
sudo setenforce 1     # Enforcing
sudo setenforce 0     # Permissive

# Permanent change — edit /etc/selinux/config:
sudo sed -i 's/^SELINUX=.*/SELINUX=enforcing/' /etc/selinux/config
```

### SELinux Context — Security String

Every file and process has a context with four fields:

```
user:role:type:level (optional MLS/MCS range)

Example:
unconfined_u:object_r:httpd_sys_content_t:s0

Breakdown:
- unconfined_u    — SELinux user
- object_r        — Role
- httpd_sys_content_t — Type (the most important part)
- s0              — Sensitivity level (MLS/MCS)
```

### Common SELinux Commands

```bash
# Check context of a file
ls -Z /var/www/html/index.html
# unconfined_u:object_r:httpd_sys_content_t:s0 /var/www/html/index.html

# Check context of a process
ps -Z $(pgrep httpd) | head -5
# system_u:system_r:httpd_t:s0  1234 ?  00:00:00 httpd

# Change file context
sudo chcon -t httpd_sys_content_t /var/www/html/index.html

# Restore default context (from policy)
sudo restorecon -v /var/www/html/index.html

# List all file contexts for a directory
sudo semanage fcontext -l | grep /var/www

# Set default context for a path
sudo semanage fcontext -a -t httpd_sys_content_t "/srv/www(/.*)?"
sudo restorecon -Rv /srv/www
```

### SELinux Booleans

SELinux booleans are tunable policy switches that allow/deny specific behaviors without writing new policies:

```bash
# List all booleans
sudo getsebool -a

# Check a specific boolean
sudo getsebool httpd_can_network_connect

# Set a boolean (temporary)
sudo setsebool httpd_can_network_connect on

# Set persistently
sudo setsebool -P httpd_can_network_connect on

# Common web server booleans:
# httpd_can_network_connect — Allow httpd to connect to network (proxies)
# httpd_can_sendmail       — Allow httpd to send email
# httpd_enable_homedirs    — Allow httpd to access user home dirs
# httpd_use_nfs            — Allow httpd to access NFS mounts
# ssh_sysadm_login         — Allow SSH login as sysadm_r
```

### SELinux Policy Modules

```bash
# List installed modules
sudo semodule -l

# Install a new module
sudo semodule -i mymodule.pp

# Remove a module
sudo semodule -r mymodule

# Create a custom module from audit log
sudo grep httpd /var/log/audit/audit.log | sudo audit2allow -M myhttpdmodule
sudo semodule -i myhttpdmodule.pp
```

### Troubleshooting SELinux Denials

```bash
# Check for denials in real time
sudo tail -f /var/log/audit/audit.log | grep AVC

# Use sealert for human-readable messages
sudo sealert -a /var/log/audit/audit.log

# Show all denials in summary
sudo ausearch -m AVC -ts today | audit2why

# Generate policy to allow denials
sudo ausearch -m AVC -ts today | audit2allow -M mymodule
```

### Choosing: AppArmor vs SELinux

| Factor | AppArmor | SELinux |
|--------|----------|---------|
| **Complexity** | Simple, path-based | Complex, label-based |
| **Granularity** | File paths + capabilities | Types, roles, users, levels |
| **Ease of use** | Beginner-friendly | Steep learning curve |
| **Default on** | Ubuntu, Debian, OpenSUSE | RHEL, CentOS, Fedora |
| **Policy language** | Profile syntax (simple) | TE (Type Enforcement) |
| **MLS/MCS** | Limited | Full support |

---

## 🔍 Section 12: SSH Hardening

### Comprehensive sshd_config

```bash
# Backup the original
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

# Write hardened configuration
sudo tee /etc/ssh/sshd_config > /dev/null << 'EOF'
# /etc/ssh/sshd_config — Hardened

# --- Protocol and Port ---
Port 22
Protocol 2                     # Only protocol 2 (protocol 1 is insecure)

# --- Authentication ---
PermitRootLogin no              # Never allow direct root login
PubkeyAuthentication yes        # Enable key-based auth
PasswordAuthentication no       # Disable password auth (keys only)
KbdInteractiveAuthentication no # Disable keyboard-interactive
ChallengeResponseAuthentication no
AuthenticationMethods publickey # Only publickey (no keyboard-interactive fallback)

# --- Key Types ---
HostKey /etc/ssh/ssh_host_ed25519_key
HostKey /etc/ssh/ssh_host_rsa_key
# Disable weak host keys:
# HostKey /etc/ssh/ssh_host_dsa_key     # DSA is broken
# HostKey /etc/ssh/ssh_host_ecdsa_key   # ECDSA has questionable NIST curves

# --- Access Control ---
AllowUsers alice bob charlie      # Only these users can SSH
# DenyUsers mallory                  # Explicitly deny
# AllowGroups ssh-users              # Or use groups
# DenyGroups attackers

# --- Rate Limiting ---
MaxAuthTries 3                    # Max 3 auth attempts before disconnect
MaxSessions 10                    # Max 10 concurrent sessions from one connection
MaxStartups 10:30:60              # Startrate: 10 max unauthenticated, 30% drop chance at 60

# --- Timeouts ---
ClientAliveInterval 300           # Send keepalive every 300 seconds
ClientAliveCountMax 2             # Max 2 missed keepalives before disconnect
LoginGraceTime 60                 # Must authenticate within 60 seconds

# --- Cryptographic Settings ---
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com
KexAlgorithms sntrup761x25519-sha512@openssh.com,curve25519-sha256@libssh.org,diffie-hellman-group16-sha512

# --- Logging ---
SyslogFacility AUTH
LogLevel VERBOSE                   # Log key fingerprints

# --- PAM ---
UsePAM yes                         # Enable PAM for account restrictions

# --- Environment ---
PermitUserEnvironment no           # Never allow user environment variables
AcceptEnv LANG LC_*

# --- Forwarding ---
AllowTcpForwarding no              # Disable TCP forwarding (reduce lateral movement)
X11Forwarding no                   # Disable X11 forwarding (security risk)
AllowAgentForwarding no            # Disable agent forwarding
PermitTunnel no

# --- Chroot and Restricted Shell ---
# Subsystem sftp internal-sftp      # Use internal-sftp for chroot
# Match Group sftp-users
#     ChrootDirectory /srv/sftp/%u
#     ForceCommand internal-sftp
#     X11Forwarding no
#     AllowTcpForwarding no
#     PermitTunnel no
EOF

# Test configuration before restarting
sudo sshd -t

# Restart SSH
sudo systemctl restart sshd
```

### ChrootDirectory for Restricted Users

```bash
# Create a chroot environment for SFTP-only users
sudo mkdir -p /srv/sftp/john/{incoming,.ssh}
sudo chown root:root /srv/sftp/john
sudo chmod 755 /srv/sftp/john
sudo chown john:john /srv/sftp/john/incoming
sudo chmod 755 /srv/sftp/john/incoming

# SSH config for chroot:
# Match Group sftp-users
#     ChrootDirectory /srv/sftp/%u
#     ForceCommand internal-sftp
#     X11Forwarding no
#     AllowTcpForwarding no
```

### SSH Key Types and Strength

```bash
# Generate strong keys
ssh-keygen -t ed25519 -a 100     # Fast, secure, short keys
ssh-keygen -t rsa -b 4096        # Compatible, but slower
ssh-keygen -t ecdsa -b 521       # ECDSA with P-521 curve

# Check existing key fingerprints
ssh-keygen -lf ~/.ssh/id_ed25519.pub
# 256 SHA256:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx user@host (ED25519)

# Add key to agent
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
```

### SSH Audit Script

```bash
#!/bin/bash
# ssh-audit.sh — Quick SSH security check
echo "=== SSH Configuration Audit ==="
echo ""

# Check PermitRootLogin
ROOT_LOGIN=$(sudo sshd -T | grep permitrootlogin | awk '{print $2}')
echo "PermitRootLogin: $ROOT_LOGIN"
[ "$ROOT_LOGIN" = "no" ] && echo "  ✅ PASS" || echo "  ❌ FAIL"

# Check PasswordAuthentication
PASS_AUTH=$(sudo sshd -T | grep passwordauthentication | awk '{print $2}')
echo "PasswordAuthentication: $PASS_AUTH"
[ "$PASS_AUTH" = "no" ] && echo "  ✅ PASS" || echo "  ❌ FAIL"

# Check Protocol
PROTOCOL=$(sudo sshd -T | grep protocol | awk '{print $2}')
echo "Protocol: $PROTOCOL"
[ "$PROTOCOL" = "2" ] && echo "  ✅ PASS" || echo "  ❌ FAIL"

# Check MaxAuthTries
MAX_TRIES=$(sudo sshd -T | grep maxauthtries | awk '{print $2}')
echo "MaxAuthTries: $MAX_TRIES"
[ "$MAX_TRIES" -le 3 ] 2>/dev/null && echo "  ✅ PASS" || echo "  ⚠️ CHECK"

# Check key exchange algorithms
KEX=$(sudo sshd -T | grep kexalgorithms | tr ',' '\n' | head -5)
echo "Key exchange algorithms (first 5):"
echo "$KEX" | sed 's/^/  /'

# Check for weak ciphers
WEAK=$(sudo sshd -T | grep ciphers | grep -c -E 'aes128-cbc|aes256-cbc|3des')
echo ""
[ "$WEAK" -gt 0 ] && echo "❌ WEAK CIPHERS DETECTED" || echo "✅ No weak ciphers detected"
```

---

## 🔍 Section 13: Log Security

### Remote Log Shipping with rsyslog

Centralized logging prevents attackers from covering their tracks by deleting local logs:

```bash
# On the log server (receiver)
sudo tee /etc/rsyslog.d/remote.conf > /dev/null << 'EOF'
# Listen for remote logs on TCP/UDP 514
module(load="imtcp")
module(load="imudp")
input(type="imtcp" port="514")
input(type="imudp" port="514")

# Template for organizing logs by hostname
$template RemoteLogs,"/var/log/remote/%hostname%/%programname%.log"
*.* ?RemoteLogs

# Stop processing after writing to remote file (don't write locally)
& ~
EOF

sudo systemctl restart rsyslog
sudo ufw allow 514/tcp
sudo ufw allow 514/udp

# On client machines (senders)
sudo tee /etc/rsyslog.d/forward.conf > /dev/null << 'EOF'
# Forward all logs to central server
*.* @@logserver.example.com:514    # TCP (reliable)
# *.* @logserver.example.com:514   # UDP (faster, less reliable)
EOF

sudo systemctl restart rsyslog
```

### Log Encryption with TLS

For logs containing sensitive data, encrypt in transit:

```bash
# On the log server
sudo tee /etc/rsyslog.d/tls-server.conf > /dev/null << 'EOF'
# Load TLS module
module(load="imtcp")
module(load="gtls")

# TCP listener with TLS
input(type="imtcp"
      port="6514"
      TLS="on"
      TLS.CertFile="/etc/ssl/certs/logserver.crt"
      TLS.KeyFile="/etc/ssl/private/logserver.key"
      TLS.CAFile="/etc/ssl/certs/ca.crt"
)
EOF

# On clients
sudo tee /etc/rsyslog.d/tls-client.conf > /dev/null << 'EOF'
# Load TLS module
module(load="omtcp")
module(load="gtls")

# Forward with TLS
action(type="omfwd"
       Target="logserver.example.com"
       Port="6514"
       Protocol="tcp"
       TCP_Framing="octet-counted"
       StreamDriver="gtls"
       StreamDriverMode="1"          # Authenticate TLS
       StreamDriverAuthMode="x509/name"
       StreamDriverPermittedPeers="logserver.example.com"
       ResendLastMSGOnReconnect="on"
       Action.ResumeInterval="10"
)
EOF
```

### Log Rotation

```bash
# Default config is in /etc/logrotate.conf
# Custom configs go in /etc/logrotate.d/

sudo tee /etc/logrotate.d/security-logs > /dev/null << 'EOF'
/var/log/audit/audit.log {
    rotate 7
    daily
    maxsize 50M
    missingok
    notifempty
    compress
    delaycompress
    postrotate
        /sbin/auditctl -R /etc/audit/rules.d/audit.rules
    endscript
}

/var/log/remote/*.log {
    rotate 30
    daily
    maxsize 100M
    missingok
    notifempty
    compress
    sharedscripts
    postrotate
        /usr/bin/systemctl reload rsyslog > /dev/null 2>&1 || true
    endscript
}
EOF
```

### Immutable Logs (Append-Only)

Prevent log tampering even by root:

```bash
# Make log files append-only
sudo chattr +a /var/log/auth.log
sudo chattr +a /var/log/syslog
sudo chattr +a /var/log/kern.log
sudo chattr +a /var/log/audit/audit.log

# Verify
lsattr /var/log/auth.log /var/log/syslog /var/log/audit/audit.log
# -----a----------e-- /var/log/auth.log
# -----a----------e-- /var/log/syslog
# -----a----------e-- /var/log/audit/audit.log

# To remove (must be root with CAP_LINUX_IMMUTABLE)
sudo chattr -a /var/log/auth.log
```

### SIEM Integration Basics

**SIEM** (Security Information and Event Management) aggregates logs from multiple sources for correlation, alerting, and compliance reporting:

```bash
# Common SIEM log shipping methods:

# 1. rsyslog -> SIEM (as shown above)
# 2. Filebeat + Logstash + Elasticsearch (ELK)
# 3. Splunk Universal Forwarder
# 4. Fluentd / Fluent Bit
# 5. Wazuh (open-source fork of OSSEC)

# Filebeat configuration example (shipping audit logs to Elasticsearch):
# filebeat.inputs:
# - type: log
#   enabled: true
#   paths:
#     - /var/log/audit/audit.log
#   fields:
#     log_type: auditd
# output.elasticsearch:
#   hosts: ["https://elastic.example.com:9200"]
#   username: "filebeat"
#   password: "${ES_PWD}"
```

---

## 🔍 Section 14: Security Auditing Procedures

### Vulnerability Scanning

Regular scans identify known vulnerabilities (CVEs) in installed software:

```bash
# OpenVAS / Greenbone Vulnerability Manager
sudo apt install -y openvas
sudo gvm-setup
sudo gvm-start
# Access web UI at https://127.0.0.1:9392
# Default credentials: admin / (auto-generated password shown during setup)

# Nessus Essentials (free for up to 16 IPs)
# Download from https://www.tenable.com/products/nessus/nessus-essentials
sudo dpkg -i Nessus-*.deb
sudo systemctl start nessusd
# Access web UI at https://localhost:8834

# Quick local vulnerability check
sudo apt install -y debsecan
sudo debsecan

# Or use the distribution's security tracker
sudo apt install -y unattended-upgrades
sudo unattended-upgrades --dry-run --debug
```

### Penetration Testing Basics

Understanding how attackers think helps you defend better:

```bash
# Reconnaissance and scanning
nmap -sV -sC -O target.example.com
nmap -p- -A target.example.com     # Full port scan with OS detection

# Service enumeration
nmap --script=http-headers,target-http-nse target.example.com

# Password brute-force testing (authorized targets only!)
hydra -l admin -P /usr/share/wordlists/rockyou.txt ssh://target

# Web app testing (OWASP ZAP or Burp Suite)
sudo apt install -y zaproxy
zap.sh -daemon -port 8080

# Wireless auditing (if applicable)
sudo airmon-ng start wlan0
sudo airodump-ng wlan0mon
```

### Incident Response Plan

Every organization needs a documented incident response plan. The **NIST SP 800-61** framework defines four phases:

```
┌─────────────────────────────────────────────────────────┐
│                   INCIDENT RESPONSE                       │
├─────────────────────────────────────────────────────────┤
│  1. Preparation                                          │
│     ├─ Document policies, build jump boxes, train staff   │
│     └─ Have tools ready (forensic images, log access)     │
│                                                           │
│  2. Detection & Analysis                                  │
│     ├─ "Something is wrong" (alerts, anomalies, reports)  │
│     └─ Determine scope, impact, and containment strategy  │
│                                                           │
│  3. Containment, Eradication & Recovery                   │
│     ├─ Isolate affected systems (network disconnect)      │
│     ├─ Preserve evidence (forensic image, memory dump)    │
│     ├─ Remove malware, close backdoors                    │
│     └─ Restore from clean backup                          │
│                                                           │
│  4. Post-Incident Activity                                │
│     ├─ Root cause analysis (RCA)                          │
│     ├─ Lessons learned document                           │
│     └─ Update policies, detection rules, and training     │
└─────────────────────────────────────────────────────────┘
```

### Forensics Tools

```bash
# Create a forensic disk image
sudo dd if=/dev/sda1 of=/mnt/evidence/disk_image.dd bs=4M conv=noerror,sync status=progress

# Create a memory capture (LiME or avml)
# LiME (Linux Memory Extractor)
sudo insmod lime.ko "path=/mnt/evidence/memory.lime format=lime"

# AVML (Acquire Volatile Memory for Linux)
./avml /mnt/evidence/memory.avml

# Recover deleted files
sudo foremost -i /mnt/evidence/disk_image.dd -o /mnt/evidence/recovered/

# Analyze disk image (Autopsy / sleuthkit)
sudo apt install -y sleuthkit
sudo fls -r /mnt/evidence/disk_image.dd > /mnt/evidence/file_list.txt
sudo icat /mnt/evidence/disk_image.dd <inode_number> > /mnt/evidence/recovered_file

# Timeline analysis
sudo fls -m /mnt/evidence/disk_image.dd | mactime -b > /tmp/timeline.csv
```

### Regular Audit Schedule

```bash
# /etc/cron.weekly/security-audit
sudo tee /etc/cron.weekly/security-audit > /dev/null << 'EOF'
#!/bin/bash
# Weekly security audit script
LOG_DIR="/var/log/security-audit"
mkdir -p "$LOG_DIR"
DATE=$(date +%Y-%m-%d)

{
  echo "=== Weekly Security Audit: $DATE ==="
  echo ""

  # 1. Check for failed login attempts
  echo "--- Failed Logins ---"
  ausearch --success no -m USER_LOGIN -ts week 2>/dev/null | aucount || echo "No auditd data"
  lastb | head -20

  # 2. Check for SUID changes
  echo "--- SUID Binaries ---"
  find / -perm -4000 -type f 2>/dev/null | sort | diff - /etc/security/suid-baseline.txt 2>/dev/null || \
    echo "SUID baseline changed! Review above."

  # 3. Check listening ports
  echo "--- Listening Ports ---"
  ss -tlnp

  # 4. Check for unexpected open ports to internet
  echo "--- Open Ports (from outside) ---"
  nmap -sT -Pn localhost | grep "open"

  # 5. Check disk usage and rootkits
  echo "--- Rootkit Check ---"
  which rkhunter && sudo rkhunter --check --skip-keypress 2>/dev/null | tail -5 || echo "rkhunter not installed"
  which chkrootkit && sudo chkrootkit 2>/dev/null | grep -v "not infected" || echo "chkrootkit not installed"

  # 6. Check AIDE integrity
  echo "--- AIDE Check ---"
  which aide && sudo aide --check 2>&1 | tail -10 || echo "AIDE not installed"

  # 7. Check pending security updates
  echo "--- Security Updates ---"
  which unattended-upgrade && sudo unattended-upgrades --dry-run --debug 2>&1 | grep "packages" | tail -5

} | tee "$LOG_DIR/audit-$DATE.log" | mail -s "Weekly Security Audit: $DATE" root

# Trim old logs (keep 90 days)
find "$LOG_DIR" -name "*.log" -mtime +90 -delete
EOF
sudo chmod +x /etc/cron.weekly/security-audit
```

---

## 💻 PRACTICE SECTION — 15 Hands-On Exercises

### Practice 1: Run a Lynis Audit

```bash
# 1. Install Lynis
sudo apt update && sudo apt install -y lynis

# 2. Run a full system audit
sudo lynis audit system

# 3. Note your current hardening index

# 4. Identify the top 5 warnings/suggestions

# 5. Apply one fix (e.g., install aide, configure PAM)
```

### Practice 2: Improve Your Hardening Index

```bash
# 1. Based on Lynis suggestions, implement fixes:
#    - Set stricter /etc/shadow permissions
sudo chmod 640 /etc/shadow

#    - Install PAM pwquality
sudo apt install -y libpam-pwquality

#    - Configure password policy
sudo sed -i 's/^PASS_MAX_DAYS.*/PASS_MAX_DAYS 90/' /etc/login.defs
sudo sed -i 's/^PASS_MIN_DAYS.*/PASS_MIN_DAYS 7/' /etc/login.defs
sudo sed -i 's/^PASS_WARN_AGE.*/PASS_WARN_AGE 14/' /etc/login.defs

# 2. Re-run Lynis and compare the hardening index
sudo lynis audit system | grep -i "hardening index"
```

### Practice 3: Run OpenSCAP with CIS Profile

```bash
# 1. Install OpenSCAP
sudo apt install -y openscap-scanner

# 2. Find available content
ls /usr/share/xml/scap/ssg/content/
oscap info /usr/share/xml/scap/ssg/content/ssg-ubuntu2404-ds.xml 2>/dev/null || \
  oscap info /usr/share/xml/scap/ssg/content/ssg-debian10-ds.xml 2>/dev/null || \
  echo "No SCAP content found — install ssg-debian or ssg-rhel"

# 3. Run a scan (adjust filename to match your system)
# sudo oscap xccdf eval --profile xccdf_org.ssgproject.content_profile_cis \
#   --results /tmp/oscap-results.xml --report /tmp/oscap-report.html \
#   /usr/share/xml/scap/ssg/content/ssg-*.xml

# 4. Open the HTML report in a browser
# xdg-open /tmp/oscap-report.html
```

### Practice 4: Configure auditd

```bash
# 1. Install auditd
sudo apt install -y auditd

# 2. Enable and start
sudo systemctl enable --now auditd

# 3. Add a rule to watch /etc/passwd
sudo auditctl -w /etc/passwd -p wa -k passwd_monitor

# 4. Generate an event
sudo useradd testuser_audit

# 5. Search for the event
sudo ausearch -k passwd_monitor -i

# 6. Clean up
sudo userdel testuser_audit
```

### Practice 5: Master ausearch and aureport

```bash
# 1. Add several audit rules
sudo auditctl -w /etc/shadow -p wa -k shadow_mon
sudo auditctl -w /etc/ssh/sshd_config -p wa -k sshd_mon
sudo auditctl -a always,exit -F arch=b64 -S mount -k mount_events

# 2. Generate events
sudo touch /etc/ssh/sshd_config_test 2>/dev/null || true
sudo mount -t tmpfs tmpfs /mnt 2>/dev/null; sudo umount /mnt 2>/dev/null

# 3. Generate reports
sudo aureport --summary
sudo aureport -f
sudo aureport -x

# 4. Find specific events
sudo ausearch -k shadow_mon -i
sudo ausearch -k mount_events -i

# 5. Export report to CSV
sudo aureport -u --csv > /tmp/user-report.csv

# 6. View the csv
column -t -s, /tmp/user-report.csv | head -20
```

### Practice 6: Set Up AIDE Integrity Checking

```bash
# 1. Install AIDE
sudo apt install -y aide aide-common

# 2. Create a baseline database
sudo aideinit
sudo mv /var/lib/aide/aide.db.new /var/lib/aide/aide.db

# 3. Run an integrity check
sudo aide --check

# 4. Make a change to a monitored file
echo "# Test comment" | sudo tee -a /etc/ssh/sshd_config

# 5. Re-check and observe the alert
sudo aide --check | grep -A 2 "changed"

# 6. Update the database to accept the change
sudo aideinit
sudo mv /var/lib/aide/aide.db.new /var/lib/aide/aide.db

# 7. Verify clean check
sudo aide --check | tail -5
```

### Practice 7: Harden SSH Configuration

```bash
# 1. Backup original
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup

# 2. Apply hardening (at minimum):
sudo sshd -T | grep -E 'permitrootlogin|passwordauthentication|maxauthtries' | sort

# 3. If PermitRootLogin is not "no", change it:
sudo sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config

# 4. If PasswordAuthentication is not "no", change it:
sudo sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config

# 5. Add or set MaxAuthTries:
echo "MaxAuthTries 3" | sudo tee -a /etc/ssh/sshd_config

# 6. Test configuration
sudo sshd -t

# 7. Restart
sudo systemctl restart sshd
```

### Practice 8: Enable SELinux Enforcing or AppArmor Profiles

```bash
# For RHEL/CentOS/Fedora (SELinux):
# 1. Check current mode
getenforce

# 2. If not enforcing, try permissive first
sudo setenforce 0
# Run your services — check /var/log/audit/audit.log for denials

# 3. Once no denials, switch to enforcing
sudo setenforce 1

# 4. Make permanent
sudo sed -i 's/^SELINUX=.*/SELINUX=enforcing/' /etc/selinux/config

# For Ubuntu/Debian (AppArmor):
# 1. Check status
sudo aa-status | head -10

# 2. Put a profile in enforce mode
sudo aa-enforce /usr/sbin/nginx 2>/dev/null || echo "No nginx profile found"

# 3. Generate a new profile (if you have a custom app)
# sudo aa-genprof /usr/bin/your-app
```

### Practice 9: Audit and Clean SUID Binaries

```bash
# 1. Create a SUID baseline
sudo find / -perm -4000 -type f 2>/dev/null | sort > /tmp/suid-baseline.txt
echo "Found $(wc -l < /tmp/suid-baseline.txt) SUID binaries"

# 2. Investigate each one — does it NEED setuid?
#    Common legitimate ones: sudo, passwd, su, ping, mount, umount
#    Suspicious ones: anything in /tmp, /var/tmp, or user home dirs

# 3. Remove SUID from unnecessary binaries
sudo chmod -s /usr/bin/wall
sudo chmod -s /usr/bin/write
sudo chmod -s /usr/bin/chsh

# 4. Set up a cron job to detect new SUID files
sudo tee /etc/cron.d/suid-monitor > /dev/null << 'EOF'
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
*/5 * * * * root find / -perm -4000 -type f 2>/dev/null | diff - /etc/security/suid-baseline.txt 2>/dev/null || echo "SUID change detected!" | mail -s "SUID Alert" root
EOF

# 5. Also audit SGID
sudo find / -perm -2000 -type f 2>/dev/null | sort
```

### Practice 10: Harden sysctl Kernel Parameters

```bash
# 1. Apply all kernel hardening parameters
sudo tee /etc/sysctl.d/99-security-hardening.conf > /dev/null << 'EOF'
kernel.randomize_va_space = 2
kernel.kptr_restrict = 2
kernel.dmesg_restrict = 1
kernel.unprivileged_bpf_disabled = 1
kernel.yama.ptrace_scope = 2
kernel.perf_event_paranoid = 3
fs.suid_dumpable = 0
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.tcp_syncookies = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.conf.all.log_martians = 1
EOF

# 2. Apply
sudo sysctl --system

# 3. Verify a few settings
sudo sysctl kernel.randomize_va_space kernel.kptr_restrict kernel.dmesg_restrict

# 4. Check that they persist across reboot
sudo sysctl --system 2>&1 | grep -E 'error|failed' || echo "All parameters applied successfully"
```

### Practice 11: Configure Firewall Lockdown

```bash
# Option A: UFW
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw --force enable
sudo ufw status verbose

# Option B: nftables
sudo systemctl enable --now nftables
sudo nft flush ruleset
sudo nft add table inet filter
sudo nft add chain inet filter input '{ type filter hook input priority 0; policy drop; }'
sudo nft add rule inet filter input ct state established,related accept
sudo nft add rule inet filter input iif lo accept
sudo nft add rule inet filter input tcp dport 22 accept
sudo nft add rule inet filter input ip protocol icmp accept
sudo nft add rule inet filter input log prefix "nft-drop " drop
sudo nft list ruleset | sudo tee /etc/nftables.conf

# Test firewall
sudo nmap -sT -p 22,80,443,3306,8080 localhost
```

### Practice 12: Configure a Remote Log Server

```bash
# 1. On log server (Machine A): configure remote log reception
sudo tee /etc/rsyslog.d/remote-receive.conf > /dev/null << 'EOF'
module(load="imtcp")
module(load="imudp")
input(type="imtcp" port="514")
input(type="imudp" port="514")
*.* /var/log/remote/%hostname%/messages.log
EOF
sudo systemctl restart rsyslog

# 2. Open firewall on log server
sudo ufw allow 514/tcp
sudo ufw allow 514/udp

# 3. On client (Machine B): forward logs
sudo tee /etc/rsyslog.d/forward.conf > /dev/null << 'EOF'
*.* @logserver.example.com:514
EOF
sudo systemctl restart rsyslog

# 4. Generate test log
sudo logger "Test log message from $(hostname)"

# 5. Check on server
sudo ls /var/log/remote/
sudo tail -f /var/log/remote/*/messages.log
```

### Practice 13: Implement a Password Policy

```bash
# 1. Set password aging in /etc/login.defs
sudo sed -i 's/^PASS_MAX_DAYS.*/PASS_MAX_DAYS 90/' /etc/login.defs
sudo sed -i 's/^PASS_MIN_DAYS.*/PASS_MIN_DAYS 7/' /etc/login.defs
sudo sed -i 's/^PASS_WARN_AGE.*/PASS_WARN_AGE 14/' /etc/login.defs

# 2. Install pwquality
sudo apt install -y libpam-pwquality

# 3. Configure strong password rules
sudo tee /etc/security/pwquality.conf > /dev/null << 'EOF'
minlen = 14
dcredit = -1
ucredit = -1
lcredit = -1
ocredit = -1
maxrepeat = 3
minclass = 3
enforce_for_root
EOF

# 4. Test by creating a weak password
sudo useradd testpam
echo "testpam:weak" | sudo chpasswd 2>&1 || echo "Weak password correctly rejected"
sudo userdel -r testpam

# 5. Set account lockout policy
sudo apt install -y libpam-modules
# (See Section 7 for the full PAM faillock configuration)
```

### Practice 14: Create a Complete Security Audit Script

```bash
#!/bin/bash
# comprehensive-security-audit.sh
# Run with: sudo bash comprehensive-security-audit.sh

REPORT="/tmp/security-audit-$(date +%Y%m%d-%H%M).txt"

echo "==========================================" | tee "$REPORT"
echo "  COMPREHENSIVE SECURITY AUDIT" | tee -a "$REPORT"
echo "  $(date)" | tee -a "$REPORT"
echo "==========================================" | tee -a "$REPORT"

# 1. System Information
echo "" | tee -a "$REPORT"
echo "--- 1. SYSTEM INFORMATION ---" | tee -a "$REPORT"
echo "Hostname: $(hostname)" | tee -a "$REPORT"
echo "Kernel: $(uname -r)" | tee -a "$REPORT"
echo "OS: $(lsb_release -ds 2>/dev/null || cat /etc/os-release 2>/dev/null | head -1)" | tee -a "$REPORT"
echo "Uptime: $(uptime -p)" | tee -a "$REPORT"

# 2. User Accounts
echo "" | tee -a "$REPORT"
echo "--- 2. USER ACCOUNTS ---" | tee -a "$REPORT"
echo "Users with UID 0 (should be only root):" | tee -a "$REPORT"
awk -F: '($3 == 0) { print $1 }' /etc/passwd | tee -a "$REPORT"
echo "" | tee -a "$REPORT"
echo "Users with login shells:" | tee -a "$REPORT"
grep -v "/usr/sbin/nologin\|/bin/false" /etc/passwd | awk -F: '{print $1 " -> " $7}' | tee -a "$REPORT"
echo "" | tee -a "$REPORT"
echo "Empty passwords:" | tee -a "$REPORT"
awk -F: '($2 == "" ) { print $1 }' /etc/shadow 2>/dev/null | tee -a "$REPORT"

# 3. SUID/SGID Files
echo "" | tee -a "$REPORT"
echo "--- 3. SUID/SGID FILES ---" | tee -a "$REPORT"
echo "SUID count: $(find / -perm -4000 -type f 2>/dev/null | wc -l)" | tee -a "$REPORT"
echo "SGID count: $(find / -perm -2000 -type f 2>/dev/null | wc -l)" | tee -a "$REPORT"

# 4. Listening Ports
echo "" | tee -a "$REPORT"
echo "--- 4. LISTENING PORTS ---" | tee -a "$REPORT"
ss -tlnp 2>/dev/null | tee -a "$REPORT"

# 5. SSH Configuration
echo "" | tee -a "$REPORT"
echo "--- 5. SSH CONFIGURATION ---" | tee -a "$REPORT"
[ -f /etc/ssh/sshd_config ] && {
  echo "PermitRootLogin: $(sshd -T 2>/dev/null | grep -i permitrootlogin | awk '{print $2}')"
  echo "PasswordAuthentication: $(sshd -T 2>/dev/null | grep -i passwordauthentication | awk '{print $2}')"
  echo "PubkeyAuthentication: $(sshd -T 2>/dev/null | grep -i pubkeyauthentication | awk '{print $2}')"
  echo "Protocol: $(sshd -T 2>/dev/null | grep -i protocol | awk '{print $2}')"
  echo "MaxAuthTries: $(sshd -T 2>/dev/null | grep -i maxauthtries | awk '{print $2}')"
} | tee -a "$REPORT"

# 6. Auditd Status
echo "" | tee -a "$REPORT"
echo "--- 6. AUDITD STATUS ---" | tee -a "$REPORT"
systemctl is-active auditd 2>/dev/null | tee -a "$REPORT"
auditctl -s 2>/dev/null | grep enabled | tee -a "$REPORT"

# 7. AIDE Status
echo "" | tee -a "$REPORT"
echo "--- 7. AIDE STATUS ---" | tee -a "$REPORT"
[ -f /var/lib/aide/aide.db ] && echo "AIDE database exists: $(du -h /var/lib/aide/aide.db | cut -f1)" || echo "AIDE database NOT found" | tee -a "$REPORT"

# 8. Failed Logins
echo "" | tee -a "$REPORT"
echo "--- 8. FAILED LOGINS (last 24h) ---" | tee -a "$REPORT"
lastb -s "$(date -d '24 hours ago' +%Y%m%d%H%M%S)" 2>/dev/null | head -20 | tee -a "$REPORT"

# 9. Pending Updates
echo "" | tee -a "$REPORT"
echo "--- 9. PENDING SECURITY UPDATES ---" | tee -a "$REPORT"
apt list --upgradable 2>/dev/null | grep -i security | tee -a "$REPORT"

# 10. Kernel Security Parameters
echo "" | tee -a "$REPORT"
echo "--- 10. KERNEL SECURITY PARAMETERS ---" | tee -a "$REPORT"
for param in kernel.randomize_va_space kernel.kptr_restrict kernel.dmesg_restrict kernel.unprivileged_bpf_disabled kernel.yama.ptrace_scope net.ipv4.conf.all.rp_filter net.ipv4.tcp_syncookies net.ipv4.conf.all.accept_redirects; do
  echo "$param = $(sysctl -n $param 2>/dev/null || echo 'N/A')"
done | tee -a "$REPORT"

# 11. World-Writable Files
echo "" | tee -a "$REPORT"
echo "--- 11. WORLD-WRITABLE FILES (first 30) ---" | tee -a "$REPORT"
find / -type f -perm -0002 ! -type l 2>/dev/null | head -30 | tee -a "$REPORT"

# 12. Failed Services
echo "" | tee -a "$REPORT"
echo "--- 12. FAILED SYSTEMD SERVICES ---" | tee -a "$REPORT"
systemctl --failed | tee -a "$REPORT"

echo "" | tee -a "$REPORT"
echo "==========================================" | tee -a "$REPORT"
echo "  AUDIT COMPLETE" | tee -a "$REPORT"
echo "  Report saved to: $REPORT" | tee -a "$REPORT"
echo "==========================================" | tee -a "$REPORT"
```

### Practice 15: Real-World Integration — Complete Hardening and Audit Script

This is the capstone exercise. Write a single script that:

1. Runs all the individual security hardening steps from this entire part
2. Runs a Lynis audit
3. Runs an AIDE check
4. Runs an OpenSCAP scan (if available)
5. Generates a summary report with pass/fail for each category
6. Emails the report to the admin

```bash
#!/bin/bash
# ============================================================
# real-world-hardening.sh — Complete Security Hardening & Audit
# ============================================================
# This script implements ALL hardening measures from Part 49
# and runs a comprehensive audit.
#
# Usage: sudo bash real-world-hardening.sh
# ============================================================

set -euo pipefail

LOG="/var/log/security-hardening-$(date +%Y%m%d-%H%M).log"
REPORT="/tmp/hardening-report-$(date +%Y%m%d-%H%M).txt"
ADMIN_EMAIL="root"

# Redirect all output to log
exec > >(tee -a "$LOG") 2>&1

echo "========================================="
echo " SECURITY HARDENING & AUDIT"
echo " Started: $(date)"
echo "========================================="

# --- HELPER FUNCTIONS ---
pass() { echo "  ✅ $1"; }
fail() { echo "  ❌ $1"; }
info() { echo "  ℹ️  $1"; }

# --- SECTION 2: CIS BENCHMARKS (basic) ---
apply_cis() {
    echo ""
    echo "=== CIS Benchmark Hardening ==="

    # Disable unused filesystems
    for fs in crampfs freevxfs jffs2 hfs hfsplus squashfs udf; do
        sudo modprobe -r "$fs" 2>/dev/null && info "Removed $fs module" || true
    done

    # Secure /dev/shm
    mount -o remount,nodev,nosuid,noexec /dev/shm 2>/dev/null && pass "/dev/shm secured" || fail "Could not remount /dev/shm"

    pass "CIS basic hardening applied"
}

# --- SECTION 3: LYNIS ---
run_lynis() {
    echo ""
    echo "=== Lynis Audit ==="
    if ! command -v lynis &>/dev/null; then
        apt-get install -y lynis
    fi
    lynis audit system 2>&1 | tee /tmp/lynis-output.txt
    HARDENING_INDEX=$(grep "hardening index" /tmp/lynis-output.txt | grep -oP '\d+')
    echo "Hardening Index: $HARDENING_INDEX"
    echo "Lynis audit complete" >> "$REPORT"
}

# --- SECTION 4: OPENSCAP ---
run_oscap() {
    echo ""
    echo "=== OpenSCAP Scan ==="
    if command -v oscap &>/dev/null; then
        local CONTENT
        CONTENT=$(ls /usr/share/xml/scap/ssg/content/ssg-*-ds.xml 2>/dev/null | head -1)
        if [ -n "$CONTENT" ]; then
            oscap xccdf eval \
                --profile xccdf_org.ssgproject.content_profile_cis_level1_server \
                --results /tmp/oscap-results.xml \
                --report /tmp/oscap-report.html \
                "$CONTENT" 2>/dev/null && pass "OpenSCAP scan complete" || fail "OpenSCAP scan had errors"
        else
            info "No SCAP content found — skipping"
        fi
    else
        info "OpenSCAP not installed — skipping"
    fi
}

# --- SECTION 5: AUDITD ---
configure_auditd() {
    echo ""
    echo "=== Auditd Configuration ==="
    if ! systemctl is-active --quiet auditd; then
        apt-get install -y auditd
        systemctl enable --now auditd
    fi

    # Apply standard rules
    auditctl -D 2>/dev/null
    auditctl -b 8192

    # File watches
    auditctl -w /etc/passwd -p wa -k passwd_changes
    auditctl -w /etc/shadow -p wa -k shadow_changes
    auditctl -w /etc/group -p wa -k group_changes
    auditctl -w /etc/sudoers -p wa -k sudoers_changes
    auditctl -w /etc/ssh/sshd_config -p wa -k sshd_config

    # Syscall auditing
    auditctl -a always,exit -F arch=b64 -S execve -C uid!=euid -F euid=0 -k priv_esc

    pass "Auditd configured with $(auditctl -l | wc -l) rules"
}

# --- SECTION 6: AIDE ---
setup_aide() {
    echo ""
    echo "=== AIDE Integrity Check ==="
    if ! command -v aide &>/dev/null; then
        apt-get install -y aide aide-common
    fi
    if [ ! -f /var/lib/aide/aide.db ]; then
        aideinit
        mv /var/lib/aide/aide.db.new /var/lib/aide/aide.db
    fi
    aide --check 2>&1 | tail -5
    pass "AIDE check complete"
}

# --- SECTION 7: USER ACCOUNT HARDENING ---
harden_users() {
    echo ""
    echo "=== User Account Hardening ==="

    # Password aging
    sed -i 's/^PASS_MAX_DAYS.*/PASS_MAX_DAYS 90/' /etc/login.defs
    sed -i 's/^PASS_MIN_DAYS.*/PASS_MIN_DAYS 7/' /etc/login.defs
    sed -i 's/^PASS_WARN_AGE.*/PASS_WARN_AGE 14/' /etc/login.defs
    pass "Password aging configured"

    # pwquality
    apt-get install -y libpam-pwquality
    cat > /etc/security/pwquality.conf << 'EOF'
minlen = 14
dcredit = -1
ucredit = -1
lcredit = -1
ocredit = -1
maxrepeat = 3
minclass = 3
enforce_for_root
EOF
    pass "Password quality configured"

    # Check for users with UID 0 (other than root)
    local extra_root
    extra_root=$(awk -F: '($3 == 0) {print $1}' /etc/passwd | grep -v "^root$" || true)
    if [ -n "$extra_root" ]; then
        fail "Extra UID 0 users: $extra_root"
    else
        pass "No extra UID 0 users"
    fi
}

# --- SECTION 8: FILESYSTEM SECURITY ---
harden_filesystem() {
    echo ""
    echo "=== Filesystem Security ==="

    # Find and flag world-writable files
    local www_count
    www_count=$(find / -type f -perm -0002 ! -type l 2>/dev/null | wc -l)
    info "World-writable files: $www_count"

    # SUID audit
    local suid_count
    suid_count=$(find / -perm -4000 -type f 2>/dev/null | wc -l)
    info "SUID binaries: $suid_count"

    # Check sticky bit on /tmp
    local tmp_sticky
    tmp_sticky=$(stat -c %a /tmp)
    if [ "${tmp_sticky: -1}" = "1" ]; then
        pass "/tmp has sticky bit"
    else
        chmod +t /tmp && pass "Set sticky bit on /tmp"
    fi
}

# --- SECTION 9: NETWORK SECURITY ---
harden_network() {
    echo ""
    echo "=== Network Security ==="

    # List listening ports
    info "Listening ports:"
    ss -tlnp | tail -n +2

    # Enable firewall if UFW
    if command -v ufw &>/dev/null; then
        ufw --force enable 2>/dev/null
        ufw default deny incoming 2>/dev/null
        ufw default allow outgoing 2>/dev/null
        ufw allow ssh 2>/dev/null
        pass "UFW firewall enabled"
    fi
}

# --- SECTION 10: KERNEL HARDENING ---
harden_kernel() {
    echo ""
    echo "=== Kernel Hardening ==="
    cat > /etc/sysctl.d/99-security-hardening.conf << 'EOF'
kernel.randomize_va_space = 2
kernel.kptr_restrict = 2
kernel.dmesg_restrict = 1
kernel.unprivileged_bpf_disabled = 1
kernel.yama.ptrace_scope = 2
kernel.perf_event_paranoid = 3
fs.suid_dumpable = 0
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.tcp_syncookies = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.conf.all.log_martians = 1
EOF
    sysctl --system > /dev/null 2>&1
    pass "Kernel parameters hardened"

    # Verify key params
    for p in kernel.randomize_va_space kernel.kptr_restrict kernel.dmesg_restrict; do
        val=$(sysctl -n "$p")
        [ "$val" -gt 0 ] && pass "$p = $val" || fail "$p = $val (should be > 0)"
    done
}

# --- SECTION 11: APPARMOR/SELINUX ---
harden_mac() {
    echo ""
    echo "=== MAC (Mandatory Access Control) ==="
    if command -v getenforce &>/dev/null; then
        local mode
        mode=$(getenforce)
        if [ "$mode" = "Enforcing" ]; then
            pass "SELinux is Enforcing"
        else
            fail "SELinux is $mode (should be Enforcing)"
        fi
    elif command -v aa-status &>/dev/null; then
        local profiles
        profiles=$(aa-status 2>/dev/null | grep "profiles are in enforce" | grep -oP '\d+')
        if [ -n "$profiles" ] && [ "$profiles" -gt 0 ]; then
            pass "AppArmor: $profiles profiles in enforce mode"
        else
            fail "AppArmor: No profiles in enforce mode"
        fi
    else
        info "No MAC system detected (SELinux or AppArmor)"
    fi
}

# --- SECTION 12: SSH HARDENING ---
harden_ssh() {
    echo ""
    echo "=== SSH Hardening ==="
    local config="/etc/ssh/sshd_config"
    if [ -f "$config" ]; then
        sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' "$config"
        sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' "$config"
        sed -i 's/^#\?PubkeyAuthentication.*/PubkeyAuthentication yes/' "$config"
        grep -q "^MaxAuthTries" "$config" && \
          sed -i 's/^MaxAuthTries.*/MaxAuthTries 3/' "$config" || \
          echo "MaxAuthTries 3" >> "$config"
        sshd -t && systemctl restart sshd && pass "SSH hardened" || fail "SSH config has errors"
    else
        fail "sshd_config not found"
    fi
}

# --- MAIN EXECUTION ---
{
    apply_cis
    run_lynis
    run_oscap
    configure_auditd
    setup_aide
    harden_users
    harden_filesystem
    harden_network
    harden_kernel
    harden_mac
    harden_ssh
} 2>&1

echo ""
echo "========================================="
echo " HARDENING AND AUDIT COMPLETE"
echo " Log: $LOG"
echo " Report: $REPORT"
echo "========================================="

# Generate summary
{
    echo "Security Hardening Summary — $(date)"
    echo "====================================="
    echo "Lynis Hardening Index: $(grep -oP 'Hardening Index: \K\d+' /tmp/lynis-output.txt 2>/dev/null || echo 'N/A')"
    echo "AIDE check: $(aide --check 2>&1 | tail -1)"
    echo "Auditd rules: $(auditctl -l | wc -l)"
    echo "SUID binaries: $(find / -perm -4000 -type f 2>/dev/null | wc -l)"
} >> "$REPORT"

# Email report
mail -s "Security Hardening Report — $(hostname) — $(date +%F)" "$ADMIN_EMAIL" < "$REPORT" 2>/dev/null || true

echo ""
echo "Report emailed to $ADMIN_EMAIL"
```

---

## 🧠 Deep Understanding

### How Linux Auditd Hooks Into the Kernel

The Linux Audit Framework operates at the **kernel level** through the following mechanism:

1. **System call interception**: When a syscall like `open()`, `execve()`, or `write()` is made, the kernel's syscall entry point checks whether audit rules are loaded.

2. **kauditd thread**: If a rule matches, the **kauditd** kernel thread generates an audit record containing:
   - Syscall number, arguments, return value
   - Process context (PID, UID, GID, SELinux context)
   - Security context (capabilities, LSM labels)
   - Timestamp and serial number

3. **Netlink socket**: kauditd sends the record to userspace via a **netlink socket** (protocol family `AF_NETLINK`, type `NETLINK_AUDIT`). This is a special socket type for kernel-userspace communication.

4. **auditd daemon**: The userspace `auditd` daemon reads from the netlink socket, formats the records, and writes them to `/var/log/audit/audit.log`.

5. **Audit dispatcher (audispd)**: `audispd` can forward audit events to other consumers (e.g., `ausearch`, SIEM systems, or custom scripts) via plugins in `/etc/audit/plugins.d/`.

```
Userspace:
  ┌──────────────────────────────────────┐
  │  auditd ← reads from netlink socket  │
  │    ↓ writes to /var/log/audit/*.log  │
  │  audispd → dispatches to plugins     │
  │  auditctl → sets rules via netlink   │
  └────────────┬─────────────────────────┘
               │ AF_NETLINK / NETLINK_AUDIT
Kernel:
  ┌────────────┴─────────────────────────┐
  │  syscall entry → audit_filter()      │
  │    ↓ if match                        │
  │  kauditd → build record              │
  │    ↓ send via netlink                │
  │  audit rules stored in kernel memory  │
  └──────────────────────────────────────┘
```

Key kernel source paths:
- `kernel/audit.c` — Core audit subsystem
- `kernel/auditsc.c` — Syscall auditing
- `kernel/auditfilter.c` — Rule matching
- `kernel/audit_watch.c` — File/directory watches (fanotify-based)

### How AIDE Builds and Compares File Hash Databases

AIDE works in two phases:

**Phase 1 — Database Creation (`aideinit`)**:

```
For each file/directory matching rules in aide.conf:
  1. stat() the file → get metadata (permissions, owner, size, mtime)
  2. Read the file → compute hashes:
     - SHA-256
     - SHA-512
     - RMD-160
     - MD5 (if configured)
     - Tiger (if configured)
  3. Store metadata + hashes in /var/lib/aide/aide.db
     (proprietary binary format, compressed)
```

**Phase 2 — Integrity Check (`aide --check`)**:

```
For each file/directory in aide.db:
  1. stat() the file → get current metadata
  2. Read the file → compute current hashes
  3. Compare against stored values:
     ┌──────────────┬──────────────┐
     │ Match?       │ Result       │
     ├──────────────┼──────────────┤
     │ All match    │ "ok"         │
     │ Metadata     │ "changed"    │
     │  changed     │ (report diff)│
     │ Hash changed │ "changed"    │
     │              │ (possible    │
     │              │  tampering)  │
     │ File missing │ "missing"    │
     │ New file     │ "added"      │
     │  (if rule    │              │
     │   allows)    │              │
     └──────────────┴──────────────┘
```

**Security notes**:
- The database file (`aide.db`) should be stored on **read-only media** (e.g., a mounted ISO or USB key) to prevent tampering.
- AIDE must be run from a **trusted environment** (e.g., single-user mode or from a live CD) for forensic-level integrity verification.
- AIDE uses the kernel's `audit_fill_sig` mechanism to verify its own binary has not been tampered with.

### How SELinux MLS/MCS Works

**MLS (Multi-Level Security)** and **MCS (Multi-Category Security)** extend SELinux with sensitivity labels:

**Security context format**:
```
user:role:type:sensitivity[:categories]

Example (MLS):
    john:user_r:user_t:s1:c1.c5,c10

Example (MCS — simplified MLS used by Docker, sVirt):
    system_u:system_r:svirt_t:s0:c98,c312
```

**MLS (Bell-LaPadula model)**:
- Each subject (process) has a **clearance level** (e.g., s0 = unclassified, s1 = secret, s2 = top_secret)
- Each object (file) has a **classification level**
- **No read up**: A subject at s1 cannot read an object at s2
- **No write down**: A subject at s2 cannot write to an object at s1

**MCS (simplified MLS)**:
- Adds categories (`c0` through `c1023`)
- Categories are orthogonal to levels — they represent compartments (e.g., `c100 = finance`, `c200 = HR`)
- A subject must have all of an object's categories to access it

```
                   MLS Level
                s2 (Top Secret)
                s1 (Secret)
                s0 (Unclassified)
                     │
       ┌─────────────┼─────────────┐
       c0     c1     c2 ...  c1023
       └──────────────────────────┘
             MCS Categories
```

**Docker/sVirt example**:
```
Container A: system_u:system_r:svirt_t:s0:c1,c2
Container B: system_u:system_r:svirt_t:s0:c3,c4
File A:      system_u:object_r:svirt_file_t:s0:c1,c2
File B:      system_u:object_r:svirt_file_t:s0:c3,c4
```
Container A can access File A (same categories) but not File B (different categories). This is how sVirt isolates container filesystems even if the processes escape.

### How LSM (Linux Security Module) Framework Works

The **Linux Security Module** framework is a kernel hook system that allows security modules (SELinux, AppArmor, Smack, Tomoyo, Yama) to intercept system calls **after** the standard DAC (Discretionary Access Control) check:

```
System call (e.g., open())
  │
  ▼
┌──────────────────────┐
│ 1. DAC Check         │ ← Standard Unix permissions
│    (uid/gid/mode)    │    If DENIED → return -EACCES
└──────────┬───────────┘
           │ PASS
           ▼
┌──────────────────────┐
│ 2. LSM Hook          │ ← Generic hook point
│    (security_*)       │    Called by kernel for every
│                       │    security-relevant operation
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│ 3. Specific Module   │ ← SELinux / AppArmor / etc.
│    Check             │    Makes MAC decision
│    (e.g., selinux_    │    If DENIED → return -EACCES
│     inode_permission)│
└──────────┬───────────┘
           │ PASS
           ▼
    Operation proceeds
```

**Key LSM hooks** (defined in `include/linux/security.h`):
```c
// File operations
security_file_permission()
security_inode_permission()
security_inode_create()
security_inode_unlink()

// Process operations
security_task_ptrace()
security_task_kill()
security_bprm_check()      // execve checks

// Network operations
security_socket_connect()
security_socket_bind()
security_socket_listen()

// System-wide
security_sb_mount()
security_kernel_module_from_file()
```

**The `CONFIG_LSM` kernel option** determines which modules are stacked:

```bash
# Check which LSMs are enabled
cat /sys/kernel/security/lsm
# Example output: "lockdown,capability,yama,apparmor"
# Example output: "lockdown,capability,yama,selinux"
```

**Module initialization flow**:
1. Kernel boots, calls `security_init()` for each module in `CONFIG_LSM` order
2. Each module initializes its own data structures (policy database, context caches)
3. Each module registers its hook functions in the global `security_hook_heads`
4. When a hook point is reached, the kernel iterates through stacked modules and calls each one's hook function
5. If any module returns an error, the operation is denied

### DAC vs MAC — The Fundamental Difference

| Aspect | DAC (Discretionary Access Control) | MAC (Mandatory Access Control) |
|--------|-----------------------------------|--------------------------------|
| **Who decides** | File owners set permissions | System policy (written by admin) |
| **Override** | Root can override anything | Even root is constrained |
| **Mechanism** | `rwx` bits, ACLs | SELinux types, AppArmor profiles |
| **Granularity** | Owner/group/other | Full process/file labeling |
| **Scope** | Files only | Files, processes, network, IPC, capabilities |
| **Bypass** | `sudo`, `chmod 777` | Only policy changes (require reload) |
| **Example** | `chmod 600 /etc/shadow` | `allow httpd_t httpd_log_t:file { write };` |

**DAC** is discretionary because the owner of a file decides who can access it. Root can always override.

**MAC** is mandatory because the system policy applies to everyone, including root. If the SELinux policy says Apache cannot write to `/etc/shadow`, then `httpd_t` cannot — even if the DAC permissions say `rw-rw-rw-`.

Both are needed: DAC first, then MAC as a safety net.

---

## 📋 Summary — Complete Command Reference

### Security Auditing Tools

| Command | Purpose | Example |
|---------|---------|---------|
| `lynis audit system` | Run Lynis security audit | `sudo lynis audit system` |
| `lynis show categories` | Show Lynis test categories | `sudo lynis show categories` |
| `oscap xccdf eval` | Run SCAP compliance scan | `sudo oscap xccdf eval --profile cis --results r.xml --report r.html content.xml` |
| `oscap info` | Display SCAP content info | `oscap info ssg-rhel9-ds.xml` |
| `oscap xccdf generate fix` | Generate remediation script | `oscap xccdf generate fix --profile cis --fix-type bash content.xml` |

### Auditd

| Command | Purpose | Example |
|---------|---------|---------|
| `auditctl -l` | List active audit rules | `sudo auditctl -l` |
| `auditctl -w path -p rwxa -k key` | Watch file/directory | `sudo auditctl -w /etc/passwd -p wa -k passwd_changes` |
| `auditctl -a always,exit -S syscall` | Watch system call | `sudo auditctl -a always,exit -F arch=b64 -S execve -k exec` |
| `auditctl -D` | Delete all rules | `sudo auditctl -D` |
| `ausearch -k key` | Search audit log by key | `sudo ausearch -k passwd_changes` |
| `ausearch -au uid` | Search by user ID | `sudo ausearch -au 1000` |
| `ausearch -ts start -te end` | Search by time range | `sudo ausearch -ts 10:00:00 -te 11:00:00` |
| `ausearch -i` | Interpret output (UIDs→names) | `sudo ausearch -k passwd_changes -i` |
| `aureport --summary` | Generate summary report | `sudo aureport --summary` |
| `aureport -au` | Authentication report | `sudo aureport -au` |
| `aureport -x` | Executable report | `sudo aureport -x` |
| `aureport -f` | File access report | `sudo aureport -f` |
| `aureport -l` | Login report | `sudo aureport -l` |

### File Integrity

| Command | Purpose | Example |
|---------|---------|---------|
| `aideinit` | Initialize AIDE database | `sudo aideinit` |
| `aide --check` | Run AIDE integrity check | `sudo aide --check` |
| `aide --update` | Update AIDE database | `sudo aide --update` |
| `ossec-check` | Run OSSEC integrity check | `sudo /var/ossec/bin/ossec-check` |

### AppArmor

| Command | Purpose | Example |
|---------|---------|---------|
| `aa-status` | Show AppArmor status | `sudo aa-status` |
| `aa-enforce profile` | Set profile to enforce | `sudo aa-enforce /usr/sbin/nginx` |
| `aa-complain profile` | Set profile to complain | `sudo aa-complain /usr/sbin/nginx` |
| `aa-disable profile` | Disable profile | `sudo aa-disable /usr/sbin/nginx` |
| `aa-genprof binary` | Generate new profile | `sudo aa-genprof /usr/bin/custom-app` |
| `aa-logprof` | Review log and update profile | `sudo aa-logprof` |

### SELinux

| Command | Purpose | Example |
|---------|---------|---------|
| `getenforce` | Show current SELinux mode | `getenforce` |
| `setenforce 0\|1` | Set permissive/enforcing | `sudo setenforce 1` |
| `getsebool -a` | List all booleans | `getsebool -a` |
| `setsebool -P bool on` | Set boolean persistently | `sudo setsebool -P httpd_can_network_connect on` |
| `ls -Z` | Show file context | `ls -Z /etc/passwd` |
| `ps -Z` | Show process context | `ps -Z $(pgrep httpd)` |
| `chcon -t type file` | Change file context | `sudo chcon -t httpd_sys_content_t /var/www/index.html` |
| `restorecon -Rv dir` | Restore default context | `sudo restorecon -Rv /var/www` |
| `semanage fcontext -l` | List file context defaults | `sudo semanage fcontext -l` |
| `audit2allow -a` | Generate allow rules from log | `sudo audit2allow -a -M mymodule` |
| `audit2why` | Explain SELinux denials | `sudo ausearch -m AVC -ts today | audit2why` |

### Filesystem Security

| Command | Purpose | Example |
|---------|---------|---------|
| `find / -perm -4000 -type f` | Find SUID binaries | `sudo find / -perm -4000 -type f` |
| `find / -perm -2000 -type f` | Find SGID binaries | `sudo find / -perm -2000 -type f` |
| `chmod +t dir` | Set sticky bit | `sudo chmod +t /shared` |
| `chattr +i file` | Make file immutable | `sudo chattr +i /etc/passwd` |
| `chattr +a file` | Make file append-only | `sudo chattr +a /var/log/auth.log` |
| `lsattr file` | List file attributes | `lsattr /etc/passwd` |

### Kernel Hardening

| Command | Purpose | Example |
|---------|---------|---------|
| `sysctl -a` | List all kernel parameters | `sysctl -a | grep kernel` |
| `sysctl --system` | Apply all sysctl files | `sudo sysctl --system` |
| `sysctl -w param=value` | Set parameter temporarily | `sudo sysctl -w kernel.randomize_va_space=2` |

### Network Security

| Command | Purpose | Example |
|---------|---------|---------|
| `ss -tlnp` | List TCP listening ports | `sudo ss -tlnp` |
| `ss -ulnp` | List UDP listening ports | `sudo ss -ulnp` |
| `ufw enable` | Enable UFW firewall | `sudo ufw --force enable` |
| `nft list ruleset` | List nftables rules | `sudo nft list ruleset` |
| `nmap -sV -sC target` | Service/version scan | `nmap -sV -sC localhost` |

### System Information for Auditing

| Command | Purpose | Example |
|---------|---------|---------|
| `lastb` | Show failed login attempts | `lastb \| head -20` |
| `last` | Show last logins | `last \| head -20` |
| `w` | Who is logged in | `w` |
| `journalctl -p err -b` | System errors since boot | `journalctl -p err -b` |

---

## 🚀 What's Coming in Part 50

Security is never finished — it's a continuous process of assessment, hardening, monitoring, and improvement. In Part 50, we will continue the advanced administration track with:

- **Cloud Infrastructure** — AWS, GCP, Azure fundamentals for sysadmins
- **Infrastructure as Code** — Terraform, Ansible, Pulumi
- **Kubernetes Administration** — Cluster setup, pod security, RBAC
- **CI/CD Pipelines** — GitHub Actions, GitLab CI, Jenkins
- **Automation at Scale** — Configuration management with Ansible, Puppet, SaltStack
- **Monitoring & Observability** — Prometheus, Grafana, OpenTelemetry

---

## ✅ Self-Test

**Score:** 15/15 correct = ready for Part 50.

1. What are the three principles of the CIA triad? Give a real-world example of each.

2. Explain defense in depth. Why is a single firewall not enough?

3. What does the Lynis **hardening index** measure? What is a reasonable target score?

4. Write the command to run a Lynis audit and save the output to a file.

5. What is the difference between XCCDF, OVAL, and CPE in the SCAP standard?

6. Write an auditctl rule to watch `/etc/shadow` for write and attribute changes, with key `shadow_mon`.

7. After adding an audit rule, how do you search the log for events matching that rule?

8. What is the purpose of `kernel.randomize_va_space = 2`? Explain what happens at each value (0, 1, 2).

9. Explain the difference between `chattr +i` and `chattr +a`. When would you use each?

10. In SELinux, what do each of the four fields in `unconfined_u:object_r:httpd_sys_content_t:s0` mean?

11. What is the difference between `aa-enforce` and `aa-complain`? When should you use each?

12. Write the sshd_config directives needed to disable root login and require SSH keys only.

13. What is the role of the `kauditd` kernel thread? How does it communicate with `auditd`?

14. What is the difference between DAC and MAC? Give one example of each.

15. Your boss asks you to "harden the company's production web server." List the 5 most impactful changes you would make, in order of priority.

**Answers:**

**1.** Confidentiality (only authorized access — file permissions 600 on /etc/shadow), Integrity (data not tampered — AIDE checksums), Availability (system is up — RAID, backups, failover cluster).

**2.** Defense in depth layers multiple independent security controls. A firewall alone is not enough because: (a) an insider can bypass it, (b) a compromised web app can be attacked through allowed ports (80/443), (c) zero-day exploits bypass known rules. You need firewalls + SELinux + auditd + AIDE + PAM + SSH hardening + regular patching.

**3.** The hardening index (0-100) measures how well the system is secured based on hundreds of individual tests. A score of 60-80 is reasonable for a general-purpose server; 80+ is well-hardened.

**4.** `sudo lynis audit system | tee /tmp/lynis-audit.log`

**5.** XCCDF = checklist/benchmark format (what to check); OVAL = language for checking system state (how to check); CPE = platform identification (what system this applies to).

**6.** `sudo auditctl -w /etc/shadow -p wa -k shadow_mon`

**7.** `sudo ausearch -k shadow_mon -i`

**8.** `kernel.randomize_va_space`: 0 = ASLR disabled (all addresses predictable); 1 = randomize stack, libraries, mmap; 2 = full randomization including brk/heap base. Value 2 provides maximum protection against buffer overflow attacks.

**9.** `chattr +i` (immutable) — file cannot be modified, deleted, renamed, or linked, even by root. Use for critical config files like `/etc/passwd`, `/etc/sudoers`. `chattr +a` (append-only) — file can only be opened for appending. Use for log files like `/var/log/auth.log` so logs cannot be deleted or overwritten, only appended.

**10.** `unconfined_u` = SELinux user; `object_r` = role; `httpd_sys_content_t` = type (the primary access control attribute); `s0` = MLS sensitivity level.

**11.** `aa-enforce` actively blocks actions not in the profile (production use). `aa-complain` logs violations but allows them (testing/development — used to build and refine a profile before enforcing).

**12.** ```
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
AuthenticationMethods publickey
```

**13.** `kauditd` is a kernel thread that generates audit records when syscalls match audit rules. It communicates with `auditd` via a netlink socket (AF_NETLINK, NETLINK_AUDIT) — a special socket type for kernel-to-userspace communication.

**14.** DAC (Discretionary Access Control) — file owners set permissions; root can override. Example: `chmod 600 file`. MAC (Mandatory Access Control) — system policy applies to all, including root. Example: SELinux type enforcement prevents `httpd_t` from writing to `/etc/shadow` even if DAC says yes.

**15.** Priority order: (1) Harden SSH — disable root login, require keys; (2) Set up firewall — deny all inbound except ports 80, 443, 22; (3) Enable automatic security updates; (4) Enable auditd and AIDE to detect and log changes; (5) Apply kernel hardening parameters (ASLR, kptr_restrict, etc.) and SELinux/AppArmor enforcing.

---

## 🎓 Course Progress — What's Ahead

**Congratulations!** You have completed Parts 1-49 of the Linux System Administrator Course.

You have covered:
- **Parts 1–10:** Linux Fundamentals (filesystem, permissions, processes, boot)
- **Parts 11–25:** Essential Operations (packages, systemd, cron, logging, SSH, firewalls, SELinux, kernel, rescue)
- **Parts 26–40:** Intermediate Administration (networking, RAID, LVM, scripting, containers, web, databases)
- **Parts 41–49:** Advanced Administration (LDAP, DNS, DHCP, mail, proxies, monitoring, HA, security)

### What's Next (Parts 50+)

You have built a rock-solid foundation in on-premises Linux system administration. The next frontier is **cloud-native infrastructure and automation at scale**. Modern sysadmins are expected to manage not just physical and virtual servers, but also cloud resources (AWS, GCP, Azure), container orchestrators (Kubernetes, Docker Swarm), CI/CD pipelines (GitHub Actions, GitLab CI, Jenkins), and configuration management tooling (Ansible, Terraform, Pulumi). Starting with Part 50, the course pivots to these topics — bridging the gap between traditional Linux administration and the DevOps/SRE world. You will learn to treat infrastructure as code, deploy immutable systems, automate everything with playbooks, and monitor entire fleets with Prometheus and Grafana. The challenges change, but the fundamentals you mastered in Parts 1-49 will serve you every step of the way.

### Recommended Next Steps
1. **Review any weak areas** from the self-tests in Parts 41-48
2. **Build a homelab** with multiple VMs and practice everything you've learned
3. **Start Part 50** — Cloud Infrastructure and Infrastructure as Code

---

> **Security is not a product, but a process.** — Bruce Schneier

---

```
*Linux SysAdmin Course | Part 49 of ∞ | Reverse Engineering Approach*
*Previous → Part 48: High Availability and Clustering*
*Next → Part 50: Cloud Infrastructure and Automation*
```

[← Previous](part48.md) | [Next →](part50.md)
