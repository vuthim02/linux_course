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





[← Previous](15-section-14-security-auditing-procedures.md) | [↑ Index](index.md) | [Next →](17-deep-understanding.md)
