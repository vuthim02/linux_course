## 🖐️ Hands-On Practices

### Practice 1: Read and Understand Your PAM Stack

```bash
# View the PAM configuration for SSH
cat /etc/pam.d/sshd

# View the PAM configuration for login
cat /etc/pam.d/login

# Compare them — what modules are different?
diff /etc/pam.d/sshd /etc/pam.d/login

# Find all PAM modules loaded on your system
find /usr/lib64/security/ -name "pam_*.so" | sort

# On Debian/Ubuntu:
find /lib/security/ -name "pam_*.so" | sort
```

✅ **Expected**: You can identify the auth, account, password, and session lines in each config, and see which modules are shared

### Practice 2: Trace a Login Through PAM

```bash
# Add debug logging to PAM
# Edit /etc/pam.d/su and add "debug" to pam_unix.so line:
# auth  required  pam_unix.so debug

# Monitor PAM debug output
sudo journalctl -f &

# In another terminal, try to su to a user
su - testuser
# Enter wrong password, then correct password

# Check the logs for PAM module messages
sudo journalctl | grep pam_ | tail -20

# Remove debug when done
```

✅ **Expected**: You see detailed PAM module output including password verification steps

### Practice 3: Test pam_faillock

```bash
# Enable faillock with authselect
sudo authselect enable-feature with-faillock
sudo authselect apply-changes

# Check current faillock status
sudo faillock --user testuser

# Attempt 5 wrong passwords
for i in $(seq 1 6); do
  echo "Attempt $i:"
  su -c "echo 'wrong'" testuser 2>&1 || true
done

# Check lockout status
sudo faillock --user testuser

# Reset the lockout
sudo faillock --user testuser --reset

# Verify unlocked
sudo faillock --user testuser
```

✅ **Expected**: After 5 failed attempts, the account is locked; `faillock --reset` clears it

### Practice 4: Configure Password Quality

```bash
# Set password policy
cat <<EOF | sudo tee /etc/security/pwquality.conf
minlen = 14
dcredit = -1
ucredit = -1
lcredit = -1
ocredit = -1
maxrepeat = 3
maxclassrepeat = 4
dictcheck = 1
usercheck = 1
retry = 3
EOF

# Test the policy
passwd testuser
# Try "password" → should fail
# Try "Str0ng!Pass#2026" → should succeed

# View current password aging
sudo chage -l testuser
```

✅ **Expected**: Weak passwords are rejected; policy matches your pwquality.conf settings

### Practice 5: Explore SSSD Status

```bash
# Check SSSD service status
sudo systemctl status sssd

# List configured domains
sudo sssctl domain-status example.com

# Check SSSD configuration
sudo cat /etc/sssd/sssd.conf

# View SSSD cache
sudo sss_cache -E     # Expire cache
sudo ldbsearch -H /var/lib/sss/db/config.ldb | head -50

# Check what NSS uses
getent passwd | grep sss
getent passwd | grep files
```

✅ **Expected**: You can see SSSD is running, domain status, and NSS configuration showing `sss` before `files`

### Practice 6: LDAP Connectivity Test

```bash
# Test LDAP server connectivity
ldapsearch -x -H ldaps://ldap.example.com \
  -b "dc=example,dc=com" \
  -D "cn=readonly,ou=Service,dc=example,dc=com" \
  -W \
  "(objectClass=posixAccount)" \
  uid uidNumber homeDirectory

# Check TLS certificate
openssl s_client -connect ldap.example.com:636 -showcerts

# Test with ldapwhoami
ldapwhoami -x -H ldaps://ldap.example.com \
  -D "cn=readonly,ou=Service,dc=example,dc=com" \
  -W
```

✅ **Expected**: LDAP search returns user entries; TLS certificate is valid; ldapwhoami returns the bind DN

### Practice 7: Use authselect Safely

```bash
# View current profile
authselect current

# Create a backup
sudo authselect backup /root/pam-before-changes

# List available profiles
authselect list

# Switch to SSSD profile
sudo authselect select sssd --force

# Enable features
sudo authselect enable-feature with-faillock
sudo authselect enable-feature with-mkhomedir

# Verify changes were applied
diff <(cat /etc/pam.d/system-auth) <(authselect list | grep system-auth)

# Restore if needed
sudo authselect restore /root/pam-before-changes
```

✅ **Expected**: You can switch profiles, enable features, and restore backups cleanly

### Practice 8: Custom PAM Profile

```bash
# Create a custom profile
sudo authselect create-profile hardened \
  -b sssd \
  --symlink-pam \
  --symlink-nsswitch

# View the custom profile
ls -la /etc/authselect/custom/hardened/

# Edit system-auth to add custom requirements
sudo vi /etc/authselect/custom/hardened/system-auth
# Add: auth required pam_faillock.so deny=3 unlock_time=600

# Apply the custom profile
sudo authselect select custom/hardened --force

# Verify it's active
authselect current
```

✅ **Expected**: Custom profile is created, selected, and active with your modifications

### Practice 9: Debug SSSD Authentication

```bash
# Enable maximum debug logging
sudo sed -i 's/debug_level = .*/debug_level = 9/' /etc/sssd/sssd.conf
sudo systemctl restart sssd

# Clear cache
sudo sss_cache -E

# Try to authenticate
su - ldapuser

# Check debug logs
sudo tail -100 /var/log/sssd/sssd_example.com.log
sudo tail -50 /var/log/sssd/sssd_pam.log

# Search for errors
sudo grep -i "error\|fail\|denied" /var/log/sssd/sssd_example.com.log | tail -20

# Reset debug level
sudo sed -i 's/debug_level = 9/debug_level = 3/' /etc/sssd/sssd.conf
sudo systemctl restart sssd
```

