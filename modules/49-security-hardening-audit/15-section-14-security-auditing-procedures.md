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



---

[← Previous](14-section-13-log-security.md) | [↑ Index](index.md) | [Next →](16-practice-section-15-hands-on-exercises.md)
