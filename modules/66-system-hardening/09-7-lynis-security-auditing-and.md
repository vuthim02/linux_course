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





[← Previous](08-6-fail2ban-automated-intrusion-prevention.md) | [↑ Index](index.md) | [Next →](10-8-aide-file-integrity-monitoring.md)