✅ **Expected**: Debug logs show the full authentication flow including LDAP queries, cache operations, and result codes

### Practice 10: Manage User Password Aging

```bash
# Set password aging for a user
sudo chage -M 60 -m 7 -W 14 -I 14 testuser

# Verify settings
sudo chage -l testuser

# Force password change on next login
sudo chage -d 0 testuser

# View /etc/shadow entry (password fields)
sudo getent shadow testuser

# Set global defaults
grep -E "^PASS_" /etc/login.defs
```

✅ **Expected**: Password aging is configured; `chage -l` shows correct expiry dates

### Practice 11: pam_google_authenticator Setup

```bash
# Install (RHEL)
sudo dnf install google-authenticator

# Add to PAM for SSH
# Edit /etc/pam.d/sshd, add at the top:
# auth required pam_google_authenticator.so

# Enable in sshd_config
sudo sed -i 's/#ChallengeResponseAuthentication no/ChallengeResponseAuthentication yes/' /etc/ssh/sshd_config
sudo sed -i 's/UsePAM yes/UsePAM yes\nAuthenticationMethods publickey,keyboard-interactive/' /etc/ssh/sshd_config
sudo systemctl restart sshd

# Set up as regular user
su - testuser
google-authenticator
# Answer the prompts (scan QR code, save backup codes)

# Test: SSH should ask for verification code after key auth
```

✅ **Expected**: SSH login requires both SSH key AND TOTP verification code

### Practice 12: Audit PAM Configuration Changes

```bash
# Set up audit rules for PAM files
sudo auditctl -w /etc/pam.d/ -p wa -k pam_config_change
sudo auditctl -w /etc/sssd/sssd.conf -p wa -k sssd_config_change

# Make a change (create a test backup)
sudo cp /etc/pam.d/sshd /etc/pam.d/sshd.bak

# Search audit log
sudo ausearch -k pam_config_change -ts recent

# Remove test backup
sudo rm /etc/pam.d/sshd.bak
sudo ausearch -k pam_config_change -ts recent
```

✅ **Expected**: Audit log captures all modifications to PAM configuration files

### Practice 13: Centralized User Verification

```bash
# Test user lookup from multiple sources
echo "=== NSS Sources ==="
getent passwd john     # Should come from SSSD (LDAP) or files
getent group admins    # Should come from SSSD

echo "=== PAM Sources ==="
su - john -c "whoami && id && echo 'PAM auth works'"

echo "=== SSH Key from LDAP ==="
sudo ssh ldapuser@localhost "echo 'LDAP SSH key auth works'"

echo "=== Home Directory ==="
ls -la /home/john/     # Should exist (with mkhomedir feature)

echo "=== Sudo from LDAP ==="
sudo -l -U john        # Should show LDAP-defined sudo rules
```

✅ **Expected**: All lookups come from centralized LDAP, not local files

### Practice 14: PAM Session Tracking

```bash
# Add session logging to PAM
# Edit /etc/pam.d/sshd, add:
# session optional pam_exec.so /usr/local/bin/log_session.sh

# Create the logging script
sudo cat <<'SCRIPT' > /usr/local/bin/log_session.sh
#!/bin/bash
echo "$(date) | USER=$PAM_USER | SERVICE=$PAM_SERVICE | TYPE=$PAM_TYPE | TTY=$PAM_TTY" >> /var/log/pam_sessions.log
SCRIPT
sudo chmod 755 /usr/local/bin/log_session.sh

# Test by SSHing in
ssh testuser@localhost "exit"

# Check the log
cat /var/log/pam_sessions.log
```

✅ **Expected**: Session open/close events are logged with user, service, and timestamp

### Practice 15: Complete PAM Security Audit

```bash
#!/bin/bash
# pam_audit.sh — Security audit of PAM configuration
echo "=== PAM Security Audit ==="
echo "Timestamp: $(date)"
echo ""

echo "1. Faillock status for locked accounts:"
sudo faillock --user 2>/dev/null | head -10 || echo "  (pam_faillock not configured)"
echo ""

echo "2. Password policy:"
grep -E "^PASS_" /etc/login.defs
echo ""

echo "3. PAM config file permissions:"
ls -la /etc/pam.d/ | head -10
echo ""

echo "4. SSSD config permissions:"
ls -la /etc/sssd/sssd.conf
echo ""

echo "5. Accounts with no password (security risk):"
sudo awk -F: '($2 == "" || $2 == "!") {print $1}' /etc/shadow
echo ""

echo "6. Accounts with UID 0 (root-level):"
awk -F: '$3 == 0 {print $1}' /etc/passwd
echo ""

echo "7. Recently failed logins:"
sudo lastb 2>/dev/null | head -10
echo ""

echo "8. Active PAM modules:"
ls /usr/lib64/security/pam_*.so 2>/dev/null | wc -l
echo ""

echo "9. Current authselect profile:"
authselect current 2>/dev/null || echo "  (authselect not available)"
echo ""

echo "10. Audit rules for PAM:"
sudo auditctl -l 2>/dev/null | grep -i "pam\|sssd" || echo "  (no PAM audit rules)"
```

✅ **Expected**: Complete security audit showing PAM configuration, password policies, and potential vulnerabilities

---



---

[← Previous](10-9-pam-security.md) | [↑ Index](index.md) | [Next →](12-deep-understanding.md)
