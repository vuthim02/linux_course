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





[← Previous](06-section-5-auditd-linux-audit.md) | [↑ Index](index.md) | [Next →](08-section-7-user-account-hardening.md)
