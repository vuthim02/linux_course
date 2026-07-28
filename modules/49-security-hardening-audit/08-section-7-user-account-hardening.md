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





[← Previous](07-section-6-file-integrity-monitoring.md) | [↑ Index](index.md) | [Next →](09-section-8-filesystem-security.md)
