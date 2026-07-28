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


### Practice 2: Mount /tmp on tmpfs with Restrictions

```bash
echo "tmpfs /tmp tmpfs defaults,noexec,nosuid,nodev,size=2G 0 0" >> /etc/fstab
mount -a
mount | grep /tmp
```

✅ Expected: `/tmp` shows `tmpfs` type with `noexec,nosuid,nodev` options; `touch /tmp/test && chmod +x /tmp/test && /tmp/test` fails with "Permission denied"


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





[← Previous](11-9-automated-compliance-openscap-and.md) | [↑ Index](index.md) | [Next →](13-deep-understanding.md)
